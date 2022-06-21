--[[	*** DataStore_Quests ***
Written by : Thaoky, EU-Marécages de Zangar
July 8th, 2009
--]]

if not DataStore then return end

local addonName = "DataStore_Quests"

_G[addonName] = LibStub("AceAddon-3.0"):NewAddon(addonName, "AceConsole-3.0", "AceEvent-3.0", "AceTimer-3.0")

local addon = _G[addonName]
local L = LibStub("AceLocale-3.0"):GetLocale(addonName)

local THIS_ACCOUNT = "Default"
local THIS_REALM = GetRealmName()

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
				-- QuestLinks = {},			-- No quest links in Classic !!
				QuestHeaders = {},
				QuestTitles = {},
				QuestTags = {},
				Rewards = {},
				Money = {},
				Dailies = {},
				History = {},		-- a list of completed quests, hash table ( [questID] = true )
				HistoryBuild = nil,	-- build version under which the history has been saved
				HistorySize = 0,
				HistoryLastUpdate = nil,
			}
		}
	}
}

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
	for i = 1, GetNumQuestLogEntries() do
		local title = GetQuestLogTitle(i);
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
			if (now - quest.timestamp) > gap then
				table.remove(dailies, i)
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

	local tagID = GetQuestTagInfo(questID)
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
	if frequency == LE_QUEST_FREQUENCY_DAILY then
		return "DAILY"
	end

	if frequency == LE_QUEST_FREQUENCY_WEEKLY then
		return "WEEKLY"
	end
end


-- *** Scanning functions ***
local headersState = {}

local function SaveHeaders()
	local headerCount = 0		-- use a counter to avoid being bound to header names, which might not be unique.

	for i = GetNumQuestLogEntries(), 1, -1 do		-- 1st pass, expand all categories
		local _, _, _, _, isHeader, isCollapsed = GetQuestLogTitle(i)
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
	for i = GetNumQuestLogEntries(), 1, -1 do
		local _, _, _, _, isHeader = GetQuestLogTitle(i)
		if isHeader then
			headerCount = headerCount + 1
			if headersState[headerCount] then
				CollapseQuestHeader(i)
			end
		end
	end
	wipe(headersState)
end

local function ScanChoices(rewards)
	-- rewards = out parameter

	-- these are the actual item choices proposed to the player
	for i = 1, GetNumQuestLogChoices() do
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

local function ScanRewardSpells(rewards)
	-- rewards = out parameter
			
	for index = 1, GetNumQuestLogRewardSpells() do
		local _, _, isTradeskillSpell, isSpellLearned = GetQuestLogRewardSpell(index)
		if isTradeskillSpell or isSpellLearned then
			local link = GetQuestLogSpellLink(index)
			if link then
				local id = tonumber(link:match("spell:(%d+)"))
				if id then
					table.insert(rewards, format("s|%d", id))
				end
			end
		end
	end
end

