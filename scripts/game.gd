extends Node2D

enum GamePhase { PREP, MARCH, WIN, LOSE }

onready var pRoute = $RouteManager
onready var pBase = $BaseAnchor
onready var pSpawnManager = $SpawnManager
onready var pDefenseRoot = $DefenseRoot
onready var pMonsterRoot = $MonsterRoot
onready var pSoldierRoot = $SoldierRoot
onready var pCardPool = $UiLayer/CardPool
onready var pPhaseLabel = $UiLayer/Panel/VBox/PhaseLabel
onready var pHintLabel = $UiLayer/Panel/VBox/HintLabel
onready var pStatsLabel = $UiLayer/Panel/VBox/StatsLabel
onready var pResultLabel = $UiLayer/Panel/VBox/ResultLabel
onready var pStartButton = $UiLayer/Panel/VBox/StartButton
onready var pResetButton = $UiLayer/Panel/VBox/ResetButton

const DefenseTowerScene = preload("res://scenes/DefenseTower.tscn")
const SoldierScene = preload("res://scenes/Soldier.tscn")
const UnitData = preload("res://scripts/unit_data.gd")

export(int) var nMaxSoldiers = 8
export(int) var nStartGold = 60
export(int) var nKillGold = 15
export(int) var nRefreshCost = 15
export(float) var nRefreshCooldownMax = 6.0

var nPhase = GamePhase.PREP
var nGold = 60
var nMonstersKilled = 0
var nRefreshCooldown = 0.0
var vMonsters = []
var vTowers = []
var vSoldiers = []
var vCards = []
var vTowerSlotOccupied = []

func _ready() -> void:
    nGold = nStartGold
    pBase.connect("ReachedGoal", self, "_OnBaseReachedGoal")
    pBase.connect("Destroyed", self, "_OnBaseDestroyed")
    pBase.connect("LevelChanged", self, "_OnBaseLevelChanged")
    pStartButton.connect("pressed", self, "_OnStartPressed")
    pResetButton.connect("pressed", self, "_OnResetPressed")
    pCardPool.connect("CardPressed", self, "_OnCardPressed")
    pCardPool.connect("RefreshPressed", self, "_OnRefreshPressed")
    pCardPool.connect("UpgradePressed", self, "_OnUpgradePressed")
    pBase.Setup(pRoute, self)
    pSpawnManager.Setup(self, pRoute, pBase)
    _InitTowerSlots()
    _RollCardPool()
    _SetPhase(GamePhase.PREP)
    _UpdateUi()

func _process(delta: float) -> void:
    if nRefreshCooldown > 0.0:
        nRefreshCooldown = max(0.0, nRefreshCooldown - delta)
    if nPhase == GamePhase.MARCH or nRefreshCooldown > 0.0:
        _UpdateUi()

func IsMarchRunning() -> bool:
    return nPhase == GamePhase.MARCH

func GetAliveMonsterCount() -> int:
    var nCount = 0
    for pMonster in vMonsters:
        if pMonster != null and is_instance_valid(pMonster) and pMonster.bActive:
            nCount += 1
    return nCount

func GetNearestMonsterInRange(vPos: Vector2, nRange: float):
    var pBest = null
    var nBestDist = nRange
    for pMonster in vMonsters:
        if pMonster == null or not is_instance_valid(pMonster) or not pMonster.bActive:
            continue
        var nDist = vPos.distance_to(pMonster.global_position)
        if nDist <= nBestDist:
            nBestDist = nDist
            pBest = pMonster
    return pBest

func GetNearestMonsterInAnchorZone(vFrom: Vector2, nZoneRadius: float):
    var pBest = null
    var nBestDist = INF
    var nDetectRadius = nZoneRadius + 40.0
    for pMonster in vMonsters:
        if pMonster == null or not is_instance_valid(pMonster) or not pMonster.bActive:
            continue
        if pBase.global_position.distance_to(pMonster.global_position) > nDetectRadius:
            continue
        var nDist = vFrom.distance_to(pMonster.global_position)
        if nDist < nBestDist:
            nBestDist = nDist
            pBest = pMonster
    return pBest

