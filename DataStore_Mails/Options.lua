if not DataStore then return end

local addonName = "DataStore_Mails"
local addon = _G[addonName]
local L = LibStub("AceLocale-3.0"):GetLocale(addonName)

function addon:SetupOptions()
	-- can't improve the slider right now, the use of parentKey in XML make it hard to address _Low & _High..
	local f = DataStoreMailOptions

	DataStore:AddOptionCategory(f, addonName, "DataStore")

	-- localize options
	DataStoreMailOptions_SliderMailExpiry.tooltipText = L["Warn when mail expires in less days than this value"]
	DataStoreMailOptions_SliderMailExpiryLow:SetText("1")
	DataStoreMailOptions_SliderMailExpiryHigh:SetText("15")
	
	-- restore saved options to gui
	DataStoreMailOptions_SliderMailExpiry:SetValue(DataStore:GetOption(addonName, "MailWarningThreshold"))
	DataStoreMailOptions_SliderMailExpiryText:SetText(format("%s (%s)", L["EXPIRY_CHECK_LABEL"], DataStoreMailOptions_SliderMailExpiry:GetValue()))
	f.CheckMailExpiry:SetChecked(DataStore:GetOption(addonName, "CheckMailExpiry"))
	f.ScanMailBody:SetChecked(DataStore:GetOption(addonName, "ScanMailBody"))
	f.CheckMailExpiryAllAccounts:SetChecked(DataStore:GetOption(addonName, "CheckMailExpiryAllAccounts"))
	f.CheckMailExpiryAllRealms:SetChecked(DataStore:GetOption(addonName, "CheckMailExpiryAllRealms"))
	f.ReportExpiredMailsToChat:SetChecked(DataStore:GetOption(addonName, "ReportExpiredMailsToChat"))
end
