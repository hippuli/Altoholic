if not DataStore then return end

local addonName = "DataStore_Crafts"
local addon = _G[addonName]
local L = LibStub("AceLocale-3.0"):GetLocale(addonName)

function addon:SetupOptions()
	-- 22/02/2015: currently inactive, no options for this module, kept present for future options
	-- local f = DataStore.Frames.CraftsOptions
	
	-- DataStore:AddOptionCategory(f, addonName, "DataStore")
	
	-- restore saved options to gui
	--f._optionName_:SetChecked(DataStore:GetOption(addonName, "_optionName_"))
end
