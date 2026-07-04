extends Node2D

const UnitData = preload("res://scripts/unit_data.gd")

signal Died(pDrone)

var nType = 0
var nMaxHp = 50.0
var nHp = 50.0
var nDamage = 10.0
var nAttackRange = 50.0
var nAttackInterval = 0.5
var nMoveSpeed = 90.0
var nCatchUpSpeedMax = 420.0
var nOrbitSpeed = 1.5
var nOrbitRadius = 60.0
var bTaunt = false
var nTauntRange = 0.0
var oColor = Color.white

var nOrbitAngle = 0.0
var nOrbitSlotOffset = 0.0
var nCooldown = 0.0
var pGame = null
var pShip = null
var bActive = true

onready var pSprite = $Sprite

func Setup(pManager, pShipNode, nDroneType: int, nSlotIndex: int, nSlotTotal: int) -> void:
    pGame = pManager
    pShip = pShipNode
    nType = nDroneType
    nOrbitSlotOffset = UnitData.GetOrbitSlotAngle(nSlotIndex, nSlotTotal)

    var oStats = UnitData.GetDroneStats(nType)
    nMaxHp = oStats.hp
    nHp = nMaxHp
    nDamage = oStats.damage
    nAttackRange = oStats.range
    nAttackInterval = oStats.interval
    nMoveSpeed = oStats.move_speed
    nOrbitSpeed = oStats.orbit_speed
    nOrbitRadius = pShip.nAnchorRadius * oStats.orbit_radius_ratio
    bTaunt = oStats.taunt
    nTauntRange = oStats.taunt_range
    oColor = oStats.color
    bActive = true
    nOrbitAngle = nOrbitSlotOffset
    nCooldown = randf() * nAttackInterval
    _ApplySprite()
    position = _GetOrbitPosition()
    update()

func SyncFromShip() -> void:
    if pShip == null or not is_instance_valid(pShip):
        return
    var oStats = UnitData.GetDroneStats(nType)
    nOrbitRadius = pShip.nAnchorRadius * oStats.orbit_radius_ratio

func _ApplySprite() -> void:
    if pSprite == null:
        return
    var nScale = UnitData.GetDroneTextureScale(nType)
    pSprite.texture = UnitData.GetDroneTexture(nType)
    pSprite.scale = Vector2(nScale, nScale)

func TakeDamage(nAmount: float) -> void:
    if not bActive:
        return
    nHp -= nAmount
    update()
    if nHp <= 0.0:
        bActive = false
        emit_signal("Died", self)

func GetHpRatio() -> float:
    return clamp(nHp / nMaxHp, 0.0, 1.0)

func _process(delta: float) -> void:
    if not bActive or pShip == null or not is_instance_valid(pShip):
        return
    if pGame == null or not pGame.IsShipAlive():
        update()
        return

    nOrbitAngle += nOrbitSpeed * delta

    if not pGame.IsEscortActive():
        update()
        return

    if pGame.CanDroneAttack():
        var pTarget = pGame.GetNearestMonsterInAnchorZone(global_position, pShip.GetEscortDetectRadius())
        if pTarget != null:
            _SeekAndAttack(pTarget, delta)
        else:
            _OrbitPatrol(delta)
    else:
        _OrbitPatrol(delta)

    update()

func _GetOrbitPosition() -> Vector2:
    var vDir = Vector2(cos(nOrbitAngle + nOrbitSlotOffset * 0.15), sin(nOrbitAngle + nOrbitSlotOffset * 0.15))
    return _ClampToAnchorZone(pShip.global_position + vDir * nOrbitRadius)

func _OrbitPatrol(delta: float, nSpeedScale: float = 1.0) -> void:
    var vTarget = _GetOrbitPosition()
    _MoveTowards(vTarget, delta, _GetCatchUpSpeed(vTarget) * nSpeedScale)

func _GetCatchUpSpeed(vTarget: Vector2) -> float:
    var nDist = global_position.distance_to(vTarget)
    var nShipSpeed = pShip.GetVelocity().length() if pShip.has_method("GetVelocity") else 0.0
    var nSpeed = nMoveSpeed + nShipSpeed * 1.2
    if nDist > nOrbitRadius * 0.4:
        nSpeed += (nDist - nOrbitRadius * 0.4) * 2.0
    var nSpeedCap = max(nMoveSpeed * 2.8, nShipSpeed * 1.8 + 140.0)
    return clamp(nSpeed, nMoveSpeed, min(nCatchUpSpeedMax, nSpeedCap))

func _MoveTowards(vTarget: Vector2, delta: float, nSpeed: float) -> void:
    var vToTarget = vTarget - global_position
    var nDist = vToTarget.length()
    if nDist <= 0.001:
        return
    var nStep = min(nSpeed * delta, nDist)
    global_position += vToTarget.normalized() * nStep
    _FaceTarget(vToTarget)

func _SeekAndAttack(pTarget, delta: float) -> void:
    var vToTarget = pTarget.global_position - global_position
    var nDist = vToTarget.length()
    _FaceTarget(vToTarget)

    if nDist <= nAttackRange:
        nCooldown -= delta
        if nCooldown <= 0.0:
            nCooldown = nAttackInterval
            _FireMissile(pTarget, vToTarget)
        _OrbitPatrol(delta, 0.45)
        return

    var vMoveTarget = pTarget.global_position
    var nDistFromShip = global_position.distance_to(pShip.global_position)
    if nDistFromShip > pShip.nAnchorRadius * 0.9:
        vMoveTarget = _GetOrbitPosition()
    _MoveTowards(vMoveTarget, delta, _GetCatchUpSpeed(vMoveTarget))

func _FaceTarget(vToTarget: Vector2) -> void:
    if pSprite == null or vToTarget.length_squared() <= 0.001:
        return
    pSprite.rotation = vToTarget.angle() + PI * 0.5

func _FireMissile(pTarget, vToTarget: Vector2) -> void:
    if pGame == null or vToTarget.length_squared() <= 0.001:
        return
    var vDir = vToTarget.normalized()
    var vSpawn = global_position + vDir * 14.0
    pGame.SpawnMissile(vSpawn, vDir, nDamage, pTarget)
    pGame.PlayMissileLaunchSound(global_position)

func _ClampToAnchorZone(vPos: Vector2) -> Vector2:
    var vFromShip = vPos - pShip.global_position
    var nDist = vFromShip.length()
    if nDist <= pShip.nAnchorRadius:
        return vPos
    if nDist < 0.001:
        return pShip.global_position
    return pShip.global_position + vFromShip.normalized() * pShip.nAnchorRadius

func _draw() -> void:
    var nRatio = GetHpRatio()
    draw_rect(Rect2(Vector2(-14, -20), Vector2(28, 3)), Color(0.1, 0.08, 0.12))
    draw_rect(Rect2(Vector2(-14, -20), Vector2(28 * nRatio, 3)), Color(0.3, 0.9, 0.95))

    if bTaunt:
        draw_arc(Vector2.ZERO, nTauntRange, 0.0, TAU, 28, Color(0.4, 0.7, 1.0, 0.1), 1.0, true)
