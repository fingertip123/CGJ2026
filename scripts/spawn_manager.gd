extends Node2D

const MonsterScene = preload("res://scenes/Monster.tscn")

export(float) var nSpawnInterval = 1.6
export(float) var nSideDistance = 150.0
export(int) var nMaxAlive = 18

var pGame = null
var pRoute = null
var pBase = null
var nTimer = 0.0
var nSideToggle = 1
var nSpawned = 0

func Setup(pManager, pRouteManager, pBaseNode) -> void:
    pGame = pManager
    pRoute = pRouteManager
    pBase = pBaseNode
    nTimer = 1.0
    nSideToggle = 1
    nSpawned = 0

func Reset() -> void:
    nTimer = 1.0
    nSideToggle = 1
    nSpawned = 0

func _process(delta: float) -> void:
    if pGame == null or not pGame.CanDroneAttack():
        return
    if pBase == null or pRoute == null:
        return
    if pGame.GetAliveMonsterCount() >= nMaxAlive:
        return

    nTimer -= delta
    if nTimer > 0.0:
        return

    nTimer = nSpawnInterval * pGame.GetSpawnIntervalMultiplier()
    _SpawnMonster()
    nSpawned += 1

func _SpawnMonster() -> void:
    var vDir = Vector2.RIGHT
    if pBase.has_method("GetVelocity") and pBase.GetVelocity().length_squared() > 1.0:
        vDir = pBase.GetVelocity().normalized()
    elif pRoute != null and pRoute.has_method("GetDirection"):
        vDir = pRoute.GetDirection()

    var vNormal = Vector2(-vDir.y, vDir.x)
    if nSideToggle < 0:
        vNormal *= -1.0

    var vForwardOffset = vDir * rand_range(40.0, 120.0)
    var vSideOffset = vNormal * (nSideDistance + rand_range(-20.0, 20.0))
    var vPos = pBase.global_position + vForwardOffset + vSideOffset
    nSideToggle *= -1

    var pMonster = MonsterScene.instance()
    pGame.AddMonster(pMonster, vPos)