func GetTargetForMonster(pMonster):
    var pBestTaunt = null
    var nBestDist = INF
    for pSoldier in vSoldiers:
        if pSoldier == null or not is_instance_valid(pSoldier) or not pSoldier.bActive:
            continue
        if not pSoldier.bTaunt:
            continue
        var nDist = pMonster.global_position.distance_to(pSoldier.global_position)
        if nDist <= pSoldier.nTauntRange and nDist < nBestDist:
            nBestDist = nDist
            pBestTaunt = pSoldier
    if pBestTaunt != null:
        return pBestTaunt
    return pBase

func AddMonster(pMonster, vPos: Vector2) -> void:
    pMonsterRoot.add_child(pMonster)
    pMonster.position = vPos
    pMonster.connect("Died", self, "_OnMonsterDied")
    pMonster.Setup(self)
    vMonsters.append(pMonster)

func _InitTowerSlots() -> void:
    var nCount = pBase.GetTowerSlotCount()
    vTowerSlotOccupied.clear()
    for i in range(nCount):
        vTowerSlotOccupied.append(false)
    pBase.SetSlotOccupied(vTowerSlotOccupied)

func _GetEmptyTowerSlotIndex() -> int:
    for i in range(pBase.GetTowerSlotCount()):
        if i < vTowerSlotOccupied.size() and not vTowerSlotOccupied[i]:
            return i
    return -1

func _GetFilledTowerSlotCount() -> int:
    var nCount = 0
    for bFilled in vTowerSlotOccupied:
        if bFilled:
            nCount += 1
    return nCount

func _HasEmptyTowerSlot() -> bool:
    return _GetEmptyTowerSlotIndex() >= 0

func _RollCardPool() -> void:
    vCards.clear()
    var nSlots = pBase.GetCardSlotCount()
    for i in range(nSlots):
        vCards.append(UnitData.GenerateRandomCard())

func _GenerateSingleCard() -> Dictionary:
    return UnitData.GenerateRandomCard()

func _CanUseCard(oCard: Dictionary) -> bool:
    if nGold < oCard.cost:
        return false
    if oCard.kind == UnitData.CardKind.SOLDIER:
        return vSoldiers.size() < nMaxSoldiers
    if oCard.kind == UnitData.CardKind.TOWER:
        return _HasEmptyTowerSlot()
    return false

func _TryUseCard(nIndex: int) -> void:
    if nPhase == GamePhase.WIN or nPhase == GamePhase.LOSE:
        return
    if nIndex < 0 or nIndex >= vCards.size():
        return

    var oCard = vCards[nIndex]
    if not _CanUseCard(oCard):
        return

    nGold -= oCard.cost
    if oCard.kind == UnitData.CardKind.SOLDIER:
        _SpawnSoldier(oCard.type)
    else:
        _PlaceTowerFromCard(oCard.type)

    vCards[nIndex] = _GenerateSingleCard()
    _UpdateUi()

func _SpawnSoldier(nType: int) -> void:
    var vOffset = _GetRandomAnchorOffset()
    var pSoldier = SoldierScene.instance()
    pSoldierRoot.add_child(pSoldier)
    pSoldier.connect("Died", self, "_OnSoldierDied")
    pSoldier.Setup(self, pBase, nType, vOffset)
    vSoldiers.append(pSoldier)

func _PlaceTowerFromCard(nTowerType: int) -> void:
    var nSlot = _GetEmptyTowerSlotIndex()
    if nSlot < 0:
        return

    var vOffset = pBase.GetTowerSlotOffset(nSlot)
    var pTower = DefenseTowerScene.instance()
    pDefenseRoot.add_child(pTower)
    pTower.Setup(self, pBase, nTowerType, vOffset, nSlot)
    vTowers.append(pTower)
    vTowerSlotOccupied[nSlot] = true
    pBase.SetSlotOccupied(vTowerSlotOccupied)

func _GetRandomAnchorOffset() -> Vector2:
    var nRadius = pBase.nAnchorRadius * 0.75
    var nAngle = randf() * TAU
    return Vector2(cos(nAngle), sin(nAngle)) * rand_range(nRadius * 0.35, nRadius)

func _OnMonsterDied(pMonster) -> void:
    nMonstersKilled += 1
    nGold += nKillGold
    vMonsters.erase(pMonster)
    if is_instance_valid(pMonster):
        pMonster.queue_free()
    _UpdateUi()

