extends Node2D

enum GamePhase { PREP, MARCH, ANCHOR, ANCHOR_PLAN, WIN, LOSE }

onready var pRoute = $RouteManager
onready var pShip = $PlayerShip
onready var pAnchorPoint = $AnchorPoint
onready var pSpawnManager = $SpawnManager
onready var pDroneRoot = $DroneRoot
onready var pMiningDroneRoot = $MiningDroneRoot
onready var pMonsterRoot = $MonsterRoot
onready var pPlanetsRoot = $Planets
onready var pCardPool = $UiLayer/CardPool
onready var pPhaseLabel = $UiLayer/Panel/VBox/PhaseLabel
onready var pHintLabel = $UiLayer/Panel/VBox/HintLabel
onready var pStatsLabel = $UiLayer/Panel/VBox/StatsLabel
onready var pResultLabel = $UiLayer/Panel/VBox/ResultLabel
onready var pStartButton = $UiLayer/Panel/VBox/StartButton
onready var pDropAnchorButton = $UiLayer/Panel/VBox/DropAnchorButton
onready var pResetButton = $UiLayer/Panel/VBox/ResetButton
onready var pSpeedLabel = $UiLayer/Panel/VBox/SpeedLabel
onready var pSpeedSlider = $UiLayer/Panel/VBox/SpeedSlider
onready var pBackground = $BackgroundLayer/Background
onready var pTwinkleStars = $BackgroundLayer/TwinkleStars
onready var pAnchorIndicator = $UiLayer/AnchorIndicator
onready var pMinimap = $UiLayer/Minimap
onready var pMissileRoot = $MissileRoot
onready var pSfxRoot = $SfxRoot

const DroneEscortScene = preload("res://scenes/DroneEscort.tscn")
const DroneMiningScene = preload("res://scenes/DroneMining.tscn")
const MissileScene = preload("res://scenes/Missile.tscn")
const UnitData = preload("res://scripts/unit_data.gd")

export(int) var nStartGold = 60
export(int) var nKillGold = 15
export(int) var nRefreshCost = 15
export(float) var nRefreshCooldownMax = 6.0
export(float) var nMinLaunchSpeed = 20.0
export(float) var nMaxLaunchSpeed = 260.0
export(int) var nMissileSfxPoolSize = 8

var nPhase = GamePhase.PREP
var nGold = 60
var nMonstersKilled = 0
var nRefreshCooldown = 0.0
var vMonsters = []
var vDrones = []
var vMiningDrones = []
var vCards = []
var vParallaxOrigin = Vector2.ZERO
var vMissileSfxPlayers = []
var nMissileSfxIndex = 0
var vEnemyMissileSfxPlayers = []
var nEnemyMissileSfxIndex = 0

func _ready() -> void:
    nGold = nStartGold
    pShip.connect("ReachedGoal", self, "_OnShipReachedGoal")
    pShip.connect("Destroyed", self, "_OnShipDestroyed")
    pShip.connect("LevelChanged", self, "_OnShipLevelChanged")
    pShip.connect("FuelDepleted", self, "_OnShipFuelDepleted")
    pShip.connect("AnchorBrakeFinished", self, "_OnAnchorBrakeFinished")
    pStartButton.connect("pressed", self, "_OnStartPressed")
    pDropAnchorButton.connect("pressed", self, "_OnDropAnchorPressed")
    pResetButton.connect("pressed", self, "_OnResetPressed")
    pSpeedSlider.connect("value_changed", self, "_OnSpeedSliderChanged")
    pCardPool.connect("CardPressed", self, "_OnCardPressed")
    pCardPool.connect("RefreshPressed", self, "_OnRefreshPressed")
    pCardPool.connect("UpgradePressed", self, "_OnUpgradePressed")
    pRoute.connect("RouteChanged", self, "_OnRouteChanged")
    pShip.Setup(pRoute, self)
    pShip.SetCameraActive(false)
    pSpeedSlider.min_value = nMinLaunchSpeed
    pSpeedSlider.max_value = nMaxLaunchSpeed
    pSpeedSlider.value = pShip.nLaunchSpeed
    pRoute.SetStartPosition(pShip.global_position)
    pRoute.SetPlanetsRoot(pPlanetsRoot)
    pRoute.SetPreviewLaunchSpeed(pShip.nLaunchSpeed)
    vParallaxOrigin = pShip.global_position
    _SetParallaxOffset(Vector2.ZERO)
    pAnchorIndicator.Setup(pAnchorPoint, pShip)
    pMinimap.Setup(pShip, pAnchorPoint, pPlanetsRoot, pRoute.oEditBounds)
    _SetupMissileSfx()
    _SetupEnemyMissileSfx()
    _SetupPlanets()
    pSpawnManager.Setup(self, pRoute, pShip)
    _SyncRouteFuelRange()
    _RollCardPool()
    _SetPhase(GamePhase.PREP)
    _UpdateUi()

