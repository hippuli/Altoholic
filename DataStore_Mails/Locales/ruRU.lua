local L = LibStub("AceLocale-3.0"):NewLocale( "DataStore_Mails", "ruRU" )

if not L then return end

L["EXPIRY_CHECK_LABEL"] = "Сообщать об истечении срока хранения почты"
L["SCAN_MAIL_BODY_LABEL"] = "Просматривать почту (отмечает как прочитаную)"
L["Warn when mail expires in less days than this value"] = "Извещать о истечении срока хранения почты. Указанное значение измеряется в днях."

