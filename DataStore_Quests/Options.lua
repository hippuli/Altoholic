if not DataStore then return end

local addonName = "DataStore_Quests"
local addon = _G[addonName]

function addon:SetupOptions()
	local f = DataStore.Frames.QuestsOptions

	DataStore:AddOptionCategory(f, addonName, "DataStore")
	
	-- restore saved options to gui
	f.TrackTurnIns:SetChecked(DataStore:GetOption(addonName, "TrackTurnIns"))
	f.AutoUpdateHistory:SetChecked(DataStore:GetOption(addonName, "AutoUpdateHistory"))
end
