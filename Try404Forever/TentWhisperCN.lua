local _, FLT = ...
-- This helper intentionally runs only for the Simplified Chinese game client.
if not GetLocale or GetLocale() ~= "zhCN" then return end
local Q = FLT.QoL
local sequence, lastSent = 0, {}
local MESSAGE = "大佬能不能蹭一下你的帐篷，谢谢"
local frame = CreateFrame("Frame")
local function readable(value)
  if issecretvalue and issecretvalue(value) then return false end
  return type(value) == "string" and value ~= ""
end
local function trim(s) return (s:gsub("^%s+", ""):gsub("%s+$", "")) end
local function ownerFromLine(line)
  if not readable(line) then return nil end
  line = trim(line:gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", ""))
  line = line:gsub("^<%s*", ""):gsub("%s*>$", "")
  local owner = line:match("^放置者%s*：%s*(.+)$") or line:match("^放置者%s*:%s*(.+)$")
             or line:match("^所有者%s*：%s*(.+)$") or line:match("^所有者%s*:%s*(.+)$")
             or line:match("^由%s*(.-)%s*放置$")
             or line:match("^(.+)%s+放置$")
  if not owner then return nil end
  owner = trim(owner)
  if owner == "" or #owner > 96 or owner:find("[%c|<>:]") or owner:find("：", 1, true) then return nil end
  return owner
end
local function getLines()
  if not (C_TooltipInfo and C_TooltipInfo.GetUnit) then return nil end
  local ok, data = pcall(C_TooltipInfo.GetUnit, "target")
  if not ok or type(data) ~= "table" or (issecretvalue and issecretvalue(data)) or type(data.lines) ~= "table" then return nil end
  local lines = {}
  for _, entry in ipairs(data.lines) do
    if type(entry) == "table" and not (issecretvalue and issecretvalue(entry)) then
      if readable(entry.leftText) then lines[#lines + 1] = entry.leftText end
      if readable(entry.rightText) then lines[#lines + 1] = entry.rightText end
    end
  end
  return lines
end
local function tell(text)
  if DEFAULT_CHAT_FRAME and DEFAULT_CHAT_FRAME.AddMessage then DEFAULT_CHAT_FRAME:AddMessage("|cffffd100Try404 Guide：|r" .. text) end
end
local function selfName()
  if not UnitName then return nil end
  local a,b = UnitName("player")
  if not readable(a) then return nil end
  if readable(b) and not a:find(" ", 1, true) then return a .. " " .. b end
  return a
end
local function scan(seq, final)
  if seq ~= sequence or not Q or not Q.Get("tentWhisperCN") then return end
  if InCombatLockdown and InCombatLockdown() then return end
  if not UnitExists or not UnitExists("target") then return end
  local ok, targetName = pcall(UnitName, "target")
  if not ok or not readable(targetName) or not targetName:find("帐篷", 1, true) then return end
  local lines = getLines()
  if not lines then if final then tell("未能读取帐篷主人，未发送密语。") end; return end
  local owner
  for _,line in ipairs(lines) do owner = ownerFromLine(line); if owner then break end end
  if not owner then if final then tell("未能识别帐篷主人，未发送密语。") end; return end
  if owner == selfName() then return end
  local now = GetTime and GetTime() or 0
  if lastSent[owner] and now - lastSent[owner] < 30 then return end
  local send = C_ChatInfo and C_ChatInfo.SendChatMessage or SendChatMessage
  if type(send) ~= "function" then tell("帐篷主人：" .. owner .. "；游戏未提供密语接口。") return end
  lastSent[owner] = now
  tell("帐篷主人：" .. owner .. "，正在发送蹭帐篷请求。")
  local ok, result = pcall(send, MESSAGE, "WHISPER", nil, owner)
  if not ok or result == false then tell("游戏阻止了自动密语，请手动密语该玩家。") end
end
frame:RegisterEvent("PLAYER_TARGET_CHANGED")
frame:SetScript("OnEvent", function()
  sequence = sequence + 1
  if not Q or not Q.Get("tentWhisperCN") then return end
  local current = sequence
  pcall(scan, current)
  if C_Timer and C_Timer.After then
    C_Timer.After(0.3, function() pcall(scan, current) end)
    C_Timer.After(1, function() pcall(scan, current, true) end)
  end
end)
