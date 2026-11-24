local _, FLT = ...
local _, class = UnitClass("player")
if class ~= "PALADIN" then return end
local Q, L = FLT.QoL, FLT.L
local event = CreateFrame("Frame")
local card, castButton, timer, generation = nil, nil, nil, 0
local trackedEvents = false
local blessingIDs = {19740, 19742, 20217, 20911, 25782, 25894, 25898, 25899}
local function enabled() return Q.Get("paladinBlessingReminder") end
local function cancelTimer()
  generation = generation + 1
  if timer and timer.Cancel then timer:Cancel() end
  timer = nil
end
local function spellName(id)
  local ok, name = pcall(function()
    return C_Spell and C_Spell.GetSpellName and C_Spell.GetSpellName(id) or (GetSpellInfo and GetSpellInfo(id))
  end)
  if ok and type(name) == "string" and not FLT.IsSecret(name) then return name end
end
local function makeCard()
  if card then return end
  card = CreateFrame("Frame", nil, UIParent, "BackdropTemplate")
  card:SetSize(205, 48); card:SetPoint("CENTER", UIParent, "CENTER", 0, 170)
  card:SetFrameStrata("MEDIUM"); card:SetClampedToScreen(true)
  card:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8X8", edgeFile="Interface\\Buttons\\WHITE8X8", edgeSize=1})
  card:SetBackdropColor(0.07, 0.06, 0.04, 0.94); card:SetBackdropBorderColor(0.78, 0.56, 0.22, 1)
  local icon = card:CreateTexture(nil, "ARTWORK"); icon:SetSize(36, 36); icon:SetPoint("LEFT", 6, 0); card.icon = icon
  local title = card:CreateFontString(nil, "OVERLAY", "GameFontNormal"); title:SetPoint("TOPLEFT", icon, "TOPRIGHT", 8, -2); card.title = title
  local detail = card:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall"); detail:SetPoint("BOTTOMLEFT", icon, "BOTTOMRIGHT", 8, 2); card.detail = detail
  card:Hide()
end
local function syncCast(name)
  if InCombatLockdown and InCombatLockdown() then return end
  if name and card then
    if not castButton then
      castButton = CreateFrame("Button", "Try404PaladinBlessingCast", UIParent, "SecureActionButtonTemplate")
      castButton:SetSize(36, 36); castButton:SetFrameStrata("MEDIUM"); castButton:SetFrameLevel(card:GetFrameLevel() + 20)
      castButton:RegisterForClicks("AnyUp", "AnyDown")
      castButton:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Square", "ADD")
    end
    local x, y = card:GetLeft(), card:GetTop()
    if not x or not y then castButton:Hide(); return end
    castButton:ClearAllPoints(); castButton:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", x + 6, y - 6)
    castButton:SetAttribute("type", "spell"); castButton:SetAttribute("unit", "player"); castButton:SetAttribute("spell", name)
    castButton:Show()
  elseif castButton then castButton:Hide() end
end
local function hideCard()
  if card then card:Hide() end
  syncCast(nil)
end
local function show(id, name, missing)
  makeCard()
  local ok, icon = pcall(function() return C_Spell and C_Spell.GetSpellTexture and C_Spell.GetSpellTexture(id) or (GetSpellTexture and GetSpellTexture(id)) end)
  if ok and icon and not FLT.IsSecret(icon) then card.icon:SetTexture(icon) end
  card.title:SetText(name or spellName(id) or "Blessing")
  card.detail:SetText(missing and L["Blessing missing"] or L["Blessing expires soon"])
  card:Show()
  syncCast(name or spellName(id))
end
local function readOwnBlessing()
  local get = type(C_UnitAuras) == "table" and C_UnitAuras.GetAuraDataByIndex
  if not get then return false end -- unknown: never claim that a buff is missing
  local names = {}
  for _, id in ipairs(blessingIDs) do local n = spellName(id); if n then names[n] = true end end
  if not next(names) then return false end
  local otherBlessing = false
  for i = 1, 40 do
    local ok, aura = pcall(get, "player", i, "HELPFUL")
    if not ok then return false end
    if not aura then return otherBlessing and {other=true} or nil end
    local name, source = aura.name, aura.sourceUnit
    if FLT.IsSecret(name, source) then return false end
    if type(name) == "string" and names[name] then
      if source == nil then return false end -- cannot distinguish our blessing from another paladin's
      if type(source) == "string" then
        local own = source == "player"
        if not own and UnitIsUnit then
          local sameOK, same = pcall(UnitIsUnit, source, "player")
          if not sameOK or FLT.IsSecret(same) then return false end
          own = same == true
        end
        if own then
          local id, expiry = aura.spellId, aura.expirationTime
          if FLT.IsSecret(id, expiry) or type(id) ~= "number" or type(expiry) ~= "number" then return false end
          return {id=id, name=name, expiry=expiry}
        end
        otherBlessing = true
      end
    end
  end
  return otherBlessing and {other=true} or nil
end
local check
check = function()
  cancelTimer()
  if not enabled() then hideCard(); return end
  if UnitIsDeadOrGhost and UnitIsDeadOrGhost("player") then hideCard(); return end
  local aura = readOwnBlessing()
  if aura == false then hideCard(); return end -- aura state is unknown: do not keep a stale missing-buff warning
  local d = OneForAllCharDB
  if type(d) ~= "table" then return end
  if aura and aura.other then hideCard(); return end -- another paladin's blessing is already active
  if aura then
    d.try404LastBlessing = {id=aura.id, name=aura.name}
    local left = aura.expiry > 0 and (aura.expiry - GetTime()) or nil
    if left and left <= 30 then show(aura.id, aura.name, false)
    else
      hideCard()
      if left then
        local token = generation
        local function fire() if token == generation then check() end end
        if C_Timer.NewTimer then timer = C_Timer.NewTimer(math.max(0.1, left - 30), fire)
        elseif C_Timer.After then C_Timer.After(math.max(0.1, left - 30), fire) end
      end
    end
  elseif type(d.try404LastBlessing) == "table" and type(d.try404LastBlessing.id) == "number" then
    show(d.try404LastBlessing.id, spellName(d.try404LastBlessing.id) or d.try404LastBlessing.name, true)
  else hideCard() end
end
local function refresh()
  if enabled() and not trackedEvents then
    event:RegisterUnitEvent("UNIT_AURA", "player"); event:RegisterEvent("PLAYER_REGEN_ENABLED"); event:RegisterEvent("PLAYER_REGEN_DISABLED")
    event:RegisterEvent("PLAYER_DEAD"); event:RegisterEvent("PLAYER_ALIVE"); trackedEvents = true
  elseif not enabled() and trackedEvents then
    event:UnregisterEvent("UNIT_AURA"); event:UnregisterEvent("PLAYER_REGEN_ENABLED"); event:UnregisterEvent("PLAYER_REGEN_DISABLED")
    event:UnregisterEvent("PLAYER_DEAD"); event:UnregisterEvent("PLAYER_ALIVE"); trackedEvents = false
  end
  check()
end
Q.On("paladinBlessingReminder", refresh)
event:RegisterEvent("PLAYER_ENTERING_WORLD")
event:SetScript("OnEvent", function(_, name)
  if name == "PLAYER_ENTERING_WORLD" then refresh()
  elseif name == "PLAYER_REGEN_DISABLED" then if castButton then pcall(castButton.Hide, castButton) end
  else check() end
end)
