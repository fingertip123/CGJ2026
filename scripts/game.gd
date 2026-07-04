extends Node2D

enum GamePhase { PREP, MARCH, WIN, LOSE }

onready var pRoute = $RouteManager
onready var pShip = $BaseAnchor
onready var pSpawnManager = $SpawnManager
onready var pDroneRoot = $DroneRoot
onready var pMonsterRoot = $MonsterRoot
onready var pCardPool = $UiLayer/CardPool
onready var pPhaseLabel = $UiLayer/Panel/VBox/PhaseLabel
onready var pHintLabel = $UiLayer/Panel/VBox/HintLabel
onready var pStatsLabel = $UiLayer/Panel/VBox/StatsLabel
onready var pResultLabel = $UiLayer/Panel/VBox/ResultLabel
onready var pStartButton = $UiLayer/Panel/VBox/StartButton
onready var pResetButton = $UiLayer/Panel/VBox/ResetButton

const DroneEscortScene = preload("res://scenes/DroneEscort.tscn")
const UnitData = preload("res://scripts/unit_data.gd")

export(int) var nStartGold = 60
export(int) var nKillGold = 15
export(int) var nRefreshCost = 15
export(float) var nRefreshCooldownMax = 6.0

var nPhase = GamePhase.PREP
var nGold = 60
var nMonstersKilled = 0
var nRefreshCooldown = 0.0
var vMonsters = []
var vDrones = []
var vCards = []

func _ready() -> void:
    nGold = nStartGold
    pShip.connect("ReachedGoal", self, "_OnShipReachedGoal")
    pShip.connect("Destroyed", self, "_OnShipDestroyed")
    pShip.connect("LevelChanged", self, "_OnShipLevelChanged")
    pStartButton.connect("pressed", self, "_OnStartPressed")
    pResetButton.connect("pressed", self, "_OnResetPressed")
    pCardPool.connect("CardPressed", self, "_OnCardPressed")
    pCardPool.connect("RefreshPressed", self, "_OnRefreshPressed")
    pCardPool.connect("UpgradePressed", self, "_OnUpgradePressed")
    pShip.Setup(pRoute, self)
    pSpawnManager.Setup(self, pRoute, pShip)
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

func GetDroneMaxCount() -> int:
    return pShip.GetDroneMaxCount()

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
        if pShip.global_position.distance_to(pMonster.global_position) > nDetectRadius:
            continue
        var nDist = vFrom.distance_to(pMonster.global_position)
        if nDist < nBestDist:
            nBestDist = nDist
            pBest = pMonster
    return pBest

func GetTargetForMonster(pMonster):
    var pBestTaunt = null
    var nBestDist = INF
    for pDrone in vDrones:
        if pDrone == null or not is_instance_valid(pDrone) or not pDrone.bActive:
            continue
        if not pDrone.bTaunt:
            continue
        var nDist = pMonster.global_position.distance_to(pDrone.global_position)
        if nDist <= pDrone.nTauntRange and nDist < nBestDist:
            nBestDist = nDist
            pBestTaunt = pDrone
    if pBestTaunt != null:
        return pBestTaunt
    return pShip

func AddMonster(pMonster, vPos: Vector2) -> void:
    pMonsterRoot.add_child(pMonster)
    pMonster.position = vPos
    pMonster.connect("Died", self, "_OnMonsterDied")
    pMonster.Setup(self)
    vMonsters.append(pMonster)

func _RollCardPool() -> void:
    vCards.clear()
    var nSlots = pShip.GetCardSlotCount()
    for i in range(nSlots):
        vCards.append(UnitData.GenerateRandomDroneCard())

func _GenerateSingleCard() -> Dictionary:
    return UnitData.GenerateRandomDroneCard()

func _CanUseCard(oCard: Dictionary) -> bool:
    return nGold >= oCard.cost and vDrones.size() < GetDroneMaxCount()

