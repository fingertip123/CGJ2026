tool
extends Node2D

const UnitData = preload("res://scripts/unit_data.gd")

signal ReachedGoal
signal Destroyed
signal LevelChanged(nLevel)
signal FuelDepleted
signal AnchorBrakeFinished

onready var pCamera = $Camera2D
onready var pAircraft = $Aircraft
onready var pThrusterFlame = $ThrusterFlame

export(float) var nLaunchSpeed = 85.0
export(float) var nMaxFlightTime = 40.0
export(float) var nMaxFuel = 80.0
export(float) var nStartFuel = 22.0
export(float) var nFuelBurnRate = 5.5
export(float) var nDistancePerFuel = 13.0
export(float) var nAnchorBrakeDecel = 100.0
export(float) var nAnchorBrakeStopSpeed = 6.0

var nLevel = 1
var nMaxHp = 500.0
var nHp = 500.0
var nFuel = 22.0
var nAnchorRadius = 120.0
var nAttackDamage = 8.0
var nAttackRange = 72.0
var nAttackInterval = 0.55
var nPathT = 0.0
var bMoving = false
var bHasThrust = false
var bBraking = false
var bFuelDepletedNotified = false
var nAttackCooldown = 0.0
var nFlightTime = 0.0
var vVelocity = Vector2.ZERO
var vSpawnPosition = Vector2.ZERO
var pRoute = null
var pGame = null

func Setup(pRouteManager, pGameNode) -> void:
    pRoute = pRouteManager
    pGame = pGameNode
    vSpawnPosition = global_position
    nFuel = clamp(nStartFuel, 0.0, nMaxFuel)
    _ApplyLevelStats(false)
    nPathT = 0.0
    bMoving = false
    bHasThrust = false
    bBraking = false
    bFuelDepletedNotified = false
    nFlightTime = 0.0
    vVelocity = Vector2.ZERO
    _UpdateThruster()
    update()

func ResetPathProgress() -> void:
    nPathT = 0.0
    bMoving = false
    bHasThrust = false
    bBraking = false
    bFuelDepletedNotified = false
    nFlightTime = 0.0
    vVelocity = Vector2.ZERO
    global_position = vSpawnPosition
    _UpdateThruster()
    update()

func ResetFlightState() -> void:
    nPathT = 0.0
    bMoving = false
    bHasThrust = false
    bBraking = false
    bFuelDepletedNotified = false
    nFlightTime = 0.0
    vVelocity = Vector2.ZERO
    _UpdateThruster()
    update()

func GetSpawnPosition() -> Vector2:
    return vSpawnPosition

func UpdateSpawnPosition() -> void:
    vSpawnPosition = global_position
    update()

func SetCameraActive(bActive: bool) -> void:
    if pCamera == null:
        return
    pCamera.current = bActive

func SetLaunchSpeed(nValue: float) -> void:
    nLaunchSpeed = max(1.0, nValue)

func GetVelocity() -> Vector2:
    return vVelocity

func GetLevelConfig() -> Dictionary:
    return UnitData.GetLevelConfig(nLevel)

func GetCardSlotCount() -> int:
    return GetLevelConfig().card_slots

func GetDroneMaxCount() -> int:
    return GetLevelConfig().drone_max

func GetMiningDroneMaxCount() -> int:
    return GetLevelConfig().mining_max

func GetFuel() -> float:
    return nFuel

func GetMaxFuel() -> float:
    return nMaxFuel

func GetFuelRatio() -> float:
    return clamp(nFuel / max(nMaxFuel, 0.001), 0.0, 1.0)

func IsCoasting() -> bool:
    return bMoving and not bHasThrust

func HasFuel() -> bool:
    return nFuel > 0.001

func ConsumeFuel(nAmount: float) -> void:
    if nAmount <= 0.0:
        return
    nFuel = max(0.0, nFuel - nAmount)
    update()

func IsFuelFull() -> bool:
    return nFuel >= nMaxFuel - 0.001

func AddFuel(nAmount: float) -> float:
    if nAmount <= 0.0:
        return 0.0
    var nAdded = min(nAmount, nMaxFuel - nFuel)
    nFuel += nAdded
    update()
    return nAdded

func GetUpgradeCost() -> int:
    return GetLevelConfig().upgrade_cost

func CanUpgrade() -> bool:
    return GetUpgradeCost() > 0

func UpgradeLevel() -> bool:
    if not CanUpgrade():
        return false
    var nOldMax = nMaxHp
    nLevel += 1
    _ApplyLevelStats(true)
    nHp += nMaxHp - nOldMax
    emit_signal("LevelChanged", nLevel)
    update()
    return true

func _ApplyLevelStats(bKeepHpRatio: bool) -> void:
    var oCfg = GetLevelConfig()
    var nRatio = GetHpRatio() if bKeepHpRatio and nMaxHp > 0.0 else 1.0
    nMaxHp = oCfg.hp
    nHp = nMaxHp * nRatio if bKeepHpRatio else nMaxHp
    nAnchorRadius = oCfg.radius
    nAttackDamage = oCfg.attack
    nAttackRange = oCfg.attack_range

