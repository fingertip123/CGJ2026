extends Reference

enum DroneType { SHIELD, BEAM, STRIKE }
enum CardKind { ESCORT, MINING }

const DRONE_NAMES = {
    DroneType.SHIELD: "Shield Escort",
    DroneType.BEAM: "Beam Escort",
    DroneType.STRIKE: "Strike Escort",
}

const MINING_DRONE_NAME = "Mining Drone"

const SHIP_TEXTURE = preload("res://images/aircraft.png")
const SHIP_TEXTURE_SCALE = 0.029

const DRONE_TEXTURES = {
    DroneType.SHIELD: preload("res://images/shield-type drone.png"),
    DroneType.BEAM: preload("res://images/pulse-type drone.png"),
    DroneType.STRIKE: preload("res://images/attackAircraft.png"),
}

const DRONE_TEXTURE_SCALES = {
    DroneType.SHIELD: 0.015,
    DroneType.BEAM: 0.013,
    DroneType.STRIKE: 0.013,
}

const MINING_TEXTURE = preload("res://images/miningDrone.png")
const MINING_TEXTURE_SCALE = 0.011

const MISSILE_TEXTURE = preload("res://images/Bullet.png")
const MISSILE_TEXTURE_SCALE = 0.010
const MISSILE_LAUNCH_SOUND = preload("res://music/bullet.mp3")
const MISSILE_SPEED = 360.0

const ENEMY_DRONE_TEXTURE = preload("res://images/anemy.png")
const ENEMY_DRONE_TEXTURE_SCALE = 0.013

const ENEMY_MISSILE_TEXTURE = preload("res://images/enemy_bullet.png")
const ENEMY_MISSILE_TEXTURE_SCALE = 0.008
const ENEMY_MISSILE_LAUNCH_SOUND = preload("res://music/enemy_bullet.mp3")
const ENEMY_MISSILE_SPEED = 320.0

const ENEMY_DRONE_STATS = {
    "hp": 45.0,
    "damage": 8.0,
    "interval": 0.8,
    "move_speed": 85.0,
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

const MINING_STATS = {
    "move_speed": 105.0,
    "orbit_speed": 1.4,
    "orbit_radius_ratio": 0.42,
    "mine_time_min": 1.0,
    "mine_time_max": 2.0,
    "fuel_per_trip": 12.0,
    "gold_per_trip": 10,
    "cost": 22,
    "color": Color(0.95, 0.72, 0.25),
}

const SHIP_LEVELS = [
    {"card_slots": 2, "drone_max": 4, "mining_max": 2, "hp": 500.0, "attack": 8.0, "attack_range": 72.0, "radius": 120.0, "upgrade_cost": 80},
    {"card_slots": 3, "drone_max": 6, "mining_max": 3, "hp": 650.0, "attack": 10.0, "attack_range": 78.0, "radius": 135.0, "upgrade_cost": 150},
    {"card_slots": 4, "drone_max": 8, "mining_max": 4, "hp": 820.0, "attack": 12.0, "attack_range": 84.0, "radius": 150.0, "upgrade_cost": 250},
    {"card_slots": 5, "drone_max": 10, "mining_max": 5, "hp": 1000.0, "attack": 15.0, "attack_range": 90.0, "radius": 165.0, "upgrade_cost": -1},
]

static func GetDroneStats(nType: int) -> Dictionary:
    return DRONE_STATS[nType]

static func GetDroneName(nType: int) -> String:
    return DRONE_NAMES[nType]

static func GetDroneTexture(nType: int):
    return DRONE_TEXTURES.get(nType, DRONE_TEXTURES[DroneType.STRIKE])

static func GetDroneTextureScale(nType: int) -> float:
    return DRONE_TEXTURE_SCALES.get(nType, 0.013)

static func GetMiningTexture():
    return MINING_TEXTURE

static func GetMiningTextureScale() -> float:
    return MINING_TEXTURE_SCALE

static func GetMissileTexture():
    return MISSILE_TEXTURE

static func GetMissileTextureScale() -> float:
    return MISSILE_TEXTURE_SCALE

static func GetMissileLaunchSound():
    return MISSILE_LAUNCH_SOUND

static func GetMissileSpeed() -> float:
    return MISSILE_SPEED

static func GetEnemyDroneStats() -> Dictionary:
    return ENEMY_DRONE_STATS

static func GetEnemyDroneTexture():
    return ENEMY_DRONE_TEXTURE

static func GetEnemyDroneTextureScale() -> float:
    return ENEMY_DRONE_TEXTURE_SCALE

static func GetEnemyMissileTexture():
    return ENEMY_MISSILE_TEXTURE

static func GetEnemyMissileTextureScale() -> float:
    return ENEMY_MISSILE_TEXTURE_SCALE

static func GetEnemyMissileLaunchSound():
    return ENEMY_MISSILE_LAUNCH_SOUND

static func GetEnemyMissileSpeed() -> float:
    return ENEMY_MISSILE_SPEED

static func GetMinEscortAttackRange() -> float:
    var nMinRange = INF
    for nType in DRONE_STATS.keys():
        var nRange = DRONE_STATS[nType].range
        if nRange < nMinRange:
            nMinRange = nRange
    return nMinRange

static func GetMiningStats() -> Dictionary:
    return MINING_STATS

static func GetMiningName() -> String:
    return MINING_DRONE_NAME

static func GenerateRandomCard() -> Dictionary:
    if randf() < 0.32:
        return GenerateMiningCard()
    return GenerateRandomEscortCard()

static func GenerateRandomEscortCard() -> Dictionary:
    var vTypes = [DroneType.SHIELD, DroneType.BEAM, DroneType.STRIKE]
    var nType = vTypes[randi() % vTypes.size()]
    var oStats = GetDroneStats(nType)
    return {"kind": CardKind.ESCORT, "type": nType, "cost": oStats.cost}

static func GenerateMiningCard() -> Dictionary:
    return {"kind": CardKind.MINING, "type": 0, "cost": MINING_STATS.cost}

static func GenerateRandomDroneCard() -> Dictionary:
    return GenerateRandomEscortCard()

static func GetCardName(oCard: Dictionary) -> String:
    if oCard.get("kind", CardKind.ESCORT) == CardKind.MINING:
        return GetMiningName()
    return GetDroneName(oCard.type)

static func GetLevelConfig(nLevel: int) -> Dictionary:
    var nIndex = clamp(nLevel - 1, 0, SHIP_LEVELS.size() - 1)
    return SHIP_LEVELS[nIndex]

static func GetMaxLevel() -> int:
    return SHIP_LEVELS.size()

static func GetOrbitSlotAngle(nIndex: int, nTotal: int) -> float:
    if nTotal <= 0:
        return 0.0
    return TAU * float(nIndex) / float(nTotal)
