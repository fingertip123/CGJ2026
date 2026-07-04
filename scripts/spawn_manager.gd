extends Node2D

const MonsterScene = preload("res://scenes/Monster.tscn")

export(float) var nSpawnInterval = 0.34
export(float) var nMinSpawnInterval = 0.11
export(float) var nSpawnAccelDuration = 150.0
export(float) var nSpawnAccelMinScale = 0.22
export(float) var nEdgePadding = 64.0
export(int) var nMaxAlive = 78
export(int) var nSpawnBurstMin = 1
export(int) var nSpawnBurstMax = 3

var pGame = null
var pRoute = null
var pBase = null
var nTimer = 0.0
var nCombatTime = 0.0
var nSpawned = 0

func Setup(pManager, pRouteManager, pBaseNode) -> void:
    pGame = pManager
    pRoute = pRouteManager
    pBase = pBaseNode
    Reset()

func Reset() -> void:
    nTimer = 0.15
    nCombatTime = 0.0
    nSpawned = 0

func _process(delta: float) -> void:
    if pGame == null or not pGame.CanDroneAttack():
        return
    if pBase == null:
        return
    if pGame.GetAlivePatrolMonsterCount() >= nMaxAlive:
        return

    nCombatTime += delta
    nTimer -= delta
    if nTimer > 0.0:
        return

    nTimer = _GetSpawnInterval()
    var nBurst = _GetSpawnBurstCount()
    for _i in range(nBurst):
        if pGame.GetAlivePatrolMonsterCount() >= nMaxAlive:
            break
        _SpawnMonster()
        nSpawned += 1

func _GetSpawnBurstCount() -> int:
    var nProgress = clamp(nCombatTime / max(nSpawnAccelDuration, 0.001), 0.0, 1.0)
    var nBurst = nSpawnBurstMin + int(round(nProgress * float(nSpawnBurstMax - nSpawnBurstMin)))
    return clamp(nBurst, nSpawnBurstMin, nSpawnBurstMax)

func _GetSpawnInterval() -> float:
    var nBase = nSpawnInterval * pGame.GetSpawnIntervalMultiplier()
    var nProgress = clamp(nCombatTime / max(nSpawnAccelDuration, 0.001), 0.0, 1.0)
    var nScale = lerp(1.0, nSpawnAccelMinScale, nProgress)
    return max(nMinSpawnInterval, nBase * nScale)

func _SpawnMonster() -> void:
    var vPos = _GetRandomEdgeSpawnPos()
    var pMonster = MonsterScene.instance()
    pGame.AddMonster(pMonster, vPos)

func _GetRandomEdgeSpawnPos() -> Vector2:
    var vViewport = pGame.GetSpawnViewportSize() if pGame.has_method("GetSpawnViewportSize") else Vector2(1600, 790)
    var vCenter = pBase.global_position
    var oScreen = Rect2(vCenter - vViewport * 0.5, vViewport)
    var nEdge = randi() % 4

    match nEdge:
        0:
            return Vector2(
                rand_range(oScreen.position.x + nEdgePadding, oScreen.position.x + oScreen.size.x - nEdgePadding),
                oScreen.position.y - nEdgePadding
            )
        1:
            return Vector2(
                oScreen.position.x + oScreen.size.x + nEdgePadding,
                rand_range(oScreen.position.y + nEdgePadding, oScreen.position.y + oScreen.size.y - nEdgePadding)
            )
        2:
            return Vector2(
                rand_range(oScreen.position.x + nEdgePadding, oScreen.position.x + oScreen.size.x - nEdgePadding),
                oScreen.position.y + oScreen.size.y + nEdgePadding
            )
        _:
            return Vector2(
                oScreen.position.x - nEdgePadding,
                rand_range(oScreen.position.y + nEdgePadding, oScreen.position.y + oScreen.size.y - nEdgePadding)
            )
