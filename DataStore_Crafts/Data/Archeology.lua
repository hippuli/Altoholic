local addonName = "DataStore_Crafts"
local addon = _G[addonName]

addon.artifactDB = {}

-- 2016/08/09 : do not use GetNumArchaeologyRaces(), it might not return the proper value at this stage.
-- 2018/08/06 : note for later .. in 8.0, bliz added the 2 new races at the beginning of the list, so all races were shifted down by 2
-- .. might happen again later
-- 8.0 = hardcoding 20 races
for i = 1, 20 do
	addon.artifactDB[i] = {}
end

local RACE_DRUST = 1
local RACE_ZANDALARI = 2
local RACE_DEMONIC = 3
local RACE_HIGHMOUNTAIN_TAUREN = 4
local RACE_HIGHBORNE = 5
local RACE_OGRE = 6
local RACE_DRAENOR_CLANS = 7
local RACE_ARAKKOA = 8
local RACE_MOGU = 9
local RACE_PANDAREN = 10
local RACE_MANTID = 11
local RACE_VRYKUL = 12
local RACE_TROLL = 13
local RACE_TOL_VIR = 14
local RACE_ORC = 15
local RACE_NERUBIAN = 16
local RACE_NIGHT_ELF = 17
local RACE_FOSSIL = 18
local RACE_DRAENEI = 19
local RACE_DWARF = 20

local currentRace = 0

local function AddArtifact(itemID, spellID, rarity, fragments)
	table.insert(addon.artifactDB[currentRace], { itemID = itemID, spellID = spellID, rarity = rarity, fragments = fragments })
end

-- Data taken from Professor, code adjusted for my needs (rarity levels too)

currentRace = RACE_DRUST
AddArtifact(160751, 273852, 3,  85)  -- Dance of the Dead
AddArtifact(161089, 273854, 3,  85)  -- Pile of Bones
AddArtifact(160833, 273855, 3,  85)  -- Fetish of the Tormented Mind

currentRace = RACE_ZANDALARI
AddArtifact(160740, 273815, 3,  85)  -- Croak Crock
AddArtifact(161080, 273817, 3,  85)  -- Intact Direhorn Egg
AddArtifact(160753, 273819, 3,  85)  -- Sanguinating Totem

currentRace = RACE_DEMONIC
AddArtifact(130917, 196481, 0,  85)  -- Flayed-Skin Chronicle
AddArtifact(130920, 196484, 0, 170)  -- Houndstooth Hauberk
AddArtifact(130916, 196480, 0,  60)  -- Imp's Cup
AddArtifact(130918, 196482, 0,  95)  -- Malformed Abyssal
AddArtifact(130919, 196483, 0, 140)  -- Orb of Inner Chaos

currentRace = RACE_HIGHMOUNTAIN_TAUREN
AddArtifact(130914, 196478, 0, 115)  -- Drogbar Gem-Roller
AddArtifact(130913, 196477, 0,  50)  -- Hand-Smoothed Pyrestone
AddArtifact(130912, 196476, 0,  30)  -- Moosebone Fish-Hook
AddArtifact(130915, 196479, 0, 105)  -- Stonewood Bow
AddArtifact(130911, 196475, 0,  65)  -- Trailhead Drum

currentRace = RACE_HIGHBORNE
AddArtifact(130907, 196471, 0,  45)  -- Inert Leystone Charm
AddArtifact(130910, 196474, 0, 100)  -- Nobleman's Letter Opener
AddArtifact(130909, 196473, 0, 120)  -- Pre-War Highborne Tapestry
AddArtifact(130908, 196472, 0,  50)  -- Quietwine Vial

currentRace = RACE_DWARF
AddArtifact(64489, 91227, 4, 150)  -- Staff of Sorcerer-Thane Thaurissan
AddArtifact(64373, 90553, 3, 100)  -- Chalice of the Mountain Kings
AddArtifact(64372, 90521, 3, 100)  -- Clockwork Gnome
AddArtifact(64488, 91226, 3, 150)  -- The Innkeeper's Daughter

