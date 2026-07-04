extends Node2D

signal Died(pMonster)

export(float) var nMaxHp = 45.0
export(float) var nMoveSpeed = 85.0
export(float) var nAttackDamage = 8.0
export(float) var nAttackInterval = 0.8
export(float) var nAttackRange = 28.0

var nHp = 45.0
var pGame = null
var bActive = true
var nAttackCooldown = 0.0

func Setup(pGameNode) -> void:
    pGame = pGameNode
    nHp = nMaxHp
    bActive = true
    update()

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

    var pTarget = pGame.GetTargetForMonster(self)
    if pTarget == null or not is_instance_valid(pTarget):
        return

    var vTargetPos = pTarget.global_position if pTarget is Node2D else Vector2.ZERO
    var vToTarget = vTargetPos - global_position
    var nDist = vToTarget.length()

    if nDist <= nAttackRange:
        nAttackCooldown -= delta
        if nAttackCooldown <= 0.0:
            nAttackCooldown = nAttackInterval
            if pTarget.has_method("TakeDamage"):
                pTarget.TakeDamage(nAttackDamage)
        return

    global_position += vToTarget.normalized() * nMoveSpeed * delta
    update()

func _draw() -> void:
    var nRatio = clamp(nHp / nMaxHp, 0.0, 1.0)
    draw_circle(Vector2.ZERO, 11.0, Color(0.9, 0.25, 0.25))
    draw_circle(Vector2.ZERO, 5.0, Color(1.0, 0.55, 0.45))
    draw_rect(Rect2(Vector2(-12, -18), Vector2(24, 3)), Color(0.15, 0.05, 0.05))
    draw_rect(Rect2(Vector2(-12, -18), Vector2(24 * nRatio, 3)), Color(0.95, 0.3, 0.3))