func _process(delta: float) -> void:
    if nRefreshCooldown > 0.0:
        nRefreshCooldown = max(0.0, nRefreshCooldown - delta)
    if nPhase == GamePhase.MARCH and pAnchorPoint.is_docked(pShip.global_position):
        _OnShipReachedGoal()
    if nPhase == GamePhase.ANCHOR:
        _TryAutoDeployMiningDrones()
    if nPhase == GamePhase.MARCH or nPhase == GamePhase.WIN:
        _SetParallaxOffset(pShip.global_position - vParallaxOrigin)
    elif nPhase == GamePhase.PREP or nPhase == GamePhase.LOSE or nPhase == GamePhase.ANCHOR or nPhase == GamePhase.ANCHOR_PLAN:
        _SetParallaxOffset(Vector2.ZERO)

    if nPhase == GamePhase.MARCH or nPhase == GamePhase.ANCHOR or nPhase == GamePhase.ANCHOR_PLAN or nRefreshCooldown > 0.0:
        _UpdateUi()

func IsMarchRunning() -> bool:
    return nPhase == GamePhase.MARCH or nPhase == GamePhase.ANCHOR

func IsEscortActive() -> bool:
    return nPhase != GamePhase.WIN and nPhase != GamePhase.LOSE

func CanDroneAttack() -> bool:
    return nPhase == GamePhase.MARCH or nPhase == GamePhase.ANCHOR or nPhase == GamePhase.ANCHOR_PLAN
func _SetParallaxOffset(vOffset: Vector2) -> void:
    pBackground.SetCameraOffset(vOffset)
    pTwinkleStars.SetCameraOffset(vOffset)

func IsAnchored() -> bool:
    return nPhase == GamePhase.ANCHOR or nPhase == GamePhase.ANCHOR_PLAN

func IsRoutePlanning() -> bool:
    return nPhase == GamePhase.PREP or nPhase == GamePhase.ANCHOR_PLAN

func GetSpawnIntervalMultiplier() -> float:
    return 0.6 if IsAnchored() else 1.0

func CanLaunch() -> bool:
    return IsRoutePlanning() and pRoute.HasRoute() and pShip.HasFuel()

func CanDropAnchor() -> bool:
    return nPhase == GamePhase.MARCH and pShip.bMoving and not pShip.IsBraking()

func CanPlanRoute() -> bool:
    return nPhase == GamePhase.ANCHOR and pShip.HasFuel()

func GetDroneMaxCount() -> int:
    return pShip.GetDroneMaxCount()

func GetMiningDroneMaxCount() -> int:
    return pShip.GetMiningDroneMaxCount()

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

func GetNearestMineablePlanet(vFrom: Vector2):
    var pBest = null
    var nBestDist = INF
    for pPlanet in pPlanetsRoot.get_children():
        if pPlanet == null or not is_instance_valid(pPlanet):
            continue
        if not pPlanet.has_method("HasMineableResources") or not pPlanet.HasMineableResources():
            continue
        var nDist = vFrom.distance_to(pPlanet.global_position)
        if nDist < nBestDist:
            nBestDist = nDist
            pBest = pPlanet
    return pBest

func GetTargetForMonster(pMonster):
    var pBestDrone = null
    var nBestDist = INF
    for pDrone in vDrones:
        if pDrone == null or not is_instance_valid(pDrone) or not pDrone.bActive:
            continue
        var nDist = pMonster.global_position.distance_to(pDrone.global_position)
        if nDist < nBestDist:
            nBestDist = nDist
            pBestDrone = pDrone
    if pBestDrone != null:
        return pBestDrone
    return pShip

func OnMiningDroneDelivered(nFuelAmount: float, nGoldAmount: int) -> void:
    if nFuelAmount > 0.0 and not pShip.IsFuelFull():
        pShip.AddFuel(nFuelAmount)
    if nGoldAmount > 0:
        nGold += nGoldAmount
    if nPhase == GamePhase.ANCHOR_PLAN:
        _SyncRouteFuelRange()
    _UpdateUi()