AddArtifact(63113, 88910, 0,  34)  -- Belt Buckle with Anvilmar Crest
AddArtifact(64339, 90411, 0,  35)  -- Bodacious Door Knocker
AddArtifact(63112, 86866, 0,  32)  -- Bone Gaming Dice
AddArtifact(64340, 90412, 0,  34)  -- Boot Heel with Scrollwork
AddArtifact(63409, 86864, 0,  35)  -- Ceramic Funeral Urn
AddArtifact(64362, 90504, 0,  35)  -- Dented Shield of Horuz Killcrow
AddArtifact(66054, 93440, 0,  30)  -- Dwarven Baby Socks
AddArtifact(64342, 90413, 0,  35)  -- Golden Chamber Pot
AddArtifact(64344, 90419, 0,  36)  -- Ironstar's Petrified Shield
AddArtifact(64368, 90518, 0,  35)  -- Mithril Chain of Angerforge
AddArtifact(63414, 89717, 0,  34)  -- Moltenfist's Jeweled Goblet
AddArtifact(64337, 90410, 0,  35)  -- Notched Sword of Tunadil the Redeemer
AddArtifact(63408, 86857, 0,  35)  -- Pewter Drinking Cup
AddArtifact(64659, 91793, 0,  45)  -- Pipe of Franclorn Forgewright
AddArtifact(64487, 91225, 0,  45)  -- Scepter of Bronzebeard
AddArtifact(64367, 90509, 0,  35)  -- Scepter of Charlga Razorflank
AddArtifact(64366, 90506, 0,  35)  -- Scorched Staff of Shadow Priest Anund
AddArtifact(64483, 91219, 0,  45)  -- Silver Kris of Korl
AddArtifact(63411, 88181, 0,  34)  -- Silver Neck Torc
AddArtifact(64371, 90519, 0,  35)  -- Skull Staff of Shadowforge
AddArtifact(64485, 91223, 0,  45)  -- Spiked Gauntlets of Anvilrage
AddArtifact(63410, 88180, 0,  35)  -- Stone Gryphon
AddArtifact(64484, 91221, 0,  45)  -- Warmaul of Burningeye
AddArtifact(64343, 90415, 0,  35)  -- Winged Helm of Corehammer
AddArtifact(63111, 88909, 0,  28)  -- Wooden Whistle
AddArtifact(64486, 91224, 0,  45)  -- Word of Empress Zoe
AddArtifact(63110, 86865, 0,  30)  -- Worn Hunting Knife

currentRace = RACE_DRAENEI
AddArtifact(64456, 90983, 3, 124)  -- Arrival of the Naaru
AddArtifact(64457, 90984, 3, 130)  -- The Last Relic of Argus

AddArtifact(64440, 90853, 0,  45)  -- Anklet with Golden Bells
AddArtifact(64453, 90968, 0,  46)  -- Baroque Sword Scabbard
AddArtifact(64442, 90860, 0,  45)  -- Carved Harp of Exotic Wood
AddArtifact(64455, 90975, 0,  45)  -- Dignified Portrait
AddArtifact(64454, 90974, 0,  44)  -- Fine Crystal Candelabra
AddArtifact(64458, 90987, 0,  45)  -- Plated Elekk Goad
AddArtifact(64444, 90864, 0,  46)  -- Scepter of the Nathrezim
AddArtifact(64443, 90861, 0,  46)  -- Strange Silver Paperweight


currentRace = RACE_FOSSIL
AddArtifact(60954, 90619, 4, 100)  -- Fossilized Raptor
AddArtifact(69764, 98533, 4, 150)  -- Extinct Turtle Shell
AddArtifact(60955, 89693, 3,  85)  -- Fossilized Hatchling
AddArtifact(69821, 98582, 3, 120)  -- Pterrodax Hatchling
AddArtifact(69776, 98560, 3, 100)  -- Ancient Amber

