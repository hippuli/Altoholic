--[[	*** DataStore_Reputations ***
Written by : Thaoky, EU-Marécages de Zangar
June 22st, 2009
--]]
if not DataStore then return end

local addonName = "DataStore_Reputations"

_G[addonName] = LibStub("AceAddon-3.0"):NewAddon(addonName, "AceConsole-3.0", "AceEvent-3.0")

local addon = _G[addonName]

local THIS_ACCOUNT = "Default"

local AddonDB_Defaults = {
	global = {
		Reference = {
			UIDsRev = {},		-- ex: Reverse lookup of Faction UIDs, now in the database since opposite faction is no longer provided by the API
		},
		Characters = {
			['*'] = {				-- ["Account.Realm.Name"] 
				lastUpdate = nil,
				Factions = {},
			}
		}
	}
}

-- ** Reference tables **
local BottomLevelNames = {
	[-42000] = FACTION_STANDING_LABEL1,	 -- "Hated"
	[-6000] = FACTION_STANDING_LABEL2,	 -- "Hostile"
	[-3000] = FACTION_STANDING_LABEL3,	 -- "Unfriendly"
	[0] = FACTION_STANDING_LABEL4,		 -- "Neutral"
	[3000] = FACTION_STANDING_LABEL5,	 -- "Friendly"
	[9000] = FACTION_STANDING_LABEL6,	 -- "Honored"
	[21000] = FACTION_STANDING_LABEL7,	 -- "Revered"
	[42000] = FACTION_STANDING_LABEL8,	 -- "Exalted"
}

local BottomLevels = { -42000, -6000, -3000, 0, 3000, 9000, 21000, 42000 }

local BF = LibStub("LibBabble-Faction-3.0"):GetUnstrictLookupTable()

--[[	*** Faction UIDs ***
These UIDs have 2 purposes: 
- avoid saving numerous copies of the same string (the faction name)
- minimize the amount of data sent across the network when sharing accounts (since both sides have the same reference table)

Note: Let the system manage the ids, DO NOT delete entries from this table, if a faction is removed from the game, mark it as OLD_ or whatever.

Since WoD, GetFactionInfoByID does not return a value when an alliance player asks for an horde faction.
Default to an english text.
--]]



local factions = {
	{ id = 69, name = BF["Darnassus"] },
	-- { id = 930, name = BF["Exodar"] },
	{ id = 54, name = BF["Gnomeregan"] },
	{ id = 47, name = BF["Ironforge"] },
	{ id = 72, name = BF["Stormwind"] },
	{ id = 530, name = BF["Darkspear Trolls"] },
	{ id = 76, name = BF["Orgrimmar"] },
	{ id = 81, name = BF["Thunder Bluff"] },
	{ id = 68, name = BF["Undercity"] },
	-- { id = 911, name = BF["Silvermoon City"] },
	{ id = 509, name = BF["The League of Arathor"] },
	{ id = 890, name = BF["Silverwing Sentinels"] },
	{ id = 730, name = BF["Stormpike Guard"] },
	{ id = 510, name = BF["The Defilers"] },
	{ id = 889, name = BF["Warsong Outriders"] },
	{ id = 729, name = BF["Frostwolf Clan"] },
	{ id = 21, name = BF["Booty Bay"] },
	{ id = 577, name = BF["Everlook"] },
	{ id = 369, name = BF["Gadgetzan"] },
	{ id = 470, name = BF["Ratchet"] },
	{ id = 529, name = BF["Argent Dawn"] },
	{ id = 87, name = BF["Bloodsail Buccaneers"] },
	{ id = 910, name = BF["Brood of Nozdormu"] },
	{ id = 609, name = BF["Cenarion Circle"] },
	{ id = 909, name = BF["Darkmoon Faire"] },
	{ id = 92, name = BF["Gelkis Clan Centaur"] },
	{ id = 749, name = BF["Hydraxian Waterlords"] },
	{ id = 93, name = BF["Magram Clan Centaur"] },
	{ id = 349, name = BF["Ravenholdt"] },
	{ id = 809, name = BF["Shen'dralar"] },
	{ id = 70, name = BF["Syndicate"] },
	{ id = 59, name = BF["Thorium Brotherhood"] },
	{ id = 576, name = BF["Timbermaw Hold"] },
	{ id = 471, name = BF["Wildhammer Clan"] },
	-- { id = 922, name = BF["Tranquillien"] },
	{ id = 589, name = BF["Wintersaber Trainers"] },
	{ id = 270, name = BF["Zandalar Tribe"] },
	
	-- The Burning Crusade
	{ id = 1012, name = BF["Ashtongue Deathsworn"] },
	{ id = 942, name = BF["Cenarion Expedition"] },
	{ id = 933, name = BF["The Consortium"] },
	{ id = 946, name = BF["Honor Hold"] },
	{ id = 978, name = BF["Kurenai"] },
	{ id = 941, name = BF["The Mag'har"] },
	{ id = 1015, name = BF["Netherwing"] },
	{ id = 1038, name = BF["Ogri'la"] },
	{ id = 970, name = BF["Sporeggar"] },
	{ id = 947, name = BF["Thrallmar"] },
	{ id = 1011, name = BF["Lower City"] },
	{ id = 1031, name = BF["Sha'tari Skyguard"] },
	{ id = 1077, name = BF["Shattered Sun Offensive"] },
	{ id = 932, name = BF["The Aldor"] },
	{ id = 934, name = BF["The Scryers"] },
	{ id = 935, name = BF["The Sha'tar"] },
	{ id = 989, name = BF["Keepers of Time"] },
	{ id = 990, name = BF["The Scale of the Sands"] },
	{ id = 967, name = BF["The Violet Eye"] },
}

