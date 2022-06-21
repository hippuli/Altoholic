local L = LibStub("AceLocale-3.0"):NewLocale( "DataStore_Mails", "deDE" )

if not L then return end

L["EXPIRED_EMAILS_WARNING"] = "%s (%s) hat verfallene (oder bald verfallende) Post"
L["EXPIRY_ALL_ACCOUNTS_DISABLED"] = "Nur der aktuelle Account wird berücksichtigt; importierte Accounts werden ignoriert."
L["EXPIRY_ALL_ACCOUNTS_ENABLED"] = "Die Überprüfungsroutine nach verfallender Post sucht auf allen bekannten Accounts nach Sendungen, die verfallen."
L["EXPIRY_ALL_ACCOUNTS_LABEL"] = "Verfallende Post bei allen bekannten Accounts überprüfen"
L["EXPIRY_ALL_ACCOUNTS_TITLE"] = "Alle Accounts überprüfen"
L["EXPIRY_ALL_REALMS_DISABLED"] = "Nur der aktuelle Realm wird berücksichtigt; andere Realms werden ignoriert."
L["EXPIRY_ALL_REALMS_ENABLED"] = "Die Überprüfungsroutine nach verfallender Post sucht auf allen bekannten Realms nach Sendungen, die verfallen."
L["EXPIRY_ALL_REALMS_LABEL"] = "Verfallende Post bei allen bekannten Realms überprüfen"
L["EXPIRY_ALL_REALMS_TITLE"] = "Alle Realms überprüfen"
L["EXPIRY_CHECK_DISABLED"] = "Es wird keine Überprüfung verfallender Post durchgeführt."
L["EXPIRY_CHECK_ENABLED"] = "Verfallende Post wird 5 Sekunden nach dem Einloggen überprüft. Client-Add-Ons erhalten eine Benachrichtigung, falls mindestens eine verfallene Sendung gefunden wurde."
L["EXPIRY_CHECK_LABEL"] = "Warnung bei verfallender Post"
L["EXPIRY_CHECK_TITLE"] = "Auf verfallende Post überprüfen"
L["REPORT_EXPIRED_MAILS_DISABLED"] = "Im Chatfenster wird nichts angezeigt werden"
L["REPORT_EXPIRED_MAILS_ENABLED"] = "Während der Briefverfallüberprüfung wird die Liste der Charaktere mit verfallenen Briefen auch im Chatfenster angezeigt."
L["REPORT_EXPIRED_MAILS_LABEL"] = "Briefverfallwarnung (Chatfenster)"
L["REPORT_EXPIRED_MAILS_TITLE"] = "Briefverfallwarnung  (Chatfenster)"
L["SCAN_MAIL_BODY_DISABLED"] = "Nur die Anhänge der Sendungen werden gelesen. Die Sendungen behalten ihren Status \"nicht gelesen\"."
L["SCAN_MAIL_BODY_ENABLED"] = "Der Text jeder Sendung wird gelesen, wenn der Briefkasten gescant wird. Alle Sendungen werden als gelesen markiert."
L["SCAN_MAIL_BODY_LABEL"] = "Brieftext scannen (markiert als gelesen)"
L["SCAN_MAIL_BODY_TITLE"] = "Brieftext scannen"
L["Warn when mail expires in less days than this value"] = "Warnen, wenn Post verfällt in weniger Tagen als "