AddArtifact(64355, 90452, 0,  35)  -- Ancient Shark Jaws
AddArtifact(63121, 88930, 0,  25)  -- Beautiful Preserved Fern
AddArtifact(63109, 88929, 0,  31)  -- Black Trilobite
AddArtifact(64349, 90432, 0,  35)  -- Devilsaur Tooth
AddArtifact(64385, 90617, 0,  33)  -- Feathered Raptor Arm
AddArtifact(64473, 91132, 0,  45)  -- Imprint of a Kraken Tentacle
AddArtifact(64350, 90433, 0,  35)  -- Insect in Amber
AddArtifact(64468, 91089, 0,  45)  -- Proto-Drake Skeleton
AddArtifact(66056, 93442, 0,  30)  -- Shard of Petrified Wood
AddArtifact(66057, 93443, 0,  35)  -- Strange Velvet Worm
AddArtifact(63527, 89895, 0,  35)  -- Twisted Ammonite Shell
AddArtifact(64387, 90618, 0,  35)  -- Vicious Ancient Fish


currentRace = RACE_NIGHT_ELF
AddArtifact(64651, 91773, 4, 150)  -- Wisp Amulet
AddArtifact(64645, 91757, 4, 150)  -- Tyrande's Favorite Doll
AddArtifact(64646, 91761, 4, 150)  -- Bones of Transformation
AddArtifact(64643, 90616, 4, 100)  -- Queen Azshara's Dressing Gown
AddArtifact(64361, 90493, 3, 100)  -- Druid and Priest Statue Set
AddArtifact(64358, 90464, 3, 100)  -- Highborne Soul Mirror
AddArtifact(64383, 90614, 3,  98)  -- Kaldorei Wind Chimes

AddArtifact(64647, 91762, 0,  45)  -- Carcanet of the Hundred Magi
AddArtifact(64379, 90610, 0,  34)  -- Chest of Tiny Glass Animals
AddArtifact(63407, 89696, 0,  35)  -- Cloak Clasp with Antlers
AddArtifact(63525, 89893, 0,  35)  -- Coin from Eldre'Thalas
AddArtifact(64381, 90611, 0,  35)  -- Cracked Crystal Vial
AddArtifact(64357, 90458, 0,  35)  -- Delicate Music Box
AddArtifact(63528, 89896, 0,  35)  -- Green Dragon Ring
AddArtifact(64356, 90453, 0,  35)  -- Hairpin of Silver and Malachite
AddArtifact(63129, 89009, 0,  30)  -- Highborne Pyxis
AddArtifact(63130, 89012, 0,  30)  -- Inlaid Ivory Comb
AddArtifact(64354, 90451, 0,  35)  -- Kaldorei Amphora
AddArtifact(66055, 93441, 0,  30)  -- Necklace with Elune Pendant
AddArtifact(63131, 89014, 0,  30)  -- Scandalous Silk Nightgown
AddArtifact(64382, 90612, 0,  35)  -- Scepter of Xavius
AddArtifact(63526, 89894, 0,  35)  -- Shattered Glaive
AddArtifact(64648, 91766, 0,  45)  -- Silver Scroll Case
AddArtifact(64378, 90609, 0,  35)  -- String of Small Pink Pearls
AddArtifact(64650, 91769, 0,  45)  -- Umbra Crescent


currentRace = RACE_NERUBIAN
AddArtifact(64481, 91214, 4, 140)  -- Blessing of the Old God
AddArtifact(64482, 91215, 4, 140)  -- Puzzle Box of Yogg-Saron

