extends Node2D

const UnitData = preload("res://scripts/unit_data.gd")

signal ReachedGoal
signal Destroyed
signal LevelChanged(nLevel)

export(float) var nMoveSpeed = 0.035

var nLevel = 1
var nMaxHp = 500.0
var nHp = 500.0
var nAnchorRadius = 120.0
var nAttackDamage = 8.0
var nAttackRange = 72.0
var nAttackInterval = 0.55
var nPathT = 0.0
var bMoving = false
var nAttackCooldown = 0.0
var pRoute = null
var pGame = null
var vSlotOccupied = []

func Setup(pRouteManager, pGameNode) -> void:
	pRoute = pRouteManager
	pGame = pGameNode
	_ApplyLevelStats(false)
	nPathT = 0.0
	bMoving = false
	_InitSlotState()
	if pRoute != null:
		position = pRoute.GetPositionAt(0.0)
	update()

func GetLevelConfig() -> Dictionary:
	return UnitData.GetLevelConfig(nLevel)

func GetCardSlotCount() -> int:
	return GetLevelConfig().card_slots

func GetTowerSlotCount() -> int:
	return GetLevelConfig().tower_slots

func GetUpgradeCost() -> int:
	return GetLevelConfig().upgrade_cost

func CanUpgrade() -> bool:
	return GetUpgradeCost() > 0

func GetTowerSlotOffset(nIndex: int) -> Vector2:
	return UnitData.GetTowerSlotOffset(nIndex, GetTowerSlotCount(), nAnchorRadius)

func SetSlotOccupied(vOccupied: Array) -> void:
	vSlotOccupied = vOccupied
	update()

func UpgradeLevel() -> bool:
	if not CanUpgrade():
		return false
	var nOldMax = nMaxHp
	nLevel += 1
	_ApplyLevelStats(true)
	nHp += nMaxHp - nOldMax
	_InitSlotState()
	emit_signal("LevelChanged", nLevel)
	update()
	return true

func _InitSlotState() -> void:
	var nCount = GetTowerSlotCount()
	while vSlotOccupied.size() < nCount:
		vSlotOccupied.append(false)

func _ApplyLevelStats(bKeepHpRatio: bool) -> void:
	var oCfg = GetLevelConfig()
	var nRatio = GetHpRatio() if bKeepHpRatio and nMaxHp > 0.0 else 1.0
	nMaxHp = oCfg.hp
	nHp = nMaxHp * nRatio if bKeepHpRatio else nMaxHp
	nAnchorRadius = oCfg.radius
	nAttackDamage = oCfg.attack
	nAttackRange = oCfg.attack_range

func StartMarch() -> void:
	bMoving = true

func StopMarch() -> void:
	bMoving = false

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
	if bMoving and pRoute != null:
		nPathT += nMoveSpeed * delta
		if nPathT >= 1.0:
			nPathT = 1.0
			position = pRoute.GetPositionAt(1.0)
			bMoving = false
			emit_signal("ReachedGoal")
		else:
			position = pRoute.GetPositionAt(nPathT)

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
	draw_arc(Vector2.ZERO, nAttackRange, 0.0, TAU, 48, Color(0.55, 0.8, 1.0, 0.12), 1.0, true)

	var nSlots = GetTowerSlotCount()
	for i in range(nSlots):
		var vSlot = GetTowerSlotOffset(i)
		var bFilled = i < vSlotOccupied.size() and vSlotOccupied[i]
		var oColor = Color(0.25, 0.95, 0.55, 0.5) if bFilled else Color(0.7, 0.75, 0.85, 0.35)
		draw_rect(Rect2(vSlot - Vector2(10, 10), Vector2(20, 20)), oColor)
		draw_arc(vSlot, 12.0, 0.0, TAU, 16, oColor, 1.5, true)

	draw_rect(Rect2(Vector2(-22, -22), Vector2(44, 44)), Color(0.25, 0.55, 0.95))
	draw_rect(Rect2(Vector2(-14, -14), Vector2(28, 28)), Color(0.55, 0.8, 1.0))

	var nRatio = GetHpRatio()
	draw_rect(Rect2(Vector2(-24, -34), Vector2(48, 6)), Color(0.15, 0.08, 0.08))
	draw_rect(Rect2(Vector2(-24, -34), Vector2(48 * nRatio, 6)), Color(0.25, 0.95, 0.45))
