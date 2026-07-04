extends Node2D

const UnitData = preload("res://scripts/unit_data.gd")

enum MissileKind { DRONE, ENEMY, SHIP_PULSE }

export(float) var nSpeed = 360.0
export(float) var nHitRadius = 12.0
export(float) var nMaxLifetime = 4.0

var nDamage = 10.0
var nLifetime = 0.0
var vVelocity = Vector2.ZERO
var pTarget = null
var nKind = MissileKind.DRONE

onready var pSprite = $Sprite

func Setup(vDirection: Vector2, nDamageAmount: float, pTargetNode, nSpeedOverride: float = -1.0, nMissileKind: int = MissileKind.DRONE) -> void:
    nDamage = nDamageAmount
    pTarget = pTargetNode
    nKind = nMissileKind
    if nSpeedOverride > 0.0:
        nSpeed = nSpeedOverride
    match nKind:
        MissileKind.ENEMY:
            nHitRadius = 10.0
        MissileKind.SHIP_PULSE:
            nHitRadius = 14.0
        _:
            nHitRadius = 12.0
    vVelocity = vDirection.normalized() * nSpeed if vDirection.length_squared() > 0.001 else Vector2.UP * nSpeed
    _ApplySprite()
    _UpdateHeading()

func _ApplySprite() -> void:
    if pSprite == null:
        return
    match nKind:
        MissileKind.ENEMY:
            pSprite.texture = UnitData.GetEnemyMissileTexture()
            var nEnemyScale = UnitData.GetEnemyMissileTextureScale()
            pSprite.scale = Vector2(nEnemyScale, nEnemyScale)
        MissileKind.SHIP_PULSE:
            pSprite.texture = UnitData.GetShipPulseTexture()
            var nPulseScale = UnitData.GetShipPulseTextureScale()
            pSprite.scale = Vector2(nPulseScale, nPulseScale)
        _:
            pSprite.texture = UnitData.GetMissileTexture()
            var nScale = UnitData.GetMissileTextureScale()
            pSprite.scale = Vector2(nScale, nScale)

func _UpdateHeading() -> void:
    if pSprite == null or vVelocity.length_squared() <= 0.001:
        return
    pSprite.rotation = vVelocity.angle() + PI * 0.5

func _IsTargetValid() -> bool:
    if pTarget == null or not is_instance_valid(pTarget):
        return false
    if not pTarget.has_method("TakeDamage"):
        return false
    if "bActive" in pTarget:
        return pTarget.bActive
    if "nHp" in pTarget:
        return pTarget.nHp > 0.0
    return true

func _process(delta: float) -> void:
    nLifetime += delta
    if nLifetime >= nMaxLifetime:
        queue_free()
        return

    if _IsTargetValid():
        var vToTarget = pTarget.global_position - global_position
        var nDist = vToTarget.length()
        if nDist <= nHitRadius:
            if pTarget.has_method("TakeDamage"):
                pTarget.TakeDamage(nDamage)
            queue_free()
            return
        if nDist > 0.001:
            vVelocity = vToTarget.normalized() * nSpeed

    global_position += vVelocity * delta
    _UpdateHeading()
