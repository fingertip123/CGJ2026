extends Node2D

const UnitData = preload("res://scripts/unit_data.gd")

signal ReachedGoal
signal Destroyed
signal LevelChanged(nLevel)

onready var pCamera = $Camera2D

export(float) var nLaunchSpeed = 140.0

var nLevel = 1
var nMaxHp = 500.0
var nHp = 500.0
var nAnchorRadius = 120.0
var nAttackDamage = 8.0
var nAttackRange = 72.0
var nAttackInterval = 0.55
var bMoving = false
var nAttackCooldown = 0.0
var nFlightTime = 0.0
var vVelocity = Vector2.ZERO
var pRoute = null
var pGame = null

func Setup(pRouteManager, pGameNode) -> void:
    pRoute = pRouteManager
    pGame = pGameNode
    _ApplyLevelStats(false)
    bMoving = false
    nFlightTime = 0.0
    vVelocity = Vector2.ZERO
    if pRoute != null:
        position = pRoute.GetStartPosition()
    update()

func ResetPathProgress() -> void:
    bMoving = false
    nFlightTime = 0.0
    vVelocity = Vector2.ZERO
    if pRoute != null:
        position = pRoute.GetStartPosition()
    update()

func SetCameraActive(bActive: bool) -> void:
    if pCamera == null:
        return
    pCamera.current = bActive

func SetLaunchSpeed(nValue: float) -> void:
    nLaunchSpeed = max(1.0, nValue)

func GetLevelConfig() -> Dictionary:
    return UnitData.GetLevelConfig(nLevel)

func GetCardSlotCount() -> int:
    return GetLevelConfig().card_slots

func GetDroneMaxCount() -> int:
    return GetLevelConfig().drone_max

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
    nFlightTime = 0.0
    vVelocity = pRoute.GetDirection() * nLaunchSpeed if pRoute != null and pRoute.has_method("GetDirection") else Vector2.RIGHT * nLaunchSpeed
    bMoving = true

func StopMarch() -> void:
    bMoving = false
    vVelocity = Vector2.ZERO

func GetVelocity() -> Vector2:
    return vVelocity

func IsInsideAnchorZone(vWorldPos: Vector2) -> bool:
    return global_position.distance_to(vWorldPos) <= nAnchorRadius

func TakeDamage(nAmount: float) -> void:
    if nHp <= 0.0:
        return
    nHp -= nAmount
    update()
    if nHp <= 0.0:
        bMoving = false
        emit_signal("Destroyed")

func GetHpRatio() -> float:
    return clamp(nHp / nMaxHp, 0.0, 1.0)

func _process(delta: float) -> void:
    if bMoving and pRoute != null and (not pRoute.has_method("HasRoute") or pRoute.HasRoute()):
        nFlightTime += delta
        if pRoute.has_method("GetGravityAcceleration"):
            vVelocity += pRoute.GetGravityAcceleration(global_position) * delta
        global_position += vVelocity * delta

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

    draw_rect(Rect2(Vector2(-22, -22), Vector2(44, 44)), Color(0.25, 0.55, 0.95))
    draw_rect(Rect2(Vector2(-14, -14), Vector2(28, 28)), Color(0.55, 0.8, 1.0))
    draw_line(Vector2(-8, 0), Vector2(8, 0), Color(0.8, 0.95, 1.0), 2.0, true)

    var nRatio = GetHpRatio()
    draw_rect(Rect2(Vector2(-24, -34), Vector2(48, 6)), Color(0.15, 0.08, 0.08))
    draw_rect(Rect2(Vector2(-24, -34), Vector2(48 * nRatio, 6)), Color(0.25, 0.95, 0.45))
