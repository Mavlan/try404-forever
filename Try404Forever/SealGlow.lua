-- Three-stack Echo indicator for the native cooldown viewer.
-- Aura slot and application bar approach adapted from Unsealed Wrath Tracker
-- 3.5.0, Copyright (c) 2026 KING, MIT License; see SEAL-GLOW-LICENSE.txt.
local _, FLT = ...
local _, class = UnitClass('player')
if class ~= 'PALADIN' then return end

-- Six Unsealed Wrath echoes: a cooldown viewer entry may link all six.
local ids = { [1311701] = true, [1311703] = true, [1311704] = true,
  [1311705] = true, [1328198] = true, [1328206] = true }
local entries, pending, scheduled = {}, false, false
local diag, rendered = {}, {}
local function combat() return InCombatLockdown and InCombatLockdown() end
local function enabled() return FLT.QoL and FLT.QoL.Get('sealEchoGlow') end
local function clean(v) return not (issecretvalue and issecretvalue(v)) end

local function findIDs(child)
  local ok, cooldown = pcall(function() return child.cooldownID end)
  if not ok or not clean(cooldown) or type(cooldown) ~= 'number' or not C_CooldownViewer then return end
  local good, info = pcall(C_CooldownViewer.GetCooldownViewerCooldownInfo, cooldown)
  if not good or not clean(info) or type(info) ~= 'table' then return end
  local found = {}
  local function add(v)
    if clean(v) and type(v) == 'number' and ids[v] then found[v] = true end
  end
  for _, key in ipairs({ 'spellID', 'overrideSpellID', 'overrideTooltipSpellID' }) do add(info[key]) end
  local linked = info.linkedSpellIDs
  if clean(linked) and type(linked) == 'table' then for _, v in ipairs(linked) do add(v) end end
  return found
end

local function disableAll()
  for _, group in pairs(entries) do
    for _, e in pairs(group) do
      pcall(e.container.SetEnabled, e.container, false)
      e.wrap:Hide()
    end
  end
end

local function create(icon, id)
  local wrap = CreateFrame('Frame', nil, UIParent)
  wrap:EnableMouse(false)
  wrap:SetAllPoints(icon)
  wrap:SetFrameLevel(icon:GetFrameLevel() + 5)
  local container = CreateFrame('AuraContainer', nil, wrap, 'CustomAuraContainerTemplate')
  container:SetEnabled(false)
  container:SetAuraProcessingPolicy(CustomAuraContainerAuraProcessingPolicy.None)
  container:SetAllPoints(wrap)
  container:SetUnit('player')
  container:AddAuraSlot('Echo', 'HELPFUL', { candidateFilters = { includeSpellIDs = { [id] = true } },
    initializeFrame = function(button)
      button:EnableMouse(false)
      button:SetAllPoints(wrap)
      local bar = CreateFrame('StatusBar', nil, button)
      bar:SetPoint('CENTER', wrap, 'CENTER')
      bar:SetSize(70, 70)
      bar:SetStatusBarTexture('Interface\\Buttons\\UI-ActionButton-Border')
      local texture = bar:GetStatusBarTexture()
      texture:SetBlendMode('ADD'); texture:SetVertexColor(1, 1, 1, 1)
      -- Blizzard's animated proc atlas, inside the same native 3-stack gate.
      -- The animation runs in the UI engine; no Lua OnUpdate or aura polling.
      local ok = pcall(function()
        texture:SetAtlas('UI-HUD-ActionBar-Proc-Loop-Flipbook')
        local animation = bar:CreateAnimationGroup()
        animation:SetLooping('REPEAT')
        local flip = animation:CreateAnimation('FlipBook')
        flip:SetTarget(texture)
        flip:SetDuration(1)
        flip:SetFlipBookColumns(5); flip:SetFlipBookRows(6); flip:SetFlipBookFrames(30)
        -- Secret-driven SetShown cannot run Lua OnShow/OnHide handlers.
        animation:Play()
      end)
      if not ok then
        bar:SetStatusBarTexture('Interface\\Buttons\\UI-ActionButton-Border')
        texture = bar:GetStatusBarTexture()
        texture:SetBlendMode('ADD'); texture:SetVertexColor(1, 0.82, 0.15, 1)
      end
      local okBind, errBind = pcall(button.SetApplicationBar, button, bar, { minApplications = 2, maxApplications = 3 })
      rendered[id] = okBind and 'display ready' or ('display error: ' .. tostring(errBind))
    end })
  container:SetAuraSlotEnabled('Echo', true)
  container:SetEnabled(true)
  entries[icon] = entries[icon] or {}
  entries[icon][id] = { wrap = wrap, container = container }
end

local function refresh()
  scheduled = false
  if combat() then pending = true; return end
  pending = false
  disableAll()
  if not enabled() then return end
  if not (CustomAuraContainerAuraProcessingPolicy and C_AuraContainerUtil and C_CooldownViewer) then return end
  local viewer = _G.BuffIconCooldownViewer
  if not viewer or not viewer.GetChildren then return end
  local ok, children = pcall(function() return { viewer:GetChildren() } end)
  if not ok then return end
  for _, icon in ipairs(children) do
    local good, matches = pcall(findIDs, icon)
    if good and matches then
      for id in pairs(matches) do
        local e = entries[icon] and entries[icon][id]
        if not e then
          local created, err = pcall(create, icon, id)
          diag[id] = created and 'ok' or tostring(err)
          if created then e = entries[icon] and entries[icon][id] end
        end
        if e then e.wrap:Show(); pcall(e.container.SetEnabled, e.container, true) end
      end
    end
  end
end
local function request()
  if combat() then pending = true; return end
  if scheduled then return end
  scheduled = true
  if C_Timer and C_Timer.After then C_Timer.After(0.25, refresh) else refresh() end
end
SLASH_TRY404SEALDEBUG1 = '/tsealdebug'
SlashCmdList.TRY404SEALDEBUG = function()
  print('TRY404 seal: ' .. (enabled() and 'enabled' or 'disabled'))
  for _, id in ipairs({1311701,1311703,1311704,1311705,1328198,1328206}) do
    print(id, diag[id] or 'not matched', rendered[id] or 'waiting for aura')
  end
end
FLT.QoL.On('sealEchoGlow', request)
local event = CreateFrame('Frame')
for _, name in ipairs({ 'PLAYER_ENTERING_WORLD', 'PLAYER_REGEN_ENABLED', 'COOLDOWN_VIEWER_DATA_LOADED',
  'PLAYER_TALENT_UPDATE', 'ACTIVE_TALENT_GROUP_CHANGED', 'ADDON_LOADED' }) do pcall(event.RegisterEvent, event, name) end
event:SetScript('OnEvent', function(_, name, arg)
  if name == 'PLAYER_REGEN_ENABLED' then if pending then request() end
  elseif name ~= 'ADDON_LOADED' or arg == 'Blizzard_CooldownViewer' then request() end
end)
if EventRegistry and EventRegistry.RegisterCallback then
  EventRegistry:RegisterCallback('CooldownViewerSettings.OnHide', request)
end
