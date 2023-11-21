--[[	*** DataStore_Quests ***
Written by : Thaoky, EU-Marécages de Zangar
July 8th, 2009
--]]

if not DataStore then return end

local addonName = "DataStore_Quests"

_G[addonName] = LibStub("AceAddon-3.0"):NewAddon(addonName, "AceConsole-3.0", "AceEvent-3.0", "AceTimer-3.0")

local addon = _G[addonName]
local L = LibStub("AceLocale-3.0"):GetLocale(addonName)

local AddonDB_Defaults = {
	global = {
		Options = {
			TrackTurnIns = true,					-- by default, save the ids of completed quests in the history
			AutoUpdateHistory = true,			-- if history has been queried at least once, auto update it at logon (fast operation - already in the game's cache)
			DailyResetHour = 3,					-- Reset dailies at 3am (default value)
		},
		Characters = {
			['*'] = {				-- ["Account.Realm.Name"]
				lastUpdate = nil,
				Quests = {},
				QuestLinks = {},					-- No quest links in Classic !!
				QuestHeaders = {},
				QuestTitles = {},	
				QuestTags = {},
				Rewards = {},
				Money = {},
				Dailies = {},
				Weeklies = {},
				History = {},		-- a list of completed quests, hash table ( [questID] = true )
				HistoryBuild = nil,	-- build version under which the history has been saved
				HistorySize = 0,
				HistoryLastUpdate = nil,
				
				-- ** Expansion Features / 8.0 - Battle for Azeroth **
				Emissaries = {},
				
				-- ** Expansion Features / 9.0 - Shadowlands **
				Callings = {},
				activeCovenantID = 0,				-- Active Covenant ID (0 = None)
				covenantCampaignProgress = 0,		-- Track the progress in the covenant storyline
				story91Progress = 0,					-- Track the progress in the 9.1 storyline (Chains of Domination)
				story92Progress = 0,					-- Track the progress in the 9.2 storyline (Secrets of the First Ones)
			}
		}
	}
}

local emissaryQuests = {
	-- 7.0 Legion / EXPANSION_NAME6
	[42420] = 6, -- Court of Farondis
	[42421] = 6, -- Nightfallen
	[42422] = 6, -- The Wardens
	[42233] = 6, -- Highmountain Tribes
	[42234] = 6, -- Valarjar
	[42170] = 6, -- Dreamweavers
	[43179] = 6, -- Kirin Tor
	[48642] = 6, -- Argussian Reach
	[48641] = 6, -- Armies of Legionfall
	[48639] = 6, -- Army of the Light
	
	-- 8.0 Battle for Azeroth / EXPANSION_NAME7
	[50604] = 7, -- Tortollan Seekers 
	[50562] = 7, -- Champions of Azeroth
	[50599] = 7, -- Proudmoore Admiralty
	[50600] = 7, -- Order of Embers
	[50601] = 7, -- Storm's Wake
	[50605] = 7, -- Alliance War Effort
	[50598] = 7, -- Zandalari Empire
	[50603] = 7, -- Voldunai
	[50602] = 7, -- Talanji's Expedition
	[50606] = 7, -- Horde War Effort
	[56119] = 7, -- The Waveblade Ankoan
	[56120] = 7, -- The Unshackled
}

local weeklyWorldQuests = {
	-- Legion : https://www.wowhead.com/broken-isles-world-bosses-guide
	[43512] = true,		-- Ana-Mouz
	[43193] = true,		-- Calamir
	[43448] = true,		-- Drugon the Frostblood
	[43985] = true,		-- Flotsam
	[42819] = true,		-- Humongris
	[43192] = true,		-- Levantus
	[43513] = true,		-- Na'zak the Fiend
	[42270] = true,		-- Nithogg
	[42779] = true,		-- Shar'thos
	[42269] = true,		-- The Soultakers
	[44287] = true,		-- Withered J'im
	
	-- BfA : https://www.wowhead.com/world-bosses-in-battle-for-azeroth
	[52196] = true,		-- Dunegorger Kraulok
	[52169] = true,		-- Ji'arak
	[52181] = true,		-- T'zane
	[52166] = true,		-- Warbringer Yenajz
	[52163] = true,		-- Azurethos, The Winged Typhoon
	[52157] = true,		-- Hailstone Construct
	
	-- Shadowlands
	[61813] = true,		-- Bastion - Valinor, the Light of Eons
	[61814] = true,		-- Revendreth - Nurgash Muckformed
	[61815] = true,		-- Ardenweald - Oranomonos the Everbranching
	[61816] = true,		-- Maldraxxus - Mortanis
	[64531] = true,		-- The Maw - Mor'geth
	[65143] = true,		-- Zereth Mortis - Antros
}

local covenantCampaignIDs = {
	[Enum.CovenantType.Kyrian] = 119,
	[Enum.CovenantType.Venthyr] = 113,
	[Enum.CovenantType.NightFae] = 117,
	[Enum.CovenantType.Necrolord] = 115
}

local covenantCampaignQuestChapters = {
	-- These are the quest id's of the last quest in each chapter
	[Enum.CovenantType.Kyrian] = { 57904, 60272, 58798, 58181, 61878, 58571, 61697, 62555, 62557 },			-- https://www.wowhead.com/guides/kyrian-covenant-campaign-story-rewards
	[Enum.CovenantType.Venthyr] = { 62921, 60272, 59343, 57893, 58444, 59233, 58395, 57646, 58407 },		-- https://www.wowhead.com/guides/venthyr-covenant-campaign-story-rewards
	[Enum.CovenantType.NightFae] = { 62899, 60272, 59242, 59821, 59071, 61171, 58452, 59866, 60108 },		-- https://www.wowhead.com/guides/night-fae-covenant-campaign-story-rewards
	[Enum.CovenantType.Necrolord] = { 59609, 60272, 57648, 58820, 59894, 57636, 58624, 61761, 62406 },		-- https://www.wowhead.com/guides/necrolords-covenant-campaign-story-rewards
}

-- 9.0
local TorghastQuestLine = { 62932, 62935, 62938, 60139, 62966, 62969, 60146, 62836, 61730 }
-- 9.1
local ChainsCampaignQuestChapters = { 63639, 64555, 63902, 63727, 63622, 63656, 64437, 63593, 64314 }
-- 9.2
local SecretsOfTheFirstOnesQuestChapters = { 64958, 64825, 65305, 64844, 64813, 65328, 65238 }


-- *** Common API ***
local API_GetNumQuestLogEntries
local API_GetSelectedQuest
local API_SetSelectedQuest
local API_GetQuestInfo
local API_DailyFrequency
local API_GetQuestTagInfo

if WOW_PROJECT_ID == WOW_PROJECT_MAINLINE then
	API_GetNumQuestLogEntries = C_QuestLog.GetNumQuestLogEntries
	API_GetSelectedQuest = C_QuestLog.GetSelectedQuest
	API_SetSelectedQuest = C_QuestLog.SetSelectedQuest
	API_DailyFrequency = Enum.QuestFrequency.Daily
	API_WeeklyFrequency = Enum.QuestFrequency.Weekly
	API_GetQuestInfo = function(index) 
			local info = C_QuestLog.GetInfo(index)
		
			return info.title, info.level, info.groupSize, info.isHeader, info.isCollapsed, info.isComplete, 
				info.frequency or 0, info.questID, info.isTask, info.isBounty, info.isStory, info.isHidden, info.suggestedGroup			
		end
	API_GetQuestTagInfo = function(questID)
			local info = C_QuestLog.GetQuestTagInfo(questID) or {}
			return info.tagID
		end
else
	API_GetNumQuestLogEntries = GetNumQuestLogEntries
	API_GetSelectedQuest = GetQuestLogSelection
	API_SetSelectedQuest = SelectQuestLogEntry
	API_DailyFrequency = LE_QUEST_FREQUENCY_DAILY
	API_WeeklyFrequency = LE_QUEST_FREQUENCY_WEEKLY
	API_GetQuestInfo = function(index) 
			local title, level, groupSize, isHeader, isCollapsed, isComplete, frequency, questID, 
					_, _, _, _, isTask, isBounty, isStory, isHidden = GetQuestLogTitle(index)
			
			-- 2019/09/01 groupSize = "Dungeon", "Raid" in Classic, not numeric !! => 0
			-- temporary fix: set it to 0 (3rd return value)
			return title, level, 0, isHeader, isCollapsed, isComplete, 
					frequency, questID, isTask, isBounty, isStory, isHidden, 0
		end
	API_GetQuestTagInfo = function(questID)
			return GetQuestTagInfo(questID)
		end
end

-- *** Utility functions ***
local bAnd = bit.band
local bOr = bit.bor
local RShift = bit.rshift
local LShift = bit.lshift

local function GetOption(option)
	return addon.db.global.Options[option]
end

local function GetQuestLogIndexByName(name)
	-- helper function taken from QuestGuru
	for i = 1, API_GetNumQuestLogEntries() do
		local title = API_GetQuestInfo(i)
		
		if title == strtrim(name) then
			return i
		end
	end
end

local function TestBit(value, pos)
	-- note: this function works up to bit 51
	local mask = 2 ^ pos		-- 0-based indexing
	return value % (mask + mask) >= mask
end

local function ClearExpiredDailies()
	-- this function will clear all the dailies from the day(s) before (or same day, but before the reset hour)

	local timeTable = {}

	timeTable.year = date("%Y")
	timeTable.month = date("%m")
	timeTable.day = date("%d")
	timeTable.hour = GetOption("DailyResetHour")
	timeTable.min = 0

	local now = time()
	local resetTime = time(timeTable)

	-- gap is positive if reset time was earlier in the day (ex: it is now 9am, reset was at 3am) => simply make sure that:
	--		the elapsed time since the quest was turned in is bigger than  (ex: 10 hours ago)
	--		the elapsed time since the last reset (ex: 6 hours ago)

	-- gap is negative if reset time is later on the same day (ex: it is 1am, reset is at 3am)
	--		the elapsed time since the quest was turned in is bigger than
	--		the elapsed time since the last reset 1 day before

	local gap = now - resetTime
	gap = (gap < 0) and (86400 + gap) or gap	-- ex: it's 1am, next reset is in 2 hours, so previous reset was (24 + (-2)) = 22 hours ago

	for characterKey, character in pairs(addon.Characters) do
		-- browse dailies history backwards, to avoid messing up the indexes when removing
		local dailies = character.Dailies
		
		for i = #dailies, 1, -1 do
			local quest = dailies[i]
			-- if (now - quest.timestamp) > gap then
			if quest.timestamp and quest.expiresIn and (now - quest.timestamp) > quest.expiresIn then
				table.remove(dailies, i)
			end
		end
		
		-- Clear weeklies
		local weeklies = character.Weeklies

		for i = #weeklies, 1, -1 do
			local quest = weeklies[i]
			
			-- fix the condition
			if quest.timestamp and quest.expiresIn and (now - quest.timestamp) > quest.expiresIn then
				table.remove(weeklies, i)
			end
		end
	end
end

local function DailyResetDropDown_OnClick(self)
	-- set the new reset hour
	local newHour = self.value
	
	addon.db.global.Options.DailyResetHour = newHour
	UIDropDownMenu_SetSelectedValue(DataStore_Quests_DailyResetDropDown, newHour)
end

local function DailyResetDropDown_Initialize(self)
	local info = UIDropDownMenu_CreateInfo()
	
	local selectedHour = GetOption("DailyResetHour")
	
	for hour = 0, 23 do
		info.value = hour
		info.text = format(TIMEMANAGER_TICKER_24HOUR, hour, 0)
		info.func = DailyResetDropDown_OnClick
		info.checked = (hour == selectedHour)
	
		UIDropDownMenu_AddButton(info)
	end
end

local function GetQuestTagID(questID, isComplete, frequency)
	local tagID = API_GetQuestTagInfo(questID)
	
	if tagID then
		-- if there is a tagID, process it
		if tagID == QUEST_TAG_ACCOUNT then
			local factionGroup = GetQuestFactionGroup(questID)
			if factionGroup then
				return (factionGroup == LE_QUEST_FACTION_HORDE) and "HORDE" or "ALLIANCE"
			else
				return QUEST_TAG_ACCOUNT
			end
		end
		return tagID	-- might be raid/dungeon..
	end

	if isComplete and isComplete ~= 0 then
		return (isComplete < 0) and "FAILED" or "COMPLETED"
	end

	-- at this point, isComplete is either nil or 0
	if frequency == API_DailyFrequency then
		return "DAILY"
	end

	if frequency == API_WeeklyFrequency then
		return "WEEKLY"
	end
end

local function InjectCallingsAsEmissaries()
	-- simply loop through all characters, and add the callings to the emissaries table
	for characterKey, character in pairs(addon.Characters) do
		for questID, _ in pairs(character.Callings) do
			emissaryQuests[questID] = 8	-- 8 as Shadowlands is EXPANSION_NAME8
			
			-- if the calling quest has not yet been taken at the npc (so it is only still in the Callings list)
			-- the it will not be enough to just inject it, since the quest log won't find the quest and populate the data.

			if not character.Emissaries[questID] then
				local questTitle = C_TaskQuest.GetQuestInfoByQuestID(questID)
				local objective, _, _, numFulfilled, numRequired = GetQuestObjectiveInfo(questID, 1, false)
				
				character.Emissaries[questID] = format("%d|%d|%d|%s|%d|%s", numFulfilled, numRequired, 
					C_TaskQuest.GetQuestTimeLeftMinutes(questID), objective or " ", time(), questTitle)
			end
		end
	end
end

-- *** Scanning functions ***
local headersState = {}

local function SaveHeaders()
	local headerCount = 0		-- use a counter to avoid being bound to header names, which might not be unique.

	for i = API_GetNumQuestLogEntries(), 1, -1 do		-- 1st pass, expand all categories
		local _, _, _, isHeader, isCollapsed = API_GetQuestInfo(i)
	
		if isHeader then
			headerCount = headerCount + 1
			if isCollapsed then
				ExpandQuestHeader(i)
				headersState[headerCount] = true
			end
		end
	end
end

local function RestoreHeaders()
	local headerCount = 0
	for i = API_GetNumQuestLogEntries(), 1, -1 do
		local _, _, _, isHeader = API_GetQuestInfo(i)
		
		if isHeader then
			headerCount = headerCount + 1
			if headersState[headerCount] then
				CollapseQuestHeader(i)
			end
		end
	end
	wipe(headersState)
end

local function ScanChoices(rewards, questID)
	-- rewards = out parameter

	-- these are the actual item choices proposed to the player
	for i = 1, GetNumQuestLogChoices(questID) do
		local _, _, numItems, _, isUsable = GetQuestLogChoiceInfo(i)
		isUsable = isUsable and 1 or 0	-- this was 1 or 0, in WoD, it is a boolean, convert back to 0 or 1
		local link = GetQuestLogItemLink("choice", i)
		if link then
			local id = tonumber(link:match("item:(%d+)"))
			if id then
				table.insert(rewards, format("c|%d|%d|%d", id, numItems, isUsable))
			end
		end
	end
end

local function ScanRewards(rewards)
	-- rewards = out parameter

	-- these are the rewards given anyway
	for i = 1, GetNumQuestLogRewards() do
		local _, _, numItems, _, isUsable = GetQuestLogRewardInfo(i)
		isUsable = isUsable and 1 or 0	-- this was 1 or 0, in WoD, it is a boolean, convert back to 0 or 1
		local link = GetQuestLogItemLink("reward", i)
		if link then
			local id = tonumber(link:match("item:(%d+)"))
			if id then
				table.insert(rewards, format("r|%d|%d|%d", id, numItems, isUsable))
			end
		end
	end
end

local function ScanRewardSpells(rewards, questID)
	-- rewards = out parameter

	for _, spellID in ipairs(C_QuestInfoSystem.GetQuestRewardSpells(questID) or {}) do
		if spellID and spellID > 0 then
			local spellInfo = C_QuestInfoSystem.GetQuestRewardSpellInfo(questID, spellID);
			
			if spellInfo and (spellInfo.isTradeskill or spellInfo.isSpellLearned) then
				table.insert(rewards, format("s|%d", spellID))
			end
		end
	end
end

local function ScanCampaignProgress(chapters, field)
	local count = 0
	
	-- loop through the quest id's of the last quest of each chapter, and check if it is flagged completed
	for _, questID in pairs(chapters) do
		if C_QuestLog.IsQuestFlaggedCompleted(questID) then
			count = count + 1
		end
	end
	
	local char = addon.ThisCharacter
	char[field] = count
end

local function ScanCovenantCampaignProgress()
	-- Get the covenant ID, exit if invalid
	local covenantID = C_Covenants.GetActiveCovenantID()
	if covenantID == Enum.CovenantType.None then return end

	local count = 0
	
	-- loop through the quest id's of the last quest of each chapter, and check if it is flagged completed
	for _, questID in pairs(covenantCampaignQuestChapters[covenantID]) do
		if C_QuestLog.IsQuestFlaggedCompleted(questID) then
			count = count + 1
		end
	end
	
	local char = addon.ThisCharacter
	char.activeCovenantID = C_Covenants.GetActiveCovenantID()
	char.covenantCampaignProgress = count
end

local function ScanQuests()
	local char = addon.ThisCharacter
	local quests = char.Quests
	local links = char.QuestLinks
	local headers = char.QuestHeaders
	local rewards = char.Rewards
	local tags = char.QuestTags
	local emissaries = char.Emissaries
	local titles = char.QuestTitles
	local money = char.Money

	wipe(quests)
	wipe(links)
	wipe(headers)
	wipe(rewards)
	wipe(tags)
	wipe(titles)			 
	wipe(money)
	
	-- wipe(emissaries)
	-- We do not want to delete all emissaries, some may have just been injected
	for questID, expansionLevel in pairs(emissaryQuests) do
		-- if they are not from shadowlands .. then they may be wiped
		if expansionLevel < 8 then
			emissaries[questID] = nil
		end
	end

	local currentSelection = API_GetSelectedQuest()		-- save the currently selected quest
	SaveHeaders()

	local rewardsCache = {}
	local lastHeaderIndex = 0
	local lastQuestIndex = 0
	
	for i = 1, API_GetNumQuestLogEntries() do

		local title, level, groupSize, isHeader, isCollapsed, isComplete, 
				frequency, questID, isTask, isBounty, isStory, isHidden, suggestedGroup	= API_GetQuestInfo(i)
		
		if isHeader then
			table.insert(headers, title or "")
			lastHeaderIndex = lastHeaderIndex + 1
		else
			API_SetSelectedQuest(WOW_PROJECT_ID == WOW_PROJECT_MAINLINE and questID or i)
			
			local value = (isComplete and isComplete > 0) and 1 or 0		-- bit 0 : isComplete
			value = value + LShift((frequency == API_DailyFrequency) and 1 or 0, 1)		-- bit 1 : isDaily
			value = value + LShift(isTask and 1 or 0, 2)						-- bit 2 : isTask
			value = value + LShift(isBounty and 1 or 0, 3)					-- bit 3 : isBounty
			value = value + LShift(isStory and 1 or 0, 4)					-- bit 4 : isStory
			value = value + LShift(isHidden and 1 or 0, 5)					-- bit 5 : isHidden
			value = value + LShift((groupSize == 0) and 1 or 0, 6)		-- bit 6 : isSolo
			-- bit 7 : unused, reserved

			value = value + LShift(suggestedGroup, 8)							-- bits 8-10 : groupSize, 3 bits, shouldn't exceed 5
			value = value + LShift(lastHeaderIndex, 11)					-- bits 11-15 : index of the header (zone) to which this quest belongs
			value = value + LShift(level, 16)								-- bits 16-23 : level
			-- value = value + LShift(GetQuestLogRewardMoney(), 24)		-- bits 24+ : money
			
			table.insert(quests, value)
			lastQuestIndex = lastQuestIndex + 1
			
			tags[lastQuestIndex] = GetQuestTagID(questID, isComplete, frequency)
			titles[lastQuestIndex] = title
			links[lastQuestIndex] = GetQuestLink and GetQuestLink(questID) or nil
			money[lastQuestIndex] = GetQuestLogRewardMoney()

			-- is the quest an emissary quest ?
			-- Note: this will also process callings, since they were injected earlier
			if emissaryQuests[questID] then
				local objective, _, _, numFulfilled, numRequired = GetQuestObjectiveInfo(questID, 1, false)
				emissaries[questID] = format("%d|%d|%d|%s|%d|%s", numFulfilled, numRequired, C_TaskQuest.GetQuestTimeLeftMinutes(questID), objective or "", time(), title)
			end

			wipe(rewardsCache)
			ScanChoices(rewardsCache, questID)
			ScanRewards(rewardsCache)
			ScanRewardSpells(rewardsCache, questID)

			if #rewardsCache > 0 then
				rewards[lastQuestIndex] = table.concat(rewardsCache, ",")
			end
		end
	end

	RestoreHeaders()
	API_SetSelectedQuest(currentSelection)		-- restore the selection to match the cursor, must be properly set if a user abandons a quest
	
	if WOW_PROJECT_ID == WOW_PROJECT_MAINLINE then
		ScanCovenantCampaignProgress()
		ScanCampaignProgress(ChainsCampaignQuestChapters, "story91Progress")
		ScanCampaignProgress(SecretsOfTheFirstOnesQuestChapters, "story92Progress")
	end
	addon.ThisCharacter.lastUpdate = time()
	
	addon:SendMessage("DATASTORE_QUESTLOG_SCANNED", char)
end

local function ScanCallings(bountyInfo)
	if not bountyInfo or not C_CovenantCallings.AreCallingsUnlocked() then return end

	local char = addon.ThisCharacter
	local callings = char.Callings
	wipe(callings)
	
	for _, bounty in pairs(bountyInfo) do
		local questID = bounty.questID
		local timeRemaining = C_TaskQuest.GetQuestTimeLeftMinutes(questID) or 0
		
		callings[questID] = format("%s|%s", timeRemaining, bounty.icon)
	end
	
	InjectCallingsAsEmissaries()
end

local queryVerbose

-- *** Event Handlers ***
local function OnPlayerAlive()
	ScanQuests()
end

local function OnQuestLogUpdate()
	addon:UnregisterEvent("QUEST_LOG_UPDATE")		-- .. and unregister it right away, since we only want it to be processed once (and it's triggered way too often otherwise)
	ScanQuests()
end

local function OnUnitQuestLogChanged()			-- triggered when accepting/validating a quest .. but too soon to refresh data
	addon:RegisterEvent("QUEST_LOG_UPDATE", OnQuestLogUpdate)		-- so register for this one ..
end

local function OnCovenantCallingsUpdated(event, bountyInfo)
	-- source: https://wow.gamepedia.com/COVENANT_CALLINGS_UPDATED
	ScanCallings(bountyInfo)
end

local function OnQuestTurnedIn(event, questID, xpReward, moneyReward)
	if weeklyWorldQuests[questID] then
		table.insert(addon.ThisCharacter.Weeklies, {
			title = C_QuestLog.GetTitleForQuestID(questID),
			id = questID,
			timestamp = time(),
			expiresIn = C_DateAndTime.GetSecondsUntilWeeklyReset()
		})
	end
end


local function GetQuestHistory_Common()
	-- In retail, the questID is the value in the returned table
	if WOW_PROJECT_ID == WOW_PROJECT_MAINLINE then
		return C_QuestLog.GetAllCompletedQuestIDs()
	end

	-- In Classic and WotLK, the questID is the key ..
	local quests = {}
	GetQuestsCompleted(quests)	
	
	-- .. so let's normalize that
	return DataStore:HashToSortedArray(quests)
end

local function RefreshQuestHistory()
	local thisChar = addon.ThisCharacter
	local history = thisChar.History
	wipe(history)
	
	local quests = GetQuestHistory_Common()

	--[[	In order to save memory, we'll save the completion status of 32 quests into one number (by setting bits 0 to 31)
		Ex:
			in history[1] , we'll save quests 0 to 31		(note: questID 0 does not exist, we're losing one bit, doesn't matter :p)
			in history[2] , we'll save quests 32 to 63
			...
			index = questID / 32 (rounded up)
			bit position = questID % 32
	--]]

	local count = 0
	local index, bitPos
	for _, questID in pairs(quests) do
		bitPos = (questID % 32)
		index = ceil(questID / 32)

		history[index] = bOr((history[index] or 0), 2^bitPos)	-- read: value = SetBit(value, bitPosition)
		count = count + 1
	end

	local _, version = GetBuildInfo()				-- save the current build, to know if we can requery and expect immediate execution
	thisChar.HistoryBuild = version
	thisChar.HistorySize = count
	thisChar.HistoryLastUpdate = time()

	if queryVerbose then
		addon:Print("Quest history successfully retrieved!")
		queryVerbose = nil
	end
end

-- ** Mixins **
local function _GetEmissaryQuests()
	return emissaryQuests
end

local function _GetEmissaryQuestInfo(character, questID)
	local quest = character.Emissaries[questID]
	if not quest then return end

	local numFulfilled, numRequired, timeLeft, objective, timeSaved, questName = strsplit("|", quest)

	numFulfilled = tonumber(numFulfilled) or 0
	numRequired = tonumber(numRequired) or 0
	timeLeft = (tonumber(timeLeft) or 0) * 60		-- we want the time left to be in seconds
	
	if timeLeft > 0 then
		local secondsSinceLastUpdate = time() - character.lastUpdate
		if secondsSinceLastUpdate > timeLeft then		-- if the info has expired ..
			character.Emissaries[questID] = nil			-- .. clear the entry
			return
		end
		
		timeLeft = timeLeft - secondsSinceLastUpdate
	end

	local expansionLevel = emissaryQuests[questID]
	
	return numFulfilled, numRequired, timeLeft, objective, questName, expansionLevel
end

local function _GetQuestLogSize(character)
	return #character.Quests
end

local function _GetQuestLogInfo(character, index, callingQuestID)
	-- Typical function call : GetQuestLogInfo(character, 5)
	-- Call for a calling : GetQuestLogInfo(character, nil, 12345)
	-- 	index not necessary, calling quest id mandatory
	
	-- Special treatment in case info is requested for a calling that is not yet in the quest log
	if not index and callingQuestID and emissaryQuests[callingQuestID] then
		-- return only the quest name
		return select(5, _GetEmissaryQuestInfo(character, callingQuestID))
	end

	local quest = character.Quests[index]
	if not quest or type(quest) == "string" then return end
	
	local isComplete = TestBit(quest, 0)
	local isDaily = TestBit(quest, 1)
	local isTask = TestBit(quest, 2)
	local isBounty = TestBit(quest, 3)
	local isStory = TestBit(quest, 4)
	local isHidden = TestBit(quest, 5)
	local isSolo = TestBit(quest, 6)

	local groupSize = bAnd(RShift(quest, 8), 7)			-- 3-bits mask
	local headerIndex = bAnd(RShift(quest, 11), 31)		-- 5-bits mask
	local level = bAnd(RShift(quest, 16), 255)			-- 8-bits mask
	
	local groupName = character.QuestHeaders[headerIndex]		-- This is most often the zone name, or the profession name
	
	local tag = character.QuestTags[index]
	local link, questID, questName
	
	if WOW_PROJECT_ID == WOW_PROJECT_MAINLINE then
		link = character.QuestLinks[index]
		questID = link:match("quest:(%d+)")
		questName = link:match("%[(.+)%]")
	else
		-- link = nil			-- intentionally left nil for non-retail
		-- questID = nil
		questName = character.QuestTitles[index]
	end
	
	return questName, questID, link, groupName, level, groupSize, tag, isComplete, isDaily, isTask, isBounty, isStory, isHidden, isSolo
end

local function _GetQuestHeaders(character)
	return character.QuestHeaders
end

local function _GetQuestLogMoney(character, index)
	-- if not character.Money then return end
	
	local money = character.Money[index]
	return money or 0
end

local function _GetQuestLogNumRewards(character, index)
	local reward = character.Rewards[index]
	if reward then
		return select(2, gsub(reward, ",", ",")) + 1		-- returns the number of rewards (=count of ^ +1)
	end
	return 0
end

local function _GetQuestLogRewardInfo(character, index, rewardIndex)
	local reward = character.Rewards[index]
	if not reward then return end

	local i = 1
	for v in reward:gmatch("([^,]+)") do
		if rewardIndex == i then
			local rewardType, id, numItems, isUsable = strsplit("|", v)

			numItems = tonumber(numItems) or 0
			isUsable = (isUsable and isUsable == 1) and true or nil

			return rewardType, tonumber(id), numItems, isUsable
		end
		i = i + 1
	end
end

local function _GetQuestInfo(link)
	if type(link) ~= "string" then return end

	local questID, questLevel = link:match("quest:(%d+):(-?%d+)")
	local questName = link:match("%[(.+)%]")

	return questName, tonumber(questID), tonumber(questLevel)
end

local function _QueryQuestHistory()
	queryVerbose = true
	RefreshQuestHistory()		-- this call triggers "QUEST_QUERY_COMPLETE"
end

local function _GetQuestHistory(character)
	return character.History
end

local function _GetQuestHistoryInfo(character)
	-- return the size of the history, the timestamp, and the build under which it was saved
	return character.HistorySize, character.HistoryLastUpdate, character.HistoryBuild
end

local function _GetDailiesHistory(character)
	return character.Dailies
end

local function _GetDailiesHistorySize(character)
	return #character.Dailies
end

local function _GetDailiesHistoryInfo(character, index)
	local quest = character.Dailies[index]
	return quest.id, quest.title, quest.timestamp
end

local function _GetWeekliesHistory(character)
	return character.Weeklies
end

local function _GetWeekliesHistorySize(character)
	return #character.Weeklies
end

local function _GetWeekliesHistoryInfo(character, index)
	local quest = character.Weeklies[index]
	return quest.id, quest.title, quest.timestamp
end

local function _IsQuestCompletedBy(character, questID)
	local bitPos = (questID % 32)
	local index = ceil(questID / 32)

	if character.History[index] then
		return TestBit(character.History[index], bitPos)		-- nil = not completed (not in the table), true = completed
	end
end

local function _IsCharacterOnQuest(character, questID)
	-- Check if the quest is in the quest log
	for index, link in pairs(character.QuestLinks) do
		local id = link:match("quest:(%d+)")
		if questID == tonumber(id) then
			return true, index		-- return 'true' if the id was found, also return the index at which it was found
		end
	end
	
	-- Callings will be empty for non-retail, we can leave it as is.
	-- If not in the quest log, it may be a Calling (even not yet accepted and not yet in the quest log)
	for callingQuestID, _ in pairs(character.Callings) do
		if questID == callingQuestID then
			return true, nil
		end
	end
end

local function _GetCharactersOnQuest(questName, player, realm, account)
	-- Get the characters of the current realm that are also on a given quest
	local out = {}
	account = account or DataStore.ThisAccount
	realm = realm or DataStore.ThisRealm

	for characterKey, character in pairs(addon.Characters) do
		local accountName, realmName, characterName = strsplit(".", characterKey)
		
		-- all players except the one passed as parameter on that account & that realm
		if account == accountName and realm == realmName and player ~= characterName then
			local questLogSize = _GetQuestLogSize(character) or 0
			for i = 1, questLogSize do
				local name = _GetQuestLogInfo(character, i)
				if questName == name then		-- same quest found ?
					table.insert(out, characterKey)
				end
			end
		end
	end

	return out
end

local function _IterateQuests(character, category, callback)
	-- category : category index (or 0 for all)
	
	for index = 1, _GetQuestLogSize(character) do
		local quest = character.Quests[index]
		local headerIndex = bAnd(RShift(quest, 11), 31)		-- 5-bits mask	
		
		-- filter quests that are in the right category
		if (category == 0) or (category == headerIndex) then
			local stop = callback(index)
			if stop then return end		-- exit if the callback returns true
		end
	end
end

local function _GetCovenantCampaignProgress(character)
	return character.covenantCampaignProgress
end

local function _GetCovenantCampaignLength(character)
	local covenantID = character.activeCovenantID
	if not covenantID or covenantID == Enum.CovenantType.None then return 0 end
	
	local campaignID = covenantCampaignIDs[covenantID]				-- get the campaign ID of that character's covenant
	local chapters = C_CampaignInfo.GetChapterIDs(campaignID)	-- get the chapters of that campaing (always available for all covenants)
	
	return #chapters
end

local function _GetCovenantCampaignChaptersInfo(character)
	local covenantID = character.activeCovenantID
	if not covenantID or covenantID == Enum.CovenantType.None then return {} end
	
	local campaignID = covenantCampaignIDs[covenantID]				-- get the campaign ID of that character's covenant
	local chapters = C_CampaignInfo.GetChapterIDs(campaignID)	-- get the chapters of that campaing (always available for all covenants)
	
	local chaptersInfo = {}

	for index, id in ipairs(chapters) do
		local info = C_CampaignInfo.GetCampaignChapterInfo(id)
		
		-- completed will be true/false or nil
		-- ex: progress is 3/9
		-- 1 & 2 are true (completed)
		-- 3 is false (ongoing, but not completed yet)
		-- 4+ = nil (not yet started)
			
		local completed = nil
		if (index <= character.covenantCampaignProgress) then
			completed = true
		elseif (index == character.covenantCampaignProgress + 1) and (character.covenantCampaignProgress ~= 0) then
			completed = false
		end
		
		table.insert(chaptersInfo, { name = info.name, completed = completed})
	end
	
	return chaptersInfo
end

local function _GetCampaignChaptersInfo(character, campaignID, field)
	local chapters = C_CampaignInfo.GetChapterIDs(campaignID)	-- get the chapters of that campaign (always available for all covenants)
	
	local chaptersInfo = {}

	for index, id in ipairs(chapters) do
		local info = C_CampaignInfo.GetCampaignChapterInfo(id)
		
		-- completed will be true/false or nil
		-- ex: progress is 3/9
		-- 1 & 2 are true (completed)
		-- 3 is false (ongoing, but not completed yet)
		-- 4+ = nil (not yet started)
			
		local completed = nil
		if (index <= character[field]) then
			completed = true
		elseif (index == character[field] + 1) and (character[field] ~= 0) then
			completed = false
		end
		
		table.insert(chaptersInfo, { name = info.name, completed = completed})
	end
	
	return chaptersInfo
end

local function _GetTorghastStorylineProgress(character)
	local count = 0
	
	for _, questID in ipairs(TorghastQuestLine) do
		if _IsQuestCompletedBy(character, questID) then
			count = count + 1
		end
	end
	
	return count
end

local function _GetTorghastStorylineLength(character)
	return #TorghastQuestLine
end

local function _GetChainsOfDominationStorylineProgress(character)
	return character.story91Progress
end

local function _GetChainsOfDominationStorylineLength(character)
	return #ChainsCampaignQuestChapters
end

local function _GetSecretsOfTheFirstOnesStorylineProgress(character)
	return character.story92Progress
end

local function _GetSecretsOfTheFirstOnesStorylineLength(character)
	return #SecretsOfTheFirstOnesQuestChapters
end

local PublicMethods = {
	GetQuestLogSize = _GetQuestLogSize,
	GetQuestLogInfo = _GetQuestLogInfo,
	GetQuestHeaders = _GetQuestHeaders,
	GetQuestLogMoney = _GetQuestLogMoney,
	GetQuestLogNumRewards = _GetQuestLogNumRewards,
	GetQuestLogRewardInfo = _GetQuestLogRewardInfo,
	GetQuestInfo = _GetQuestInfo,
	QueryQuestHistory = _QueryQuestHistory,
	GetQuestHistory = _GetQuestHistory,
	GetQuestHistoryInfo = _GetQuestHistoryInfo,
	IsQuestCompletedBy = _IsQuestCompletedBy,
	GetDailiesHistory = _GetDailiesHistory,
	GetDailiesHistorySize = _GetDailiesHistorySize,
	GetDailiesHistoryInfo = _GetDailiesHistoryInfo,
	IsCharacterOnQuest = _IsCharacterOnQuest,
	GetCharactersOnQuest = _GetCharactersOnQuest,
	IterateQuests = _IterateQuests,
}

if WOW_PROJECT_ID == WOW_PROJECT_MAINLINE then
	PublicMethods.GetEmissaryQuests = _GetEmissaryQuests
	PublicMethods.GetEmissaryQuestInfo = _GetEmissaryQuestInfo
	PublicMethods.GetWeekliesHistory = _GetWeekliesHistory
	PublicMethods.GetWeekliesHistorySize = _GetWeekliesHistorySize
	PublicMethods.GetWeekliesHistoryInfo = _GetWeekliesHistoryInfo
	PublicMethods.GetCovenantCampaignProgress = _GetCovenantCampaignProgress
	PublicMethods.GetCovenantCampaignLength = _GetCovenantCampaignLength
	PublicMethods.GetCovenantCampaignChaptersInfo = _GetCovenantCampaignChaptersInfo
	PublicMethods.GetCampaignChaptersInfo = _GetCampaignChaptersInfo
	PublicMethods.GetTorghastStorylineProgress = _GetTorghastStorylineProgress
	PublicMethods.GetTorghastStorylineLength = _GetTorghastStorylineLength
	PublicMethods.GetChainsOfDominationStorylineProgress = _GetChainsOfDominationStorylineProgress
	PublicMethods.GetChainsOfDominationStorylineLength = _GetChainsOfDominationStorylineLength
	PublicMethods.GetSecretsOfTheFirstOnesStorylineProgress = _GetSecretsOfTheFirstOnesStorylineProgress
	PublicMethods.GetSecretsOfTheFirstOnesStorylineLength = _GetSecretsOfTheFirstOnesStorylineLength
end

function addon:OnInitialize()
	addon.db = LibStub("AceDB-3.0"):New(addonName .. "DB", AddonDB_Defaults)

	DataStore:RegisterModule(addonName, addon, PublicMethods)
	DataStore:SetCharacterBasedMethod("GetQuestLogSize")
	DataStore:SetCharacterBasedMethod("GetQuestLogInfo")
	DataStore:SetCharacterBasedMethod("GetQuestHeaders")
	DataStore:SetCharacterBasedMethod("GetQuestLogMoney")
	DataStore:SetCharacterBasedMethod("GetQuestLogNumRewards")
	DataStore:SetCharacterBasedMethod("GetQuestLogRewardInfo")
	DataStore:SetCharacterBasedMethod("GetQuestHistory")
	DataStore:SetCharacterBasedMethod("GetQuestHistoryInfo")
	DataStore:SetCharacterBasedMethod("IsQuestCompletedBy")
	DataStore:SetCharacterBasedMethod("GetDailiesHistory")
	DataStore:SetCharacterBasedMethod("GetDailiesHistorySize")
	DataStore:SetCharacterBasedMethod("GetDailiesHistoryInfo")
	DataStore:SetCharacterBasedMethod("IsCharacterOnQuest")
	DataStore:SetCharacterBasedMethod("IterateQuests")
	
	if WOW_PROJECT_ID == WOW_PROJECT_MAINLINE then
		DataStore:SetCharacterBasedMethod("GetWeekliesHistory")
		DataStore:SetCharacterBasedMethod("GetWeekliesHistorySize")
		DataStore:SetCharacterBasedMethod("GetWeekliesHistoryInfo")
		DataStore:SetCharacterBasedMethod("GetEmissaryQuestInfo")
		DataStore:SetCharacterBasedMethod("GetCovenantCampaignProgress")
		DataStore:SetCharacterBasedMethod("GetCovenantCampaignLength")
		DataStore:SetCharacterBasedMethod("GetCovenantCampaignChaptersInfo")
		DataStore:SetCharacterBasedMethod("GetCampaignChaptersInfo")
		DataStore:SetCharacterBasedMethod("GetTorghastStorylineProgress")
		DataStore:SetCharacterBasedMethod("GetTorghastStorylineLength")
		DataStore:SetCharacterBasedMethod("GetChainsOfDominationStorylineProgress")
		DataStore:SetCharacterBasedMethod("GetChainsOfDominationStorylineLength")
		DataStore:SetCharacterBasedMethod("GetSecretsOfTheFirstOnesStorylineProgress")
		DataStore:SetCharacterBasedMethod("GetSecretsOfTheFirstOnesStorylineLength")
	end
end

function addon:OnEnable()
	addon:RegisterEvent("PLAYER_ALIVE", OnPlayerAlive)
	addon:RegisterEvent("UNIT_QUEST_LOG_CHANGED", OnUnitQuestLogChanged)
	if WOW_PROJECT_ID == WOW_PROJECT_MAINLINE then
		addon:RegisterEvent("WORLD_QUEST_COMPLETED_BY_SPELL", ScanQuests)
		addon:RegisterEvent("COVENANT_CALLINGS_UPDATED", OnCovenantCallingsUpdated)
		addon:RegisterEvent("QUEST_TURNED_IN", OnQuestTurnedIn)
	end

	addon:SetupOptions()

	if GetOption("AutoUpdateHistory") then		-- if history has been queried at least once, auto update it at logon (fast operation - already in the game's cache)
		addon:ScheduleTimer(RefreshQuestHistory, 5)	-- refresh quest history 5 seconds later, to decrease the load at startup
	end

	-- Daily Reset Drop Down & label
	local frame = DataStore.Frames.QuestsOptions.DailyResetDropDownLabel
	frame:SetText(format("|cFFFFFFFF%s:", L["DAILY_QUESTS_RESET_LABEL"]))

	frame = DataStore_Quests_DailyResetDropDown
	UIDropDownMenu_SetWidth(frame, 60)

	-- This line causes tainting, do not use as is
	-- UIDropDownMenu_Initialize(frame, DailyResetDropDown_Initialize)
	frame.displayMode = "MENU"
	frame.initialize = DailyResetDropDown_Initialize
	
	UIDropDownMenu_SetSelectedValue(frame, GetOption("DailyResetHour"))
	
	ClearExpiredDailies()
	if WOW_PROJECT_ID == WOW_PROJECT_MAINLINE then
		InjectCallingsAsEmissaries()
	end
end

function addon:OnDisable()
	addon:UnregisterEvent("PLAYER_ALIVE")
	addon:UnregisterEvent("UNIT_QUEST_LOG_CHANGED")
	addon:UnregisterEvent("QUEST_QUERY_COMPLETE")
	
	if WOW_PROJECT_ID == WOW_PROJECT_MAINLINE then
		addon:UnregisterEvent("WORLD_QUEST_COMPLETED_BY_SPELL")
		addon:UnregisterEvent("COVENANT_CALLINGS_UPDATED")
	end
end

-- *** Hooks ***
-- GetQuestReward is the function that actually turns in a quest
hooksecurefunc("GetQuestReward", function(choiceIndex)
	-- 2019/09/09 : questID is valid, even in Classic
	local questID = GetQuestID() -- returns the last displayed quest dialog's questID

	if not GetOption("TrackTurnIns") or not questID then return end
	
	local history = addon.ThisCharacter.History
	local bitPos  = (questID % 32)
	local index   = ceil(questID / 32)

	if type(history[index]) == "boolean" then		-- temporary workaround for all players who have not cleaned their SV for 4.0
		history[index] = 0
	end

	-- mark the current quest ID as completed
	history[index] = bOr((history[index] or 0), 2^bitPos)	-- read: value = SetBit(value, bitPosition)

	if WOW_PROJECT_ID == WOW_PROJECT_MAINLINE then

		-- track daily quests turn-ins
		if QuestIsDaily() or emissaryQuests[questID] then
			-- I could not find a function to test if a quest is emissary, so their id's are tracked manually
			
			table.insert(addon.ThisCharacter.Dailies, {
				title = GetTitleText(),
				id = questID,
				timestamp = time(),
				expiresIn = C_DateAndTime.GetSecondsUntilDailyReset()
				-- https://wowpedia.fandom.com/wiki/API_C_DateAndTime.GetSecondsUntilDailyReset
			})
		end

		-- track weekly quests turn-ins
		if QuestIsWeekly() then
			table.insert(addon.ThisCharacter.Weeklies, {
				title = GetTitleText(),
				id = questID,
				timestamp = time(),
				expiresIn = C_DateAndTime.GetSecondsUntilWeeklyReset()
			})
		end
	end
	
	addon:SendMessage("DATASTORE_QUEST_TURNED_IN", questID)		-- trigger the DS event
end)