local FactionUIDsRev = {}
local FactionIdToName = {}

for k, v in pairs(factions) do
	if v.id and v.name then
		FactionIdToName[v.id] = v.name
		FactionUIDsRev[v.name] = k	-- ex : [BZ["Darnassus"]] = 1
	end
end

-- *** Utility functions ***

local headersState = {}
local inactive = {}

local function SaveHeaders()
	local headerCount = 0		-- use a counter to avoid being bound to header names, which might not be unique.
	
	for i = GetNumFactions(), 1, -1 do		-- 1st pass, expand all categories
		local name, _, _, _, _, _, _,	_, isHeader, isCollapsed = GetFactionInfo(i)
		if isHeader then
			headerCount = headerCount + 1
			if isCollapsed then
				ExpandFactionHeader(i)
				headersState[headerCount] = true
			end
		end
	end
	
	-- code disabled until I can find the other addon that conflicts with this and slows down the machine.
	
	-- If a header faction, like alliance or horde, has all child factions set to inactive, it will not be visible, so activate it, and deactivate it after the scan (thanks Zaphon for this)
	-- for i = GetNumFactions(), 1, -1 do
		-- if IsFactionInactive(i) then
			-- local name = GetFactionInfo(i)
			-- inactive[name] = true
			-- SetFactionActive(i)
		-- end
	-- end
end

local function RestoreHeaders()
	local headerCount = 0
	for i = GetNumFactions(), 1, -1 do
		local name, _, _, _, _, _, _,	_, isHeader = GetFactionInfo(i)
		
		-- if inactive[name] then
			-- SetFactionInactive(i)
		-- end
		
		if isHeader then
			headerCount = headerCount + 1
			if headersState[headerCount] then
				CollapseFactionHeader(i)
			end
		end
	end
	wipe(headersState)
end

local function GetLimits(earned)
	-- return the bottom & top values of a given rep level based on the amount of earned rep
	local top = 53000
	local index = #BottomLevels
	
	while (earned < BottomLevels[index]) do
		top = BottomLevels[index]
		index = index - 1
	end
	
	return BottomLevels[index], top
end

local function GetEarnedRep(character, faction)
	return character.Factions[FactionUIDsRev[faction]]
end