func AddMonster(pMonster, vPos: Vector2) -> void:
    pMonsterRoot.add_child(pMonster)
    pMonster.position = vPos
    pMonster.connect("Died", self, "_OnMonsterDied")
    pMonster.Setup(self)
    vMonsters.append(pMonster)

func SpawnMissile(vSpawnPos: Vector2, vDirection: Vector2, nDamage: float, pTarget) -> void:
    var pMissile = MissileScene.instance()
    pMissileRoot.add_child(pMissile)
    pMissile.global_position = vSpawnPos
    pMissile.Setup(vDirection, nDamage, pTarget, UnitData.GetMissileSpeed())

func SpawnEnemyMissile(vSpawnPos: Vector2, vDirection: Vector2, nDamage: float, pTarget) -> void:
    var pMissile = MissileScene.instance()
    pMissileRoot.add_child(pMissile)
    pMissile.global_position = vSpawnPos
    pMissile.Setup(vDirection, nDamage, pTarget, UnitData.GetEnemyMissileSpeed(), true)

func PlayMissileLaunchSound(vWorldPos: Vector2) -> void:
    if vMissileSfxPlayers.empty():
        return
    var pPlayer = _GetMissileSfxPlayer()
    pPlayer.global_position = vWorldPos
    pPlayer.stop()
    pPlayer.play()

func PlayEnemyMissileLaunchSound(vWorldPos: Vector2) -> void:
    if vEnemyMissileSfxPlayers.empty():
        return
    var pPlayer = _GetEnemyMissileSfxPlayer()
    pPlayer.global_position = vWorldPos
    pPlayer.stop()
    pPlayer.play()

func _GetMissileSfxPlayer() -> AudioStreamPlayer2D:
    for i in range(vMissileSfxPlayers.size()):
        var nIndex = (nMissileSfxIndex + i) % vMissileSfxPlayers.size()
        var pPlayer = vMissileSfxPlayers[nIndex]
        if not pPlayer.playing:
            nMissileSfxIndex = (nIndex + 1) % vMissileSfxPlayers.size()
            return pPlayer
    var pFallback = vMissileSfxPlayers[nMissileSfxIndex]
    nMissileSfxIndex = (nMissileSfxIndex + 1) % vMissileSfxPlayers.size()
    return pFallback

func _GetEnemyMissileSfxPlayer() -> AudioStreamPlayer2D:
    for i in range(vEnemyMissileSfxPlayers.size()):
        var nIndex = (nEnemyMissileSfxIndex + i) % vEnemyMissileSfxPlayers.size()
        var pPlayer = vEnemyMissileSfxPlayers[nIndex]
        if not pPlayer.playing:
            nEnemyMissileSfxIndex = (nIndex + 1) % vEnemyMissileSfxPlayers.size()
            return pPlayer
    var pFallback = vEnemyMissileSfxPlayers[nEnemyMissileSfxIndex]
    nEnemyMissileSfxIndex = (nEnemyMissileSfxIndex + 1) % vEnemyMissileSfxPlayers.size()
    return pFallback

func _SetupMissileSfx() -> void:
    vMissileSfxPlayers.clear()
    for i in range(max(1, nMissileSfxPoolSize)):
        var pPlayer = AudioStreamPlayer2D.new()
        pSfxRoot.add_child(pPlayer)
        var pStream = UnitData.GetMissileLaunchSound()
        if pStream != null:
            pStream = pStream.duplicate()
            pStream.loop = false
            pPlayer.stream = pStream
        vMissileSfxPlayers.append(pPlayer)

func _SetupEnemyMissileSfx() -> void:
    vEnemyMissileSfxPlayers.clear()
    for i in range(max(1, nMissileSfxPoolSize)):
        var pPlayer = AudioStreamPlayer2D.new()
        pSfxRoot.add_child(pPlayer)
        var pStream = UnitData.GetEnemyMissileLaunchSound()
        if pStream != null:
            pStream = pStream.duplicate()
            pStream.loop = false
            pPlayer.stream = pStream
        vEnemyMissileSfxPlayers.append(pPlayer)

func _SetupPlanets() -> void:
    for pPlanet in pPlanetsRoot.get_children():
        if pPlanet != null and is_instance_valid(pPlanet) and pPlanet.has_method("Setup"):
            pPlanet.Setup(self)

func _SyncRouteFuelRange() -> void:
    pRoute.SetFuelRange(pShip.GetFuel(), pShip.GetMaxFuel(), pShip.nFuelBurnRate)

func _SyncRouteStart() -> void:
    pRoute.SetStartPosition(pShip.global_position)