func StartMarch() -> void:
    if pRoute != null and pRoute.has_method("HasRoute") and not pRoute.HasRoute():
        return
    if not HasFuel():
        return
    nPathT = 0.0
    nFlightTime = 0.0
    vVelocity = pRoute.GetDirection() * nLaunchSpeed if pRoute != null and pRoute.has_method("GetDirection") else Vector2.RIGHT * nLaunchSpeed
    bMoving = true
    bHasThrust = true
    bFuelDepletedNotified = false
    _UpdateHeading()
    _UpdateThruster()

func StopMarch() -> void:
    bMoving = false
    bHasThrust = false
    bBraking = false
    vVelocity = Vector2.ZERO
    _UpdateThruster()

func StartAnchorBrake() -> void:
    if not bMoving:
        return
    bHasThrust = false
    bBraking = true

func IsBraking() -> bool:
    return bBraking

func _FinishAnchorBrake() -> void:
    bMoving = false
    bBraking = false
    vVelocity = Vector2.ZERO
    _UpdateThruster()
    emit_signal("AnchorBrakeFinished")

func IsInsideAnchorZone(vWorldPos: Vector2) -> bool:
    return global_position.distance_to(vWorldPos) <= nAnchorRadius

func TakeDamage(nAmount: float) -> void:
    if nHp <= 0.0:
        return
    nHp -= nAmount
    update()
    if nHp <= 0.0:
        bMoving = false
        bBraking = false
        _UpdateThruster()
        emit_signal("Destroyed")

func GetHpRatio() -> float:
    return clamp(nHp / nMaxHp, 0.0, 1.0)

func _UpdateHeading() -> void:
    if pAircraft == null or vVelocity.length_squared() <= 0.001:
        return
    pAircraft.rotation = vVelocity.angle() + PI * 0.5

func _UpdateThruster() -> void:
    if pThrusterFlame == null:
        return
    var bShowFlame = bMoving and bHasThrust and HasFuel() and vVelocity.length_squared() > 1.0
    pThrusterFlame.SetActive(bShowFlame)

func _process(delta: float) -> void:
    if Engine.editor_hint:
        update()
        return

    if bMoving:
        nFlightTime += delta
        if pRoute != null and pRoute.has_method("GetGravityAcceleration"):
            vVelocity += pRoute.GetGravityAcceleration(global_position) * delta
        if bBraking:
            var nSpeed = vVelocity.length()
            if nSpeed <= nAnchorBrakeStopSpeed:
                _FinishAnchorBrake()
            else:
                var nDecel = min(nAnchorBrakeDecel * delta, nSpeed)
                vVelocity -= vVelocity.normalized() * nDecel
        elif bHasThrust:
            if HasFuel():
                ConsumeFuel(nFuelBurnRate * delta)
            if not HasFuel():
                bHasThrust = false
                if not bFuelDepletedNotified:
                    bFuelDepletedNotified = true
                    emit_signal("FuelDepleted")
        global_position += vVelocity * delta
        nPathT = clamp(nFlightTime / max(nMaxFlightTime, 0.001), 0.0, 1.0)
        _UpdateHeading()

    _UpdateThruster()

    if pGame != null and pGame.IsMarchRunning():
        nAttackCooldown -= delta
        if nAttackCooldown <= 0.0:
            var pTarget = pGame.GetNearestMonsterInRange(global_position, nAttackRange)
            if pTarget != null:
                nAttackCooldown = nAttackInterval
                pTarget.TakeDamage(nAttackDamage)

    update()

func _draw() -> void:
    draw_circle(Vector2.ZERO, nAnchorRadius, Color(0.2, 0.75, 1.0, 0.08))
    draw_arc(Vector2.ZERO, nAnchorRadius, 0.0, TAU, 64, Color(0.35, 0.85, 1.0, 0.45), 2.0, true)
    draw_arc(Vector2.ZERO, nAnchorRadius * 0.65, 0.0, TAU, 48, Color(0.55, 0.8, 1.0, 0.08), 1.0, true)
    draw_arc(Vector2.ZERO, nAttackRange, 0.0, TAU, 48, Color(0.55, 0.8, 1.0, 0.1), 1.0, true)

    var nRatio = GetHpRatio()
    draw_rect(Rect2(Vector2(-24, -34), Vector2(48, 6)), Color(0.15, 0.08, 0.08))
    draw_rect(Rect2(Vector2(-24, -34), Vector2(48 * nRatio, 6)), Color(0.25, 0.95, 0.45))

    var nFuelRatio = GetFuelRatio()
    draw_rect(Rect2(Vector2(-24, -42), Vector2(48, 5)), Color(0.08, 0.1, 0.14))
    draw_rect(Rect2(Vector2(-24, -42), Vector2(48 * nFuelRatio, 5)), Color(0.35, 0.85, 1.0))
