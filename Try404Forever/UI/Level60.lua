local _, FLT = ...
local UI, L = FLT.UI, FLT.L

-- Production is gated; a local test copy can enable this for review.
UI.Level60Preview = true -- local review only
function UI.CanOpenLevel60(level) return UI.Level60Preview or (type(level) == "number" and level >= 60) end
local function T(en, cn, tw)
  local lang = FLT.Language and FLT.Language() or "enUS"
  if lang == "zhTW" then return tw elseif lang == "zhCN" then return cn end
  return en
end

local function chapters()
  local list = {
    { key="start", icon="INV_Misc_Book_09", title=T("First steps", "刚满级", "剛滿級"), entries={
      {T("1. Train useful skills", "1. 学常用技能", "1. 學常用技能"),T("Visit a class trainer and compare costs. Buy the ranks you actually use; you can learn situational skills later.", "先找职业训练师，升级常用输出、治疗及保命技能。先看费用，暂时用不到的技能可以以后再学。", "先找職業訓練師，升級常用輸出、治療及保命技能。先看費用，暫時用不到的技能可以以後再學。")},
      {T("2. Review your build", "2. 整理天赋与装备", "2. 整理天賦與裝備"),T("Review your talents, weapon skills and gear for your preferred role. A second talent build is optional: buy it if you intend to change roles often.", "检查天赋、武器技能和装备，决定主要玩输出、坦克还是治疗。经常切换职责再考虑双天赋，不必为了满级马上花钱。", "檢查天賦、武器技能和裝備，決定主要玩輸出、坦克還是治療。經常切換職責再考慮雙天賦，不必為了滿級馬上花錢。")},
      {T("3. Plan dungeon trips", "3. 出发前先接任务", "3. 出發前先接任務"),T("Use the dungeon page to check level, quests and drops. Combine nearby quest turn-ins with a group run to reduce travel.", "组队前打开副本页，先查看相关任务、前置和掉落；顺路接交任务，减少重复跑图。", "組隊前開啟地城頁，先查看相關任務、前置和掉落；順路接交任務，減少重複跑圖。")},
    }},
    { key="gear", icon="INV_Sword_27", title=T("Dungeon gear", "副本与装备", "地城與裝備"), entries={
      {T("Choose a destination", "先打哪些本", "先打哪些地城"),T("Lower and Upper Blackrock Spire, Scholomance, Stratholme, Dire Maul and Blackrock Depths have high-level activities. Blackmaw Hold and Shaper's Terrace are Forever dungeons. Check each entrance and group requirements in game.", "可以从黑石塔下层、通灵学院、斯坦索姆、厄运之槌和黑石深渊开始，也看看《永恒》新增的黑喉要塞与塑造者露台。出发前确认等级、队伍和入口条件。", "可以從黑石塔下層、通靈學院、斯坦索姆、厄運之槌和黑石深淵開始，也看看《永恆》新增的黑喉要塞與塑造者露台。出發前確認等級、隊伍和入口條件。")},
      {T("Compare the whole item", "怎么选装备", "怎麼選裝備"),T("Use the gear planner for your class and role. Compare weapons, attributes, set bonuses and special effects; a single score is only a guide. Check actual item tooltips and dropped sources.", "用装备规划筛选自己的职业与职责，比较武器、属性、套装效果和特效；分数只是参考。掉落与物品属性以游戏内显示为准。", "用裝備規劃篩選自己的職業與職責，比較武器、屬性、套裝效果和特效；分數只是參考。掉落與物品屬性以遊戲內顯示為準。")},
      {T("Keep useful alternatives", "留下有用的备用件", "留下有用的備用裝"),T("Keep a healing or tank set only if you intend to use that role. Compare enchantment costs against how long you expect to keep each item.", "如果有治疗或坦克的打算，可以留下对应备用装。容易更换的过渡装不必急着买昂贵附魔。", "如果有治療或坦克的打算，可以留下對應備用裝。容易更換的過渡裝不必急著買昂貴附魔。")},
    }},
    { key="onyxia", icon="INV_Misc_Head_Dragon_01", title=T("Onyxia access", "黑龙门任务", "黑龍入場任務"), entries={
      {T("Your faction's quest chain", "你的阵营任务链", "你的陣營任務鏈"),T("The following steps use the existing Onyxia data. Green means the game reports the quest completed. Some objectives can be done in parallel; a grey step does not prove it is available yet. Locations and prerequisites should be checked in game.", "下面按你的阵营列出已有的奥妮克希亚任务资料。绿色代表游戏报告该任务已完成；部分目标可并行，灰色不代表当前一定能接。地点和前置请以游戏内为准。", "下面按你的陣營列出已有的奧妮克希亞任務資料。綠色代表遊戲回報該任務已完成；部分目標可並行，灰色不代表目前一定能接。地點和前置請以遊戲內為準。")},
    }},
    { key="keys", icon="INV_Misc_Key_14", title=T("Dungeon keys", "副本钥匙", "地城鑰匙"), entries={
      {T("Upper Blackrock Spire", "黑石塔上层：晋升印章", "黑石塔上層：晉升印章"),T("The Seal of Ascension quest asks for materials from Lower Blackrock Spire and a later step involving Emberstrife. Inspect the full chain and coordinate a group before leaving.", "晋升印章任务会涉及黑石塔下层的材料，以及之后与埃博斯塔夫有关的步骤。先查看完整任务链，再约队友一起完成。", "晉升印章任務會涉及黑石塔下層的材料，以及之後與埃博斯塔夫有關的步驟。先查看完整任務鏈，再約隊友一起完成。")},
      {T("Scholomance", "通灵学院：骷髅钥匙", "通靈學院：骷髏鑰匙"),T("The key chain has faction-specific quest givers and several steps. Check the Special Quests page for the steps and reported progress.", "骷髅钥匙任务链有阵营区别和多个步骤；在特殊任务里查看接取地点、进度和目标。", "骷髏鑰匙任務鏈有陣營區別和多個步驟；在特殊任務裡查看接取地點、進度和目標。")},
      {T("Other useful keys", "其他钥匙", "其他鑰匙"),T("The Shadowforge Key helps in Blackrock Depths, and the Scepter of Celebras provides a Maraudon shortcut. Some keys are optional; ask your group before planning a run.", "暗炉钥匙有助于探索黑石深渊；塞雷布拉斯节杖可用于玛拉顿的捷径。有些钥匙并非人人必备，出发前先问队友。", "暗爐鑰匙有助於探索黑石深淵；塞雷布拉斯節杖可用於瑪拉頓的捷徑。有些鑰匙並非人人必備，出發前先問隊友。")},
    }},
    { key="weekly", icon="INV_Misc_Bag_10", title=T("Weekly and currency", "周常与代币", "週常與代幣"), entries={
      {T("Booty Bay weekly", "藏宝海湾周常", "藏寶海灣週常"),T("Look for Pix Xizzix near the Booty Bay auction house. Weekly dungeon objectives rotate. Read the NPC's current objective and reward before setting out.", "可到藏宝海湾拍卖行附近找 Pix Xizzix。每周副本任务的目标会轮换；出发前请先核对 NPC 当前显示的目标和奖励。", "可到藏寶海灣拍賣場附近找 Pix Xizzix。每週地城任務的目標會輪換；出發前請先核對 NPC 目前顯示的目標和獎勵。")},
      {T("Dungeon currency", "副本代币", "地城代幣"),T("The same NPC is listed as a vendor for high-level dungeon currency. Drops, stock and prices may change: verify in game before farming or buying.", "攻略记载这名 NPC 也提供高等级副本代币兑换。掉落、商品与价格可能调整，请在游戏内确认后再刷取或购买。", "攻略記載這名 NPC 也提供高等級地城代幣兌換。掉落、商品與價格可能調整，請在遊戲內確認後再刷取或購買。")},
    }},
    { key="prof", icon="Trade_BlackSmithing", title=T("Professions", "专业与金币", "專業與金幣"), entries={
      {T("Train and gather", "训练与采集", "訓練與採集"),T("Train your chosen professions and gather while questing or travelling. Use the profession planner to compare recipes, materials and training costs before spending gold.", "把自己在用的专业逐步练起来，赶路时顺手采集。冲级前用专业页面比较配方、材料和训练费用，别为了满级一次清空金币。", "把自己在用的專業逐步練起來，趕路時順手採集。衝級前用專業頁面比較配方、材料和訓練費用，別為了滿級一次花光金幣。")},
      {T("Crafting and auctions", "制作与拍卖行", "製作與拍賣場"),T("Compare the cost of materials with the item price. Auction prices vary and the price features need Auctionator; check whether a recipe or crafted item is bound before buying.", "先比较材料成本和成品价格；拍卖价格会变化，价格功能需要 Auctionator。购买之前留意配方和成品是否绑定。", "先比較材料成本和成品價格；拍賣價格會變動，價格功能需要 Auctionator。購買之前留意配方和成品是否綁定。")},
      {T("Mount and reserves", "坐骑和储备", "坐騎和儲備"),T("Reserve gold for riding, repairs, training and consumables. Check your trainer's actual price and faction discounts before buying.", "给骑术、修理、技能和消耗品留一笔钱；购买前查看训练师的实际费用与声望折扣。", "給騎術、修理、技能和消耗品留一筆錢；購買前查看訓練師的實際費用與聲望折扣。")},
    }},
    { key="rep", icon="INV_Misc_EngGizmos_21", title=T("Reputation", "声望", "聲望"), entries={
      {T("Choose rewards first", "先选奖励再刷声望", "先選獎勵再刷聲望"),T("Look at each faction's rewards and rank requirements in Armory. Prioritize useful recipes, equipment or items for your character rather than trying to finish every faction at once.", "在军械库的声望页面先看奖励和所需声望等级，优先挑自己能用的配方、装备或物品，不需要同时刷完所有阵营。", "在軍械庫的聲望頁面先看獎勵和所需聲望等級，優先挑自己能用的配方、裝備或物品，不需要同時刷完所有陣營。")},
      {T("Combine trips", "和任务副本顺路做", "和任務地城順路做"),T("Combine available quests and dungeons with reputation goals. Check the game for the current reputation source and any prerequisites before travelling.", "选择正在做任务或要打的副本相关声望；出发前确认当前版本的获取方式和前置条件。", "選擇正在做任務或要打的地城相關聲望；出發前確認目前版本的取得方式和前置條件。")},
    }},
    { key="legacy", icon="INV_Misc_Map_01", title=T("Legacy", "传承", "傳承"), entries={
      {T("Build account progress", "积累传承进度", "累積傳承進度"),T("Explore the game's Legacy interface for challenges and rewards. Pick activities you enjoy, including questing, dungeons or professions, and inspect each criterion before starting.", "在游戏的传承界面查看挑战和奖励，从喜欢的任务、副本、专业等内容开始；每项实际条件以游戏内显示为准。", "在遊戲的傳承介面查看挑戰和獎勵，從喜歡的任務、地城、專業等內容開始；每項實際條件以遊戲內顯示為準。")},
      {T("Dungeon status", "查看副本传承", "查看地城傳承"),T("Try404's dungeon list shows supported Legacy completion states. Shared achievements may cover more than one dungeon; an unavailable state is not proof of failure.", "Try404 的副本列表会显示已支持的传承完成状态。部分副本可能共享传承；无法读取时，不代表一定没有完成。", "Try404 的地城列表會顯示已支援的傳承完成狀態。部分地城可能共用傳承；無法讀取時，不代表一定沒有完成。")},
    }},
    { key="raid", icon="INV_Helmet_08", title=T("Raid and PvP", "团本与战场", "團本與戰場"), entries={
      {T("Before joining a raid", "团本前检查", "團本前檢查"),T("Check whether the raid is open, its group size, the group's loot rules, required keys and any attunement. Bring repair money and the consumables your group asks for.", "先确认团本是否开放、队伍人数、分配规则和入场条件，再准备修理费及团队需要的消耗品。", "先確認團本是否開放、隊伍人數、分配規則和入場條件，再準備修理費及團隊需要的消耗品。")},
      {T("PvP is optional", "战场按兴趣参加", "戰場按興趣參加"),T("Battlegrounds offer a different route to rewards. Check the current quest objective and reward at the NPC before queuing; old Classic quest information may differ in Forever.", "战场也是奖励来源之一；排队之前先和 NPC 确认任务目标及奖励。经典服旧资料不一定适用于《永恒》。", "戰場也是獎勵來源之一；排隊之前先和 NPC 確認任務目標及獎勵。經典服舊資料不一定適用於《永恆》。")},
    }},
  }
  local _, class = UnitClass("player")
  if class == "PALADIN" then
    list[#list+1] = {key="paladin",icon="Spell_Holy_AuraOfLight",title=T("Paladin", "圣骑士", "聖騎士"),entries={
      {T("Retribution build", "惩戒骑天赋", "懲戒騎天賦"),T("Review the level 60 build for your preferred role and current patch. Talent balance can change; the existing Talent Trees tab can help you inspect the choices before spending points.", "按当前版本和自己的玩法检查 60 级天赋；职业平衡可能热修，先在天赋树页面查看后再投入点数。", "按目前版本和自己的玩法檢查 60 級天賦；職業平衡可能熱修，先在天賦樹頁面查看後再投入點數。")},
      {T("Weapon and attributes", "武器与属性", "武器與屬性"),T("For a two-handed Retribution build, compare weapon damage, speed, relevant attributes and effects together. Some Forever talents also change the value of intellect or spell power; scores alone cannot capture every effect.", "双手惩戒装备一起比较武器伤害、速度、属性与特效。《永恒》部分天赋也会改变智力和法术能量的价值，不能只看一个评分。", "雙手懲戒裝備一起比較武器傷害、速度、屬性與特效。《永恆》部分天賦也會改變智力和法術能量的價值，不能只看一個評分。")},
      {T("Other roles", "治疗或坦克", "治療或坦克"),T("If you plan to heal or tank often, keep suitable gear and consider a second talent build. Retain your Retribution setup for solo play.", "如果经常担任治疗或坦克，可以留下对应装备并考虑双天赋，同时保留惩戒配置做单人内容。", "如果經常擔任治療或坦克，可以留下對應裝備並考慮雙天賦，同時保留懲戒配置做單人內容。")},
    }}
  end
  return list
