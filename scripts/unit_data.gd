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

const PLANET_TEXTURE = preload("res://images/planet.png")
const PLANET_SIZE_SCALE = 1.55

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

const SHIP_PULSE_TEXTURE = preload("res://images/pulseBulllet.png")
const SHIP_PULSE_TEXTURE_SCALE = 0.011
const SHIP_PULSE_LAUNCH_SOUND = preload("res://music/pulseBullet.mp3")
const SHIP_PULSE_SPEED = 400.0

const ENEMY_DRONE_STATS = {
    "hp": 45.0,
    "damage": 8.0,
    "interval": 0.8,
    "move_speed": 140.0,
}

const ENEMY_BASE_GUARD_STATS = {
    "hp": 72.0,
    "damage": 12.0,
    "interval": 0.65,
    "move_speed": 190.0,
}

const ENEMY_BASE_TEXTURE = preload("res://images/enemyBase.png")

const MAP_SCALE = 6.0
const MAP_BASE_SIZE = Vector2(1600, 790)

const ENEMY_BASE_STATS = {
    "body_radius": 104.0,
    "guard_count": 56,
    "guard_orbit_radius": 330.0,
    "guard_orbit_speed": 1.35,
    "alert_radius": 520.0,
    "patrol_radius": 110.0,
    "patrol_speed": 10.0,
    "shock_stun_duration": 1.5,
    "shock_speed_cap": 10.0,
}

const DRONE_STATS = {
    DroneType.SHIELD: {
        "hp": 120.0,
        "damage": 7.0,
        "range": 38.0,
        "interval": 0.65,
        "move_speed": 130.0,
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
        "move_speed": 145.0,
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
        "move_speed": 160.0,
        "orbit_speed": 2.0,
        "orbit_radius_ratio": 0.56,
        "cost": 20,
        "taunt": false,
        "taunt_range": 0.0,
        "color": Color(0.95, 0.85, 0.4),
    },
}

const MINING_STATS = {
    "move_speed": 155.0,
    "orbit_speed": 1.4,
    "orbit_radius_ratio": 0.42,
    "mine_range": 1000.0,
    "mine_time_min": 1.0,
    "mine_time_max": 2.0,
    "fuel_per_trip": 12.0,
    "gold_per_trip": 10,
    "cost": 22,
    "color": Color(0.95, 0.72, 0.25),
}

const SHIP_LEVELS = [
    {"card_slots": 2, "drone_max": 4, "mining_max": 2, "hp": 500.0, "attack": 8.0, "attack_range": 72.0, "attack_interval": 0.55, "radius": 120.0, "escort_detect_radius": 145.0, "scale": 1.0, "upgrade_cost": 80},
    {"card_slots": 3, "drone_max": 20, "mining_max": 12, "hp": 650.0, "attack": 11.0, "attack_range": 82.0, "attack_interval": 0.47, "radius": 276.0, "escort_detect_radius": 356.0, "scale": 1.1, "upgrade_cost": 150},
    {"card_slots": 4, "drone_max": 30, "mining_max": 16, "hp": 820.0, "attack": 14.0, "attack_range": 92.0, "attack_interval": 0.40, "radius": 312.0, "escort_detect_radius": 430.0, "scale": 1.2, "upgrade_cost": 250},
    {"card_slots": 5, "drone_max": 40, "mining_max": 10, "hp": 1000.0, "attack": 18.0, "attack_range": 102.0, "attack_interval": 0.34, "radius": 348.0, "escort_detect_radius": 255.0, "scale": 1.3, "upgrade_cost": -1},
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

static func GetPlanetTexture():
    return PLANET_TEXTURE

static func GetPlanetSizeScale() -> float:
    return PLANET_SIZE_SCALE

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

static func GetEnemyBaseGuardStats() -> Dictionary:
    return ENEMY_BASE_GUARD_STATS

static func GetEnemyBaseStats() -> Dictionary:
    return ENEMY_BASE_STATS

static func GetEnemyBaseShockStunDuration() -> float:
    return ENEMY_BASE_STATS.shock_stun_duration

static func GetEnemyBaseShockSpeedCap() -> float:
    return ENEMY_BASE_STATS.shock_speed_cap

static func GetEnemyBaseTexture():
    return ENEMY_BASE_TEXTURE

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

static func GetShipPulseTexture():
    return SHIP_PULSE_TEXTURE

static func GetShipPulseTextureScale() -> float:
    return SHIP_PULSE_TEXTURE_SCALE

static func GetShipPulseLaunchSound():
    return SHIP_PULSE_LAUNCH_SOUND

static func GetShipPulseSpeed() -> float:
    return SHIP_PULSE_SPEED

static func GetMinEscortAttackRange() -> float:
    var nMinRange = INF
    for nType in DRONE_STATS.keys():
        var nRange = DRONE_STATS[nType].range
        if nRange < nMinRange:
            nMinRange = nRange
    return nMinRange

static func GetMiningStats() -> Dictionary:
    return MINING_STATS

static func GetMiningRange() -> float:
    return MINING_STATS.mine_range

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

static func GenerateStartingCardPool(nSlots: int) -> Array:
    var vCards = []
    if nSlots <= 0:
        return vCards
    if nSlots == 1:
        vCards.append(GenerateMiningCard())
        return vCards
    var nMiningSlot = randi() % 2
    for i in range(nSlots):
        if i == nMiningSlot:
            vCards.append(GenerateMiningCard())
        elif i < 2:
            vCards.append(GenerateRandomEscortCard())
        else:
            vCards.append(GenerateRandomCard())
    return vCards

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

static func GetMapScale() -> float:
    return MAP_SCALE

static func GetMapBounds() -> Rect2:
    return Rect2(Vector2.ZERO, MAP_BASE_SIZE * MAP_SCALE)

static func GetMapStart() -> Vector2:
    return Vector2(140, 740) * MAP_SCALE

static func GetMapAnchor() -> Vector2:
    return Vector2(1480, 120) * MAP_SCALE

static func GetMapDefaultDirectionHandle() -> Vector2:
    return Vector2(360, 650) * MAP_SCALE

static func GetMapMaxRouteLength() -> float:
    return 820.0 * MAP_SCALE

static func GetMapPreviewBounds() -> Rect2:
    return Rect2(-3600, -3600, 16800, 12600)

static func GetMapPreviewMaxDistance() -> float:
    return 36000.0

static func GetLateEnemyBaseSpawnRatio() -> float:
    return 0.42
