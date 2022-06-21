local L = LibStub("AceLocale-3.0"):NewLocale( "DataStore_Auctions", "esES" )

if not L then return end

L["CLEAR_EXPIRED_ITEMS_DISABLED"] = "Objetos con tiempo terminado permanecen en la base de datos hasta que el jugador visite de nuevo la casa de subastas."
L["CLEAR_EXPIRED_ITEMS_ENABLED"] = "Objetos con tiempo terminado son borrados automáticamente de la base de datos."
L["CLEAR_EXPIRED_ITEMS_LABEL"] = "Borrar automáticamente subastas y pujas terminadas"
L["CLEAR_EXPIRED_ITEMS_TITLE"] = "Borrar objetos de la Casa de Subastas"

