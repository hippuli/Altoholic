--[[	*** DataStore_Crafts ***
Written by : Thaoky, EU-Marécages de Zangar
June 23rd, 2009
--]]
if not DataStore then return end

local addonName = "DataStore_Crafts"

_G[addonName] = LibStub("AceAddon-3.0"):NewAddon(addonName, "AceConsole-3.0", "AceEvent-3.0", "AceComm-3.0", "AceSerializer-3.0", "AceTimer-3.0")

local addon = _G[addonName]
local L = LibStub("AceLocale-3.0"):GetLocale("DataStore_Crafts")

local AddonDB_Defaults = {
	global = {
		Guilds = {
			['*'] = {			-- ["Account.Realm.Name"] 
				Members = {
					['*'] = {				-- ["MemberName"] 
						lastUpdate = nil,
						Version = nil,
						Professions = {},		-- 3 profession links : [1] & [2] for the 2 primary professions, [3] for cooking ([4] for archaeology ? wait & see)
					}
				}
			},
		},
		Characters = {
			['*'] = {				-- ["Account.Realm.Name"] 
				lastUpdate = nil,
				Professions = {
					['*'] = {
						FullLink = nil,		-- Tradeskill link
						Rank = 0,
						MaxRank = 0,
						Icon = nil,
						Crafts = {},
						Categories = {}, 
						Cooldowns = { ['*'] = nil },		-- list of active cooldowns
					}
				},
				ArcheologyItems = {},
			}
		}
	}
}

local ReferenceDB_Defaults = {
	global = {
		Reagents = {},		-- [recipeID] = "itemID1,count1 | itemID2,count2 | ..."
		ResultItems = {},	-- [recipeID] = itemID
		Recipes = {},		-- [recipeID] = 
		RecipeCategoryNames = {},		-- [categoryID] = name
	}
}


local SPELL_ID_ALCHEMY = 2259
local SPELL_ID_BLACKSMITHING = 3100
local SPELL_ID_ENCHANTING = 7411
local SPELL_ID_ENGINEERING = 4036
local SPELL_ID_LEATHERWORKING = 2108
local SPELL_ID_TAILORING = 3908
local SPELL_ID_SKINNING = 8613
local SPELL_ID_MINING = 2575
local SPELL_ID_HERBALISM = 2366
local SPELL_ID_SMELTING = 2656
local SPELL_ID_COOKING = 2550
local SPELL_ID_ARCHAEOLOGY = 78670

local SPELL_ID_FISHING
local SPELL_ID_FIRSTAID
local SPELL_ID_INSCRIPTION
local SPELL_ID_JEWELCRAFTING

if WOW_PROJECT_ID == WOW_PROJECT_MAINLINE then
	SPELL_ID_FISHING = 131474
else
	-- do not use 7733, it's "Artisan Fishing", not "Fishing"
	SPELL_ID_FISHING = 7732
	SPELL_ID_FIRSTAID = 3273
end

if WOW_PROJECT_ID ~= WOW_PROJECT_CLASSIC then
	SPELL_ID_INSCRIPTION = 45357
	SPELL_ID_JEWELCRAFTING = 25229
end




local ProfessionSpellID = {
	-- GetSpellInfo with this value will return localized spell name
	["Alchemy"] = SPELL_ID_ALCHEMY,
	["Blacksmithing"] = SPELL_ID_BLACKSMITHING,
	["Enchanting"] = SPELL_ID_ENCHANTING,
	["Engineering"] = SPELL_ID_ENGINEERING,
	["Inscription"] = SPELL_ID_INSCRIPTION,
	["Jewelcrafting"] = SPELL_ID_JEWELCRAFTING,
	["Leatherworking"] = SPELL_ID_LEATHERWORKING,
	["Tailoring"] = SPELL_ID_TAILORING,
	["Skinning"] = SPELL_ID_SKINNING,
	["Mining"] = SPELL_ID_MINING,
	["Herbalism"] = SPELL_ID_HERBALISM,
	["Smelting"] = SPELL_ID_SMELTING,
	["Cooking"] = SPELL_ID_COOKING,
	["Fishing"] = SPELL_ID_FISHING,
	["First Aid"] = SPELL_ID_FIRSTAID,
}

-- Add localized names
for english, localized in pairs(L) do
	if ProfessionSpellID[english] then
		ProfessionSpellID[localized] = ProfessionSpellID[english]
	end
end

-- *** Utility functions ***
local bAnd = bit.band
local LShift = bit.lshift
local RShift = bit.rshift

local function TestBit(value, pos)
	-- note: this function works up to bit 51
	local mask = 2 ^ pos		-- 0-based indexing
	return value % (mask + mask) >= mask
end

local function GetOption(option)
	return addon.db.global.Options[option]
end

local function GetProfessionID(profession)
	-- profession = localized profession name "Cooking" or "Cuisine", "Alchemy"...
	-- note: we're not using a reverse lookup table because of the localization issue.
	
	if ProfessionSpellID[profession] then
		return ProfessionSpellID[profession]
	end

	for _, id in pairs( ProfessionSpellID ) do
		if profession == GetSpellInfo(id) then		-- profession found ?
			ProfessionSpellID[profession] = id		-- cache the result to speed up future searches
			return id
		end
	end
end

local function GetThisGuild()
	local key = DataStore:GetThisGuildKey()
	return key and addon.db.global.Guilds[key] 
end

local function GetVersion()
	local _, version = GetBuildInfo()
	return tonumber(version)
end

