--[[
Reputations-related enumerations
--]]
local enum = DataStore.Enum
local BF = LibStub("LibBabble-Faction-3.0"):GetUnstrictLookupTable()


-- Low threshold of each reputation level
enum.ReputationLevels = {
	-42000, -6000, -3000, 0, 3000, 9000, 21000, 42000, 43000
}

-- Name of the various reputation levels
enum.ReputationLevelNames = {
	[-42000] = FACTION_STANDING_LABEL1,		-- "Hated"
	[-6000] = FACTION_STANDING_LABEL2,		-- "Hostile"
	[-3000] = FACTION_STANDING_LABEL3,		-- "Unfriendly"
	[0] = FACTION_STANDING_LABEL4,			-- "Neutral"
	[3000] = FACTION_STANDING_LABEL5,		-- "Friendly"
	[9000] = FACTION_STANDING_LABEL6,		-- "Honored"
	[21000] = FACTION_STANDING_LABEL7,		-- "Revered"
	[42000] = FACTION_STANDING_LABEL8,		-- "Exalted"
	[43000] = "Paragon",							-- "Paragon"
}

-- CHECK : https://www.curseforge.com/wow/addons/libbabble-faction-3-0/files

-- L["Alliance Forces"],
-- L["Horde Forces"],
-- L["Steamwheedle Cartel"],
-- L["Fishing Masters"],


enum.FactionTree = {
	-- Loop on this level with Enum.ExpansionPacks
	EXPANSION_NAME0 = {			-- "Classic"
		{	-- [1]
			name = FACTION_ALLIANCE,
			{ id = 69, name = BF["Darnassus"], icon = "Achievement_Character_Nightelf_Female" },
			{ id = 930, name = BF["Exodar"], icon = "Achievement_Character_Draenei_Male" },
			{ id = 54, name = BF["Gnomeregan"], icon = "Achievement_Character_Gnome_Female" },
			{ id = 47, name = BF["Ironforge"], icon = "Achievement_Character_Dwarf_Male" },
			{ id = 72, name = BF["Stormwind"], icon = "Achievement_Character_Human_Male" },
			{ id = 1134, name = BF["Gilneas"], icon = "Interface\\Glues\\CharacterCreate\\UI-CHARACTERCREATE-RACES", left = 0.625, right = 0.75, top = 0, bottom = 0.25 },
			{ id = 1353, name = BF["Tushui Pandaren"], icon = "Interface\\Glues\\CharacterCreate\\UI-CHARACTERCREATE-RACES", left = 0.75, right = 0.875, top = 0, bottom = 0.25 },
			{ id = 469, name = BF["Alliance"], icon = "INV_BannerPVP_02" },
		},
		{	-- [2]
			name = FACTION_HORDE,
			{ id = 530, name = BF["Darkspear Trolls"], icon = "Achievement_Character_Troll_Male" },
			{ id = 76, name = BF["Orgrimmar"], icon = "Achievement_Character_Orc_Male" },
			{ id = 81, name = BF["Thunder Bluff"], icon = "Achievement_Character_Tauren_Male" },
			{ id = 68, name = BF["Undercity"], icon = "Achievement_Character_Undead_Female" },
			{ id = 911, name = BF["Silvermoon City"], icon = "Achievement_Character_Bloodelf_Male" },
			{ id = 1133, name = BF["Bilgewater Cartel"], icon = "Interface\\Glues\\CharacterCreate\\UI-CHARACTERCREATE-RACES", left = 0.625, right = 0.75, top = 0.25, bottom = 0.5 },
			{ id = 1352, name = BF["Huojin Pandaren"], icon = "Interface\\Glues\\CharacterCreate\\UI-CHARACTERCREATE-RACES", left = 0.75, right = 0.875, top = 0.25, bottom = 0.5 },	-- "Huojin Pandaren" 
			{ id = 67, name = BF["Horde"], icon = "INV_BannerPVP_01" },	-- "Horde" 
		},
	}
}