AddArtifact(64479, 91209, 0,  45)  -- Ewer of Jormungar Blood
AddArtifact(64477, 91191, 0,  45)  -- Gruesome Heart Box
AddArtifact(64476, 91188, 0,  45)  -- Infested Ruby Ring
AddArtifact(64475, 91170, 0,  45)  -- Scepter of Nezar'Azret
AddArtifact(64478, 91197, 0,  45)  -- Six-Clawed Cornice
AddArtifact(64474, 91133, 0,  45)  -- Spidery Sundial
AddArtifact(64480, 91211, 0,  45)  -- Vizier's Scrawled Streamer


currentRace = RACE_ORC
AddArtifact(64644, 90843, 4, 130)  -- Headdress of the First Shaman

AddArtifact(64436, 90831, 0,  45)  -- Fiendish Whip
AddArtifact(64421, 90734, 0,  45)  -- Fierce Wolf Figurine
AddArtifact(64418, 90728, 0,  45)  -- Gray Candle Stub
AddArtifact(64417, 90720, 0,  45)  -- Maul of Stone Guard Mur'og
AddArtifact(64419, 90730, 0,  45)  -- Rusted Steak Knife
AddArtifact(64420, 90732, 0,  45)  -- Scepter of Nekros Skullcrusher
AddArtifact(64438, 90833, 0,  45)  -- Skull Drinking Cup
AddArtifact(64437, 90832, 0,  45)  -- Tile of Glazed Clay
AddArtifact(64389, 90622, 0,  45)  -- Tiny Bronze Scorpion


currentRace = RACE_TOL_VIR
AddArtifact(60847, 92137, 4, 150)  -- Crawling Claw
AddArtifact(64881, 92145, 4, 150)  -- Pendant of the Scarab Storm
AddArtifact(64904, 92168, 4, 150)  -- Ring of the Boy Emperor
AddArtifact(64883, 92148, 4, 150)  -- Scepter of Azj'Aqir
AddArtifact(64885, 92163, 4, 150)  -- Scimitar of the Sirocco
AddArtifact(64880, 92139, 4, 150)  -- Staff of Ammunae

AddArtifact(64657, 91790, 0,  45)  -- Canopic Jar
AddArtifact(64652, 91775, 0,  45)  -- Castle of Sand
AddArtifact(64653, 91779, 0,  45)  -- Cat Statue with Emerald Eyes
AddArtifact(64656, 91785, 0,  45)  -- Engraved Scimitar Hilt
AddArtifact(64658, 91792, 0,  45)  -- Sketch of a Desert Palace
AddArtifact(64654, 91780, 0,  45)  -- Soapstone Scarab Necklace
AddArtifact(64655, 91782, 0,  45)  -- Tiny Oasis Mosaic


currentRace = RACE_TROLL
AddArtifact(64377, 90608, 4, 150)  -- Zin'rokh, Destroyer of Worlds
AddArtifact(69824, 98588, 3, 100)  -- Voodoo Figurine
AddArtifact(69777, 98556, 3, 100)  -- Haunted War Drum

AddArtifact(64348, 90429, 0,  35)  -- Atal'ai Scepter
AddArtifact(64346, 90421, 0,  35)  -- Bracelet of Jade and Coins
AddArtifact(63524, 89891, 0,  35)  -- Cinnabar Bijou
AddArtifact(64375, 90581, 0,  35)  -- Drakkari Sacrificial Knife
AddArtifact(63523, 89890, 0,  35)  -- Eerie Smolderthorn Idol
AddArtifact(63413, 89711, 0,  34)  -- Feathered Gold Earring
AddArtifact(63120, 88907, 0,  30)  -- Fetish of Hir'eek
AddArtifact(66058, 93444, 0,  32)  -- Fine Bloodscalp Dinnerware
AddArtifact(64347, 90423, 0,  35)  -- Gahz'rilla Figurine
AddArtifact(63412, 89701, 0,  35)  -- Jade Asp with Ruby Eyes
AddArtifact(63118, 88908, 0,  32)  -- Lizard Foot Charm
AddArtifact(64345, 90420, 0,  35)  -- Skull-Shaped Planter
AddArtifact(64374, 90558, 0,  35)  -- Tooth with Gold Filling
AddArtifact(63115, 88262, 0,  27)  -- Zandalari Voodoo Doll