func _RollCardPool() -> void:
    vCards.clear()
    var nSlots = pShip.GetCardSlotCount()
    for i in range(nSlots):
        vCards.append(UnitData.GenerateRandomCard())

func _GenerateSingleCard() -> Dictionary:
    return UnitData.GenerateRandomCard()

func _CanUseCard(oCard: Dictionary) -> bool:
    if nGold < oCard.cost:
        return false
    if oCard.get("kind", UnitData.CardKind.ESCORT) == UnitData.CardKind.MINING:
        return vMiningDrones.size() < GetMiningDroneMaxCount()
    return vDrones.size() < GetDroneMaxCount()

func _TryUseCard(nIndex: int) -> void:
    if nPhase == GamePhase.WIN or nPhase == GamePhase.LOSE:
        return
    if nIndex < 0 or nIndex >= vCards.size():
        return

    var oCard = vCards[nIndex]
    if not _CanUseCard(oCard):
        return

    nGold -= oCard.cost
    if oCard.get("kind", UnitData.CardKind.ESCORT) == UnitData.CardKind.MINING:
        _SpawnMiningDrone()
    else:
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

func _SpawnMiningDrone() -> void:
    var pDrone = DroneMiningScene.instance()
    pMiningDroneRoot.add_child(pDrone)
    var nSlotIndex = vMiningDrones.size()
    var nSlotTotal = max(GetMiningDroneMaxCount(), nSlotIndex + 1)
    pDrone.Setup(self, pShip, nSlotIndex, nSlotTotal)
    vMiningDrones.append(pDrone)
    if nPhase == GamePhase.ANCHOR:
        _TryAutoDeployMiningDrones()

func _TryAutoDeployMiningDrones() -> void:
    var pPlanet = GetNearestMineablePlanet(pShip.global_position)
    if pPlanet == null:
        return
    for pDrone in vMiningDrones:
        if pDrone == null or not is_instance_valid(pDrone):
            continue
        if pDrone.CanDeploy():
            pDrone.DeployTo(pPlanet)

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
    pShip.SetCameraActive(false)
    pAnchorIndicator.SetIndicatorVisible(false)
    _SetPhase(GamePhase.WIN)
    pResultLabel.text = "Anchor reached! Mission complete."
    pResultLabel.add_color_override("font_color", Color(0.45, 0.95, 0.55))
    _UpdateUi()

func _OnShipDestroyed() -> void:
    pShip.StopMarch()
    pShip.SetCameraActive(false)
    _SetPhase(GamePhase.LOSE)
    pResultLabel.text = "Ship destroyed. Deploy more escort drones."
    pResultLabel.add_color_override("font_color", Color(0.95, 0.45, 0.45))
    _UpdateUi()

func _OnShipFuelDepleted() -> void:
    _UpdateUi()

func _OnShipLevelChanged(nLevel: int) -> void:
    while vCards.size() < pShip.GetCardSlotCount():
        vCards.append(_GenerateSingleCard())
    _UpdateUi()

func _OnStartPressed() -> void:
    if CanPlanRoute():
        _BeginRoutePlanning()
        return
    if not CanLaunch():
        return
    _BeginMarch()

func _OnDropAnchorPressed() -> void:
    _DropAnchor()

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

func _OnSpeedSliderChanged(nValue: float) -> void:
    if not IsRoutePlanning():
        return
    _SetLaunchSpeed(nValue)

func _SetLaunchSpeed(nValue: float) -> void:
    var nClampedSpeed = clamp(nValue, nMinLaunchSpeed, nMaxLaunchSpeed)
    pShip.SetLaunchSpeed(nClampedSpeed)
    pRoute.SetPreviewLaunchSpeed(nClampedSpeed)
    if pSpeedSlider.value != nClampedSpeed:
        pSpeedSlider.value = nClampedSpeed
    _UpdateUi()

func _OnRouteChanged() -> void:
    if nPhase == GamePhase.PREP:
        pShip.ResetPathProgress()
        _SyncRouteStart()
    elif nPhase == GamePhase.ANCHOR_PLAN:
        pShip.ResetFlightState()
        _SyncRouteStart()
    _UpdateUi()

func _BeginMarch() -> void:
    pRoute.SetEditingEnabled(false)
    pShip.StartMarch()
    pShip.SetCameraActive(true)
    vParallaxOrigin = pShip.global_position
    pSpawnManager.Reset()
    _SetPhase(GamePhase.MARCH)
    _UpdateUi()

func _DropAnchor() -> void:
    if not CanDropAnchor():
        return
    pShip.StartAnchorBrake()
    _UpdateUi()

