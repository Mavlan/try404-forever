local _, FLT = ...
local L = FLT.L or setmetatable({}, { __index = function(_, k) return k end }) -- (tests without Locales)
local UI = FLT.UI

-- Dungeon maps: the game's own minimap pictures of the rooms, laid out with the
-- map data of Forever Simple World Map by Tarolg (MIT, see THIRD_PARTY_LICENSES.txt;
-- data in Data\DungeonMaps.lua). Shown in Dungeons & Raids ("Map") and, if the
-- player wants, on the world map key (M) inside a dungeon.

-- Texture corners for a right-angle turn (Texture:SetTexCoord with 8 values):
-- upper-left, lower-left, upper-right, lower-right.
local TURNS = {
  [0] = { 0, 0, 0, 1, 1, 0, 1, 1 },
  [1] = { 1, 0, 0, 0, 1, 1, 0, 1 },
  [2] = { 1, 1, 1, 0, 0, 1, 0, 0 },
  [3] = { 0, 1, 1, 1, 0, 0, 1, 0 },
}
local function quarterTurn(angle)
  local quarter = angle / (math.pi / 2)
  local nearest = math.floor(quarter + 0.5)
  if math.abs(quarter - nearest) * 90 > 0.5 then return nil end
  return nearest % 4
end

local MIN_ZOOM, MAX_ZOOM = 1, 6

