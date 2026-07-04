tool
extends Node2D

const UnitData = preload("res://scripts/unit_data.gd")
const EnemyBaseGuardScene = preload("res://scenes/EnemyBaseGuard.tscn")

signal Died(pBase)

export(float) var nBodyRadius = 52.0 setget SetBodyRadius
export(float) var nAlertRadius = 250.0 setget SetAlertRadius
export(float) var nPatrolRadius = 85.0 setget SetPatrolRadius
export(float) var nPatrolSpeed = 10.0 setget SetPatrolSpeed
export(Color) var oAlertColor = Color(0.95, 0.28, 0.22, 0.28) setget SetAlertColor

var nMaxHp = 1000.0
var nHp = 1000.0
var nPatrolPhase = 0.0
var vPatrolOrigin = Vector2.ZERO
var pGame = null
var bActive = true
var bShipInAlertRange = false
var vGuards = []

onready var pSprite = $Sprite
onready var pGuardRoot = $GuardRoot

func _ready() -> void:
    vPatrolOrigin = global_position
    _ApplySprite()
    if Engine.editor_hint:
        update()

func Setup(pGameNode) -> void:
    pGame = pGameNode
    vPatrolOrigin = global_position
    nPatrolPhase = randf() * TAU
    _ApplyBaseStats()
    _SyncHpFromShip()
    _SpawnGuards()
    update()

func _ApplyBaseStats() -> void:
    var oStats = UnitData.GetEnemyBaseStats()
    nBodyRadius = oStats.body_radius
    nAlertRadius = oStats.alert_radius
    nPatrolRadius = oStats.patrol_radius
    nPatrolSpeed = oStats.patrol_speed

func _SyncHpFromShip() -> void:
    if pGame == null or pGame.pShip == null:
        return
    nMaxHp = pGame.pShip.nMaxHp * 2.0
    nHp = nMaxHp

func SyncHpFromShip() -> void:
    if not bActive or pGame == null or pGame.pShip == null:
        return
    var nRatio = clamp(nHp / max(nMaxHp, 0.001), 0.0, 1.0)
    nMaxHp = pGame.pShip.nMaxHp * 2.0
    nHp = nMaxHp * nRatio

func _SpawnGuards() -> void:
    _ClearGuards()
    if Engine.editor_hint or pGame == null or pGuardRoot == null:
        return

    var nCount = UnitData.GetEnemyBaseStats().guard_count
    for i in range(nCount):
        var pGuard = EnemyBaseGuardScene.instance()
        pGuardRoot.add_child(pGuard)
        pGuard.connect("Died", pGame, "_OnMonsterDied")
        pGuard.connect("Died", self, "_OnGuardRemoved")
        pGuard.Setup(pGame, self, i, nCount)
        pGame.RegisterBaseGuard(pGuard)
        vGuards.append(pGuard)

func _ClearGuards() -> void:
    for pGuard in vGuards:
        if pGuard == null or not is_instance_valid(pGuard):
            continue
        if pGame != null:
            pGame.vMonsters.erase(pGuard)
        pGuard.ForceDeactivate()
        pGuard.queue_free()
    vGuards.clear()

func _OnGuardRemoved(pGuard) -> void:
    vGuards.erase(pGuard)

func SetBodyRadius(nValue: float) -> void:
    nBodyRadius = max(1.0, nValue)
    _ApplySprite()
    update()

func SetAlertRadius(nValue: float) -> void:
    nAlertRadius = max(nBodyRadius, nValue)
    update()

func SetPatrolRadius(nValue: float) -> void:
    nPatrolRadius = max(8.0, nValue)
    update()

func SetPatrolSpeed(nValue: float) -> void:
    nPatrolSpeed = max(0.0, nValue)

func SetAlertColor(oValue: Color) -> void:
    oAlertColor = oValue
    update()

func _ApplySprite() -> void:
    if pSprite == null:
        return
    var pTexture = UnitData.GetEnemyBaseTexture()
    if pTexture == null:
        return
    pSprite.texture = pTexture
    var vTexSize = pTexture.get_size()
    var nMaxTex = max(vTexSize.x, vTexSize.y)
    if nMaxTex <= 0.001:
        return
    var nScale = (nBodyRadius * 2.0) / nMaxTex
    pSprite.scale = Vector2(nScale, nScale)

func IsShipInAlertRange() -> bool:
    return bShipInAlertRange

func TakeDamage(nAmount: float) -> void:
    if not bActive:
        return
    nHp -= nAmount
    update()
    if nHp <= 0.0:
        _DestroyBase()

func GetHpRatio() -> float:
    return clamp(nHp / nMaxHp, 0.0, 1.0)

func _DestroyBase() -> void:
    bActive = false
    bShipInAlertRange = false
    _ClearGuards()
    emit_signal("Died", self)

func _process(delta: float) -> void:
    if Engine.editor_hint:
        return
    if not bActive:
        return

    nPatrolPhase += delta * (nPatrolSpeed / max(nPatrolRadius, 1.0))
    global_position = vPatrolOrigin + Vector2(cos(nPatrolPhase), sin(nPatrolPhase * 0.82)) * nPatrolRadius

    if pGame != null and pGame.pShip != null and is_instance_valid(pGame.pShip):
        bShipInAlertRange = global_position.distance_to(pGame.pShip.global_position) <= nAlertRadius
    else:
        bShipInAlertRange = false

    update()

func _draw() -> void:
    draw_circle(Vector2.ZERO, nAlertRadius, Color(oAlertColor.r, oAlertColor.g, oAlertColor.b, oAlertColor.a * 0.18))
    draw_arc(Vector2.ZERO, nAlertRadius, 0.0, TAU, 72, oAlertColor, 2.0, true)

    if bShipInAlertRange:
        draw_arc(Vector2.ZERO, nAlertRadius, 0.0, TAU, 72, Color(0.95, 0.35, 0.25, 0.55), 3.0, true)

    var nRatio = GetHpRatio()
    var vBar = Vector2(-nBodyRadius, -nBodyRadius - 16.0)
    var nBarW = nBodyRadius * 2.0
    draw_rect(Rect2(vBar, Vector2(nBarW, 5)), Color(0.12, 0.05, 0.05))
    draw_rect(Rect2(vBar, Vector2(nBarW * nRatio, 5)), Color(0.95, 0.3, 0.25))
