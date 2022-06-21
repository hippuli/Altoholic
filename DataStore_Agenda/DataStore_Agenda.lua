--[[	*** DataStore_Agenda ***
Written by : Thaoky, EU-Marécages de Zangar
April 2nd, 2011
--]]

if not DataStore then return end

local addonName = "DataStore_Agenda"

_G[addonName] = LibStub("AceAddon-3.0"):NewAddon(addonName, "AceConsole-3.0", "AceEvent-3.0", "AceComm-3.0", "AceSerializer-3.0", "AceTimer-3.0")

local addon = _G[addonName]

local THIS_ACCOUNT = "Default"

local AddonDB_Defaults = {
	global = {
		Characters = {
			['*'] = {				-- ["Account.Realm.Name"]
				lastUpdate = nil,
				DungeonIDs = {},		-- raid timers
				BossKills = {},		-- Boss kills
			}
		}
	}
}

-- *** Scanning functions ***
local function ScanDungeonIDs()
	local character = addon.ThisCharacter
	local dungeons = character.DungeonIDs
	wipe(dungeons)
	
	local bossKills = character.BossKills
	wipe(bossKills)

	for i = 1, GetNumSavedInstances() do
		local instanceName, instanceID, instanceReset, difficulty, _, extended, _, isRaid, maxPlayers, difficultyName, 
				numEncounters, encounterProgress, extendDisabled = GetSavedInstanceInfo(i)

		if instanceReset > 0 then		-- in 3.2, instances with reset = 0 are also listed (to support raid extensions)
			extended = extended and 1 or 0
			isRaid = isRaid and 1 or 0

			if difficulty > 1 then
				instanceName = format("%s %s", instanceName, difficultyName)
			end

			local key = format("%s|%s", instanceName, instanceID)
			dungeons[key] = format("%s|%s|%s|%s", instanceReset, time(), extended, isRaid)
			
			-- Bosses killed in this dungeon
			bossKills[key] = {}
			
			for encounterIndex = 1, numEncounters do
				local name, _, isKilled = GetSavedInstanceEncounterInfo(i, encounterIndex)
				isKilled = isKilled and 1 or 0
				
				table.insert(bossKills[key], format("%s|%s", name, isKilled))
			end
		end
	end
	
	character.lastUpdate = time()
end


-- *** Event Handlers ***
local function OnPlayerAlive()
	ScanDungeonIDs()
end

local function OnUpdateInstanceInfo()
	ScanDungeonIDs()
end

local function OnRaidInstanceWelcome()
	RequestRaidInfo()
end

local function OnBossKill(event, encounterID, encounterName)
	-- To do
	-- print("event:" .. (event or "nil"))
	-- print("encounterID:" .. (encounterID or "nil"))
	-- print("encounterName:" .. (encounterName or "nil"))
end

local function OnChatMsgSystem(event, arg)
	if arg then
		if tostring(arg) == INSTANCE_SAVED then
			RequestRaidInfo()
		end
	end
end


-- ** Mixins **

-- * Dungeon IDs *
local function _GetSavedInstances(character)
	return character.DungeonIDs

	--[[	Typical usage:

		for dungeonKey, _ in pairs(DataStore:GetSavedInstances(character) do
			myvar1, myvar2, .. = DataStore:GetSavedInstanceInfo(character, dungeonKey)
		end
	--]]
end

local function _GetSavedInstanceInfo(character, key)
	local instanceInfo = character.DungeonIDs[key]
	if not instanceInfo then return end

	local hasExpired
	local reset, lastCheck, isExtended, isRaid = strsplit("|", instanceInfo)

	return tonumber(reset), tonumber(lastCheck), (isExtended == "1") and true or nil, (isRaid == "1") and true or nil
end

local function _GetSavedInstanceNumEncounters(character, key)
	return (character.BossKills[key]) and #character.BossKills[key] or 0
end

local function _GetSavedInstanceEncounterInfo(character, key, index)
	local info = character.BossKills[key]
	if not info then return end
	
	local name, isKilled = strsplit("|", info[index])
	
	return name, (isKilled == "1") and true or nil
end

local function _HasSavedInstanceExpired(character, key)
	local reset, lastCheck = _GetSavedInstanceInfo(character, key)
	if not reset or not lastCheck then return end

	local hasExpired
	local expiresIn = reset - (time() - lastCheck)

	if expiresIn <= 0 then	-- has expired
		hasExpired = true
	end

	return hasExpired, expiresIn
end

local function _DeleteSavedInstance(character, key)
	character.DungeonIDs[key] = nil
end


local PublicMethods = {
	GetSavedInstances = _GetSavedInstances,
	GetSavedInstanceInfo = _GetSavedInstanceInfo,
	GetSavedInstanceNumEncounters = _GetSavedInstanceNumEncounters,
	GetSavedInstanceEncounterInfo = _GetSavedInstanceEncounterInfo,
	HasSavedInstanceExpired = _HasSavedInstanceExpired,
	DeleteSavedInstance = _DeleteSavedInstance,
}

function addon:OnInitialize()
	addon.db = LibStub("AceDB-3.0"):New(addonName .. "DB", AddonDB_Defaults)

	DataStore:RegisterModule(addonName, addon, PublicMethods)

	DataStore:SetCharacterBasedMethod("GetSavedInstances")
	DataStore:SetCharacterBasedMethod("GetSavedInstanceInfo")
	DataStore:SetCharacterBasedMethod("GetSavedInstanceNumEncounters")
	DataStore:SetCharacterBasedMethod("GetSavedInstanceEncounterInfo")
	DataStore:SetCharacterBasedMethod("HasSavedInstanceExpired")
	DataStore:SetCharacterBasedMethod("DeleteSavedInstance")
end

function addon:OnEnable()
	addon:RegisterEvent("PLAYER_ALIVE", OnPlayerAlive)
	
	-- Dungeon IDs
	addon:RegisterEvent("UPDATE_INSTANCE_INFO", OnUpdateInstanceInfo)
	addon:RegisterEvent("RAID_INSTANCE_WELCOME", OnRaidInstanceWelcome)
	addon:RegisterEvent("BOSS_KILL", OnBossKill)
	addon:RegisterEvent("CHAT_MSG_SYSTEM", OnChatMsgSystem)
end

function addon:OnDisable()
	addon:UnregisterEvent("PLAYER_ALIVE")
	addon:UnregisterEvent("UPDATE_INSTANCE_INFO")
	addon:UnregisterEvent("RAID_INSTANCE_WELCOME")
	addon:UnregisterEvent("BOSS_KILL")
	addon:UnregisterEvent("CHAT_MSG_SYSTEM")
end
