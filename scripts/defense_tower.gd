extends Node2D

const UnitData = preload("res://scripts/unit_data.gd")

export(float) var nRange = 90.0
export(float) var nDamage = 30.0
export(float) var nFireInterval = 0.35

var nTowerType = 0
var vLocalOffset = Vector2.ZERO
var nSlotIndex = -1
var nCooldown = 0.0
var oColor = Color(0.2, 0.85, 0.55)
var pGame = null
var pBase = null

func Setup(pManager, pBaseNode, nType: int, vOffset: Vector2, nSlot: int) -> void:
	pGame = pManager
	pBase = pBaseNode
	nTowerType = nType
	vLocalOffset = vOffset
	nSlotIndex = nSlot

	var oStats = UnitData.GetTowerStats(nType)
	nRange = oStats.range
	nDamage = oStats.damage
	nFireInterval = oStats.interval
	oColor = oStats.color
	position = pBase.global_position + vLocalOffset
	nCooldown = randf() * nFireInterval
	update()

func _process(delta: float) -> void:
	if pBase == null or not is_instance_valid(pBase):
		return

	position = pBase.global_position + vLocalOffset

	if pGame == null or not pGame.IsMarchRunning():
		return

	nCooldown -= delta
	if nCooldown > 0.0:
		return

	var pTarget = pGame.GetNearestMonsterInRange(global_position, nRange)
	if pTarget == null:
		return

	nCooldown = nFireInterval
	pTarget.TakeDamage(nDamage)
	update()

func _draw() -> void:
	draw_circle(Vector2.ZERO, nRange, Color(oColor.r, oColor.g, oColor.b, 0.07))
	draw_arc(Vector2.ZERO, nRange, 0.0, TAU, 40, Color(oColor.r, oColor.g, oColor.b, 0.35), 1.5, true)
	draw_rect(Rect2(Vector2(-11, -11), Vector2(22, 22)), oColor.darkened(0.15))
	draw_rect(Rect2(Vector2(-7, -7), Vector2(14, 14)), oColor.lightened(0.15))
