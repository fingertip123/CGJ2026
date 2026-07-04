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
    if pGame == null or not pGame.IsMarchRunning():
        return
    if pBase == null or pRoute == null:
        return
    if pGame.GetAliveMonsterCount() >= nMaxAlive:
        return

    nTimer -= delta
    if nTimer > 0.0:
        return

    nTimer = nSpawnInterval
    _SpawnMonster()
    nSpawned += 1

func _SpawnMonster() -> void:
    var t = clamp(pBase.nPathT + rand_range(-0.03, 0.05), 0.0, 0.98)
    var vPos = pRoute.GetSideSpawnPosition(t, nSideToggle, nSideDistance + rand_range(-20.0, 20.0))
    nSideToggle *= -1

    var pMonster = MonsterScene.instance()
    pGame.AddMonster(pMonster, vPos)
