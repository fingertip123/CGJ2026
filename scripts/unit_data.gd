extends Reference

enum DroneType { SHIELD, BEAM, STRIKE }

const DRONE_NAMES = {
    DroneType.SHIELD: "Shield Escort",
    DroneType.BEAM: "Beam Escort",
    DroneType.STRIKE: "Strike Escort",
}

const DRONE_STATS = {
    DroneType.SHIELD: {
        "hp": 120.0,
        "damage": 7.0,
        "range": 38.0,
        "interval": 0.65,
        "move_speed": 80.0,
        "orbit_speed": 1.2,
        "orbit_radius_ratio": 0.50,
        "cost": 30,
        "taunt": true,
        "taunt_range": 105.0,
        "color": Color(0.45, 0.7, 1.0),
    },
    DroneType.BEAM: {
        "hp": 42.0,
        "damage": 22.0,
        "range": 118.0,
        "interval": 0.5,
        "move_speed": 95.0,
        "orbit_speed": 1.6,
        "orbit_radius_ratio": 0.62,
        "cost": 25,
        "taunt": false,
        "taunt_range": 0.0,
        "color": Color(0.35, 0.95, 0.75),
    },
    DroneType.STRIKE: {
        "hp": 70.0,
        "damage": 15.0,
        "range": 50.0,
        "interval": 0.45,
        "move_speed": 110.0,
        "orbit_speed": 2.0,
        "orbit_radius_ratio": 0.56,
        "cost": 20,
        "taunt": false,
        "taunt_range": 0.0,
        "color": Color(0.95, 0.85, 0.4),
    },
}

const SHIP_LEVELS = [
    {"card_slots": 2, "drone_max": 4, "hp": 500.0, "attack": 8.0, "attack_range": 72.0, "radius": 120.0, "upgrade_cost": 80},
    {"card_slots": 3, "drone_max": 6, "hp": 650.0, "attack": 10.0, "attack_range": 78.0, "radius": 135.0, "upgrade_cost": 150},
    {"card_slots": 4, "drone_max": 8, "hp": 820.0, "attack": 12.0, "attack_range": 84.0, "radius": 150.0, "upgrade_cost": 250},
    {"card_slots": 5, "drone_max": 10, "hp": 1000.0, "attack": 15.0, "attack_range": 90.0, "radius": 165.0, "upgrade_cost": -1},
]

static func GetDroneStats(nType: int) -> Dictionary:
    return DRONE_STATS[nType]

static func GetDroneName(nType: int) -> String:
    return DRONE_NAMES[nType]

static func GenerateRandomDroneCard() -> Dictionary:
    var vTypes = [DroneType.SHIELD, DroneType.BEAM, DroneType.STRIKE]
    var nType = vTypes[randi() % vTypes.size()]
    var oStats = GetDroneStats(nType)
    return {"type": nType, "cost": oStats.cost}

static func GetLevelConfig(nLevel: int) -> Dictionary:
    var nIndex = clamp(nLevel - 1, 0, SHIP_LEVELS.size() - 1)
    return SHIP_LEVELS[nIndex]

static func GetMaxLevel() -> int:
    return SHIP_LEVELS.size()

static func GetOrbitSlotAngle(nIndex: int, nTotal: int) -> float:
    if nTotal <= 0:
        return 0.0
    return TAU * float(nIndex) / float(nTotal)