func _OnAnchorBrakeFinished() -> void:
    pShip.SetCameraActive(false)
    pShip.UpdateSpawnPosition()
    _SyncRouteStart()
    pRoute.ClearRoute()
    pRoute.SetEditingEnabled(false)
    _SetPhase(GamePhase.ANCHOR)
    _TryAutoDeployMiningDrones()
    _UpdateUi()

func _BeginRoutePlanning() -> void:
    if not pShip.HasFuel():
        return
    pShip.UpdateSpawnPosition()
    _SyncRouteStart()
    _SyncRouteFuelRange()
    pRoute.ClearRoute()
    pRoute.SetEditingEnabled(true)
    _SetPhase(GamePhase.ANCHOR_PLAN)
    _UpdateUi()

func _SetPhase(nNewPhase: int) -> void:
    nPhase = nNewPhase
    pRoute.SetEditingEnabled(nPhase == GamePhase.PREP or nPhase == GamePhase.ANCHOR_PLAN)
    if nPhase == GamePhase.PREP or nPhase == GamePhase.ANCHOR_PLAN or nPhase == GamePhase.LOSE or nPhase == GamePhase.ANCHOR:
        pShip.SetCameraActive(false)
    pResetButton.disabled = false
    _UpdateActionButtons()

func _UpdateUi() -> void:
    var nFuelRange = int(pRoute.GetFuelRange())
    match nPhase:
        GamePhase.PREP:
            pPhaseLabel.text = "Phase: Prep"
            pHintLabel.text = pRoute.GetEditHint() + " Route range: %d px." % nFuelRange
        GamePhase.MARCH:
            pPhaseLabel.text = "Phase: Flight"
            if pShip.IsBraking():
                pHintLabel.text = "Anchor deployed — braking to a stop."
            elif pShip.IsCoasting():
                pHintLabel.text = "Out of fuel — coasting. Drop anchor to stop and mine."
            else:
                pHintLabel.text = "Fuel draining. Drop anchor anytime to stop and replan."
        GamePhase.ANCHOR:
            pPhaseLabel.text = "Phase: Anchored"
            pHintLabel.text = "Mine for fuel/gold, then click Plan Route when ready."
        GamePhase.ANCHOR_PLAN:
            pPhaseLabel.text = "Phase: Route Planning"
            pHintLabel.text = pRoute.GetEditHint() + " Current fuel allows ~%d px." % nFuelRange
        GamePhase.WIN:
            pPhaseLabel.text = "Phase: Victory"
            pHintLabel.text = "Press Reset to play again."
        GamePhase.LOSE:
            pPhaseLabel.text = "Phase: Defeat"
            pHintLabel.text = "Press Reset to try again."

    pStatsLabel.text = "Ship Lv.%d HP:%d  Fuel:%d/%d  Gold:%d  Escort:%d/%d  Mining:%d/%d  Kills:%d  Pos:(%d,%d)" % [
        pShip.nLevel, int(pShip.nHp), int(pShip.GetFuel()), int(pShip.GetMaxFuel()), nGold,
        vDrones.size(), GetDroneMaxCount(), vMiningDrones.size(), GetMiningDroneMaxCount(), nMonstersKilled,
        int(round(pShip.global_position.x)), int(round(pShip.global_position.y))
    ]

    pSpeedLabel.text = "Launch Speed: %d" % int(round(pShip.nLaunchSpeed))
    pSpeedSlider.editable = IsRoutePlanning()

    _UpdateActionButtons()

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
        GetDroneMaxCount(),
        vMiningDrones.size(),
        GetMiningDroneMaxCount()
    )

func _UpdateActionButtons() -> void:
    pDropAnchorButton.visible = nPhase == GamePhase.MARCH
    pDropAnchorButton.disabled = not CanDropAnchor()
    pDropAnchorButton.text = "Drop Anchor"

    if CanPlanRoute():
        pStartButton.text = "Plan Route"
        pStartButton.disabled = false
        pStartButton.visible = true
    elif CanLaunch():
        pStartButton.text = "Launch"
        pStartButton.disabled = false
        pStartButton.visible = true
    else:
        pStartButton.visible = IsRoutePlanning() or nPhase == GamePhase.ANCHOR
        pStartButton.disabled = true
        if nPhase == GamePhase.ANCHOR:
            pStartButton.text = "Plan Route"
        else:
            pStartButton.text = "Launch"

func _unhandled_input(event: InputEvent) -> void:
    if event is InputEventKey and event.pressed and not event.echo:
        if event.scancode == KEY_R:
            _OnResetPressed()