local function ClearExpiredProfessions()
	-- this function will clear all the guild profession links that were saved with a build number anterior to the current one (they're invalid after a patch anyway)
	
	local thisGuild = GetThisGuild()
	if not thisGuild then return end
		
	local version = GetVersion()
	
	for name, member in pairs(thisGuild.Members) do
		if member.Version ~= version then
			thisGuild.Members[name] = nil		-- clear this member's entry if version is outdated
		end
	end
end

local function LocalizeProfessionSpellIDs()
	-- this function adds localized entries in the ProfessionSpellID table
	
	local localizedSpells = {}		-- avoid infinite loop by storing in a temp table first
	local localizedName
	for englishName, spellID in pairs(ProfessionSpellID) do
		localizedName = GetSpellInfo(spellID)
		localizedSpells[localizedName] = spellID
	end
	
	for name, id in pairs(localizedSpells) do
		ProfessionSpellID[name] = id
	end
end

local function GetRecipeRank(info)
	local currentRank = 0
	local totalRanks = 1
	local highestRankID = info.recipeID

	-- Go back to the first rank of the recipe
	while info.previousRecipeID do
		info = C_TradeSkillUI.GetRecipeInfo(info.previousRecipeID)
	end

	-- if this happens, the level 1 recipe is not known, so set it as highest rank (even if we came from level 2)
	if not info.learned then
		highestRankID = info.recipeID
	end
	
	-- Loop until the last rank
	while info.nextRecipeID do
		totalRanks = totalRanks + 1
		if info.learned then
			currentRank = currentRank + 1
			highestRankID = info.recipeID
		end
		info = C_TradeSkillUI.GetRecipeInfo(info.nextRecipeID)
	end
	
	-- process the last item
	if info.learned then
		currentRank = currentRank + 1
		highestRankID = info.recipeID
	end
	
	return currentRank, totalRanks, highestRankID
end

-- *** Scanning functions ***

local selectedTradeSkillIndex
local subClasses, subClassID
local invSlots, invSlotID

local function GetSubClassID()
	-- The purpose of this function is to get the subClassID in a UI independant way
	-- ie: without relying on UIDropDownMenu_GetSelectedID(TradeSkillSubClassDropDown), which uses a hardcoded frame name.
	
	if GetTradeSkillSubClassFilter(0) then		-- if "All Subclasses" is selected, GetTradeSkillSubClassFilter() will return 1 for all indexes, including 0
		return 1				-- thus return 1 as selected id	(as would be returned by UIDropDownMenu_GetSelectedID(TradeSkillSubClassDropDown))
	end

	local isEnabled
	for i = 1, #subClasses do
	   isEnabled = GetTradeSkillSubClassFilter(i)
	   if isEnabled then
	      return i+1			-- ex: 3rd element of the subClasses array, but 4th in the dropdown due to "All Subclasses", so return i+1
	   end
	end
end

local function GetInvSlotID()
	-- The purpose of this function is to get the invSlotID in a UI independant way	(same as GetSubClassID)
	-- ie: without relying on UIDropDownMenu_GetSelectedID(TradeSkillInvSlotDropDown), which uses a hardcoded frame name.

	if GetTradeSkillInvSlotFilter(0) then		-- if "All Slots" is selected, GetTradeSkillInvSlotFilter() will return 1 for all indexes, including 0
		return 1				-- thus return 1 as selected id	(as would be returned by  UIDropDownMenu_GetSelectedID(TradeSkillInvSlotDropDown))
	end

	local filter
	for i = 1, #invSlots do
	   filter = GetTradeSkillInvSlotFilter(i)
	   if filter then
	      return i+1			-- ex: 3rd element of the invSlots array, but 4th in the dropdown due to "All Slots", so return i+1
	   end
	end
end

local function SaveActiveFilters()
	selectedTradeSkillIndex = GetTradeSkillSelectionIndex()
	
	subClasses = { GetTradeSkillSubClasses() }
	invSlots = { GetTradeSkillInvSlots() }
	subClassID = GetSubClassID()
	invSlotID = GetInvSlotID()
	
	-- Subclasses
	SetTradeSkillSubClassFilter(0, 1, 1)	-- this checks "All subclasses"
	if TradeSkillSubClassDropDown then
		UIDropDownMenu_SetSelectedID(TradeSkillSubClassDropDown, 1)
	end
	
	-- Inventory slots
	SetTradeSkillInvSlotFilter(0, 1, 1)		-- this checks "All slots"
	if TradeSkillInvSlotDropDown then
		UIDropDownMenu_SetSelectedID(TradeSkillInvSlotDropDown, 1)
	end
end

local function RestoreActiveFilters()
	-- Subclasses
	SetTradeSkillSubClassFilter(subClassID-1, 1, 1)	-- this checks the previously checked value
	
	local frame = TradeSkillSubClassDropDown
	if frame then	-- other addons might nil this frame (delayed load, etc..), so secure DDM calls
		local text = (subClassID == 1) and ALL_SUBCLASSES or subClasses[subClassID-1]
		UIDropDownMenu_SetSelectedID(frame, subClassID)
		UIDropDownMenu_SetText(frame, text);
	end
	
	subClassID = nil
	wipe(subClasses)
	subClasses = nil
	
	-- Inventory slots
	invSlotID = invSlotID or 1
	SetTradeSkillInvSlotFilter(invSlotID-1, 1, 1)	-- this checks the previously checked value
	
	frame = TradeSkillInvSlotDropDown
	if frame then
		local text = (invSlotID == 1) and ALL_INVENTORY_SLOTS or invSlots[invSlotID-1]
		UIDropDownMenu_SetSelectedID(frame, invSlotID)
		UIDropDownMenu_SetText(frame, text);
	end
	
	invSlotID = nil
	wipe(invSlots)
	invSlots = nil

	SelectTradeSkill(selectedTradeSkillIndex)
	selectedTradeSkillIndex = nil
end

local headersState = {}

local function SaveHeaders()
	local headerCount = 0		-- use a counter to avoid being bound to header names, which might not be unique.
	
	for i = GetNumTradeSkills(), 1, -1 do		-- 1st pass, expand all categories
		local _, skillType, _, isExpanded  = GetTradeSkillInfo(i)
		 if (skillType == "header") then
			headerCount = headerCount + 1
			if not isExpanded then
				ExpandTradeSkillSubClass(i)
				headersState[headerCount] = true
			end
		end
	end
end

local function RestoreHeaders()
	local headerCount = 0
	for i = GetNumTradeSkills(), 1, -1 do
		local _, skillType  = GetTradeSkillInfo(i)
		if (skillType == "header") then
			headerCount = headerCount + 1
			if headersState[headerCount] then
				CollapseTradeSkillSubClass(i)
			end
		end
	end
	wipe(headersState)
end

local function ScanProfessionInfo(index, mainIndex)
	local char = addon.ThisCharacter

	if char and mainIndex and not index then
		char["Prof"..mainIndex] = nil			-- profession may have been cleared, nil it
	end

	if not char or not index then return end
	
	local profName, texture, rank, maxRank, _, _, _, _, _, _, currentLevelName = GetProfessionInfo(index);
	local profession = char.Professions[profName]
	profession.CurrentLevelName = currentLevelName
	
	if profName == GetSpellInfo(SPELL_ID_ARCHAEOLOGY) then
		profession.Rank = rank
		profession.MaxRank = maxRank
	end
	
	if mainIndex then
		char["Prof"..mainIndex] = profName
	end
end

local function ScanProfessionLinks()
	-- Retail
	if WOW_PROJECT_ID == WOW_PROJECT_MAINLINE then
		local prof1, prof2, arch, fish, cook = GetProfessions()

		ScanProfessionInfo(cook)
		ScanProfessionInfo(fish)
		ScanProfessionInfo(arch)
		ScanProfessionInfo(prof1, 1)
		ScanProfessionInfo(prof2, 2)
		
		addon.ThisCharacter.lastUpdate = time()
		
		addon:SendMessage("DATASTORE_PROFESSION_LINKS_UPDATED")
		return
	end
	
	-- Non-retail
	local char = addon.ThisCharacter
	if not char then return end

	-- reset, in case a profession is dropped
	char.Prof1 = nil
	char.Prof2 = nil
	
	-- 1st pass, expand all categories
	for i = GetNumSkillLines(), 1, -1 do
		local _, isHeader = GetSkillLineInfo(i)
		if isHeader then
			ExpandSkillHeader(i)
		end
	end
	
	local category
	for i = 1, GetNumSkillLines() do
		local profName, isHeader, _, rank, _, _, maxRank = GetSkillLineInfo(i)
		
		if profName == "Secourisme" then
			profName = GetSpellInfo(SPELL_ID_FIRSTAID)
		end
		
		if isHeader then
			category = profName
		else
			if category and profName then
				local field
				
				if category == L["Professions"] then
					field = "isPrimary"
					
					-- if this profession is not known yet as 
					if not char.Prof1 then			-- if there is not "first profession" known yet ..
						char.Prof1 = profName
					else
						char.Prof2 = profName
					end
				end
				
				if category == L["Secondary Skills"] then
					field = "isSecondary"
				end
				
				if field then
					local profession = char.Professions[profName]
				
					profession[field] = true
					profession.Rank = rank
					profession.MaxRank = maxRank
					
					-- Always nil classic apparently
					-- should be nil anyway for fishing, mining, etc..
					-- local newLink = select(2, GetSpellLink(skillName))
					-- if newLink then		-- sometimes a nil value may be returned, so keep the old one if nil
						-- char.Professions[skillName].FullLink = newLink
					-- end
				end
			end
		end
	end
	
	char.lastUpdate = time()
end

local SkillTypeToColor = {
	["header"] = 0,
	["optimal"] = 1,		-- orange
	["medium"] = 2,		-- yellow
	["easy"] = 3,			-- green
	["trivial"] = 4,		-- grey
}

local function ScanCooldowns()
	local tradeskillName = GetTradeSkillLine()
	local char = addon.ThisCharacter
	local profession = char.Professions[tradeskillName]
	
	wipe(profession.Cooldowns)
	for i = 1, GetNumTradeSkills() do
		local skillName, skillType = GetTradeSkillInfo(i)
		
		if skillType ~= "header" then
			local cooldown = GetTradeSkillCooldown(i)
			if cooldown then
				-- ex: "Hexweave Cloth|86220|1533539676" expire at "now + cooldown"
				table.insert(profession.Cooldowns, format("%s|%d|%d", skillName, cooldown, cooldown + time()))
				
				addon:SendMessage("DATASTORE_PROFESSION_COOLDOWN_UPDATED")
			end
		end
	end
end

local function ScanRecipeCategories(profession)
	-- clear storage
	profession.Categories = profession.Categories or {}
	wipe(profession.Categories)
	
	local names = addon.ref.global.RecipeCategoryNames
	local cumulatedRank = 0
	local cumulatedMaxRank = 0
	
	-- loop through this profession's categories
	for _, id in ipairs( { C_TradeSkillUI.GetCategories() } ) do
		local info = C_TradeSkillUI.GetCategoryInfo(id)
		
		cumulatedRank = cumulatedRank + (info.skillLineCurrentLevel or 0)
		cumulatedMaxRank = cumulatedMaxRank + (info.skillLineMaxLevel or 0)
		names[info.categoryID] = info.name
	
		-- save the names of subcategories
		local subCats = { C_TradeSkillUI.GetSubCategories(info.categoryID) }
		for _, subCatID in pairs(subCats) do
			local subCatInfo = C_TradeSkillUI.GetCategoryInfo(subCatID)
			
			names[subCatInfo.categoryID] = subCatInfo.name
		end
	
		table.insert(profession.Categories, { 
			id = info.categoryID, 
			Rank = info.skillLineCurrentLevel, 
			MaxRank = info.skillLineMaxLevel,
			SubCategories = subCats
		})
	end
	
	profession.Rank = cumulatedRank
	profession.MaxRank = cumulatedMaxRank
end

local function ScanRecipes_Retail()
	
	local info = C_TradeSkillUI.GetBaseProfessionInfo()
	local tradeskillName = info.professionName

	if not tradeskillName or tradeskillName == "UNKNOWN" then return end	-- may happen after a patch, or under extreme lag, so do not save anything to the db !

	local char = addon.ThisCharacter
	local profession = char.Professions[tradeskillName]
	
	ScanRecipeCategories(profession)
	
	-- Get profession link
	local profLink = C_TradeSkillUI.GetTradeSkillListLink()
	if profLink then	-- sometimes a nil value may be returned, so keep the old one if nil
		profession.FullLink = profLink
	end
	
	local crafts = profession.Crafts
	wipe(crafts)
		
	local recipes = C_TradeSkillUI.GetAllRecipeIDs()
	if not recipes or (#recipes == 0) then return end
	
	local resultItems = addon.ref.global.ResultItems
	local reagentsDB = addon.ref.global.Reagents
	
	addon.ref.global.Recipes[tradeskillName] = addon.ref.global.Recipes[tradeskillName] or {}
	local recipesDB = addon.ref.global.Recipes[tradeskillName]
	local reagentsInfo = {}
	
	wipe(profession.Cooldowns)
	
	for i, recipeID in pairs(recipes) do
		
		-- scan reagents for all recipes (even unlearned)
		wipe(reagentsInfo)

		local schematic = C_TradeSkillUI.GetRecipeSchematic(recipeID, false)
		local numReagents = #schematic.reagentSlotSchematics
				
		for reagentIndex = 1, numReagents do
			local reagent = schematic.reagentSlotSchematics[reagentIndex]
			
			local count = reagent.quantityRequired
			local itemID = reagent.reagents[1].itemID

			if itemID and count then
				table.insert(reagentsInfo, format("%s,%s", itemID, count))
			end
		end
		
		reagentsDB[recipeID] = table.concat(reagentsInfo, "|")

		-- Resulting item ID
		local maxMade = schematic.quantityMax
		if maxMade > 255 then maxMade = 255 end
		
		if schematic.outputItemID then
			resultItems[recipeID] = maxMade + LShift(schematic.outputItemID, 8) 	-- bits 0-7 = maxMade, bits 8+ = item id
		end
		
		-- Get recipe info
		local info = C_TradeSkillUI.GetRecipeInfo(recipeID)
		local recipeRank, totalRanks, highestRankID = GetRecipeRank(info)
		
		-- if we are rank 2 out of 3 for a recipe, do not save rank 1 and rank 3
		if recipeID == highestRankID then
		
			-- save the recipe
			crafts[info.categoryID] = crafts[info.categoryID] or {}
			table.insert(crafts[info.categoryID], 
				info.relativeDifficulty 
				+ LShift((info.learned == true) and 1 or 0, 2) 	-- bit 2 => 1 = learned, 0 = not learned
				+ LShift(recipeRank, 3)		-- bits 3-4 = recipe rank
				+ LShift(totalRanks, 5)		-- bits 5-6 = max rank
				+ LShift(recipeID, 7))		-- bits 7+ = recipeID
		end
		
		-- scan cooldown
		local cooldown = C_TradeSkillUI.GetRecipeCooldown(recipeID)
		if cooldown then
			-- ex: "Hexweave Cloth|86220|1533539676" expire at "now + cooldown"
			table.insert(profession.Cooldowns, format("%s|%d|%d", info.name, cooldown, cooldown + time()))
		end
	end
	
	addon:SendMessage("DATASTORE_RECIPES_SCANNED", char, tradeskillName)
end

local function ScanRecipes_NonRetail()
	local tradeskillName = GetTradeSkillLine()
	
	-- special treatment for frFR, change "Secourisme" into "Premiers soins"
	if tradeskillName == "Secourisme" then
		tradeskillName = GetSpellInfo(SPELL_ID_FIRSTAID)
	end
	
	-- number of known entries in the current skill list including headers and categories
	local numTradeSkills = GetNumTradeSkills()
	local skillName, skillType, _, _, altVerb = GetTradeSkillInfo(1)	-- test the first line
	
	-- print(tradeskillName or "prof nil")
	-- print(numTradeSkills or "numTradeSkills nil")
	-- print(skillType or "skillType nil")
	-- print("-- Count " .. count)	
	-- count = count + 1
	
	-- This method seems to be stable to not miss skills, or to make incomplete scans. At least in Classic.
	if not tradeskillName or not numTradeSkills
		or	tradeskillName == "UNKNOWN"
		or	numTradeSkills == 0
		or (skillType ~= "header" and skillType ~= "subheader") then
		
		-- if for any reason the frame is not ready, call it again in 1 second
		-- addon:ScheduleTimer(ScanRecipes_NonRetail, 0.5)
		return
	end

	addon:CancelAllTimers()

	-- print("scan ok : " .. numTradeSkills)
	local char = addon.ThisCharacter
	local profession = char.Professions[tradeskillName]
	
	if WOW_PROJECT_ID == WOW_PROJECT_WRATH_CLASSIC then
		-- Get profession link
		local profLink = GetTradeSkillListLink()
		if profLink then	-- sometimes a nil value may be returned, so keep the old one if nil
			--addon:Print(format(("%s"), profLink)) -- debug
			profession.FullLink = profLink
		end
	end

	-- clear storage
	profession.Categories = profession.Categories or {}
	wipe(profession.Categories)
	
	local crafts = profession.Crafts
	wipe(crafts)
		
	local resultItems = addon.ref.global.ResultItems
	local reagentsDB = addon.ref.global.Reagents
	local reagentsInfo = {}
	
	wipe(profession.Cooldowns)
	local link, recipeLink, itemID, recipeID
	
	for i = 1, numTradeSkills do
		skillName, skillType, _, _, altVerb = GetTradeSkillInfo(i)
		--print(format("skillName: %s, skillType: %s, altVerb : %s", skillName or "nil", skillType or "nil", altVerb or "nil")) --debug
		-- scan reagents for current skill
		wipe(reagentsInfo)
		local numReagents =  GetTradeSkillNumReagents(i)

		for reagentIndex = 1, numReagents do
			local _, _, count = GetTradeSkillReagentInfo(i, reagentIndex)
			link = GetTradeSkillReagentItemLink(i, reagentIndex)
			
			if link and count then
				itemID = tonumber(link:match("item:(%d+)"))
				if itemID then
					table.insert(reagentsInfo, format("%s,%s", itemID, count))
				end
			end
		end
		
		-- Get recipeID
		
		if WOW_PROJECT_ID == WOW_PROJECT_WRATH_CLASSIC then
			recipeLink = GetTradeSkillRecipeLink(i) -- add recipe link here to get recipeID
			if recipeLink then
				local found, _, enchantString = string.find(recipeLink, "^|%x+|H(.+)|h%[.+%]")
				recipeID = tonumber(enchantString:match("enchant:(%d+)"))
				if recipeID then
					reagentsDB[recipeID] = table.concat(reagentsInfo, "|")
				end
			end
		end

		-- Resulting itemID if there is one
		link = GetTradeSkillItemLink(i)
		if link then
			itemID = tonumber(link:match("item:(%d+)"))
			
			if WOW_PROJECT_ID == WOW_PROJECT_WRATH_CLASSIC then
				if itemID and recipeID then
					local maxMade = 1
					resultItems[recipeID] = maxMade + LShift(itemID, 8) 	-- bits 0-7 = maxMade, bits 8+ = item id
				end
			else
				if itemID then
					reagentsDB[itemID] = table.concat(reagentsInfo, "|")
				end
			end
			
		end
		
		-- Scan recipe
		local color = SkillTypeToColor[skillType]
		local craftInfo
		
		if color then
			if skillType == "header" then
				craftInfo = skillName or ""
				table.insert(profession.Categories, skillName)
			else
				-- cooldowns, if any
				local cooldown = GetTradeSkillCooldown(i)
				if cooldown then
				-- ex: "Hexweave Cloth|86220|1533539676" expire at "now + cooldown"
					table.insert(profession.Cooldowns, format("%s|%d|%d", skillName, cooldown, cooldown + time()))
				end

				-- if there is a valid recipeID, save it
				if WOW_PROJECT_ID == WOW_PROJECT_WRATH_CLASSIC then
					craftInfo = (recipeLink and recipeID) and recipeID or ""
				else
					craftInfo = (link and itemID) and itemID or ""
				end
			end
			crafts[i] = format("%s|%s", color, craftInfo)
		end
	end
	
	addon:SendMessage("DATASTORE_RECIPES_SCANNED", char, tradeskillName)
end

local function ScanEnchantingRecipes()
	local tradeskillName = GetCraftDisplaySkillLine()
	
	local char = addon.ThisCharacter
	local profession = char.Professions[tradeskillName]
	
	-- There will be no categories for poisons, beast training, etc..
	if not profession or not profession.Categories then return end
	
	wipe(profession.Categories)
	
	table.insert(profession.Categories, tradeskillName)	-- insert a fake "Enchanting" category
	
	local crafts = profession.Crafts
	wipe(crafts)
	
	table.insert(crafts, format("0|%s", tradeskillName))	-- insert a fake "0|Enchanting" header
	
	local reagentsDB = addon.ref.global.Reagents
	local reagentsInfo = {}
	
	for i = 1, GetNumCrafts() do
		local name, _, skillType = GetCraftInfo(i)			-- Ex: Runed Copper Rod
		local _, _, icon, _, _, _, spellID = GetSpellInfo(name)		-- Gets : icon = 135225, spellID = 7421
		
		local color = SkillTypeToColor[skillType]
		if color then
			table.insert(crafts, format("%d|%d|%d", color, spellID, icon))
		end
		
		-- scan reagents for current skill
		wipe(reagentsInfo)
		
		-- reagents
		for reagentIndex = 1, GetCraftNumReagents(i) do
			local _, _, count = GetCraftReagentInfo(i, reagentIndex)
			local link = GetCraftReagentItemLink(i, reagentIndex) 
    
			if link and count then
				itemID = tonumber(link:match("item:(%d+)"))
				if itemID then
					table.insert(reagentsInfo, format("%s,%s", itemID, count))
				end
			end
		end
		
		-- Used a spell prefix for enchanting, to avoid having a spellID overwriting an itemID
		reagentsDB[format("spell:%d", spellID)] = table.concat(reagentsInfo, "|")
	end
	
	addon.ThisCharacter.lastUpdate = time()
end

local function ScanTradeSkills()
	if WOW_PROJECT_ID == WOW_PROJECT_MAINLINE then
		ScanRecipes_Retail()
	
	else
		SaveActiveFilters()
		SaveHeaders()
		ScanRecipes_NonRetail()
		RestoreHeaders()
		RestoreActiveFilters()
	end
	
	addon.ThisCharacter.lastUpdate = time()
end

local function ScanArcheologyItems()
	local items = addon.ThisCharacter.ArcheologyItems
	wipe(items)
	
	local names = {}
	local spellName
	local numArtifactsByRace
	
	for raceIndex = 1, GetNumArchaeologyRaces() do
		wipe(names)
		
		numArtifactsByRace = GetNumArtifactsByRace(raceIndex)
		
		if numArtifactsByRace > 0 and addon.artifactDB[raceIndex] then
			-- Create a table where ["Artifact Name"] = associated spell id 
			-- this is necessary because the archaeology API does not return any other way to match artifacts with either spell ID or item ID
			for index, artifact in pairs(addon.artifactDB[raceIndex]) do
				spellName = GetSpellInfo(artifact.spellID)
				names[spellName] = artifact.spellID
			end
			
			for artifactIndex = 1, GetNumArtifactsByRace(raceIndex) do
				local artifactName, _, _, _, _, _, _, _, _, completionCount = GetArtifactInfoByRace(raceIndex, artifactIndex)

				-- debug only
				-- if not names[artifactName] then
					-- print(artifactName .. " not found")
				-- end
				
				if names[artifactName] and completionCount > 0 then
					items[names[artifactName]] = true
				end
			end
		end
	end
end

-- *** Event Handlers ***
local function OnPlayerAlive()
	ScanProfessionLinks()
end

local function OnTradeSkillClose()
	if WOW_PROJECT_ID ~= WOW_PROJECT_MAINLINE then
		addon:UnregisterEvent("TRADE_SKILL_UPDATE")
	end
	addon:UnregisterEvent("TRADE_SKILL_CLOSE")
	addon.isOpen = nil
end

local currentCraftRecipeID

local function OnTradeSkillListUpdate(self)
	if not currentCraftRecipeID then return end
	
	local cooldown = C_TradeSkillUI.GetRecipeCooldown(currentCraftRecipeID)
	if cooldown then
		ScanRecipes_Retail()
		addon:SendMessage("DATASTORE_PROFESSION_COOLDOWN_UPDATED")
		currentCraftRecipeID = nil
	end
end

local updateCooldowns

local function OnTradeSkillUpdate()
	-- The hook in DoTradeSkill will set this flag so that we only update skills once.
	if updateCooldowns then
		ScanCooldowns()	-- only cooldowns need to be refreshed
		updateCooldowns = nil
	end	
end

local function OnTradeSkillShow()
	-- Retail only
	if WOW_PROJECT_ID == WOW_PROJECT_MAINLINE then
		if C_TradeSkillUI.IsTradeSkillLinked() or C_TradeSkillUI.IsTradeSkillGuild() or C_TradeSkillUI.IsNPCCrafting() then return end
		
		hooksecurefunc(C_TradeSkillUI, "CraftRecipe", function(recipeID) 
			currentCraftRecipeID = recipeID
		end)
	end
	
	addon:RegisterEvent("TRADE_SKILL_CLOSE", OnTradeSkillClose)
	addon.isOpen = true
	
	-- Non-retail only
	if WOW_PROJECT_ID ~= WOW_PROJECT_MAINLINE then
		addon:RegisterEvent("TRADE_SKILL_UPDATE", OnTradeSkillUpdate)
	
		ScanProfessionLinks()

		-- Scan 0.5 seconds after the SHOW event
		addon:ScheduleTimer(ScanTradeSkills, 0.5)	
	end
end

local function OnCraftClose()
	addon:UnregisterEvent("CRAFT_CLOSE")
end

local function OnCraftUpdate()     
	addon:RegisterEvent("CRAFT_CLOSE", OnCraftClose)
	ScanProfessionLinks()
	ScanEnchantingRecipes()
end

local function OnArtifactHistoryReady()
	ScanArcheologyItems()
end

local function OnArtifactComplete()
	ScanArcheologyItems()
end

-- this turns
--	"Your skill in %s has increased to %d."
-- into
--	"Your skill in (.+) has increased to (%d+)."
local arg1pattern, arg2pattern
if GetLocale() == "deDE" then		
	-- ERR_SKILL_UP_SI = "Eure Fertigkeit '%1$s' hat sich auf %2$d erhöht.";
	arg1pattern = "'%%1%$s'"
	arg2pattern = "%%2%$d"
else
	arg1pattern = "%%s"
	arg2pattern = "%%d"
end

local skillUpMsg = gsub(ERR_SKILL_UP_SI, arg1pattern, "(.+)")
skillUpMsg = gsub(skillUpMsg, arg2pattern, "(%%d+)")

local function OnChatMsgSkill(self, message)
	if not message then return end

	-- Check it is the right type of message
	local skill = message:match(skillUpMsg)
	if not skill then return end
	
	if WOW_PROJECT_ID == WOW_PROJECT_MAINLINE then
		local info = C_TradeSkillUI.GetChildProfessionInfo()
		-- if we gained a skill point in the currently opened profession pane, rescan
		if skill == info.professionName then	
			ScanTradeSkills()
		end		
	else
		-- Do nothing if it is not a real profession
		local tradeSkillName = GetTradeSkillLine()
		if tradeSkillName == "UNKNOWN" then return end
	end

	ScanProfessionLinks() -- added to update skills upon firing of skillup event 
end


local unlearnMsg = gsub(ERR_SPELL_UNLEARNED_S, arg1pattern, "(.+)")

local function OnChatMsgSystem(self, message)
	if not message then return end

	-- Check it is the right type of message
	local skillLink = message:match(unlearnMsg)
	if not skillLink then return end

	-- Check it is a proper profession
	local skillName = skillLink:match("%[(.+)%]")
	if skillName then
		
		-- Clear the list of recipes
		local char = addon.ThisCharacter
		wipe(char.Professions[skillName])
		char.Professions[skillName] = nil
	end
			
	-- this won't help, as GetProfessions does not return the right values right after the profession has been abandonned.
	-- The problem of listing Prof1 & Prof2 with potentially the same value fixes itself after the next logon though.
	-- Until I find more time to work around this issue, we will live with it .. it's not like players are abandonning professions 100x / day :)
	-- ScanProfessionLinks()	
end

local function OnDataSourceChanged(self)
	if WOW_PROJECT_ID == WOW_PROJECT_WRATH_CLASSIC then
		if IsTradeSkillLinked() then return end
	
	else
		if C_TradeSkillUI.IsTradeSkillLinked() or C_TradeSkillUI.IsTradeSkillGuild() or C_TradeSkillUI.IsNPCCrafting() then return end
		
		ScanTradeSkills()
	end
end




-- ** Mixins **
local function _GetProfession(character, name)
	if name then
		return character.Professions[name]
	end
end
	
local function _GetProfessions(character)
	return character.Professions
end

local function _GetProfessionInfo(profession)
	-- accepts either a pointer (type == table)to the profession table, as returned by addon:GetProfession()
	-- or a link (type == string)
	
	local rank, maxRank, spellID, _
	local link

	if type(profession) == "table" then
		rank = profession.Rank
		maxRank = profession.MaxRank 
		link = profession.FullLink
	elseif type(profession) == "string" then
		link = profession
	end
	
	if link and type(link) ~= "number" then
		-- _, spellID, rank, maxRank = link:match("trade:(%w+):(%d+):(%d+):(%d+):")
		_, spellID = link:match("trade:(%w+):(%d+)")		-- Fix 5.4, rank no longer in the profession link
	end
	
	return tonumber(rank) or 0, tonumber(maxRank) or 0, tonumber(spellID)
end
	
local function _IsProfessionKnown(character, professionName)
	if (character.Prof1 and character.Prof1 == professionName) or
		(character.Prof2 and character.Prof2 == professionName) then 
		return true 
	end
end
	
local function _GetNumRecipeCategories(profession)
	return (profession.Categories) and #profession.Categories or 0
end

local function GetCategoryName(id)
	return addon.ref.global.RecipeCategoryNames[id]
end

local function _GetRecipeCategoryInfo_Retail(profession, index)
	local category = profession.Categories[index]
	return category.id, GetCategoryName(category.id), category.Rank, category.MaxRank
end

local function _GetRecipeCategoryInfo_NonRetail(profession, index)
	return profession.Categories[index]
end

local function _GetNumRecipeCategorySubItems(profession, index)
	local category = profession.Categories[index]
	return #category.SubCategories
end

local function _GetRecipeSubCategoryInfo(profession, catIndex, subCatIndex)
	local catID = profession.Categories[catIndex].SubCategories[subCatIndex]
	
	-- return real category id, name, and list of recipes
	return catID, GetCategoryName(catID), profession.Crafts[catID]
end

local function _GetRecipeInfo_Retail(recipeData)
	local color = bAnd(recipeData, 3)			-- Bits 0-1 = color
	local isLearned = TestBit(recipeData, 2) 	-- Bit 2 = isLearned
	local recipeRank = bAnd(RShift(recipeData, 3), 3)		-- bits 3-4 = recipe rank
	local totalRanks = bAnd(RShift(recipeData, 5), 3)		-- bits 5-6 = max rank
	-- local minMade = bAnd(RShift(recipeData, 7), 255)		-- bits 7-14 = minMade (8 bits)
	-- local maxMade = bAnd(RShift(recipeData, 15), 255)		-- bits 15-22 = maxMade (8 bits)
	local recipeID = RShift(recipeData, 7)		-- bits 7+ = recipeID
	
	return color, recipeID, isLearned, recipeRank, totalRanks, minMade, maxMade
end

local function _GetRecipeInfo_NonRetail(character, profession, index)
	local prof = DataStore:GetProfession(character, profession)
	local crafts = prof.Crafts
	
	-- id = itemID in vanilla, recipeID in LK
	local color, id, icon = strsplit("|", crafts[index])

	return tonumber(color), tonumber(id), icon
end

-- Iterate through all recipes, and callback a function for each of them
local function _IterateRecipes_Retail(profession, mainCategory, subCategory, callback)
	-- mainCategory : category index (or 0 for all)
	-- subCategory : sub-category index (or 0 for all)
	local crafts = profession.Crafts
	
	-- loop through categories
	for catIndex = 1, _GetNumRecipeCategories(profession) do
		-- if there is no filter on main category, or if it is just the one we want to see
		if (mainCategory == 0) or (mainCategory == catIndex) then
			-- loop through subcategories
			for subCatIndex = 1, _GetNumRecipeCategorySubItems(profession, catIndex) do
				-- if there is no filter on sub category, or if it is just the one we want to see
				if (subCategory == 0) or (subCategory == subCatIndex) then
					local subCatID, _, recipes = _GetRecipeSubCategoryInfo(profession, catIndex, subCatIndex)
					
					if type(recipes) == "table" then
						-- loop through recipes
						for i = 1, #recipes do
							local stop = callback(recipes[i])
							
							-- exit if the callback returns true
							if stop then return end
						end
					end
				end
			end
		end
	end
end

local function _IterateRecipes_NonRetail(profession, mainCategory, callback)
	-- mainCategory : category index (or 0 for all)
	local crafts = profession.Crafts
	local currentCategory = 0
	
	
	local stop
	
	-- loop through recipes
	for i = 1, #crafts do
		-- id = itemID in vanilla, recipeID in LK
		local color, id = strsplit("|", crafts[i])

		color = tonumber(color)
		if color == 0 then			-- it's a header
			currentCategory = currentCategory + 1
			-- no callback for headers
		else
			if (mainCategory == 0) or (currentCategory == mainCategory) then
				id = tonumber(id)	-- it's a spellID, return a number
				stop = callback(color, id, i)
			end
			
			-- exit if the callback returns true
			if stop then return end
		end
	end
	
	--[[
	
	-- loop through categories
	for catIndex = 1, _GetNumRecipeCategories(profession) do
		-- if there is no filter on main category, or if it is just the one we want to see
		if (mainCategory == 0) or (mainCategory == catIndex) then
			local stop
			
			-- loop through recipes
			for i = 1, #crafts do
				local color, itemID = strsplit("|", crafts[i])
	
				color = tonumber(color)
				if color == 0 then			-- it's a header
					currentCategory = currentCategory + 1
				end
					
				if (mainCategory == 0) or (currentCategory == catIndex) then
					itemID = tonumber(itemID)	-- it's a spellID, return a number
					stop = callback(color, itemID, i)
				end
				
				-- exit if the callback returns true
				if stop then return end
			end			
		end
	end
	--]]
end

local function _GetCraftCooldownInfo(profession, index)
	local cooldown = profession.Cooldowns[index]
	local name, resetsIn, expiresAt = strsplit("|", cooldown)
	
	resetsIn = tonumber(resetsIn)
	expiresAt = tonumber(expiresAt)	
	local expiresIn = expiresAt - time()
	
	return name, expiresIn, resetsIn, expiresAt
end

local function _GetNumActiveCooldowns(profession)
	assert(type(profession) == "table")		-- this is the pointer to a profession table, obtained through addon:GetProfession()
	return #profession.Cooldowns
end

local function _ClearExpiredCooldowns(profession)
	assert(type(profession) == "table")		-- this is the pointer to a profession table, obtained through addon:GetProfession()
	
	for i = #profession.Cooldowns, 1, -1 do		-- from last to first, to avoid messing up indexes when removing entries
		local _, expiresIn = _GetCraftCooldownInfo(profession, i)
		if expiresIn <= 0 then		-- already expired ? remove it
			table.remove(profession.Cooldowns, i)
		end
	end
end

local function _GetNumRecipesByColor_Retail(profession)
	-- counts the number of orange, yellow, green and grey recipes.
	local counts = { [0] = 0, [1] = 0, [2] = 0, [3] = 0 }
	
	_IterateRecipes_Retail(profession, 0, 0, function(recipeData) 
		local color = _GetRecipeInfo_Retail(recipeData)
		counts[color] = counts[color] + 1
	end)
	
	return counts[3], counts[2], counts[1], counts[0]		-- orange, yellow, green, grey
end

local function _GetNumRecipesByColor_NonRetail(profession)
	-- counts the number of headers = [0], orange, yellow, green and grey recipes.
	local counts = { [0] = 0, [1] = 0, [2] = 0, [3] = 0, [4] = 0 }
	
	_IterateRecipes_NonRetail(profession, 0, function(color, itemID)
		counts[color] = counts[color] + 1
	end)
	
	return counts[1], counts[2], counts[3], counts[4]		-- orange, yellow, green, grey
end

local function _IsCraftKnown_Retail(profession, spellID)
	-- returns true if a given spell ID is known in the profession passed as first argument
	local isKnown
	
	_IterateRecipes_Retail(profession, 0, 0, function(recipeData) 
		local _, recipeID, isLearned = _GetRecipeInfo_Retail(recipeData)
		if recipeID == spellID and isLearned then
			isKnown = true
			return true	-- stop iteration
		end
	end)

	return isKnown
end

local function _IsCraftKnown_NonRetail(profession, soughtID)
	-- returns true if a given item ID (LK) or spell ID (Vanilla) is known in the profession passed as first argument
	local isKnown
	
	_IterateRecipes_NonRetail(profession, 0, function(color, itemID)
		if itemID == soughtID then
			isKnown = true
			return true	-- stop iteration
		end
	end)

	return isKnown
end

local function _GetGuildCrafters(guild)
	return guild.Members
end

local function _GetGuildMemberProfession(guild, member, index)
	local m = guild.Members[member]
	local profession = m.Professions[index]
	
	if type(profession) == "string" then
		local spellID = profession:match("trade:(%d+):")
		return tonumber(spellID), profession, m.lastUpdate	-- return the profession spell ID + full link
	elseif type(profession) == "number" then
		return profession, nil, m.lastUpdate					-- return the profession spell ID
	end
end

local function _GetProfessionSpellID(name)
	-- name can be either the english name or the localized name
	return ProfessionSpellID[name]
end

local function _GetProfession1(character)
	local profession = _GetProfession(character, character.Prof1)

	if profession then
		local rank, maxRank, spellID = _GetProfessionInfo(profession)
		return rank or 0, maxRank or 0, spellID, character.Prof1
	end
	return 0, 0, nil, nil
end

local function _GetProfession2(character)
	local profession = _GetProfession(character, character.Prof2)
	if profession then
		local rank, maxRank, spellID = _GetProfessionInfo(profession)
		return rank or 0, maxRank or 0, spellID, character.Prof2
	end
	return 0, 0, nil, nil
end

local function _GetCookingRank(character)
	local profession = _GetProfession(character, GetSpellInfo(SPELL_ID_COOKING))
	if profession then
		return _GetProfessionInfo(profession)
	end
end

local function _GetFishingRank(character)
	local profession = _GetProfession(character, GetSpellInfo(SPELL_ID_FISHING))
	if profession then
		return _GetProfessionInfo(profession)
	end
end

local function _GetFirstAidRank(character)
	local profession = _GetProfession(character, GetSpellInfo(SPELL_ID_FIRSTAID))
	if profession then
		return _GetProfessionInfo(profession)
	end
end

local function _GetArchaeologyRank(character)
	local profession = _GetProfession(character, GetSpellInfo(SPELL_ID_ARCHAEOLOGY))
	if profession then
		return _GetProfessionInfo(profession)
	end
end

local function _GetArchaeologyRaceArtifacts(race)
	return addon.artifactDB[race]
end

local function _GetRaceNumArtifacts(race)
	return #addon.artifactDB[race]
end

local function _GetArtifactInfo(race, index)
	return addon.artifactDB[race][index]
end

local function _IsArtifactKnown(character, spellID)
	return character.ArcheologyItems[spellID]
end

local function _GetCraftReagents(recipeID)
	return addon.ref.global.Reagents[recipeID]
end

local function _GetCraftResultItem(recipeID)
	local itemData = addon.ref.global.ResultItems[recipeID]
	local itemID, maxMade
	
	if itemData then
		maxMade = bAnd(itemData, 255)		-- bits 0-7 = maxMade (8 bits)
		itemID = RShift(itemData, 8)		-- bits 8+ = recipeID
	end

	return itemID, maxMade
end


local PublicMethods = {
	GetProfession = _GetProfession,
	GetProfessions = _GetProfessions,
	GetProfessionInfo = _GetProfessionInfo,
	IsProfessionKnown = _IsProfessionKnown,
	GetCraftCooldownInfo = _GetCraftCooldownInfo,
	GetNumActiveCooldowns = _GetNumActiveCooldowns,
	ClearExpiredCooldowns = _ClearExpiredCooldowns,
	GetNumRecipeCategories = _GetNumRecipeCategories,
	GetNumRecipeCategorySubItems = _GetNumRecipeCategorySubItems,
	GetRecipeSubCategoryInfo = _GetRecipeSubCategoryInfo,
	GetGuildCrafters = _GetGuildCrafters,
	GetGuildMemberProfession = _GetGuildMemberProfession,
	GetProfessionSpellID = _GetProfessionSpellID,
	GetProfession1 = _GetProfession1,
	GetProfession2 = _GetProfession2,
	GetCookingRank = _GetCookingRank,
	GetFishingRank = _GetFishingRank,
	GetCraftReagents = _GetCraftReagents,
	GetCraftResultItem = _GetCraftResultItem,
}

if WOW_PROJECT_ID == WOW_PROJECT_MAINLINE then
	PublicMethods.GetArchaeologyRank = _GetArchaeologyRank
	PublicMethods.GetArchaeologyRaceArtifacts = _GetArchaeologyRaceArtifacts
	PublicMethods.GetRaceNumArtifacts = _GetRaceNumArtifacts
	PublicMethods.GetArtifactInfo = _GetArtifactInfo
	PublicMethods.IsArtifactKnown = _IsArtifactKnown
	PublicMethods.GetRecipeCategoryInfo = _GetRecipeCategoryInfo_Retail
	PublicMethods.IterateRecipes = _IterateRecipes_Retail
	PublicMethods.GetNumRecipesByColor = _GetNumRecipesByColor_Retail
	PublicMethods.GetRecipeInfo = _GetRecipeInfo_Retail
	PublicMethods.IsCraftKnown = _IsCraftKnown_Retail
else
	PublicMethods.GetFirstAidRank = _GetFirstAidRank
	PublicMethods.GetRecipeCategoryInfo = _GetRecipeCategoryInfo_NonRetail
	PublicMethods.IterateRecipes = _IterateRecipes_NonRetail
	PublicMethods.GetNumRecipesByColor = _GetNumRecipesByColor_NonRetail
	PublicMethods.GetRecipeInfo = _GetRecipeInfo_NonRetail
	PublicMethods.IsCraftKnown = _IsCraftKnown_NonRetail
end

function addon:OnInitialize()
	addon.db = LibStub("AceDB-3.0"):New(addonName .. "DB", AddonDB_Defaults)
	addon.ref = LibStub("AceDB-3.0"):New(addonName .. "RefDB", ReferenceDB_Defaults)

	DataStore:RegisterModule(addonName, addon, PublicMethods)
	DataStore:SetCharacterBasedMethod("GetProfession")
	DataStore:SetCharacterBasedMethod("GetProfessions")
	DataStore:SetCharacterBasedMethod("IsProfessionKnown")
	
	DataStore:SetCharacterBasedMethod("GetProfession1")
	DataStore:SetCharacterBasedMethod("GetProfession2")
	DataStore:SetCharacterBasedMethod("GetCookingRank")
	DataStore:SetCharacterBasedMethod("GetFishingRank")
	
	if WOW_PROJECT_ID == WOW_PROJECT_MAINLINE then
		DataStore:SetCharacterBasedMethod("GetArchaeologyRank")
		DataStore:SetCharacterBasedMethod("IsArtifactKnown")
	else
		DataStore:SetCharacterBasedMethod("GetFirstAidRank")
	end
	
	DataStore:SetGuildBasedMethod("GetGuildCrafters")
	DataStore:SetGuildBasedMethod("GetGuildMemberProfession")
end

function addon:OnEnable()
	addon:RegisterEvent("PLAYER_ALIVE", OnPlayerAlive)
	addon:RegisterEvent("TRADE_SKILL_SHOW", OnTradeSkillShow)
	addon:RegisterEvent("CHAT_MSG_SKILL", OnChatMsgSkill)
	addon:RegisterEvent("CHAT_MSG_SYSTEM", OnChatMsgSystem)
	addon:RegisterEvent("TRADE_SKILL_DATA_SOURCE_CHANGED", OnDataSourceChanged)
	
	if WOW_PROJECT_ID == WOW_PROJECT_CLASSIC then 
		addon:RegisterEvent("CRAFT_UPDATE", OnCraftUpdate)	-- For enchanting
	end
	
	if WOW_PROJECT_ID == WOW_PROJECT_MAINLINE then
		addon:RegisterEvent("TRADE_SKILL_LIST_UPDATE", OnTradeSkillListUpdate)
		
		local _, _, arch = GetProfessions()

		if arch and RequestArtifactCompletionHistory then
			addon:RegisterEvent("RESEARCH_ARTIFACT_HISTORY_READY", OnArtifactHistoryReady)
			addon:RegisterEvent("RESEARCH_ARTIFACT_COMPLETE", OnArtifactComplete)
			RequestArtifactCompletionHistory()		-- this will trigger RESEARCH_ARTIFACT_HISTORY_READY
		end
	end
	
--	addon:SetupOptions()
	ClearExpiredProfessions()	-- automatically cleanup guild profession links that are from an older version
	LocalizeProfessionSpellIDs()
	
	if WOW_PROJECT_ID ~= WOW_PROJECT_MAINLINE then
		hooksecurefunc("DoTradeSkill", function()
			updateCooldowns = true
		end)
	end
end

function addon:OnDisable()
	addon:UnregisterEvent("PLAYER_ALIVE")
	addon:UnregisterEvent("TRADE_SKILL_SHOW")
	addon:UnregisterEvent("CHAT_MSG_SKILL")
	addon:UnregisterEvent("CHAT_MSG_SYSTEM")
	addon:UnregisterEvent("TRADE_SKILL_DATA_SOURCE_CHANGED")
	
	if WOW_PROJECT_ID == WOW_PROJECT_MAINLINE then
		addon:UnregisterEvent("TRADE_SKILL_LIST_UPDATE")
	end
end

function addon:IsTradeSkillWindowOpen()
	-- note : maybe there's a function in the WoW API to test this, but I did not find it :(
	return addon.isOpen
end
