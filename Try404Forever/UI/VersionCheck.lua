local _, FLT = ...
local L = FLT.L or setmetatable({}, { __index = function(_, k) return k end }) -- (tests without Locales)

-- New version notices use Try404's own addon-message protocol. Peers in the
-- guild or party report versions; WoW addons cannot query CurseForge directly.
-- Check on login and when the guild or group roster changes. A verified newer
-- version is shown as soon as it is learned, once per version in this session.
local PREFIX = "TRY404VER"

local function myVersion()
  local v
  if C_AddOns and C_AddOns.GetAddOnMetadata then v = C_AddOns.GetAddOnMetadata("Try404Forever", "Version")
  elseif GetAddOnMetadata then v = GetAddOnMetadata("Try404Forever", "Version") end
  return v or "0"
end

-- "4.19.0" -> {4,19,0}; versions with a suffix (beta, test) -> nil
local function parse(v, allowSuffix)
  if type(v) ~= "string" then return nil end
  local nums, rest = v:match("^([%d%.]+)(.*)$")
  if not nums or (rest ~= "" and not allowSuffix) then return nil end
  local t = {}
  for n in nums:gmatch("%d+") do t[#t + 1] = tonumber(n) end
  return #t > 0 and t or nil
end
local function newer(a, b) -- a > b
  for i = 1, math.max(#a, #b) do
    local x, y = a[i] or 0, b[i] or 0
    if x ~= y then return x > y end
  end
  return false
end

local mine = parse(myVersion(), true) or {0}
local reports, told = {}, {}

local function now() return GetTime and GetTime() or 0 end
local function enabled()
  return not (type(OneForAllDB) == "table" and OneForAllDB.versionNotice == false)
end

local function announce(v)
  if told[v] then return end
  told[v] = true
  if FLT.Msg then
    FLT.Msg("|cffffd100" .. string.format(L["TRY404 update %s is available. You are using %s. Download: https://www.curseforge.com/wow/addons/try404"], v, myVersion()) .. "|r")
  end
end

local function confirmed(v)
  if enabled() then announce(v) end
end

local function onVersion(v, sender, trusted)
  local t = parse(v, false)
  if not (t and newer(t, mine)) or told[v] then return end
  local seen = reports[v] or {}
  reports[v] = seen
  seen[sender or "?"] = true
  local n = 0
  for _ in pairs(seen) do n = n + 1 end
  if trusted or n >= 2 then confirmed(v) end
end

local function send(msg, dist, target)
  if not (C_ChatInfo and C_ChatInfo.SendAddonMessage) then return end
  pcall(C_ChatInfo.SendAddonMessage, PREFIX, msg, dist, target)
end

local function channelID()
  if FLT.RecipeChannelOff then return end -- 6.1.4: no channel any more
  local id = GetChannelName and GetChannelName(FLT.RecipeChannelName and FLT.RecipeChannelName() or "OFAShare3")
  if id and id > 0 then return id end
end

local lastAsk
local function ask()
  lastAsk = now()
  local q = "Q\t" .. myVersion()
  if IsInGuild and IsInGuild() then send(q, "GUILD") end
  if IsInRaid and IsInRaid() then send(q, "RAID") elseif IsInGroup and IsInGroup() then send(q, "PARTY") end
  local id = channelID()
  if id then send(q, "CHANNEL", id) end
end

-- Roster changes may come in bursts; send at most one check every 30 seconds.
-- A delayed check still runs after the last burst, so a newly joined player is not missed.
local checkScheduled = false
local function scheduleCheck()
  if checkScheduled then return end
  local wait = lastAsk and math.max(2, 30 - (now() - lastAsk)) or 2
  if not (C_Timer and C_Timer.After) then ask(); return end
  checkScheduled = true
  C_Timer.After(wait, function() checkScheduled = false; ask() end)
end

-- Answer someone with an older version once (random delay, skipped if another
-- player already answered with the same version in the meantime).
local lastAnswer, answeredBy = {}, {}
local function answer(dist)
  local key = dist
  if lastAnswer[key] and now() - lastAnswer[key] < 60 then return end
  lastAnswer[key] = now()
  local v = myVersion()
  if not parse(v, false) then return end -- test builds never answer
  local function go()
    if answeredBy[v] and now() - answeredBy[v] < 30 then return end
    if dist == "CHANNEL" then
      local id = channelID()
      if id then send("V\t" .. v, "CHANNEL", id) end
    else
      send("V\t" .. v, dist)
    end
  end
  if C_Timer and C_Timer.After then C_Timer.After(1 + math.random() * 5, go) else go() end
end

local ev = CreateFrame("Frame")
for _, e in ipairs({"PLAYER_LOGIN", "CHAT_MSG_ADDON", "GROUP_ROSTER_UPDATE", "GUILD_ROSTER_UPDATE"}) do pcall(ev.RegisterEvent, ev, e) end
ev:SetScript("OnEvent", function(_, event, prefix, msg, channel, sender)
  if event == "PLAYER_LOGIN" then
    if C_ChatInfo and C_ChatInfo.RegisterAddonMessagePrefix then pcall(C_ChatInfo.RegisterAddonMessagePrefix, PREFIX) end
    if C_Timer and C_Timer.After then
      -- a newer version seen in an earlier session
      C_Timer.After(8, function()
        if type(OneForAllDB) ~= "table" then return end
        local p = OneForAllDB.try404PendingNewVersion
        OneForAllDB.try404PendingNewVersion = nil
        local t = parse(p, false)
        if t and newer(t, mine) and enabled() then announce(p) end
      end)
      -- after the recipe-sharing channel is joined (about 12 s after login)
      C_Timer.After(20, function()
        if not lastAsk or now() - lastAsk >= 30 then ask() end
      end)
    end
  elseif event == "GROUP_ROSTER_UPDATE" or event == "GUILD_ROSTER_UPDATE" then
    scheduleCheck()
  elseif event == "CHAT_MSG_ADDON" and not (FLT.IsSecret and FLT.IsSecret(prefix, msg, channel) ) and prefix == PREFIX and type(msg) == "string" then
    local kind, v = msg:match("^(%a)\t(.+)$")
    if not kind then return end
    local trusted = channel == "GUILD" or channel == "PARTY" or channel == "RAID"
    if kind == "V" then
      answeredBy[v] = now()
      onVersion(v, sender, trusted)
    elseif kind == "Q" then
      onVersion(v, sender, trusted) -- the asker may run a newer version too
      local t = parse(v, true)
      if t and newer(mine, t) then answer(channel) end
    end
  end
end)
