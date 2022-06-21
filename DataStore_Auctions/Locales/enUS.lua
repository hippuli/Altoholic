local debug = false
--[===[@debug@
debug = true
--@end-debug@]===]

local L = LibStub("AceLocale-3.0"):NewLocale("DataStore_Auctions", "enUS", true, debug)

L["CLEAR_EXPIRED_ITEMS_DISABLED"] = "Expired items remain in the database until the player next visits the auction house."
L["CLEAR_EXPIRED_ITEMS_ENABLED"] = "Expired items are automatically deleted from the database."
L["CLEAR_EXPIRED_ITEMS_LABEL"] = "Automatically clear expired auctions and bids"
L["CLEAR_EXPIRED_ITEMS_TITLE"] = "Clear Auction House items"