func _TryUseCard(nIndex: int) -> void:
    if nPhase == GamePhase.WIN or nPhase == GamePhase.LOSE:
        return
    if nIndex < 0 or nIndex >= vCards.size():
        return

    var oCard = vCards[nIndex]
    if not _CanUseCard(oCard):
        return

    nGold -= oCard.cost
    _SpawnDrone(oCard.type)
    vCards[nIndex] = _GenerateSingleCard()
    _UpdateUi()

func _SpawnDrone(nType: int) -> void:
    var pDrone = DroneEscortScene.instance()
    pDroneRoot.add_child(pDrone)
    pDrone.connect("Died", self, "_OnDroneDied")
    var nSlotIndex = vDrones.size()
    var nSlotTotal = max(GetDroneMaxCount(), nSlotIndex + 1)
    pDrone.Setup(self, pShip, nType, nSlotIndex, nSlotTotal)
    vDrones.append(pDrone)

func _OnMonsterDied(pMonster) -> void:
    nMonstersKilled += 1
    nGold += nKillGold
    vMonsters.erase(pMonster)
    if is_instance_valid(pMonster):
        pMonster.queue_free()
    _UpdateUi()

func _OnDroneDied(pDrone) -> void:
    vDrones.erase(pDrone)
    if is_instance_valid(pDrone):
        pDrone.queue_free()
    _UpdateUi()

func _OnShipReachedGoal() -> void:
    pShip.StopMarch()
    _SetPhase(GamePhase.WIN)
    pResultLabel.text = "Anchor reached! Mission complete."
    pResultLabel.add_color_override("font_color", Color(0.45, 0.95, 0.55))
    _UpdateUi()

func _OnShipDestroyed() -> void:
    pShip.StopMarch()
    _SetPhase(GamePhase.LOSE)
    pResultLabel.text = "Ship destroyed. Deploy more escort drones."
    pResultLabel.add_color_override("font_color", Color(0.95, 0.45, 0.45))
    _UpdateUi()

func _OnShipLevelChanged(nLevel: int) -> void:
    while vCards.size() < pShip.GetCardSlotCount():
        vCards.append(_GenerateSingleCard())
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
    if not pShip.CanUpgrade():
        return
    var nCost = pShip.GetUpgradeCost()
    if nGold < nCost:
        return
    nGold -= nCost
    pShip.UpgradeLevel()
    _UpdateUi()

func _BeginMarch() -> void:
    pShip.StartMarch()
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
            pHintLabel.text = "Deploy escort drones from card pool. They orbit the ship anchor zone."
        GamePhase.MARCH:
            pPhaseLabel.text = "Phase: Flight"
            pHintLabel.text = "Drones orbit and intercept threats within anchor range."
        GamePhase.WIN:
            pPhaseLabel.text = "Phase: Victory"
            pHintLabel.text = "Press Reset to play again."
        GamePhase.LOSE:
            pPhaseLabel.text = "Phase: Defeat"
            pHintLabel.text = "Press Reset to try again."

    pStatsLabel.text = "Ship Lv.%d HP:%d  Gold:%d  Drones:%d/%d  Kills:%d" % [
        pShip.nLevel, int(pShip.nHp), nGold, vDrones.size(), GetDroneMaxCount(), nMonstersKilled
    ]

    var bCanRefresh = nRefreshCooldown <= 0.0 and nGold >= nRefreshCost and nPhase != GamePhase.WIN and nPhase != GamePhase.LOSE
    pCardPool.UpdateDisplay(
        nGold,
        vCards,
        pShip.GetCardSlotCount(),
        nRefreshCooldown,
        nRefreshCost,
        bCanRefresh,
        pShip.nLevel,
        pShip.GetUpgradeCost(),
        pShip.CanUpgrade(),
        vDrones.size(),
        GetDroneMaxCount()
    )

func _unhandled_input(event: InputEvent) -> void:
    if event is InputEventKey and event.pressed and not event.echo:
        if event.scancode == KEY_SPACE and nPhase == GamePhase.PREP:
            _BeginMarch()
        elif event.scancode == KEY_R:
            _OnResetPressed()