currentRace = RACE_VRYKUL
AddArtifact(64460, 90997, 4, 130)  -- Nifflevar Bearded Axe
AddArtifact(69775, 98569, 3, 100)  -- Vrykul Drinking Horn

AddArtifact(64464, 91014, 0,  45)  -- Fanged Cloak Pin
AddArtifact(64462, 91012, 0,  45)  -- Flint Striker
AddArtifact(64459, 90988, 0,  45)  -- Intricate Treasure Chest Key
AddArtifact(64461, 91008, 0,  45)  -- Scramseax
AddArtifact(64467, 91084, 0,  45)  -- Thorned Necklace

currentRace = RACE_MANTID
AddArtifact(95391, 139786, 3, 180)	-- Mantid Sky Reaver
AddArtifact(95392, 139787, 3, 180)	-- Sonic Pulse Generator

AddArtifact(95375, 139776, 0, 50)	-- Banner of the Mantid Empire
AddArtifact(95376, 139779, 0, 50)	-- Ancient Sap Feeder
AddArtifact(95377, 139780, 0, 50)	-- The Praying Mantid
AddArtifact(95378, 139781, 0, 50)	-- Inert Sound Beacon
AddArtifact(95379, 139782, 0, 50)	-- Remains of a Paragon
AddArtifact(95380, 139783, 0, 50)	-- Mantid Lamp
AddArtifact(95381, 139784, 0, 50)	-- Pollen Collector
AddArtifact(95382, 139785, 0, 50)	-- Kypari Sap Container

currentRace = RACE_PANDAREN
AddArtifact(89685, 113981, 3, 180)  -- Spear of Xuen
AddArtifact(89684, 113980, 3, 180)  -- Umbrella of Chi-Ji

AddArtifact(79903, 113977, 0,  50)  -- Apothecary Tins
AddArtifact(79901, 113975, 0,  50)  -- Carved Bronze Mirror
AddArtifact(79897, 113971, 0,  50)  -- Panderan Game Board
AddArtifact(79900, 113974, 0,  50)  -- Empty Keg of Brewfather Xin Wo Yin
AddArtifact(79902, 113976, 0,  50)  -- Gold-Inlaid Porecelain Funerary Figurine
AddArtifact(79904, 113978, 0,  50)  -- Pearl of Yu'lon
AddArtifact(79905, 113979, 0,  50)  -- Standard  of Niuzao
AddArtifact(79898, 113972, 0,  50)  -- Twin Stein Set of Brewfather Quan Tou Kuo
AddArtifact(79899, 113973, 0,  50)  -- Walking Cane of Brewfather Ren Yun
AddArtifact(79896, 113968, 0,  50)  -- Pandaren Tea Set


currentRace = RACE_MOGU
AddArtifact(89614, 113993, 3, 180)  -- Anatomical Dummy
AddArtifact(89611, 113992, 3, 180)  -- Quilen Statuette

AddArtifact(79909, 113983, 0,  50)  -- Cracked Mogu Runestone
AddArtifact(79913, 113987, 0,  50)  -- Edicts of the Thunder King
AddArtifact(79914, 113988, 0,  50)  -- Iron Amulet
AddArtifact(79908, 113982, 0,  50)  -- Manacles of Rebellion
AddArtifact(79916, 113990, 0,  50)  -- Mogu Coin
AddArtifact(79911, 113985, 0,  50)  -- Petrified Bone Whip
AddArtifact(79910, 113984, 0,  50)  -- Terracotta Arm
AddArtifact(79912, 113986, 0,  50)  -- Thunder King Insignia
AddArtifact(79915, 113989, 0,  50)  -- Warlord's Branding Iron
AddArtifact(79917, 113991, 0,  50)  -- Worn Monument Ledger

