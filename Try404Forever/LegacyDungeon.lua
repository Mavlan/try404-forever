local _, FLT = ...

-- Read-only Legacy achievement criteria. nil means the client did not provide
-- sufficient information; it must never be displayed as an incomplete run.
function FLT.LegacyDungeonSnapshot()
  local mappings = FLT.LEGACY_DUNGEON_CRITERIA or {}
  local criteria, needed = {}, {}
  for _, groups in pairs(mappings) do
    for _, refs in ipairs(groups) do
      for _, ref in ipairs(refs) do needed[ref[1]] = true end
    end
  end
  if type(GetAchievementNumCriteria) ~= "function" or type(GetAchievementCriteriaInfo) ~= "function" then return {} end
  for achievementID in pairs(needed) do
    local ok, count = pcall(GetAchievementNumCriteria, achievementID)
    if ok and type(count) == "number" and (not issecretvalue or not issecretvalue(count)) then
      local values = {}; criteria[achievementID] = values
      for i = 1, count do
        local success, _, _, done, _, _, _, _, _, _, id = pcall(GetAchievementCriteriaInfo, achievementID, i)
        if success and type(id) == "number" and type(done) == "boolean"
            and (not issecretvalue or (not issecretvalue(id) and not issecretvalue(done))) then
          values[id] = done
        end
      end
    end
  end
  local result = {}
  for name, groups in pairs(mappings) do
    local allComplete, allKnown = true, true
    for _, refs in ipairs(groups) do
      local complete, known = false, true
      for _, ref in ipairs(refs) do
        local set = criteria[ref[1]]
        -- Do not use `set and set[id]` to detect false: false is valid data.
        if set and set[ref[2]] ~= nil then
          if set[ref[2]] == true then complete = true end
        else known = false end
      end
      if not known and not complete then allKnown = false end
      if not complete then allComplete = false end
    end
    if allComplete then result[name] = true elseif allKnown then result[name] = false end
  end
  return result
end
