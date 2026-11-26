--!strict
-- Cosmetic items. They are built from parts in OutfitBuilder.
-- assetId is optional. Leave it "" until you upload a mesh or accessory, then
-- OutfitBuilder will try that id before the procedural shape.

export type ItemInfo = {
	id: string,
	name: string,
	style: string,
	assetId: string,
}

local function item(id: string, name: string, style: string): ItemInfo
	return {
		id = id,
		name = name,
		style = style,
		assetId = "",
	}
end

local categories: { [string]: { ItemInfo } } = {
	Headgear = {
		item("SweepVisor", "Sweep Visor", "visor"),
		item("HalfMask", "Half Mask", "mask"),
		item("CrestHelm", "Crest Helm", "helm"),
		item("PlainCrown", "Plain Crown", "crown"),
		item("ArcTiara", "Arc Tiara", "tiara"),
		item("HoodWrap", "Hood Wrap", "hood"),
	},
	Suits = {
		item("ChestPlate", "Chest Plate", "plate"),
		item("FieldVest", "Field Vest", "vest"),
		item("ShortJacket", "Short Jacket", "jacket"),
		item("PlateTorso", "Plate Torso", "armor"),
		item("SleekSuit", "Sleek Suit", "suit"),
		item("WrapTop", "Wrap Top", "wrap"),
	},
	Pants = {
		item("CargoLegs", "Cargo Legs", "cargo"),
		item("PlateLegs", "Plate Legs", "legplate"),
		item("Shorts", "Shorts", "shorts"),
		item("SuitPants", "Suit Pants", "suitpants"),
		item("Greaves", "Greaves", "greaves"),
		item("WrapLegs", "Wrap Legs", "legwrap"),
	},
	Capes = {
		item("ShortCape", "Short Cape", "shortcape"),
		item("LongCape", "Long Cape", "longcape"),
		item("Scarf", "Scarf", "scarf"),
		item("SplitCape", "Split Cape", "split"),
		item("CollarCape", "High Collar", "collar"),
		item("ShoulderDrape", "Shoulder Drape", "drape"),
	},
	Gloves = {
		item("HandWraps", "Hand Wraps", "wraps"),
		item("Gauntlets", "Gauntlets", "gauntlet"),
		item("Fingerless", "Fingerless", "fingerless"),
		item("Bracers", "Bracers", "bracer"),
		item("ClawTips", "Claw Tips", "claws"),
		item("Cuffs", "Cuffs", "cuffs"),
	},
	Boots = {
		item("AnkleBoots", "Ankle Boots", "ankle"),
		item("Runners", "Runners", "runner"),
		item("ArmoredBoots", "Armored Boots", "armored"),
		item("Sandals", "Sandals", "sandal"),
		item("ShinGuards", "Shin Guards", "shin"),
		item("HighBoots", "High Boots", "high"),
	},
	Auras = {
		item("SparkAura", "Spark Aura", "spark"),
		item("FlameAura", "Flame Aura", "flame"),
		item("FrostAura", "Frost Aura", "frost"),
		item("SmokeAura", "Smoke Aura", "smoke"),
		item("BoltAura", "Bolt Aura", "bolt"),
		item("ShineAura", "Shine Aura", "shine"),
	},
}

local order = { "Headgear", "Suits", "Pants", "Capes", "Gloves", "Boots", "Auras" }

local byId: { [string]: ItemInfo } = {}
for _, list in categories do
	for _, info in list do
		byId[info.id] = info
	end
end

local OutfitCatalog = {
	Categories = categories,
	Order = order,
	ById = byId,
}

function OutfitCatalog.Find(category: string, id: string): ItemInfo?
	local list = categories[category]
	if not list then
		return nil
	end
	for _, info in list do
		if info.id == id then
			return info
		end
	end
	return nil
end

return OutfitCatalog
