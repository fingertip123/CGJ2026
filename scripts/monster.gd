extends Node2D

const UnitData = preload("res://scripts/unit_data.gd")

signal Died(pMonster)

var nMaxHp = 45.0
var nMoveSpeed = 85.0
var nAttackDamage = 8.0
var nAttackInterval = 0.8
var nAttackRange = 32.0

var nHp = 45.0
var pGame = null
var bActive = true
var nAttackCooldown = 0.0

onready var pSprite = $Sprite

func Setup(pGameNode) -> void:
    pGame = pGameNode
    var oStats = UnitData.GetEnemyDroneStats()
    nMaxHp = oStats.hp
    nHp = nMaxHp
    nMoveSpeed = oStats.move_speed
    nAttackDamage = oStats.damage
    nAttackInterval = oStats.interval
    nAttackRange = max(20.0, UnitData.GetMinEscortAttackRange() - 6.0)
    bActive = true
    nAttackCooldown = randf() * nAttackInterval
    _ApplySprite()
    update()

func _ApplySprite() -> void:
    if pSprite == null:
        return
    pSprite.texture = UnitData.GetEnemyDroneTexture()
    var nScale = UnitData.GetEnemyDroneTextureScale()
    pSprite.scale = Vector2(nScale, nScale)

func TakeDamage(nAmount: float) -> void:
    if not bActive:
        return
    nHp -= nAmount
    update()
    if nHp <= 0.0:
        bActive = false
        emit_signal("Died", self)

func _process(delta: float) -> void:
    if not bActive or pGame == null:
        return
    if not pGame.IsShipAlive() or not pGame.CanDroneAttack():
        return

    var pTarget = pGame.GetTargetForMonster(self)
    if pTarget == null or not is_instance_valid(pTarget):
        return

    var vTargetPos = pTarget.global_position if pTarget is Node2D else Vector2.ZERO
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
        update()
        return

    global_position += vToTarget.normalized() * nMoveSpeed * delta
    update()

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
