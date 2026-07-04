extends Node2D

const UnitData = preload("res://scripts/unit_data.gd")

signal Died(pSoldier)

var nType = 0
var nMaxHp = 50.0
var nHp = 50.0
var nDamage = 10.0
var nAttackRange = 50.0
var nAttackInterval = 0.5
var nMoveSpeed = 90.0
var bTaunt = false
var nTauntRange = 0.0
var oColor = Color.white

var vHomeOffset = Vector2.ZERO
var nCooldown = 0.0
var pGame = null
var pBase = null
var bActive = true

func Setup(pManager, pBaseNode, nSoldierType: int, vOffset: Vector2) -> void:
	pGame = pManager
	pBase = pBaseNode
	nType = nSoldierType
	vHomeOffset = vOffset

	var oStats = UnitData.GetSoldierStats(nType)
	nMaxHp = oStats.hp
	nHp = nMaxHp
	nDamage = oStats.damage
	nAttackRange = oStats.range
	nAttackInterval = oStats.interval
	nMoveSpeed = oStats.move_speed
	bTaunt = oStats.taunt
	nTauntRange = oStats.taunt_range
	oColor = oStats.color
	bActive = true
	nCooldown = randf() * nAttackInterval
	position = pBase.global_position + vHomeOffset
	update()

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
	if not bActive or pBase == null or not is_instance_valid(pBase):
		return

	if pGame == null:
		return

	if not pGame.IsMarchRunning():
		_ReturnToHome(delta)
		update()
		return

	var pTarget = pGame.GetNearestMonsterInAnchorZone(global_position, pBase.nAnchorRadius)
	if pTarget != null:
		_SeekAndAttack(pTarget, delta)
	else:
		_ReturnToHome(delta * 0.6)

	update()

func _SeekAndAttack(pTarget, delta: float) -> void:
	var vToTarget = pTarget.global_position - global_position
	var nDist = vToTarget.length()

	if nDist <= nAttackRange:
		nCooldown -= delta
		if nCooldown <= 0.0:
			nCooldown = nAttackInterval
			pTarget.TakeDamage(nDamage)
		return

	var vNext = global_position + vToTarget.normalized() * nMoveSpeed * delta
	global_position = _ClampToAnchorZone(vNext)

func _ReturnToHome(delta: float) -> void:
	var vHome = pBase.global_position + vHomeOffset
	var vToHome = vHome - global_position
	if vToHome.length() <= 3.0:
		global_position = _ClampToAnchorZone(vHome)
		return
	var vNext = global_position + vToHome.normalized() * nMoveSpeed * 0.5 * delta
	global_position = _ClampToAnchorZone(vNext)

func _ClampToAnchorZone(vPos: Vector2) -> Vector2:
	var vFromBase = vPos - pBase.global_position
	var nDist = vFromBase.length()
	if nDist <= pBase.nAnchorRadius:
		return vPos
	if nDist < 0.001:
		return pBase.global_position
	return pBase.global_position + vFromBase.normalized() * pBase.nAnchorRadius

func _draw() -> void:
	var nRatio = GetHpRatio()
	var nRadius = 10.0 if nType != UnitData.SoldierType.TANK else 13.0
	draw_circle(Vector2.ZERO, nRadius, oColor)
	draw_circle(Vector2.ZERO, nRadius * 0.45, oColor.lightened(0.25))
	draw_rect(Rect2(Vector2(-14, -22), Vector2(28, 4)), Color(0.12, 0.08, 0.08))
	draw_rect(Rect2(Vector2(-14, -22), Vector2(28 * nRatio, 4)), Color(0.25, 0.95, 0.35))

	if bTaunt:
		draw_arc(Vector2.ZERO, nTauntRange, 0.0, TAU, 32, Color(0.4, 0.65, 1.0, 0.12), 1.0, true)

	if nType == UnitData.SoldierType.ARCHER:
		draw_line(Vector2.ZERO, Vector2(nAttackRange * 0.35, 0), Color(0.35, 0.9, 0.55, 0.35), 2.0, true)