currentRace = RACE_ARAKKOA
AddArtifact(117382, 168331, 3, 190)  -- Beakbreaker of Terokk
AddArtifact(117354, 172460, 2, 250)  -- Ancient Nest Guardian

AddArtifact(114197, 168321, 0, 45)  -- Dreamcatcher
AddArtifact(114198, 168322, 0, 55)  -- Burial Urn
AddArtifact(114199, 168323, 0, 50)  -- Decree Scrolls
AddArtifact(114200, 168324, 0, 45)  -- Solar Orb
AddArtifact(114201, 168325, 0, 60)  -- Sundial
AddArtifact(114202, 168326, 0, 50)  -- Talonpriest Mask
AddArtifact(114203, 168327, 0, 45)  -- Outcast Dreamcatcher
AddArtifact(114204, 168328, 0, 70)  -- Apexis Crystal
AddArtifact(114205, 168329, 0, 65)  -- Apexis Hieroglyph
AddArtifact(114206, 168330, 0, 50)  -- Apexis Scroll

currentRace = RACE_DRAENOR_CLANS
AddArtifact(117380, 172466, 3, 175)  -- Ancient Frostwolf Fang
AddArtifact(116985, 172459, 3, 180)  -- Headdress of the First Shaman

AddArtifact(114141, 168290, 0, 50)  -- Fang-Scarred Frostwolf Axe
AddArtifact(114143, 168291, 0, 60)  -- Frostwolf Ancestry Scrimshaw
AddArtifact(114145, 168292, 0, 45)  -- Wolfskin Snowshoes
AddArtifact(114147, 168293, 0, 45)  -- Warsinger's Drums
AddArtifact(114149, 168294, 0, 55)  -- Screaming Bullroarer
AddArtifact(114151, 168295, 0, 60)  -- Warsong Ceremonial Pike
AddArtifact(114153, 168296, 0, 50)  -- Metalworker's Hammer
AddArtifact(114155, 168297, 0, 65)  -- Elemental Bellows
AddArtifact(114157, 168298, 0, 50)  -- Blackrock Razor
AddArtifact(114159, 168299, 0, 45)  -- Weighted Chopping Axe
AddArtifact(114161, 168300, 0, 60)  -- Hooked Dagger
AddArtifact(114163, 168301, 0, 45)  -- Barbed Fishing Hook
AddArtifact(114167, 168303, 0, 40)  -- Ceremonial Tattoo Needles
AddArtifact(114169, 168304, 0, 45)  -- Cracked Ivory Idol
AddArtifact(114171, 168305, 0, 55)  -- Ancestral Talisman
AddArtifact(114173, 168306, 0, 50)  -- Flask of Blazegrease
AddArtifact(114175, 168307, 0, 55)  -- Gronn-Tooth Necklace
AddArtifact(114177, 168308, 0, 40)  -- Doomsday Prophecy

currentRace = RACE_OGRE
AddArtifact(117384, 168320, 3, 200)  -- Warmaul of the Warmaul Chieftain
AddArtifact(117385, 168319, 3, 150)  -- Sorcerer-King Toe Ring

AddArtifact(114181, 168309, 0, 40)  -- Stonemaul Succession Stone
AddArtifact(114183, 168310, 0, 55)  -- Stone Manacles
AddArtifact(114185, 168311, 0, 45)  -- Ogre Figurine
AddArtifact(114187, 168312, 0, 55)  -- Pictogram Carving
AddArtifact(114189, 168313, 0, 50)  -- Gladiator's Shield
AddArtifact(114190, 168314, 0, 55)  -- Mortar and Pestle
AddArtifact(114191, 168315, 0, 70)  -- Eye of Har'gunn the Blind
AddArtifact(114192, 168316, 0, 50)  -- Stone Dentures
AddArtifact(114193, 168317, 0, 55)  -- Rylak Riding Harness
AddArtifact(114194, 168318, 0, 45)  -- Imperial Decree Stele