-- *** Scanning functions ***
local function ScanReputations()
	SaveHeaders()
	local f = addon.ThisCharacter.Factions
	wipe(f)
	
	for i = 1, GetNumFactions() do		-- 2nd pass, data collection
		local name, _, _, _, _, earned, _, _, _, _, _, _, _, factionID = GetFactionInfo(i)
		if (earned and earned > 0) then		-- new in 3.0.2, headers may have rep, ex: alliance vanguard + horde expedition
			if FactionUIDsRev[name] then		-- is this a faction we're tracking ?
				f[FactionUIDsRev[name]] = earned
			end
		end
	end

	RestoreHeaders()
	addon.ThisCharacter.lastUpdate = time()
end

-- *** Event Handlers ***
local function OnPlayerAlive()
	ScanReputations()
end

local function OnFactionChange(event, messageType, faction, amount)
	if messageType ~= "FACTION" then return end
	
	local bottom, top, earned = DataStore:GetRawReputationInfo(DataStore:GetCharacter(), faction)
	if not earned then 	-- faction not in the db, scan all
		ScanReputations()	
		return 
	end
	
	local newValue = earned + amount
	if newValue >= top then	-- rep status increases (to revered, etc..)
		ScanReputations()					-- so scan all
	else
		addon.ThisCharacter.Factions[FactionUIDsRev[faction]] = newValue
		addon.ThisCharacter.lastUpdate = time()
	end
end


-- ** Mixins **
local function _GetReputationInfo(character, faction)
	local earned = GetEarnedRep(character, faction)
	if not earned then return end

	local bottom, top = GetLimits(earned)
	local rate = (earned - bottom) / (top - bottom) * 100

	-- ex: "Revered", 15400, 21000, 73%
	return BottomLevelNames[bottom], (earned - bottom), (top - bottom), rate 
end

local function _GetRawReputationInfo(character, faction)
	-- same as GetReputationInfo, but returns raw values
	
	local earned = GetEarnedRep(character, faction)
	if not earned then return end

	local bottom, top = GetLimits(earned)
	return bottom, top, earned
end

local function _GetReputations(character)
	return character.Factions
end

local function _GetReputationLevels()
	return BottomLevels
end

local function _GetReputationLevelText(bottom)
	return BottomLevelNames[bottom]
end

local function _GetFactionName(id)
	return FactionIdToName[id]
end

local PublicMethods = {
	GetReputationInfo = _GetReputationInfo,
	GetRawReputationInfo = _GetRawReputationInfo,
	GetReputations = _GetReputations,
	GetReputationLevels = _GetReputationLevels,
	GetReputationLevelText = _GetReputationLevelText,
	GetFactionName = _GetFactionName,
}

function addon:OnInitialize()
	addon.db = LibStub("AceDB-3.0"):New(addonName .. "DB", AddonDB_Defaults)

	DataStore:RegisterModule(addonName, addon, PublicMethods)
	DataStore:SetCharacterBasedMethod("GetReputationInfo")
	DataStore:SetCharacterBasedMethod("GetRawReputationInfo")
	DataStore:SetCharacterBasedMethod("GetReputations")
end

function addon:OnEnable()
	addon:RegisterEvent("PLAYER_ALIVE", OnPlayerAlive)
	addon:RegisterEvent("COMBAT_TEXT_UPDATE", OnFactionChange)
end

function addon:OnDisable()
	addon:UnregisterEvent("PLAYER_ALIVE")
	addon:UnregisterEvent("COMBAT_TEXT_UPDATE")
end

-- *** Utility functions ***
local PT = LibStub("LibPeriodicTable-3.1")

function addon:GetSource(searchedID)
	-- returns the faction where a given item ID can be obtained, as well as the level
	local level, repData = PT:ItemInSet(searchedID, "Reputation.Reward")
	if level and repData then
		local _, _, faction = strsplit(".", repData)		-- ex: "Reputation.Reward.Sporeggar"
	
		-- level = 7,  29150:7 where 7 means revered
		return faction, _G["FACTION_STANDING_LABEL"..level]
	end
end