end

local function createPanel(parent)
  local panel=CreateFrame("Frame",nil,parent); UI.PlacePanel(panel,parent,UI.TITLE_BAND_H)
  local nav,y=UI.SideNav(panel,-74,"emblem_armory",L["Level 60 Preparation"])
  local body=CreateFrame("Frame",nil,panel); body:SetPoint("TOPLEFT",182,-74); body:SetPoint("BOTTOMRIGHT",-8,4)
  local sf=FLT.SkinBlizz(CreateFrame("ScrollFrame",nil,body,"UIPanelScrollFrameTemplate"))
  sf:SetPoint("TOPLEFT",10,-8);sf:SetPoint("BOTTOMRIGHT",-28,8);UI.AutoHideScrollBar(sf)
  local content=CreateFrame("Frame",nil,sf);content:SetSize(730,1);sf:SetScrollChild(content)
  local sections=chapters();local rows,buttons={},{};local selected=0
  local paint
  local function fs(owner,font,x,y,width)
    local t=owner:CreateFontString(nil,"OVERLAY",font);t:SetPoint("TOPLEFT",x,y);t:SetWidth(width);t:SetJustifyH("LEFT");t:SetWordWrap(true);return t
  end
  local heading=fs(content,"GameFontNormalLarge",6,-4,700)
  local hint=fs(content,"GameFontHighlightSmall",6,-28,700)
  -- A compact endgame landing page built from existing in-game and addon data.
  local home=CreateFrame("Frame",nil,content);home:SetPoint("TOPLEFT",0,0);home:SetSize(700,700)
  -- Reflow horizontally as the window changes size without scaling fonts or artwork vertically.
  local homeLayout={}
  local function reflow(f) homeLayout[#homeLayout+1]=f end
  local function box(parent,x,y,w,h)
    local f=CreateFrame("Frame",nil,parent);f:SetPoint("TOPLEFT",x,y);f:SetSize(w,h)
    reflow(function(scale) f:ClearAllPoints();f:SetPoint("TOPLEFT",x*scale,y);f:SetWidth(w*scale) end)
    local bg=f:CreateTexture(nil,"BACKGROUND");bg:SetAllPoints();bg:SetColorTexture(0.10,0.085,0.065,0.96)
    if UI.RoundRect and UI.ASSET_ROOT then UI.RoundRect(f,f,"BORDER",0,6,0,0.45,0.34,0.17,0.9,UI.ASSET_ROOT.."window_ring") end
    return f
  end
  local function label(parent,font,text,x,y,w)
    local t=fs(parent,font,x,y,w);t:SetText(text)
    reflow(function(scale) t:ClearAllPoints();t:SetPoint("TOPLEFT",x*scale,y);t:SetWidth(w*scale) end)
    return t
  end
  local ATLAS=UI.ASSET_ROOT.."level60_scenes"
  local function scene(parent,col,row,x,y,w,h)
    local art=parent:CreateTexture(nil,"ARTWORK");art:SetPoint("TOPLEFT",x,y);art:SetSize(w,h);FLT.SetTex(art,ATLAS)
    reflow(function(scale) art:ClearAllPoints();art:SetPoint("TOPLEFT",x*scale,y);art:SetWidth(w*scale) end)
    local pad=0.002;art:SetTexCoord(col/3+pad,(col+1)/3-pad,row/2+pad,(row+1)/2-pad)
    return art
  end
  local function dim(parent,x,y,w,h,alpha)
    local overlay=parent:CreateTexture(nil,"ARTWORK",nil,1);overlay:SetPoint("TOPLEFT",x,y);overlay:SetSize(w,h);overlay:SetColorTexture(0.025,0.020,0.014,alpha or 0.8)
    reflow(function(scale) overlay:ClearAllPoints();overlay:SetPoint("TOPLEFT",x*scale,y);overlay:SetWidth(w*scale) end)
    return overlay
  end
  local function detail(parent,text,x,y,w)
    return label(parent,"GameFontHighlightSmall",text,x,y,w)
  end
  local function goChapter(key)
    for i,c in ipairs(sections) do if c.key==key then selected=i;sf:SetVerticalScroll(0);paint();return end end
  end
  local hero=box(home,0,0,700,70)
  local backdrop=scene(hero,2,1,420,-2,278,66);backdrop:SetAlpha(0.55)
  dim(hero,360,-2,338,66,0.40)
  local crest=hero:CreateTexture(nil,"OVERLAY");crest:SetPoint("TOPLEFT",12,-11);crest:SetSize(42,42);FLT.SetTex(crest,UI.ASSET_ROOT.."faction_crests")
  local portrait=hero:CreateTexture(nil,"OVERLAY");portrait:SetPoint("TOPLEFT",60,-9);portrait:SetSize(48,48)
  label(hero,"GameFontNormalLarge",T("Level 60 adventure","满级冒险","滿級冒險"),120,-11,205)
  local character=label(hero,"GameFontHighlightSmall","",120,-40,225)
  character:SetWordWrap(false)
  label(hero,"GameFontNormal",T("Your next adventure awaits","欢迎回到艾泽拉斯！","歡迎回到艾澤拉斯！"),356,-13,320)
  detail(hero,T("Explore dungeons, quests and rewards.","副本、任务、声望与更多冒险。","地城、任務、聲望與更多冒險。"),356,-38,320)
  local dungeonGroup=box(home,0,-80,460,258)
  label(dungeonGroup,"GameFontNormalLarge",T("Recommended dungeons","推荐地下城","推薦地城"),12,-11,240)
  detail(dungeonGroup,T("Explore loot and quests","查看掉落与任务","查看掉落與任務"),225,-13,220)
  local weeklyGroup=box(home,470,-80,230,258)
  label(weeklyGroup,"GameFontNormalLarge",T("Weekly activities","本周活动","本週活動"),12,-11,205)
  detail(weeklyGroup,T("Level 60 activities","满级每周活动","滿級每週活動"),12,-37,200)
  local picks={"Blackrock Depths","Scholomance","Stratholme"}
  local function findDungeon(name)
    for _,d in ipairs(FLT.DUNGEONS or {}) do if d.name==name then return d end end
  end
  local function openDungeon(name)
    local d=findDungeon(name);if not d or not FLT.OpenPanel then return end
    FLT:OpenPanel("dungeons");if UI.OpenDungeon then UI.OpenDungeon(d) end
  end
  for i,name in ipairs(picks) do
    local d=findDungeon(name);local c=box(dungeonGroup,8+(i-1)*149,-43,146,206)
    scene(c,i-1,0,3,-3,140,141);dim(c,3,-91,140,53,0.84)
    label(c,"GameFontNormal",(FLT.DungeonName and FLT.DungeonName(name)) or name,9,-98,128)
    detail(c,T("Level ","等级 ","等級 ")..(d and d.level or "?"),9,-120,128)
    detail(c,T("Loot · quests","装备 · 任务","裝備 · 任務"),9,-151,128)
    local b=UI.GoldButton(c,T("View dungeon","查看副本","查看地城"),128,23);b:SetPoint("BOTTOM",0,7)
    if not d then b:Disable() else b:SetScript("OnClick",function() openDungeon(name) end) end
  end
  local week=box(weeklyGroup,8,-59,214,190)
  local weeklyIcon=week:CreateTexture(nil,"ARTWORK");weeklyIcon:SetPoint("TOPLEFT",9,-11);weeklyIcon:SetSize(40,40);weeklyIcon:SetTexture("Interface\\Icons\\INV_Misc_Coin_01")
  label(week,"GameFontNormal",T("Booty Bay weekly","藏宝海湾周常","藏寶海灣週常"),57,-12,145)
  detail(week,((FLT.Name and FLT.Name("Pix Xizzix")) or "Pix Xizzix").." · "..T("Booty Bay","藏宝海湾","藏寶海灣"),57,-36,145)
  detail(week,T("Weekly dungeon objectives rotate. Check the current quest in game.","周常目标会轮换，请以游戏内任务为准。","週常目標會輪換，請以遊戲內任務為準。"),12,-66,190)
  detail(week,T("Location: Booty Bay (28.5, 75.9)","位置：藏宝海湾 (28.5, 75.9)","位置：藏寶海灣 (28.5, 75.9)"),12,-112,190)
  local wb=UI.GoldButton(week,T("Map","地图","地圖"),91,23);wb:SetPoint("BOTTOMLEFT",9,9)
  wb:SetScript("OnClick",function() FLT:ShowOnMap({mapID=1434,x=28.5,y=75.9,name=(FLT.Name and FLT.Name("Pix Xizzix")) or "Pix Xizzix"}) end)
  local wdetail=UI.GoldButton(week,T("Details","查看详情","查看詳情"),98,23);wdetail:SetPoint("BOTTOMRIGHT",-9,9);wdetail:SetScript("OnClick",function() goChapter("weekly") end)
  local zonesGroup=box(home,0,-348,460,184)
  label(zonesGroup,"GameFontNormalLarge",T("Explore zones","探索地图","探索地圖"),12,-10,205)
  detail(zonesGroup,T("Quests, reputation and resources","任务、声望与资源","任務、聲望與資源"),200,-12,240)
  local zones={
    {id=1422,en="Western Plaguelands",cn="西瘟疫之地",tw="西瘟疫之地",art=0},
    {id=1448,en="Felwood",cn="费伍德森林",tw="費伍德森林",art=1},
  }
  local function openZone(id)
    if InCombatLockdown and InCombatLockdown() then return end
    if WorldMapFrame and WorldMapFrame.SetMapID then
      if not WorldMapFrame:IsShown() then WorldMapFrame:Show() end
      WorldMapFrame:SetMapID(id)
    elseif C_Map and C_Map.OpenWorldMap then C_Map.OpenWorldMap(id) end
  end
  for i,z in ipairs(zones) do
    local c=box(zonesGroup,8+(i-1)*225,-39,220,135)
    scene(c,z.art,1,3,-3,214,129);dim(c,3,-60,214,72,0.80)
    label(c,"GameFontNormal",T(z.en,z.cn,z.tw),10,-65,200)
    detail(c,T("Explore quests and reputation","探索任务与声望","探索任務與聲望"),10,-87,200)
    local b=UI.GoldButton(c,T("Map","地图","地圖"),82,22);b:SetPoint("BOTTOMRIGHT",-7,7);b:SetScript("OnClick",function() openZone(z.id) end)
  end
  local prep=box(home,470,-348,230,184)
  label(prep,"GameFontNormalLarge",T("Character preparation","角色准备","角色準備"),12,-10,205)
  local actions={
    {T("Gear planner","装备规划","裝備規劃"),"INV_Chest_Plate01",function() if FLT.OpenPanel then FLT:OpenPanel("armory") end end},
    {T("Reputation","声望","聲望"),"INV_Misc_Ribbon_01",function() goChapter("rep") end},
    {T("Dungeon keys","副本钥匙","地城鑰匙"),"INV_Misc_Key_14",function() goChapter("keys") end},
  }
  for i,a in ipairs(actions) do
    local item=box(prep,8,-40-(i-1)*45,214,40)
    local icon=item:CreateTexture(nil,"ARTWORK");icon:SetPoint("LEFT",6,0);icon:SetSize(29,29);icon:SetTexture("Interface\\Icons\\"..a[2])
    local b=UI.GoldButton(item,a[1],160,26);b:SetPoint("RIGHT",-6,0);b:SetScript("OnClick",a[3])
  end
  local function refreshHome()
    local name=(UnitName and UnitName("player")) or "?";local level=(UnitLevel and UnitLevel("player")) or "?"
    local class=(UnitClass and UnitClass("player")) or "";local faction=UnitFactionGroup and UnitFactionGroup("player")
    local side=faction=="Horde" and T("Horde","部落","部落") or faction=="Alliance" and T("Alliance","联盟","聯盟") or ""
    character:SetText(name.." · "..T("Level ","等级 ","等級 ")..level.." · "..class)
    if faction=="Horde" then crest:SetTexCoord(0.25,0.5,0,1) else crest:SetTexCoord(0,0.25,0,1) end
    if SetPortraitTexture then pcall(SetPortraitTexture,portrait,"player") else portrait:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark") end
  end
  local function layoutHome()
    local width=sf:GetWidth()
    if type(width)~="number" or width<100 then width=700 end
    content:SetWidth(width);home:SetWidth(width)
    local scale=width/700
    for _,apply in ipairs(homeLayout) do apply(scale) end
  end
  sf:HookScript("OnSizeChanged",function() if selected==0 then layoutHome() end end)
  local function row(i)
    if rows[i] then return rows[i] end
    local r=CreateFrame("Frame",nil,content);r:SetWidth(700)
    local bg=r:CreateTexture(nil,"BACKGROUND");bg:SetAllPoints();bg:SetColorTexture(0.10,0.085,0.065,0.9)
    r.title=fs(r,"GameFontNormal",12,-10,600);r.desc=fs(r,"GameFontHighlight",12,-32,615)
    r.map=UI.GoldButton(r,L["Map"],64,22);r.map:SetPoint("TOPRIGHT",-10,-8)
    rows[i]=r;return r
  end
  paint=function()
    for _,r in ipairs(rows) do r:Hide() end
    if selected==0 then
      heading:Hide();hint:Hide();home:Show();refreshHome();layoutHome();content:SetHeight(545)
      for i,b in ipairs(buttons) do b:SetActive(i==1) end
      return
    end
    home:Hide();content:SetWidth(730);heading:Show();hint:Show()
    local chapter=sections[selected];heading:SetText(chapter.title)
    hint:SetText(T("Practical notes for level 60. Verify quest requirements and rewards in game.","60 级实用指南；任务条件和奖励以游戏内为准。","60 級實用指南；任務條件和獎勵以遊戲內為準。"))
    for _,r in ipairs(rows) do r:Hide() end
    local entries={};for _,v in ipairs(chapter.entries) do entries[#entries+1]=v end
    if chapter.key=="onyxia" then
      local faction=UnitFactionGroup and UnitFactionGroup("player")
      for _,key in ipairs((FLT.DUNGEON_KEYS and FLT.DUNGEON_KEYS["Onyxia's Lair"]) or {}) do
        for _,s in ipairs(key.steps or {}) do
          if s.quest and (not s.faction or s.faction==faction) then
            local texts=FLT.Try404AttunementTexts and FLT.Try404AttunementTexts[FLT.Language()]
            local tr=texts and texts[s.quest]; local name=(tr and tr[1]) or (FLT.Name and FLT.Name(s.name)) or s.name
            local check=C_QuestLog and C_QuestLog.IsQuestFlaggedCompleted or IsQuestFlaggedCompleted
            local state=T("Unknown", "状态未知", "狀態未知")
            if type(check)=="function" then
              local ok,done=pcall(check,s.quest)
              if ok and done~=nil then state=done and ("|cff66dd66"..L["Done"].."|r") or T("Not completed", "未完成", "未完成") end
              if ok and done==false and UI.DungeonHelpers and UI.DungeonHelpers.getQuestLogInfo then
                local found,ready=UI.DungeonHelpers.getQuestLogInfo({id=s.quest,name=s.name})
                if found then state=ready and L["Ready to turn in"] or L["In log"] end
              end
            end
            local place=s.pickup and ((FLT.PlaceText and FLT.PlaceText(s.pickup)) or s.pickup) or "?"
            local finish=s.turnin and ((FLT.PlaceText and FLT.PlaceText(s.turnin)) or s.turnin) or "?"
            local objective=(tr and tr[2]) or s.objective or ""
            entries[#entries+1]={ name.."  ·  "..state, T("Start: ","接取：","接取：")..place.."\n"..T("Objective: ","目标：","目標：")..objective.."\n"..T("Turn in: ","交付：","交付：")..finish, s.map }
          end
        end
      end
    end
    local yy=-59
    for i,e in ipairs(entries) do
      local r=row(i);r:ClearAllPoints();r:SetPoint("TOPLEFT",0,yy);r.title:SetText(e[1]);r.desc:SetText(e[2] or "")
      local h=math.max(65,44+(r.desc:GetStringHeight() or 18));r:SetHeight(h);r:Show();yy=yy-h-8
      local m=e[3];if m and m.mapID and m.x and m.y then
        r.map:Show();r.map:SetScript("OnClick",function() FLT:ShowOnMap({mapID=m.mapID,x=m.x,y=m.y,name=e[1]}) end)
      else r.map:Hide() end
    end
    content:SetHeight(math.max(1,-yy+15))
    for i,b in ipairs(buttons) do b:SetActive(i==selected+1) end
  end
  local homeButton;homeButton,y=UI.NavEntry(nav,y,T("Overview","冒险首页","冒險首頁"),"Interface\\Icons\\INV_Misc_Map_01")
  homeButton:SetScript("OnClick",function() selected=0;sf:SetVerticalScroll(0);paint() end);buttons[1]=homeButton
  for i,c in ipairs(sections) do
    local b;b,y=UI.NavEntry(nav,y,c.title,"Interface\\Icons\\"..c.icon)
    b:SetScript("OnClick",function() selected=i;sf:SetVerticalScroll(0);paint() end);buttons[i+1]=b
  end
  function panel:Refresh() if self:IsVisible() then paint() end end
  local ev=CreateFrame("Frame",nil,panel)
  for _,e in ipairs({"QUEST_TURNED_IN","QUEST_ACCEPTED","QUEST_REMOVED"}) do pcall(ev.RegisterEvent,ev,e) end
  ev:SetScript("OnEvent",function() if panel:IsVisible() and selected>0 and sections[selected].key=="onyxia" then paint() end end)
  paint();panel:Hide();return panel
end

UI.RegisterPanel({key="level60",label="Level 60 Preparation",order=2.5,tabWidth=110,create=createPanel})