local function ScanQuests()
	local char = addon.ThisCharacter
	local quests = char.Quests
	-- local links = char.QuestLinks
	local headers = char.QuestHeaders
	local rewards = char.Rewards
	local tags = char.QuestTags
	local titles = char.QuestTitles
	local money = char.Money

	wipe(quests)
	-- wipe(links)
	wipe(headers)
	wipe(rewards)
	wipe(tags)
	wipe(titles)
	wipe(money)

	local currentSelection = GetQuestLogSelection()		-- save the currently selected quest
	SaveHeaders()

	local rewardsCache = {}
	local lastHeaderIndex = 0
	local lastQuestIndex = 0
	
	for i = 1, GetNumQuestLogEntries() do
		local title, level, groupSize, isHeader, isCollapsed, isComplete, frequency, questID, startEvent, displayQuestID, 
				isOnMap, hasLocalPOI, isTask, isBounty, isStory, isHidden = GetQuestLogTitle(i)

		-- 2019/09/01 groupSize = "Dungeon", "Raid" in Classic, not numeric !!
		-- temporary fix: set it to 0
		groupSize = 0
				
		if isHeader then
			table.insert(headers, title or "")
			lastHeaderIndex = lastHeaderIndex + 1
		else
			SelectQuestLogEntry(i)
			
			local value = (isComplete and isComplete > 0) and 1 or 0		-- bit 0 : isComplete
			value = value + LShift((frequency == LE_QUEST_FREQUENCY_DAILY) and 1 or 0, 1)		-- bit 1 : isDaily
			value = value + LShift(isTask and 1 or 0, 2)						-- bit 2 : isTask
			value = value + LShift(isBounty and 1 or 0, 3)					-- bit 3 : isBounty
			value = value + LShift(isStory and 1 or 0, 4)					-- bit 4 : isStory
			value = value + LShift(isHidden and 1 or 0, 5)					-- bit 5 : isHidden
			value = value + LShift((groupSize == 0) and 1 or 0, 6)		-- bit 6 : isSolo
			-- bit 7 : unused, reserved
			
			value = value + LShift(groupSize or 1, 8)						-- bits 8-10 : groupSize, 3 bits, shouldn't exceed 5
			value = value + LShift(lastHeaderIndex, 11)					-- bits 11-15 : index of the header (zone) to which this quest belongs
			value = value + LShift(level, 16)								-- bits 16-23 : level
			-- value = value + LShift(GetQuestLogRewardMoney(), 24)		-- bits 24+ : money
			
			table.insert(quests, value)
			lastQuestIndex = lastQuestIndex + 1
			
			tags[lastQuestIndex] = GetQuestTagID(questID, isComplete, frequency)
			titles[lastQuestIndex] = title
			-- links[lastQuestIndex] = GetQuestLink(questID)
			money[lastQuestIndex] = GetQuestLogRewardMoney()

			wipe(rewardsCache)
			ScanChoices(rewardsCache)
			ScanRewards(rewardsCache)
			ScanRewardSpells(rewardsCache)

			if #rewardsCache > 0 then
				rewards[lastQuestIndex] = table.concat(rewardsCache, ",")
			end
		end
	end

	RestoreHeaders()
	SelectQuestLogEntry(currentSelection)		-- restore the selection to match the cursor, must be properly set if a user abandons a quest

	addon.ThisCharacter.lastUpdate = time()
	
	addon:SendMessage("DATASTORE_QUESTLOG_SCANNED", char)
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

local function RefreshQuestHistory()
	local thisChar = addon.ThisCharacter
	local history = thisChar.History
	wipe(history)
	local quests = {}
	GetQuestsCompleted(quests)	-- works in Classic !! Yay \o/ 

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
	for questID in pairs(quests) do
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
local function _GetQuestLogSize(character)
	return #character.Quests
end

local function _GetQuestLogInfo(character, index)
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
	-- local link = character.QuestLinks[index]
	local link = nil
	-- local questID = link:match("quest:(%d+)")
	local questID = nil
	-- local questName = link:match("%[(.+)%]")
	local questName = character.QuestTitles[index]
	
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

local function _IsQuestCompletedBy(character, questID)
	local bitPos = (questID % 32)
	local index = ceil(questID / 32)

	if character.History[index] then
		return TestBit(character.History[index], bitPos)		-- nil = not completed (not in the table), true = completed
	end
end

local function _IsCharacterOnQuest(character, questID)
	-- TODO fix for classic

	for index, link in pairs(character.QuestLinks) do
		local id = link:match("quest:(%d+)")
		if questID == tonumber(id) then
			return true, index		-- return 'true' if the id was found, also return the index at which it was found
		end
	end
end

local function _GetCharactersOnQuest(questName, player, realm, account)
	-- Get the characters of the current realm that are also on a given quest
	local out = {}
	account = account or THIS_ACCOUNT
	realm = realm or THIS_REALM

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
end

function addon:OnEnable()
	addon:RegisterEvent("PLAYER_ALIVE", OnPlayerAlive)
	addon:RegisterEvent("UNIT_QUEST_LOG_CHANGED", OnUnitQuestLogChanged)

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
end

function addon:OnDisable()
	addon:UnregisterEvent("PLAYER_ALIVE")
	addon:UnregisterEvent("UNIT_QUEST_LOG_CHANGED")
	addon:UnregisterEvent("QUEST_QUERY_COMPLETE")
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

	addon:SendMessage("DATASTORE_QUEST_TURNED_IN", questID)		-- trigger the DS event
end)