func _OnSoldierDied(pSoldier) -> void:
    vSoldiers.erase(pSoldier)
    if is_instance_valid(pSoldier):
        pSoldier.queue_free()
    _UpdateUi()

func _OnBaseReachedGoal() -> void:
    pBase.StopMarch()
    _SetPhase(GamePhase.WIN)
    pResultLabel.text = "Mission complete! Base reached the goal."
    pResultLabel.add_color_override("font_color", Color(0.45, 0.95, 0.55))
    _UpdateUi()

func _OnBaseDestroyed() -> void:
    pBase.StopMarch()
    _SetPhase(GamePhase.LOSE)
    pResultLabel.text = "Base destroyed. Recruit more units and upgrade."
    pResultLabel.add_color_override("font_color", Color(0.95, 0.45, 0.45))
    _UpdateUi()

func _OnBaseLevelChanged(nLevel: int) -> void:
    while vTowerSlotOccupied.size() < pBase.GetTowerSlotCount():
        vTowerSlotOccupied.append(false)
    while vCards.size() < pBase.GetCardSlotCount():
        vCards.append(_GenerateSingleCard())
    pBase.SetSlotOccupied(vTowerSlotOccupied)
    _UpdateUi()

func _OnStartPressed() -> void:
    if nPhase != GamePhase.PREP:
        return
    _BeginMarch()

func _OnResetPressed() -> void:
    get_tree().reload_current_scene()

func _OnCardPressed(nIndex: int) -> void:
    _TryUseCard(nIndex)

func _OnRefreshPressed() -> void:
    if nRefreshCooldown > 0.0:
        return
    if nGold < nRefreshCost:
        return
    nGold -= nRefreshCost
    nRefreshCooldown = nRefreshCooldownMax
    _RollCardPool()
    _UpdateUi()

func _OnUpgradePressed() -> void:
    if not pBase.CanUpgrade():
        return
    var nCost = pBase.GetUpgradeCost()
    if nGold < nCost:
        return
    nGold -= nCost
    pBase.UpgradeLevel()
    _UpdateUi()

func _BeginMarch() -> void:
    pBase.StartMarch()
    pSpawnManager.Reset()
    _SetPhase(GamePhase.MARCH)
    _UpdateUi()

func _SetPhase(nNewPhase: int) -> void:
    nPhase = nNewPhase
    pStartButton.disabled = nPhase != GamePhase.PREP
    pResetButton.disabled = false

func _UpdateUi() -> void:
    match nPhase:
        GamePhase.PREP:
            pPhaseLabel.text = "Phase: Prep"
            pHintLabel.text = "Use cards to recruit. Towers fill fixed slots on base."
        GamePhase.MARCH:
            pPhaseLabel.text = "Phase: March"
            pHintLabel.text = "Cards auto-refill. Earn gold from kills to refresh pool."
        GamePhase.WIN:
            pPhaseLabel.text = "Phase: Victory"
            pHintLabel.text = "Press Reset to play again."
        GamePhase.LOSE:
            pPhaseLabel.text = "Phase: Defeat"
            pHintLabel.text = "Press Reset to try again."

    pStatsLabel.text = "Base Lv.%d HP:%d  Gold:%d  Units:%d  Towers:%d/%d  Kills:%d" % [
        pBase.nLevel, int(pBase.nHp), nGold, vSoldiers.size(),
        _GetFilledTowerSlotCount(), pBase.GetTowerSlotCount(), nMonstersKilled
    ]

    var bCanRefresh = nRefreshCooldown <= 0.0 and nGold >= nRefreshCost and nPhase != GamePhase.WIN and nPhase != GamePhase.LOSE
    pCardPool.UpdateDisplay(
        nGold,
        vCards,
        pBase.GetCardSlotCount(),
        nRefreshCooldown,
        nRefreshCost,
        bCanRefresh,
        pBase.nLevel,
        pBase.GetUpgradeCost(),
        pBase.CanUpgrade(),
        _HasEmptyTowerSlot(),
        pBase.GetTowerSlotCount(),
        _GetFilledTowerSlotCount()
    )

func _unhandled_input(event: InputEvent) -> void:
    if event is InputEventKey and event.pressed and not event.echo:
        if event.scancode == KEY_SPACE and nPhase == GamePhase.PREP:
            _BeginMarch()
        elif event.scancode == KEY_R:
            _OnResetPressed()
