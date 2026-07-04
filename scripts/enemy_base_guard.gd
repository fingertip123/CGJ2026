extends Node2D

const UnitData = preload("res://scripts/unit_data.gd")

signal Died(pGuard)

enum GuardState { ORBIT, AGGRO }

var nMaxHp = 45.0
var nHp = 45.0
var nMoveSpeed = 85.0
var nAttackDamage = 8.0
var nAttackInterval = 0.8
var nAttackRange = 32.0
var nOrbitRadius = 115.0
var nOrbitSpeed = 1.35
var nOrbitAngle = 0.0
var nOrbitSlotOffset = 0.0
var nAttackCooldown = 0.0
var nState = GuardState.ORBIT
var pGame = null
var pBase = null
var bActive = true

onready var pSprite = $Sprite

func Setup(pGameNode, pBaseNode, nSlotIndex: int, nSlotTotal: int) -> void:
    pGame = pGameNode
    pBase = pBaseNode
    nOrbitSlotOffset = UnitData.GetOrbitSlotAngle(nSlotIndex, nSlotTotal)

    var oStats = UnitData.GetEnemyDroneStats()
    var oBaseStats = UnitData.GetEnemyBaseStats()
    nMaxHp = oStats.hp
    nHp = nMaxHp
    nMoveSpeed = oStats.move_speed
    nAttackDamage = oStats.damage
    nAttackInterval = oStats.interval
    nAttackRange = max(20.0, UnitData.GetMinEscortAttackRange() - 6.0)
    nOrbitRadius = oBaseStats.guard_orbit_radius
    nOrbitSpeed = oBaseStats.guard_orbit_speed
    bActive = true
    nState = GuardState.ORBIT
    nOrbitAngle = nOrbitSlotOffset
    nAttackCooldown = randf() * nAttackInterval
    _ApplySprite()
    position = _GetOrbitPosition()
    update()

func IsAggroActive() -> bool:
    return bActive and nState == GuardState.AGGRO

func ForceDeactivate() -> void:
    bActive = false
    nState = GuardState.ORBIT
    update()

func TakeDamage(nAmount: float) -> void:
    if not bActive:
        return
    nHp -= nAmount
    update()
    if nHp <= 0.0:
        bActive = false
        emit_signal("Died", self)

func _ApplySprite() -> void:
    if pSprite == null:
        return
    pSprite.texture = UnitData.GetEnemyDroneTexture()
    var nScale = UnitData.GetEnemyDroneTextureScale()
    pSprite.scale = Vector2(nScale, nScale)

func _process(delta: float) -> void:
    if not bActive or pGame == null or pBase == null or not is_instance_valid(pBase):
        return
    if not pBase.bActive:
        return

    nOrbitAngle += nOrbitSpeed * delta

    if pBase.IsShipInAlertRange() and pGame.CanDroneAttack():
        nState = GuardState.AGGRO
    else:
        nState = GuardState.ORBIT

    match nState:
        GuardState.ORBIT:
            position = _GetOrbitPosition()
        GuardState.AGGRO:
            _ProcessAggro(delta)

    update()

func _GetOrbitPosition() -> Vector2:
    var vDir = Vector2(cos(nOrbitAngle + nOrbitSlotOffset * 0.18), sin(nOrbitAngle + nOrbitSlotOffset * 0.18))
    return vDir * nOrbitRadius

func _ProcessAggro(delta: float) -> void:
    var pTarget = pGame.GetTargetForMonster(self)
    if pTarget == null or not is_instance_valid(pTarget):
        position = _GetOrbitPosition()
        return

    var vTargetPos = pTarget.global_position if pTarget is Node2D else global_position
    var vToTarget = vTargetPos - global_position
    var nDist = vToTarget.length()
    _FaceTarget(vToTarget)

    if nDist <= nAttackRange:
        nAttackCooldown -= delta
        if nAttackCooldown <= 0.0:
            nAttackCooldown = nAttackInterval
            _FireMissile(pTarget, vToTarget)
        if nDist > nAttackRange * 0.55:
            global_position += vToTarget.normalized() * nMoveSpeed * delta * 0.35
        return

    global_position += vToTarget.normalized() * nMoveSpeed * delta

func _FaceTarget(vToTarget: Vector2) -> void:
    if pSprite == null or vToTarget.length_squared() <= 0.001:
        return
    pSprite.rotation = vToTarget.angle() + PI * 0.5

func _FireMissile(pTarget, vToTarget: Vector2) -> void:
    if pGame == null:
        return
    var vDir = vToTarget
    if vDir.length_squared() <= 0.001 and pTarget is Node2D:
        vDir = pTarget.global_position - global_position
    if vDir.length_squared() <= 0.001:
        vDir = Vector2.RIGHT
    vDir = vDir.normalized()
    var vSpawn = global_position + vDir * 12.0
    pGame.SpawnEnemyMissile(vSpawn, vDir, nAttackDamage, pTarget)
    pGame.PlayEnemyMissileLaunchSound(global_position)

func _draw() -> void:
    var nRatio = clamp(nHp / nMaxHp, 0.0, 1.0)
    draw_rect(Rect2(Vector2(-12, -18), Vector2(24, 3)), Color(0.15, 0.05, 0.05))
    draw_rect(Rect2(Vector2(-12, -18), Vector2(24 * nRatio, 3)), Color(0.95, 0.3, 0.3))
