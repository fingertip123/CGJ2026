extends Reference

enum CardKind { SOLDIER, TOWER }
enum SoldierType { TANK, ARCHER, WARRIOR }
enum TowerType { ARROW, CANNON }

const SOLDIER_NAMES = {
	SoldierType.TANK: "Tank",
	SoldierType.ARCHER: "Archer",
	SoldierType.WARRIOR: "Warrior",
}

const TOWER_NAMES = {
	TowerType.ARROW: "Arrow Tower",
	TowerType.CANNON: "Cannon Tower",
}

const SOLDIER_STATS = {
	SoldierType.TANK: {
		"hp": 130.0,
		"damage": 6.0,
		"range": 36.0,
		"interval": 0.7,
		"move_speed": 75.0,
		"cost": 30,
		"taunt": true,
		"taunt_range": 110.0,
		"color": Color(0.45, 0.65, 0.95),
	},
	SoldierType.ARCHER: {
		"hp": 45.0,
		"damage": 20.0,
		"range": 115.0,
		"interval": 0.55,
		"move_speed": 90.0,
		"cost": 25,
		"taunt": false,
		"taunt_range": 0.0,
		"color": Color(0.35, 0.9, 0.55),
	},
	SoldierType.WARRIOR: {
		"hp": 75.0,
		"damage": 14.0,
		"range": 48.0,
		"interval": 0.5,
		"move_speed": 105.0,
		"cost": 20,
		"taunt": false,
		"taunt_range": 0.0,
		"color": Color(0.95, 0.8, 0.35),
	},
}

const TOWER_STATS = {
	TowerType.ARROW: {
		"damage": 28.0,
		"range": 95.0,
		"interval": 0.35,
		"cost": 35,
		"color": Color(0.2, 0.85, 0.55),
	},
	TowerType.CANNON: {
		"damage": 45.0,
		"range": 75.0,
		"interval": 0.65,
		"cost": 40,
		"color": Color(0.85, 0.45, 0.25),
	},
}

const BASE_LEVELS = [
	{"card_slots": 2, "tower_slots": 2, "hp": 500.0, "attack": 8.0, "attack_range": 72.0, "radius": 120.0, "upgrade_cost": 80},
	{"card_slots": 3, "tower_slots": 3, "hp": 650.0, "attack": 10.0, "attack_range": 78.0, "radius": 135.0, "upgrade_cost": 150},
	{"card_slots": 4, "tower_slots": 4, "hp": 820.0, "attack": 12.0, "attack_range": 84.0, "radius": 150.0, "upgrade_cost": 250},
	{"card_slots": 5, "tower_slots": 5, "hp": 1000.0, "attack": 15.0, "attack_range": 90.0, "radius": 165.0, "upgrade_cost": -1},
]

static func GetSoldierStats(nType: int) -> Dictionary:
	return SOLDIER_STATS[nType]

static func GetTowerStats(nType: int) -> Dictionary:
	return TOWER_STATS[nType]

static func GetCardDisplayName(oCard: Dictionary) -> String:
	if oCard.kind == CardKind.SOLDIER:
		return SOLDIER_NAMES[oCard.type]
	return TOWER_NAMES[oCard.type]

static func GenerateRandomCard() -> Dictionary:
	if randf() < 0.55:
		var nType = [SoldierType.TANK, SoldierType.ARCHER, SoldierType.WARRIOR][randi() % 3]
		var oStats = GetSoldierStats(nType)
		return {"kind": CardKind.SOLDIER, "type": nType, "cost": oStats.cost}
	var nType = TowerType.ARROW if randf() < 0.6 else TowerType.CANNON
	var oTower = GetTowerStats(nType)
	return {"kind": CardKind.TOWER, "type": nType, "cost": oTower.cost}

static func GetLevelConfig(nLevel: int) -> Dictionary:
	var nIndex = clamp(nLevel - 1, 0, BASE_LEVELS.size() - 1)
	return BASE_LEVELS[nIndex]

static func GetMaxLevel() -> int:
	return BASE_LEVELS.size()

static func GetTowerSlotOffset(nIndex: int, nTotal: int, nRadius: float) -> Vector2:
	if nTotal <= 0:
		return Vector2.ZERO
	var nAngle = TAU * float(nIndex) / float(nTotal) - PI * 0.5
	var nDist = nRadius * 0.62
	return Vector2(cos(nAngle), sin(nAngle)) * nDist
