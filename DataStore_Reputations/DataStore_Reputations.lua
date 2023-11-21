--[[	*** DataStore_Reputations ***
Written by : Thaoky, EU-Marécages de Zangar
June 22st, 2009
--]]
if not DataStore then return end

local addonName = "DataStore_Reputations"

_G[addonName] = LibStub("AceAddon-3.0"):NewAddon(addonName, "AceConsole-3.0", "AceEvent-3.0")

local addon = _G[addonName]

local PARAGON_LABEL = "Paragon"

local AddonDB_Defaults = {
	global = {
		Reference = {
			UIDsRev = {},		-- ex: Reverse lookup of Faction UIDs, now in the database since opposite faction is no longer provided by the API
		},
		Characters = {
			['*'] = {				-- ["Account.Realm.Name"] 
				lastUpdate = nil,
				guildName = nil,		-- nil = not in a guild, as returned by GetGuildInfo("player")
				guildRep = nil,
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
	[43000] = PARAGON_LABEL,	 -- "Paragon"
}

local BottomLevels = { -42000, -6000, -3000, 0, 3000, 9000, 21000, 42000, 43000 }

local BF = LibStub("LibBabble-Faction-3.0"):GetUnstrictLookupTable()

--[[	*** Faction UIDs ***
These UIDs have 2 purposes: 
- avoid saving numerous copies of the same string (the faction name)
- minimize the amount of data sent across the network when sharing accounts (since both sides have the same reference table)

Note: Let the system manage the ids, DO NOT delete entries from this table, if a faction is removed from the game, mark it as OLD_ or whatever.

Since WoD, GetFactionInfoByID does not return a value when an alliance player asks for an horde faction.
Default to an english text.

Note 2 : now that this DataStore module works will all versions, be sure to preserve the insertion order !!

At the next expansion, reorder this whole thing and request a database reset.
--]]


local factions = {}

table.insert(factions, { id = 69, name = BF["Darnassus"] })

if WOW_PROJECT_ID ~= WOW_PROJECT_CLASSIC then
	table.insert(factions, { id = 930, name = BF["Exodar"] })
end

if WOW_PROJECT_ID == WOW_PROJECT_WRATH_CLASSIC then
	table.insert(factions, { id = 54, name = BF["Gnomeregan Exiles"] })
else
	table.insert(factions, { id = 54, name = BF["Gnomeregan"] })
end

table.insert(factions, { id = 47, name = BF["Ironforge"] })
table.insert(factions, { id = 72, name = BF["Stormwind"] })
table.insert(factions, { id = 530, name = BF["Darkspear Trolls"] })
table.insert(factions, { id = 76, name = BF["Orgrimmar"] })
table.insert(factions, { id = 81, name = BF["Thunder Bluff"] })
table.insert(factions, { id = 68, name = BF["Undercity"] })

if WOW_PROJECT_ID ~= WOW_PROJECT_CLASSIC then
	table.insert(factions, { id = 911, name = BF["Silvermoon City"] })
end
	
table.insert(factions, { id = 509, name = BF["The League of Arathor"] })
table.insert(factions, { id = 890, name = BF["Silverwing Sentinels"] })
table.insert(factions, { id = 730, name = BF["Stormpike Guard"] })
table.insert(factions, { id = 510, name = BF["The Defilers"] })
table.insert(factions, { id = 889, name = BF["Warsong Outriders"] })
table.insert(factions, { id = 729, name = BF["Frostwolf Clan"] })
table.insert(factions, { id = 21, name = BF["Booty Bay"] })
table.insert(factions, { id = 577, name = BF["Everlook"] })
table.insert(factions, { id = 369, name = BF["Gadgetzan"] })
table.insert(factions, { id = 470, name = BF["Ratchet"] })
table.insert(factions, { id = 529, name = BF["Argent Dawn"] })
table.insert(factions, { id = 87, name = BF["Bloodsail Buccaneers"] })
table.insert(factions, { id = 910, name = BF["Brood of Nozdormu"] })
table.insert(factions, { id = 609, name = BF["Cenarion Circle"] })
table.insert(factions, { id = 909, name = BF["Darkmoon Faire"] })
table.insert(factions, { id = 92, name = BF["Gelkis Clan Centaur"] })
table.insert(factions, { id = 749, name = BF["Hydraxian Waterlords"] })
table.insert(factions, { id = 93, name = BF["Magram Clan Centaur"] })
table.insert(factions, { id = 349, name = BF["Ravenholdt"] })
table.insert(factions, { id = 809, name = BF["Shen'dralar"] })
table.insert(factions, { id = 70, name = BF["Syndicate"] })
table.insert(factions, { id = 59, name = BF["Thorium Brotherhood"] })
table.insert(factions, { id = 576, name = BF["Timbermaw Hold"] })

if WOW_PROJECT_ID ~= WOW_PROJECT_MAINLINE then
	table.insert(factions, { id = 471, name = BF["Wildhammer Clan"] })
end

if WOW_PROJECT_ID ~= WOW_PROJECT_CLASSIC then
	table.insert(factions, { id = 922, name = BF["Tranquillien"] })
end

table.insert(factions, { id = 589, name = BF["Wintersaber Trainers"] })
table.insert(factions, { id = 270, name = BF["Zandalar Tribe"] })

if WOW_PROJECT_ID ~= WOW_PROJECT_CLASSIC then
	-- LK & later

	-- The Burning Crusade
	table.insert(factions, { id = 1012, name = BF["Ashtongue Deathsworn"] })
	table.insert(factions, { id = 942, name = BF["Cenarion Expedition"] })
	table.insert(factions, { id = 933, name = BF["The Consortium"] })
	table.insert(factions, { id = 946, name = BF["Honor Hold"] })
	table.insert(factions, { id = 978, name = BF["Kurenai"] })
	table.insert(factions, { id = 941, name = BF["The Mag'har"] })
	table.insert(factions, { id = 1015, name = BF["Netherwing"] })
	table.insert(factions, { id = 1038, name = BF["Ogri'la"] })
	table.insert(factions, { id = 970, name = BF["Sporeggar"] })
	table.insert(factions, { id = 947, name = BF["Thrallmar"] })
	table.insert(factions, { id = 1011, name = BF["Lower City"] })
	table.insert(factions, { id = 1031, name = BF["Sha'tari Skyguard"] })
	table.insert(factions, { id = 1077, name = BF["Shattered Sun Offensive"] })
	table.insert(factions, { id = 932, name = BF["The Aldor"] })
	table.insert(factions, { id = 934, name = BF["The Scryers"] })
	table.insert(factions, { id = 935, name = BF["The Sha'tar"] })
	table.insert(factions, { id = 989, name = BF["Keepers of Time"] })
	table.insert(factions, { id = 990, name = BF["The Scale of the Sands"] })
	table.insert(factions, { id = 967, name = BF["The Violet Eye"] })

	-- Wrath of the Lich King
	table.insert(factions, { id = 1106, name = BF["Argent Crusade"] })
	table.insert(factions, { id = 1090, name = BF["Kirin Tor"] })
	table.insert(factions, { id = 1073, name = BF["The Kalu'ak"] })
	table.insert(factions, { id = 1091, name = BF["The Wyrmrest Accord"] })
	table.insert(factions, { id = 1098, name = BF["Knights of the Ebon Blade"] })
	table.insert(factions, { id = 1119, name = BF["The Sons of Hodir"] })
	table.insert(factions, { id = 1156, name = BF["The Ashen Verdict"] })
	table.insert(factions, { id = 1037, name = BF["Alliance Vanguard"] })
	table.insert(factions, { id = 1068, name = BF["Explorers' League"] })
	table.insert(factions, { id = 1126, name = BF["The Frostborn"] })
	table.insert(factions, { id = 1094, name = BF["The Silver Covenant"] })
	table.insert(factions, { id = 1050, name = BF["Valiance Expedition"] })
	table.insert(factions, { id = 1052, name = BF["Horde Expedition"] })
	table.insert(factions, { id = 1067, name = BF["The Hand of Vengeance"] })
	table.insert(factions, { id = 1124, name = BF["The Sunreavers"] })
	table.insert(factions, { id = 1064, name = BF["The Taunka"] })
	table.insert(factions, { id = 1085, name = BF["Warsong Offensive"] })
	table.insert(factions, { id = 1104, name = BF["Frenzyheart Tribe"] })
	table.insert(factions, { id = 1105, name = BF["The Oracles"] })
	table.insert(factions, { id = 469, name = BF["Alliance"] })
	table.insert(factions, { id = 67, name = BF["Horde"] })
	table.insert(factions, { id = 1134, name = BF["Gilneas"] })
	table.insert(factions, { id = 1133, name = BF["Bilgewater Cartel"] })
end

if WOW_PROJECT_ID == WOW_PROJECT_MAINLINE then

	-- cataclysm
	table.insert(factions, { id = 1158, name = BF["Guardians of Hyjal"] })
	table.insert(factions, { id = 1135, name = BF["The Earthen Ring"] })
	table.insert(factions, { id = 1171, name = BF["Therazane"] })
	table.insert(factions, { id = 1174, name = BF["Wildhammer Clan"] })
	table.insert(factions, { id = 1173, name = BF["Ramkahen"] })
	table.insert(factions, { id = 1177, name = BF["Baradin's Wardens"] })
	table.insert(factions, { id = 1172, name = BF["Dragonmaw Clan"] })
	table.insert(factions, { id = 1178, name = BF["Hellscream's Reach"] })
	table.insert(factions, { id = 1204, name = BF["Avengers of Hyjal"] })

	-- Mists of Pandaria
	table.insert(factions, { id = 1277, name = BF["Chee Chee"] })
	table.insert(factions, { id = 1275, name = BF["Ella"] })
	table.insert(factions, { id = 1283, name = BF["Farmer Fung"] })
	table.insert(factions, { id = 1282, name = BF["Fish Fellreed"] })
	table.insert(factions, { id = 1228, name = BF["Forest Hozen"] })
	table.insert(factions, { id = 1281, name = BF["Gina Mudclaw"] })
	table.insert(factions, { id = 1269, name = BF["Golden Lotus"] })
	table.insert(factions, { id = 1279, name = BF["Haohan Mudclaw"] })
	table.insert(factions, { id = 1273, name = BF["Jogu the Drunk"] })
	table.insert(factions, { id = 1358, name = BF["Nat Pagle"] })
	table.insert(factions, { id = 1276, name = BF["Old Hillpaw"] })
	table.insert(factions, { id = 1271, name = BF["Order of the Cloud Serpent"] })
	table.insert(factions, { id = 1242, name = BF["Pearlfin Jinyu"] })
	table.insert(factions, { id = 1270, name = BF["Shado-Pan"] })
	table.insert(factions, { id = 1216, name = BF["Shang Xi's Academy"] })
	table.insert(factions, { id = 1278, name = BF["Sho"] })
	table.insert(factions, { id = 1302, name = BF["The Anglers"] })
	table.insert(factions, { id = 1341, name = BF["The August Celestials"] })
	table.insert(factions, { id = 1359, name = BF["The Black Prince"] })
	table.insert(factions, { id = 1351, name = BF["The Brewmasters"] })
	table.insert(factions, { id = 1337, name = BF["The Klaxxi"] })
	table.insert(factions, { id = 1345, name = BF["The Lorewalkers"] })
	table.insert(factions, { id = 1272, name = BF["The Tillers"] })
	table.insert(factions, { id = 1280, name = BF["Tina Mudclaw"] })
	table.insert(factions, { id = 1353, name = BF["Tushui Pandaren"] })
	table.insert(factions, { id = 1352, name = BF["Huojin Pandaren"] })

	table.insert(factions, { id = 1376, name = BF["Operation: Shieldwall"] })
	table.insert(factions, { id = 1387, name = BF["Kirin Tor Offensive"] })
	table.insert(factions, {}) -- was "Akama's Trust", keep this index empty
	table.insert(factions, { id = 1375, name = BF["Dominance Offensive"] })
	table.insert(factions, { id = 1388, name = BF["Sunreaver Onslaught"] })
	table.insert(factions, { id = 1435, name = BF["Shado-Pan Assault"] })
	table.insert(factions, { id = 1440, name = BF["Darkspear Rebellion"] })
	table.insert(factions, { id = 1492, name = GetFactionInfoByID(1492) })		-- BF["Emperor Shaohao"]

	-- Warlords of Draenor
	table.insert(factions, { id = 1515, name = GetFactionInfoByID(1515) })		-- Arrakoa Outcasts
	table.insert(factions, { id = 1731, name = GetFactionInfoByID(1731) })		-- Council of Exarchs
	table.insert(factions, { id = 1445, name = GetFactionInfoByID(1445) })		-- Frostwold Orcs
	table.insert(factions, { id = 1710, name = GetFactionInfoByID(1710) })		-- Sha'tari Defense
	table.insert(factions, { id = 1711, name = GetFactionInfoByID(1711) })		-- Steamwheedle Preservation Society
	table.insert(factions, { id = 1682, name = GetFactionInfoByID(1682) })		-- Wrynn's Vanguard
	table.insert(factions, { id = 1708, name = GetFactionInfoByID(1708) })		-- Laughing Skull Orcs
	table.insert(factions, { id = 1681, name = GetFactionInfoByID(1681) })		-- Vol'jin's Spear
	table.insert(factions, { id = 1847, name = GetFactionInfoByID(1847) })		-- Hand of the Prophet
	table.insert(factions, { id = 1848, name = GetFactionInfoByID(1848) })		-- Vol'jin's Headhunters
	table.insert(factions, { id = 1849, name = GetFactionInfoByID(1849) })		-- Order of the Awakened
	table.insert(factions, { id = 1850, name = GetFactionInfoByID(1850) })		-- The Saberstalkers

	-- Legion
	table.insert(factions, { id = 1900, name = GetFactionInfoByID(1900) })		-- Court of Farondis
	table.insert(factions, { id = 1883, name = GetFactionInfoByID(1883) })		-- Dreamweavers
	table.insert(factions, { id = 1828, name = GetFactionInfoByID(1828) })		-- Highmountain Tribe
	table.insert(factions, { id = 1948, name = GetFactionInfoByID(1948) })		-- Valarjar
	table.insert(factions, { id = 1859, name = GetFactionInfoByID(1859) })		-- The Nightfallen
	table.insert(factions, { id = 1894, name = GetFactionInfoByID(1894) })		-- The Wardens
	table.insert(factions, { id = 2045, name = GetFactionInfoByID(2045) })		-- Armies of Legionfall
	table.insert(factions, { id = 2165, name = GetFactionInfoByID(2165) })		-- Army of the Light
	table.insert(factions, { id = 2170, name = GetFactionInfoByID(2170) })		-- Argussian Reach
	table.insert(factions, { id = 1975, name = GetFactionInfoByID(1975) }) 	-- Conjurer Margoss
	table.insert(factions, { id = 2097, name = GetFactionInfoByID(2097) }) 	-- Ilyssia of the Waters
	table.insert(factions, { id = 2099, name = GetFactionInfoByID(2099) }) 	-- Akule Riverhorn
	table.insert(factions, { id = 2101, name = GetFactionInfoByID(2101) }) 	-- Sha'leth
	table.insert(factions, { id = 2100, name = GetFactionInfoByID(2100) }) 	-- Corbyn
	table.insert(factions, { id = 2102, name = GetFactionInfoByID(2102) }) 	-- Impus
	table.insert(factions, { id = 2098, name = GetFactionInfoByID(2098) }) 	-- Keeper Raynae
	table.insert(factions, { id = 2135, name = GetFactionInfoByID(2135) }) 	-- Chromie

	-- Battle for Azeroth
	table.insert(factions, { id = 2159, name = GetFactionInfoByID(2159) })		-- A  - 7th Legion
	table.insert(factions, { id = 2164, name = GetFactionInfoByID(2164) })		-- AH - Champions of Azeroth
	table.insert(factions, { id = 2161, name = GetFactionInfoByID(2161) })		-- A  - Order of Embers	(alternate ID: 2264 but this seems unused on wowhead)
	table.insert(factions, { id = 2160, name = GetFactionInfoByID(2160) })		-- A  - Proudmoore Admiralty (alternate ID: 2120 but this seems unused on wowhead)
	table.insert(factions, { id = 2162, name = GetFactionInfoByID(2162) })		-- A  - Storm's Wake (alternate ID: 2265 but this seems unused on wowhead)
	table.insert(factions, { id = 2156, name = GetFactionInfoByID(2156) })		-- H  - Talanji's Expedition
	table.insert(factions, { id = 2157, name = GetFactionInfoByID(2157) })		-- H  - The Honorbound
	table.insert(factions, { id = 2163, name = GetFactionInfoByID(2163) })		-- AH - Tortollan Seekers
	table.insert(factions, { id = 2158, name = GetFactionInfoByID(2158) })		-- H  - Voldunai
	table.insert(factions, { id = 2103, name = GetFactionInfoByID(2103) })		-- H  - Zandalari Empire
	table.insert(factions, { id = 2400, name = BF["Waveblade Ankoan"] })		-- A  - Waveblade Ankoan
	table.insert(factions, { id = 2373, name = BF["The Unshackled"] })			-- H  - The Unshackled
	table.insert(factions, { id = 2391, name = GetFactionInfoByID(2391) })		-- Rustbolt Resistance
	table.insert(factions, { id = 2415, name = GetFactionInfoByID(2415) })		-- 8.3 Rajani
	table.insert(factions, { id = 2417, name = GetFactionInfoByID(2417) })		-- 8.3 Uldum Accord

	-- Shadowlands (Source : https://www.wowhead.com/factions/shadowlands)
	table.insert(factions, { id = 2407, name = GetFactionInfoByID(2407) or BF["The Ascended"] })			-- Zone: Bastion
	table.insert(factions, { id = 2410, name = GetFactionInfoByID(2410) or BF["The Undying Army"]}) 		-- Zone : Maldraxxus
	table.insert(factions, { id = 2465, name = GetFactionInfoByID(2465) or BF["The Wild Hunt"]})			-- Zone : Ardenweald
	table.insert(factions, { id = 2413, name = GetFactionInfoByID(2413) or BF["Court of Harvesters"] })	-- Zone : Revendreth
	table.insert(factions, { id = 2432, name = GetFactionInfoByID(2432) })     -- Ve'nari (The Maw)
	table.insert(factions, { id = 2439, name = GetFactionInfoByID(2439) })     -- The Avowed (Halls of Attonement)
	table.insert(factions, { id = 2464, name = GetFactionInfoByID(2464) })     -- Court of Night (Ardenweald)
	table.insert(factions, { id = 2463, name = GetFactionInfoByID(2463) })     -- Marasimus (Ardenweald)
	
	table.insert(factions, { id = 2470, name = GetFactionInfoByID(2470) })     -- 9.1 Death's Advance
	table.insert(factions, { id = 2472, name = GetFactionInfoByID(2472) })     -- 9.1 Archivist's Codex
	table.insert(factions, { id = 2478, name = GetFactionInfoByID(2478) })     -- 9.2 The Enlightened
	
	-- Dragonflight
	table.insert(factions, { id = 2507, name = GetFactionInfoByID(2507) })     -- Dragonscale Expedition
	table.insert(factions, { id = 2503, name = GetFactionInfoByID(2503) })     -- Maruuk Centaur
	table.insert(factions, { id = 2511, name = GetFactionInfoByID(2511) })     -- Iskaara Tuskarr
	table.insert(factions, { id = 2510, name = GetFactionInfoByID(2510) })     -- Valdrakken Accord
	
	table.insert(factions, { id = 2526, name = GetFactionInfoByID(2526) })     -- Winterpelt Furbolg
	table.insert(factions, { id = 2544, name = GetFactionInfoByID(2544) })     -- Artisan's Consortium - Dragon Isles Branch
	table.insert(factions, { id = 2550, name = GetFactionInfoByID(2550) })     -- Cobalt Assembly
	table.insert(factions, { id = 2517, name = GetFactionInfoByID(2517) })     -- Wrathion
	table.insert(factions, { id = 2518, name = GetFactionInfoByID(2518) })     -- Sabellian
	table.insert(factions, { id = 2553, name = GetFactionInfoByID(2553) })     -- Soridormi
	table.insert(factions, { id = 2564, name = GetFactionInfoByID(2564) })     -- Loamm Niffen
	table.insert(factions, { id = 2568, name = GetFactionInfoByID(2568) })     -- Glimmerogg Racer
	table.insert(factions, { id = 2574, name = GetFactionInfoByID(2574) })     -- Dream Wardens	
end


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
	-- Return guild reputation
	if character.guildName and faction == character.guildName then
		return character.guildRep
	end
	
	local internalIndex = FactionUIDsRev[faction]
	local factionID = factions[internalIndex] and factions[internalIndex].id
	
	-- also return the game's faction ID, the caller may need it
	return character.Factions[internalIndex], factionID
end

-- *** Scanning functions ***
local currentGuildName

local function ScanReputations()
	SaveHeaders()
	local f = addon.ThisCharacter.Factions
	wipe(f)
	
	if WOW_PROJECT_ID == WOW_PROJECT_MAINLINE then
		-- Retail scan
		for i = 1, GetNumFactions() do		-- 2nd pass, data collection
			local name, _, _, _, _, earned, _, _, _, _, _, _, _, factionID = GetFactionInfo(i)
			
			if FactionUIDsRev[name] then		-- is this a faction we're tracking ?
				local repInfo = factionID and C_GossipInfo.GetFriendshipReputation(factionID)

				-- From WoW's ReputationFrame.lua, give priority to friendship factions
				if (repInfo and repInfo.friendshipFactionID > 0) then
					
					local ranks = C_GossipInfo.GetFriendshipReputationRanks(factionID)

					-- Ex: Cobalt assembly, ID 2550, standing 205 / next threshold 300 => rank 1 / 5 (5 is not saved, maxLevel is identical for all)
					f[FactionUIDsRev[name]] = format("%d,%d,%d", ranks.currentLevel, repInfo.standing, repInfo.nextThreshold)
				
				-- new in 3.0.2, headers may have rep, ex: alliance vanguard + horde expedition
				-- 2021/08/20 do not test for positivity, earned rep may be negative !
				elseif earned then
					-- check paragon factions
					if (C_Reputation.IsFactionParagon(factionID)) then
						local currentValue, threshold, _, hasRewardPending = C_Reputation.GetFactionParagonInfo(factionID)
						while (currentValue >= 10000) do
							currentValue = currentValue - 10000
						end
					
						if hasRewardPending then
							currentValue = currentValue + 10000
						end
						f[FactionUIDsRev[name]] = 43000 + currentValue
					else
						f[FactionUIDsRev[name]] = earned
					end

					-- Special treatment for new major factions in 10.0
					if C_Reputation.IsMajorFaction(factionID) then
						local data = C_MajorFactions.GetMajorFactionData(factionID)
						
						f[FactionUIDsRev[name]] = format("%d,%d,%d", data.renownLevel, data.renownReputationEarned, data.renownLevelThreshold)
					end
				end
			end
		end

	else
		-- Non-retail scan
		for i = 1, GetNumFactions() do		-- 2nd pass, data collection
			local name, _, _, _, _, earned, _, _, _, _, _, _, _, factionID = GetFactionInfo(i)
			if earned then --(earned and earned > 0) then		-- new in 3.0.2, headers may have rep, ex: alliance vanguard + horde expedition
				if FactionUIDsRev[name] then		-- is this a faction we're tracking ?
					f[FactionUIDsRev[name]] = earned
				end
			end
		end	
	end

	RestoreHeaders()
	addon.ThisCharacter.lastUpdate = time()
end

local function ScanGuildReputation()
	SaveHeaders()
	for i = 1, GetNumFactions() do		-- 2nd pass, data collection
		local name, _, _, _, _, earned = GetFactionInfo(i)
		if name and name == currentGuildName then
			addon.ThisCharacter.guildRep = earned
		end
	end
	RestoreHeaders()
end

-- *** Event Handlers ***
local function OnPlayerAlive()
	ScanReputations()
end

local function OnPlayerGuildUpdate()
	-- at login this event is called between OnEnable and PLAYER_ALIVE, where GetGuildInfo returns a wrong value
	-- however, the value returned here is correct
	if IsInGuild() and not currentGuildName then		-- the event may be triggered multiple times, and GetGuildInfo may return incoherent values in subsequent calls, so only save if we have no value.
		currentGuildName = GetGuildInfo("player")
		if currentGuildName then	
			addon.ThisCharacter.guildName = currentGuildName
			ScanGuildReputation()
		end
	end
end

local function OnFactionChange(event, messageType, faction, amount)
	if messageType ~= "FACTION" then return end
	
	if faction == GUILD then
		ScanGuildReputation()
		return
	end
	
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
local function _GetReputationInfo_NonRetail(character, faction)
	local earned = GetEarnedRep(character, faction)
	if not earned then return end

	local currentLevel, repEarned, nextLevel, rate
	local bottom, top = GetLimits(earned)

	-- ex: "Revered", 15400, 21000, 73%
	currentLevel = BottomLevelNames[bottom]
	repEarned = earned - bottom
	nextLevel = top - bottom
	rate = repEarned / nextLevel * 100

	return currentLevel, repEarned, nextLevel, rate
end

local function _GetReputationInfo_Retail(character, faction)
	local earned, factionID = GetEarnedRep(character, faction)
	if not earned then return end

	local currentLevel, repEarned, nextLevel, rate
	
	-- earned reputation will be saved as a number for old/normal reputations.
	if type(earned) == "number" then
		local bottom, top = GetLimits(earned)
	
		-- ex: "Revered", 15400, 21000, 73%
		currentLevel = BottomLevelNames[bottom]
		repEarned = earned - bottom
		nextLevel = top - bottom
	
	-- For the new major factions introduced in Dragonflight, different processing is required
	elseif type(earned) == "string" then
		-- ex: "9,1252,2500" = level 9, 1252/2500
		-- => 9, 1252, 2500, 50%
		currentLevel, repEarned, nextLevel = strsplit(",", earned)
	end
	
	if nextLevel == "0" then
		rate = 100
	else
		rate = repEarned / nextLevel * 100
	end
	
	-- is it a major faction ? (4 Dragonflight renown)
	local isMajorFaction = factionID and C_Reputation.IsMajorFaction(factionID)
	
	-- is it a friendship faction ? 
	local repInfo = factionID and C_GossipInfo.GetFriendshipReputation(factionID)	
	local isFrienshipFaction = (repInfo and repInfo.friendshipFactionID > 0) 
	
	return currentLevel, repEarned, nextLevel, rate, isMajorFaction, isFrienshipFaction, factionID
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

local function _GetGuildReputation(character)
	return character.guildRep or 0
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
	GetRawReputationInfo = _GetRawReputationInfo,
	GetReputations = _GetReputations,
	GetReputationLevels = _GetReputationLevels,
	GetReputationLevelText = _GetReputationLevelText,
	GetFactionName = _GetFactionName,
}

if WOW_PROJECT_ID == WOW_PROJECT_MAINLINE then
	PublicMethods.GetGuildReputation = _GetGuildReputation
	PublicMethods.GetReputationInfo = _GetReputationInfo_Retail
else
	PublicMethods.GetReputationInfo = _GetReputationInfo_NonRetail
end

function addon:OnInitialize()
	addon.db = LibStub("AceDB-3.0"):New(addonName .. "DB", AddonDB_Defaults)

	DataStore:RegisterModule(addonName, addon, PublicMethods)
	DataStore:SetCharacterBasedMethod("GetReputationInfo")
	DataStore:SetCharacterBasedMethod("GetRawReputationInfo")
	DataStore:SetCharacterBasedMethod("GetReputations")
	
	if WOW_PROJECT_ID == WOW_PROJECT_MAINLINE then
		DataStore:SetCharacterBasedMethod("GetGuildReputation")
	end
end

function addon:OnEnable()
	addon:RegisterEvent("PLAYER_ALIVE", OnPlayerAlive)
	addon:RegisterEvent("COMBAT_TEXT_UPDATE", OnFactionChange)
	
	if WOW_PROJECT_ID == WOW_PROJECT_MAINLINE then
		addon:RegisterEvent("PLAYER_GUILD_UPDATE", OnPlayerGuildUpdate)				-- for gkick, gquit, etc..
	end
end

function addon:OnDisable()
	addon:UnregisterEvent("PLAYER_ALIVE")
	addon:UnregisterEvent("COMBAT_TEXT_UPDATE")
	
	if WOW_PROJECT_ID == WOW_PROJECT_MAINLINE then
		addon:UnregisterEvent("PLAYER_GUILD_UPDATE")
	end
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