-- Map widget: f:SetMap(map, dungeon, onBoss) draws a map from FLT.DUNGEON_MAPS;
-- onBoss(index) is called when a boss marker is clicked.
function UI.CreateDungeonMap(parent)
  local f = CreateFrame("Frame", nil, parent)
  UI.FramedPanel(f)
  local vp = CreateFrame("Frame", nil, f); vp:SetPoint("TOPLEFT", 8, -8); vp:SetPoint("BOTTOMRIGHT", -8, 30)
  if vp.SetClipsChildren then vp:SetClipsChildren(true) end
  vp:EnableMouse(true)
  if vp.EnableMouseWheel then vp:EnableMouseWheel(true) end
  local bg = vp:CreateTexture(nil, "BACKGROUND"); bg:SetAllPoints(); bg:SetColorTexture(0.015, 0.015, 0.02, 1)
  local canvas = CreateFrame("Frame", nil, vp); canvas:SetAllPoints()
  local pinLayer = CreateFrame("Frame", nil, vp); pinLayer:SetAllPoints(); pinLayer:SetFrameLevel((canvas:GetFrameLevel() or 1) + 5)

  local hint = FLT.NewFS(f, nil, "OVERLAY", "GameFontDisableSmall")
  hint:SetPoint("BOTTOMLEFT", 12, 10)
  hint:SetText(L["Mouse wheel: zoom  ·  drag: move  ·  click a boss to see its loot  ·  map layout: Forever Simple World Map by Tarolg"])
  local fit = UI.GoldButton(f, L["Fit"], 54, 20, nil, 11); fit:SetPoint("BOTTOMRIGHT", -10, 6)
  -- switch to the game's world map (user 05.11.: from the dungeon map on M there was no way to it)
  local wm = UI.GoldButton(f, L["World map"], 90, 20, nil, 11); wm:SetPoint("RIGHT", fit, "LEFT", -6, 0)
  wm:SetScript("OnClick", function()
    if UI.IsWindowShown and UI.IsWindowShown() then FLT:ToggleUI() end
    if ToggleWorldMap then ToggleWorldMap() elseif WorldMapFrame then WorldMapFrame:Show() end
  end)
  local note = FLT.NewFS(f, nil, "OVERLAY", "GameFontHighlightSmall"); note:SetPoint("TOPLEFT", vp, "TOPLEFT", 10, -8)
  note:SetTextColor(0.75, 0.72, 0.66)

  local tex, pins = {}, {}
  local items = {} -- { texture, u, v, width, height, turn } for everything drawn on the canvas
  local mask
  local map, data, dungeon, onBoss
  local floorRoot, floorIndex
  local nav, routeShown, segments, routeIndex = nil, true, {}, 1
  -- Put the location above the map's child frames, not on the parent behind the tiles.
  local roomPin = pinLayer:CreateTexture(nil, "OVERLAY")
  roomPin:SetTexture("Interface\\TargetingFrame\\UI-RaidTargetingIcon_1")
  roomPin:SetSize(26, 26); roomPin:Hide()
  local roomText = FLT.NewFS(pinLayer, nil, "OVERLAY", "GameFontNormalSmall")
  roomText:SetPoint("TOPLEFT", vp, "TOPLEFT", 10, -25)
  local roomPoint
  local routeButton
  local function label(cn, tw, en)
    local lang = FLT.Language and FLT.Language()
    return lang == "zhCN" and cn or lang == "zhTW" and tw or en
  end
  local floorButton = UI.GoldButton(f, "", 86, 20, nil, 11)
  floorButton:SetFrameLevel((pinLayer:GetFrameLevel() or 1) + 10) -- keep the control above the map and boss pins
  floorButton:SetPoint("TOPRIGHT", vp, "TOPRIGHT", -8, -8); floorButton:Hide()
  floorButton:SetScript("OnClick", function()
    if floorRoot then floorIndex = floorIndex % #floorRoot.floors + 1; f:SetMap(floorRoot, dungeon, onBoss, floorIndex) end
  end)
  routeButton = UI.GoldButton(f, "", 90, 20, nil, 11)
  routeButton:SetPoint("TOPRIGHT", vp, "TOPRIGHT", -8, -32)
  routeButton:SetFrameLevel((pinLayer:GetFrameLevel() or 1) + 10)
  local zoom, ox, oy = 1, 0, 0
  local TILE = 1600 / 3 -- size of an outdoor minimap square in yards

  local function baseK()
    local b = map.bounds
    local w, h = vp:GetWidth() or 1, vp:GetHeight() or 1
    if w < 10 or h < 10 then return 1 end
    return math.min(w / (b[3] - b[1]), h / (b[4] - b[2])) * 0.94
  end
  -- screen offset (from the viewport centre) of canvas point u, v
  local function toScreen(u, v, k)
    local b = map.bounds
    local cu, cv = (b[1] + b[3]) / 2, (b[2] + b[4]) / 2
    return (u - cu) * k + ox, -(v - cv) * k + oy
  end

  local function layout()
    if not map then return end
    local k = baseK() * zoom
    local w, h = vp:GetWidth() or 0, vp:GetHeight() or 0
    for _, it in ipairs(items) do
      local x = it[1]
      if it[6] and it[6] % 2 == 1 then x:SetSize(it[5] * k + 0.5, it[4] * k + 0.5) else x:SetSize(it[4] * k + 0.5, it[5] * k + 0.5) end
      local sx, sy = toScreen(it[2], it[3], k)
      x:ClearAllPoints(); x:SetPoint("CENTER", vp, "TOPLEFT", w / 2 + sx, -h / 2 + sy)
    end
    for _, p in ipairs(pins) do
      if p:IsShown() then
        local sx, sy = toScreen(p.u, p.v, k)
        p:ClearAllPoints(); p:SetPoint("CENTER", vp, "TOPLEFT", w / 2 + sx, -h / 2 + sy)
      end
    end
    for _, line in ipairs(segments) do
      if routeShown and line.enabled then
        local ax, ay = toScreen(line.u1, line.v1, k)
        local bx, by = toScreen(line.u2, line.v2, k)
        line:ClearAllPoints()
        line:SetStartPoint("TOPLEFT", vp, w / 2 + ax, -h / 2 + ay)
        line:SetEndPoint("TOPLEFT", vp, w / 2 + bx, -h / 2 + by)
        line:Show()
        if line.arrowA and line.hasArrow then
          local dx, dy = bx - ax, by - ay
          local length = math.sqrt(dx * dx + dy * dy)
          if length >= 8 then
            dx, dy = dx / length, dy / length
            local mx, my = (ax + bx) / 2, (ay + by) / 2
            for i, wing in ipairs({line.arrowA, line.arrowB}) do
              local side = i == 1 and 1 or -1
              wing:SetStartPoint("TOPLEFT", vp, w / 2 + mx, -h / 2 + my)
              wing:SetEndPoint("TOPLEFT", vp, w / 2 + mx - dx * 7 - dy * 4 * side, -h / 2 + my - dy * 7 + dx * 4 * side)
              wing:Show()
            end
          else line.arrowA:Hide(); line.arrowB:Hide() end
        end
      else
        line:Hide()
        if line.arrowA then line.arrowA:Hide(); line.arrowB:Hide() end
      end
    end
    if roomPoint then
      local sx, sy = toScreen(roomPoint[1], roomPoint[2], k)
      roomPin:ClearAllPoints(); roomPin:SetPoint("CENTER", vp, "TOPLEFT", w / 2 + sx, -h / 2 + sy)
      roomPin:Show()
    else roomPin:Hide() end
  end

  local function updateRoom()
    roomPoint = nil
    local roomName, unknownName
    if nav and dungeon and IsInInstance and GetInstanceInfo then
      local inside, kind = IsInInstance()
      local _, _, _, _, _, _, _, id = GetInstanceInfo()
      if not (issecretvalue and (issecretvalue(inside) or issecretvalue(kind) or issecretvalue(id)))
          and inside and (kind == "party" or kind == "raid") and id == nav.instanceID then
        local sub = GetSubZoneText and GetSubZoneText()
        local mini = GetMinimapZoneText and GetMinimapZoneText()
        if issecretvalue and issecretvalue(sub) then sub = nil end
        if issecretvalue and issecretvalue(mini) then mini = nil end
        unknownName = (type(sub) == "string" and sub ~= "" and sub) or (type(mini) == "string" and mini ~= "" and mini) or nil
        for _, room in ipairs(nav.rooms or {}) do
          if (sub and sub ~= "" and (room[1] == sub or room[2] == sub or room[3] == sub))
              or (mini and mini ~= "" and (room[1] == mini or room[2] == mini or room[3] == mini)) then
            local lang = FLT.Language and FLT.Language()
            roomName = lang == "zhCN" and room[2] or lang == "zhTW" and room[3] or room[1]
            local best
            for _, box in ipairs(room[4]) do
              if (box[1] == 0 or box[1] == floorIndex) and (not best or box[4] > best[4]) then best = box end
            end
            if best then roomPoint = { best[2], best[3] } end
            break
          end
        end
      end
    end
    roomText:SetText(roomName and (label("所在区域（大致）：", "所在區域（大致）：", "Approximate area: ") .. roomName)
      or unknownName and (label("区域暂无法定位：", "區域暫無法定位：", "Area not located: ") .. unknownName) or "")
    layout()
  end
  routeButton:SetScript("OnClick", function()
    if nav and #nav.routes > 1 then
      if not routeShown then routeShown, routeIndex = true, 1
      elseif routeIndex < #nav.routes then routeIndex = routeIndex + 1
      else routeShown = false end
    else routeShown = not routeShown end
    local savedZoom, savedX, savedY = zoom, ox, oy
    if floorRoot then f:SetMap(floorRoot, dungeon, onBoss, floorIndex) else f:SetMap(map, dungeon, onBoss) end
    zoom, ox, oy = savedZoom, savedX, savedY
    layout()
  end)
  routeButton:SetScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, "ANCHOR_LEFT")
    GameTooltip:AddLine(label("点击切换路线或隐藏路线。金色为主路线，蓝色为支线。", "點擊切換路線或隱藏路線。金色為主路線，藍色為支線。", "Click to switch or hide the route. Gold: main route; blue: side route."), 1, 1, 1, true)
    GameTooltip:Show()
  end)
  routeButton:SetScript("OnLeave", function() GameTooltip:Hide() end)
  for _, event in ipairs({"PLAYER_ENTERING_WORLD", "ZONE_CHANGED_NEW_AREA", "ZONE_CHANGED_INDOORS", "ZONE_CHANGED"}) do f:RegisterEvent(event) end
  f:SetScript("OnEvent", function() if f:IsShown() then updateRoom() end end)
  f:SetScript("OnShow", updateRoom)

  local nTex = 0
  local function nextTexture(image, layer, sub)
    nTex = nTex + 1
    local x = tex[nTex]
    if not x then x = canvas:CreateTexture(nil, layer); tex[nTex] = x end
    if x.RemoveMaskTexture and mask and x._ofaMasked then x:RemoveMaskTexture(mask); x._ofaMasked = nil end
    if type(image) == "string" then x:SetTexture(UI.ASSET_ROOT .. "Maps\\" .. image) else x:SetTexture(image) end
    x:SetDrawLayer(layer, sub or 0); x:SetVertexColor(1, 1, 1, 1)
    if x.SetRotation then x:SetRotation(0) end
    x:SetTexCoord(0, 1, 0, 1)
    x:Show()
    return x
  end
  local function useMask(x)
    if mask and x.AddMaskTexture then x:AddMaskTexture(mask); x._ofaMasked = true end
  end

  local function pin(i)
    local p = pins[i]; if p then return p end
    p = CreateFrame("Button", nil, pinLayer); p:SetSize(26, 26)
    local disc = p:CreateTexture(nil, "BACKGROUND"); disc:SetPoint("TOPLEFT", 3, -3); disc:SetPoint("BOTTOMRIGHT", -3, 3)
    disc:SetTexture("Interface\\CHARACTERFRAME\\TempPortraitAlphaMask"); disc:SetVertexColor(0.06, 0.05, 0.04, 0.92)
    local ring = p:CreateTexture(nil, "BORDER"); ring:SetAllPoints(); FLT.SetTex(ring, UI.ASSET_ROOT .. "ring_gold")
    p.disc, p.ring = disc, ring
    p.icon = p:CreateTexture(nil, "ARTWORK"); p.icon:SetSize(14, 14); p.icon:SetPoint("CENTER")
    p.num = FLT.NewFS(p, nil, "OVERLAY", "GameFontNormalSmall"); p.num:SetPoint("CENTER", 0, 0)
    -- boss portrait in the gold boss ring (same as Bosses & Loot), shown instead of the disc
    p.boss = UI.CreateBossFrame and UI.CreateBossFrame(p, 34, false, true)
    if p.boss then p.boss:SetPoint("CENTER"); p.boss:Hide() end
    -- a boss killed in your current run (dungeon tracker, 6.2.14): red X like on the tracker (user 23.11.)
    p.dead = p:CreateTexture(nil, "OVERLAY", nil, 3); p.dead:SetSize(24, 24); p.dead:SetPoint("CENTER")
    p.dead:SetTexture("Interface\\RaidFrame\\ReadyCheck-NotReady"); p.dead:Hide()
    p.label = FLT.NewFS(p, nil, "OVERLAY", "GameFontHighlightSmall"); p.label:SetPoint("TOP", p, "BOTTOM", 0, -3)
    p.label:SetShadowColor(0, 0, 0, 1); p.label:SetShadowOffset(1, -1)
    local hl = p:CreateTexture(nil, "HIGHLIGHT"); hl:SetAllPoints(); hl:SetBlendMode("ADD")
    FLT.SetTex(hl, UI.ASSET_ROOT .. "ring_plain"); hl:SetVertexColor(FLT.SkinC(1, 0.85, 0.45, 0.8)) -- matches the plain boss ring
    p:SetScript("OnEnter", function(self)
      GameTooltip:SetOwner(self, "ANCHOR_RIGHT"); GameTooltip:AddLine(self.title, 1, 0.82, 0)
      if self.killed then GameTooltip:AddLine(string.format(L["Killed after %s"], FLT.RunTracker.Clock(self.killed)), 0.45, 1, 0.5) end
      if self.tip then GameTooltip:AddLine(self.tip, 1, 1, 1, true) end
      GameTooltip:Show()
    end)
    p:SetScript("OnLeave", function() GameTooltip:Hide() end)
    pins[i] = p
    return p
  end

  -- m = FLT.DUNGEON_MAPS[name] (what to show of which map), d = our dungeon
  function f:SetMap(m, d, bossCallback, selectedFloor)
    floorRoot = m.floors and m or nil
    if floorRoot then
      floorIndex = selectedFloor or 1; m = floorRoot.floors[floorIndex]
      local lang = FLT.Language and FLT.Language()
      floorButton:SetLabel((lang == "zhTW" and "樓層 " or lang == "zhCN" and "楼层 " or "Floor ") .. floorIndex .. "/" .. #floorRoot.floors)
      if #floorRoot.floors > 1 then floorButton:Show() else floorButton:Hide() end
      hint:SetText(lang == "zhTW" and "滾輪縮放 · 拖曳移動 · 點擊首領查看戰利品" or lang == "zhCN" and "滚轮缩放 · 拖动移动 · 点击首领查看战利品" or "Mouse wheel: zoom · drag: move · click a boss to see its loot")
    else
      floorIndex = nil; floorButton:Hide()
      hint:SetText(L["Mouse wheel: zoom  ·  drag: move  ·  click a boss to see its loot  ·  map layout: Forever Simple World Map by Tarolg"])
    end
    map, dungeon, onBoss = m, d, bossCallback
    local previousNav = nav
    nav = d and FLT.DUNGEON_NAV and FLT.DUNGEON_NAV[d.name]
    if nav ~= previousNav then routeIndex, routeShown = 1, true end
    for _, line in ipairs(segments) do
      line.enabled = false; line:Hide()
      if line.arrowA then line.arrowA:Hide(); line.arrowB:Hide() end
    end
    local count = 0
    if nav and canvas.CreateLine then
      for _, path in ipairs((nav.routes[routeIndex] and nav.routes[routeIndex].paths) or {}) do
        if path[1] == 0 or path[1] == floorIndex then
          for j = 3, #path - 3, 2 do
            count = count + 1
            local line = segments[count]
            if not line then line = canvas:CreateLine(nil, "OVERLAY"); segments[count] = line end
            line.enabled, line.u1, line.v1, line.u2, line.v2 = true, path[j], path[j+1], path[j+2], path[j+3]
            line:SetThickness(path[2] == 1 and 3 or 2)
            if path[2] == 1 then line:SetColorTexture(1, 0.72, 0.12, 0.9) else line:SetColorTexture(0.5, 0.75, 1, 0.8) end
            if path[2] == 1 and (j - 3) % 12 == 0 then
              line.hasArrow = true
              if not line.arrowA then
                line.arrowA = canvas:CreateLine(nil, "OVERLAY"); line.arrowB = canvas:CreateLine(nil, "OVERLAY")
                for _, wing in ipairs({line.arrowA, line.arrowB}) do wing:SetThickness(2); wing:SetColorTexture(1, 0.9, 0.55, 1) end
              end
            elseif line.arrowA then
              line.arrowA:Hide(); line.arrowB:Hide(); line.hasArrow = false
            end
          end
        end
      end
    end
    local hasRoute = count > 0
    if nav and not hasRoute then
      for _, candidate in ipairs(nav.routes) do
        for _, path in ipairs(candidate.paths or {}) do
          if path[1] == 0 or path[1] == floorIndex then hasRoute = true; break end
        end
        if hasRoute then break end
      end
    end
    routeButton:SetShown(hasRoute and canvas.CreateLine ~= nil)
    if nav and #nav.routes > 1 then
      local r = nav.routes[routeIndex]
      routeButton:SetLabel(routeShown and label(r[2], r[3], r[1]) or label("路线：关闭", "路線：關閉", "Route: off"))
    else
      routeButton:SetLabel(routeShown and label("隐藏路线", "隱藏路線", "Hide route") or label("显示路线", "顯示路線", "Show route"))
    end
    data = FLT.DUNGEON_MAP_DATA and FLT.DUNGEON_MAP_DATA[m.map] or {}
    zoom, ox, oy = 1, 0, 0
    for _, x in ipairs(tex) do x:Hide() end
    nTex, items = 0, {}
    local part = m.part
    local function inPart(u, v) return not part or (u >= part[1] and u <= part[3] and v >= part[2] and v <= part[4]) end
    -- the outdoor ground and extra pictures are seen through the map's soft-edged mask
    if data.mask then
      mask = mask or (canvas.CreateMaskTexture and canvas:CreateMaskTexture())
      if mask then
        mask:SetTexture(UI.ASSET_ROOT .. "Maps\\" .. m.map .. "_mask", "CLAMPTOBLACKADDITIVE", "CLAMPTOBLACKADDITIVE")
        local r = data.mask
        items[#items + 1] = { mask, (r[1] + r[3]) / 2, (r[2] + r[4]) / 2, r[3] - r[1], r[4] - r[2] }
      end
    end
    local shade = (#(data.tiles or {}) > 0 and not data.ground) and 0.6 or 1
    if data.mask and mask then
      for cell, fid in pairs(data.terrain or {}) do
        local row, col = math.floor(cell / 64), cell % 64
        local x = nextTexture(fid, "BACKGROUND", 0); x:SetVertexColor(shade, shade, shade, 1); useMask(x)
        items[#items + 1] = { x, (col + 0.5) * TILE, (row + 0.5) * TILE, TILE, TILE }
      end
      for _, a in ipairs(data.art or {}) do
        local x = nextTexture(a[1], "BACKGROUND", 1); useMask(x)
        items[#items + 1] = { x, (a[2] + a[4]) / 2, (a[3] + a[5]) / 2, a[4] - a[2], a[5] - a[3] }
      end
    end
    for _, t in ipairs(data.tiles or {}) do
      if inPart(t[2], t[3]) then
        local x = nextTexture(t[1], "ARTWORK", t[7] or 0)
        local turn = quarterTurn(t[6])
        if t[8] then
          x:SetTexCoord(unpack(t[8]))
        elseif turn then
          local c = TURNS[turn]
          x:SetTexCoord(c[1], c[2], c[3], c[4], c[5], c[6], c[7], c[8])
        elseif x.SetRotation then
          x:SetRotation(t[6])
        end
        items[#items + 1] = { x, t[2], t[3], t[4], t[5], turn or 0 }
      end
    end
    for _, p in ipairs(pins) do p:Hide() end
    local n = 0
    -- our boss list decides the numbers (same order as Bosses & Loot)
    local order = {}
    for i, b in ipairs((d and d.bosses) or {}) do order[b.name or tostring(b)] = i end
    for i, b in ipairs(m.bosses or {}) do
      n = n + 1
      local p = pin(n); p:Show()
      local idx = order[b[1]] or i
      p.u, p.v, p.title = b[2], b[3], (FLT.Name and FLT.Name(b[1]) or b[1])
      p.tip = L["Click: show its loot in Bosses & Loot."]
      p.icon:Hide(); p.label:SetText(p.title)
      local boss = d and d.bosses and d.bosses[idx]
      p.bossRec = boss
      if p.boss and boss and UI.setBossPortrait then
        UI.setBossPortrait(p.boss.portrait, d, boss)
        p.boss:Show(); p.disc:Hide(); p.ring:Hide(); p.num:Hide(); p:SetSize(34, 34)
      else
        if p.boss then p.boss:Hide() end
        p.disc:Show(); p.ring:Show(); p.num:Show(); p.num:SetText(tostring(idx)); p:SetSize(26, 26)
      end
      p:SetScript("OnClick", function() if onBoss then onBoss(idx) end end)
    end
    if m.entrance then
      n = n + 1
      local p = pin(n); p:Show()
      p.u, p.v, p.title, p.tip, p.bossRec = m.entrance[1], m.entrance[2], L["Entrance"], nil, nil
      -- the dungeon / raid swirl of the world map (same as Map Landmarks, user 16.10.)
      p.num:Hide(); p.label:SetText(""); p.icon:Show(); p.icon:ClearAllPoints(); p.icon:SetAllPoints(p)
      if not (p.icon.SetAtlas and pcall(p.icon.SetAtlas, p.icon, (d and d.raid) and "raid" or "dungeon")) then
        p.icon:SetTexture("Interface\\Buttons\\UI-SpellbookIcon-NextPage-Up"); p.icon:SetTexCoord(0, 1, 0, 1)
      end
      if p.boss then p.boss:Hide() end
      p.disc:Hide(); p.ring:Hide(); p:SetSize(42, 42)
      p:SetScript("OnClick", nil)
    end
    -- numbered marks (Data/DungeonMapExtras.lua, 6.2.13-beta13, user 20.11.: the Sunken Temple statues 1-6 "ohne symbol"):
    -- the number on the dark disc, no ring and no icon
    local mk = m.marks
    for _, e in ipairs(mk or {}) do
      n = n + 1
      local p = pin(n); p:Show()
      p.u, p.v, p.bossRec = e[2], e[3], nil
      p.title = mk.title and string.format(L[mk.title], e[1]) or e[1]
      p.tip = mk.tip and L[mk.tip] or nil
      p.icon:Hide(); p.label:SetText(""); if p.boss then p.boss:Hide() end
      p.ring:Hide(); p.disc:Show(); p.num:Show(); p.num:SetText(e[1]); p:SetSize(20, 20)
      p:SetScript("OnClick", nil)
    end
    if floorRoot then
      local lang = FLT.Language and FLT.Language()
      note:SetText(lang == "zhTW" and "首領位置為近似值" or lang == "zhCN" and "首领位置为近似值" or "Boss positions are approximate")
    else
      note:SetText(#(m.bosses or {}) == 0 and L["Boss positions are not known yet for this dungeon."] or "")
    end
    updateRoom()
    f.MarkKills()
    layout()
  end
  -- the bosses dead in your current run of this dungeon (its open run in the dungeon tracker; gone after a reset)
  function f.MarkKills()
    local RT = FLT.RunTracker
    local c = RT and RT.Current and RT.Current()
    if c and not (dungeon and c.key == dungeon.key) then c = nil end
    for _, p in ipairs(pins) do
      local k = c and p.bossRec and RT.Killed(c, p.bossRec) or nil
      p.killed = k
      p.dead:SetShown(k and p:IsShown() and true or false)
      if p.boss then p.boss.portrait:SetDesaturated(k and true or false) end
    end
  end
  f.Refresh = function() f.MarkKills(); layout() end
  if FLT.RunTracker then
    local RT = FLT.RunTracker
    RT.mapViews = RT.mapViews or setmetatable({}, { __mode = "k" })
    RT.mapViews[f] = true
  end

  vp:SetScript("OnSizeChanged", layout)
  vp:SetScript("OnMouseWheel", function(self, delta)
    if not map then return end
    local old = zoom
    zoom = math.max(MIN_ZOOM, math.min(MAX_ZOOM, zoom * (delta > 0 and 1.25 or 0.8)))
    -- keep the point under the cursor where it is
    local cx, cy = GetCursorPosition()
    local s = self:GetEffectiveScale()
    local left, top = self:GetLeft(), self:GetTop()
    if left and top and s and s > 0 then
      local mx = cx / s - left - (self:GetWidth() or 0) / 2
      local my = cy / s - top + (self:GetHeight() or 0) / 2
      ox = mx - (mx - ox) * zoom / old
      oy = my - (my - oy) * zoom / old
    end
    if zoom == MIN_ZOOM then ox, oy = 0, 0 end
    layout()
  end)
  -- dragging: OnUpdate runs only between mouse down and up (one reused table)
  local drag = {}
  local function dragUpdate()
    local cx, cy = GetCursorPosition()
    ox = drag.ox + (cx - drag.x) / drag.s
    oy = drag.oy + (cy - drag.y) / drag.s
    layout()
  end
  local function stopDrag(self) self:SetScript("OnUpdate", nil) end
  vp:SetScript("OnMouseDown", function(self, button)
    if button ~= "LeftButton" then return end
    drag.x, drag.y = GetCursorPosition()
    drag.ox, drag.oy, drag.s = ox, oy, self:GetEffectiveScale()
    self:SetScript("OnUpdate", dragUpdate)
  end)
  vp:SetScript("OnMouseUp", stopDrag)
  vp:SetScript("OnHide", stopDrag)
  fit:SetScript("OnClick", function() zoom, ox, oy = 1, 0, 0; layout() end)
  return f
end

-- World map key (M) inside a dungeon ------------------------------------------
-- On by default, can be turned off (Settings > Dungeons | Raids): override bindings on the keys of "Toggle World
-- Map", owned by one button, only while we are in a dungeon that has a map.
-- Bindings cannot change in combat, so a change waits for the combat to end.
-- The button needs a global name for SetOverrideBindingClick.
local keyButton = CreateFrame("Button", "OneForAllDungeonMapKey", UIParent)
keyButton:SetScript("OnClick", function() FLT.SafeCall("DungeonMapKey", function() if FLT.ToggleDungeonMap then FLT.ToggleDungeonMap() end end) end)
local applied = ""

local function currentMapDungeon()
  local d = FLT.FindCurrentDungeon and FLT.FindCurrentDungeon()
  if d and FLT.DUNGEON_MAPS and FLT.DUNGEON_MAPS[d.name] then return d end
end

function FLT.ApplyDungeonMapKey()
  if type(SetOverrideBindingClick) ~= "function" or type(ClearOverrideBindings) ~= "function" or type(GetBindingKey) ~= "function" then return end
  if InCombatLockdown and InCombatLockdown() then keyButton:RegisterEvent("PLAYER_REGEN_ENABLED"); return end
  keyButton:UnregisterEvent("PLAYER_REGEN_ENABLED")
  local on = type(OneForAllDB) == "table" and OneForAllDB.dungeonMapKey == true and currentMapDungeon() ~= nil
  local keys = {}
  if on then for _, k in ipairs({ GetBindingKey("TOGGLEWORLDMAP") }) do if type(k) == "string" then keys[#keys + 1] = k end end end
  local sig = table.concat(keys, "\1")
  -- (re)binding fires UPDATE_BINDINGS again: nothing to do when it is unchanged
  if sig == applied then return end
  applied = sig
  ClearOverrideBindings(keyButton)
  for _, k in ipairs(keys) do SetOverrideBindingClick(keyButton, false, k, "OneForAllDungeonMapKey") end
end

-- test (/ofa dmap): any dungeon with a map when you are not in one
function FLT.ToggleDungeonMap(test, prepared)
  if UI.IsWindowShown and UI.IsWindowShown() then FLT:ToggleUI(); return end
  local d = currentMapDungeon()
  if not d and test and FLT.DUNGEONS and FLT.DUNGEON_MAPS then
    for _, x in ipairs(FLT.DUNGEONS) do if FLT.DUNGEON_MAPS[x.name] then d = x; break end end
  end
  if not d then if ToggleWorldMap then ToggleWorldMap() end return end
  -- 6.2.12-beta6 (Discord 18.11.: "script ran too long" on M in a dungeon): window, page and map one frame after the other
  if not prepared and UI.PrepareWindow then
    UI.PrepareWindow("dungeons", function() FLT.SafeCall("DungeonMapKey", FLT.ToggleDungeonMap, test, true) end)
    return
  end
  if not test and FLT.DungeonToOpen then d = FLT.DungeonToOpen() or d end -- the wing already shown stays (Scarlet Monastery)
  FLT:OpenPanel("dungeons")
  if UI.OpenDungeon then UI.OpenDungeon(d, nil, "map") end
end

keyButton:RegisterEvent("PLAYER_ENTERING_WORLD")
keyButton:RegisterEvent("ZONE_CHANGED_NEW_AREA")
keyButton:RegisterEvent("UPDATE_BINDINGS")
keyButton:SetScript("OnEvent", function() FLT.SafeCall("DungeonMapKey", FLT.ApplyDungeonMapKey) end)
