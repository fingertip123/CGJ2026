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
onready var pEnemyBasesRoot = $EnemyBases
onready var pCardPool = $UiLayer/CardPool
onready var pPhaseLabel = $UiLayer/Panel/VBox/HeaderRow/PhaseLabel
onready var pHintLabel = $UiLayer/Panel/VBox/HintLabel
onready var pStatsLabel = $UiLayer/Panel/VBox/StatsLabel
onready var pResultLabel = $UiLayer/Panel/VBox/ResultLabel
onready var pStartButton = $UiLayer/Panel/VBox/ButtonRow/StartButton
onready var pResetButton = $UiLayer/Panel/VBox/ButtonRow/ResetButton
onready var pSpeedLabel = $UiLayer/Panel/VBox/SpeedBlock/SpeedLabel
onready var pSpeedSlider = $UiLayer/Panel/VBox/SpeedBlock/SpeedSlider
onready var pBackground = $BackgroundLayer/Background
onready var pTwinkleStars = $BackgroundLayer/TwinkleStars
onready var pAnchorIndicator = $UiLayer/AnchorIndicator
onready var pMinimap = $UiLayer/Minimap
onready var pMissileRoot = $MissileRoot
onready var pGrappleRoot = $GrappleRoot
onready var pSfxRoot = $SfxRoot
onready var pFlowUi = $FlowUi
onready var pGamePanel = $UiLayer/Panel

const DroneEscortScene = preload("res://scenes/DroneEscort.tscn")
const DroneMiningScene = preload("res://scenes/DroneMining.tscn")
const MissileScene = preload("res://scenes/Missile.tscn")
const GrappleAnchorScene = preload("res://scenes/GrappleAnchor.tscn")
const PlanetScene = preload("res://scenes/Planet.tscn")
const EnemyBaseScene = preload("res://scenes/EnemyBase.tscn")
const UnitData = preload("res://scripts/unit_data.gd")

export(int) var nStartGold = 60
export(int) var nKillGold = 15
export(int) var nRefreshCost = 15
export(float) var nRefreshCooldownMax = 6.0
export(float) var nMinLaunchSpeed = 20.0
export(float) var nMaxLaunchSpeed = 260.0
export(int) var nMissileSfxPoolSize = 8
export(float) var nGrappleMaxChainLength = 480.0

var nPhase = GamePhase.PREP
var nGold = 60
var nMonstersKilled = 0
var nRefreshCooldown = 0.0
var vMonsters = []
var vEnemyBases = []
var vDrones = []
var vMiningDrones = []
var vCards = []
var vParallaxOrigin = Vector2.ZERO
var vMissileSfxPlayers = []
var nMissileSfxIndex = 0
var vEnemyMissileSfxPlayers = []
var nEnemyMissileSfxIndex = 0
var vShipPulseSfxPlayers = []
var nShipPulseSfxIndex = 0
var pActiveGrapple = null
var bLateEnemyBasesSpawned = false

func _ready() -> void:
    nGold = nStartGold
    pShip.connect("ReachedGoal", self, "_OnShipReachedGoal")
    pShip.connect("Destroyed", self, "_OnShipDestroyed")
    pShip.connect("LevelChanged", self, "_OnShipLevelChanged")
    pShip.connect("FuelDepleted", self, "_OnShipFuelDepleted")
    pShip.connect("AnchorBrakeFinished", self, "_OnAnchorBrakeFinished")
    pStartButton.connect("pressed", self, "_OnStartPressed")
    pResetButton.connect("pressed", self, "_OnResetPressed")
    pSpeedSlider.connect("value_changed", self, "_OnSpeedSliderChanged")
    pCardPool.connect("CardPressed", self, "_OnCardPressed")
    pCardPool.connect("RefreshPressed", self, "_OnRefreshPressed")
    pCardPool.connect("UpgradePressed", self, "_OnUpgradePressed")
    pRoute.connect("RouteChanged", self, "_OnRouteChanged")
    _ApplyMapLayout()
    pShip.Setup(pRoute, self)
    pShip.SetCameraActive(false)
    pSpeedSlider.min_value = nMinLaunchSpeed
    pSpeedSlider.max_value = nMaxLaunchSpeed
    pSpeedSlider.value = pShip.nLaunchSpeed
    pRoute.SetStartPosition(pShip.global_position)
    pRoute.SetPlanetsRoot(pPlanetsRoot)
    pRoute.SetPreviewLaunchSpeed(pShip.nLaunchSpeed)
    pRoute.SetShipReference(pShip)
    vParallaxOrigin = pShip.global_position
    _SetParallaxOffset(Vector2.ZERO)
    pAnchorIndicator.Setup(pAnchorPoint, pShip)
    pMinimap.Setup(pShip, pAnchorPoint, pPlanetsRoot, pRoute.oEditBounds, pEnemyBasesRoot)
    _SetupMissileSfx()
    _SetupEnemyMissileSfx()
    _SetupShipPulseSfx()
    _GeneratePlanets()
    _SetupEnemyBases()
    pSpawnManager.Setup(self, pRoute, pShip)
    _SyncRouteFuelRange()
    _RollCardPool(true)
    pFlowUi.connect("WelcomeFinished", self, "_OnWelcomeFinished")
    pFlowUi.connect("ResetRequested", self, "_OnResetPressed")
    _SetGameplayUiVisible(false)
    _SetPhase(GamePhase.PREP)
    _UpdateUi()

func _SetGameplayUiVisible(bVisible: bool) -> void:
    pGamePanel.visible = bVisible
    pCardPool.visible = bVisible
    pMinimap.visible = bVisible

func _OnWelcomeFinished() -> void:
    _SetGameplayUiVisible(true)
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

    pFlowUi.UpdateDangerMusic(IsShipThreatenedByEnemyBase())
    _TrySpawnLateEnemyBases()

func IsMarchRunning() -> bool:
    return nPhase == GamePhase.MARCH or nPhase == GamePhase.ANCHOR

func IsEscortActive() -> bool:
    return nPhase != GamePhase.WIN and nPhase != GamePhase.LOSE

func IsShipAlive() -> bool:
    return pShip != null and is_instance_valid(pShip) and pShip.nHp > 0.0

func IsShipThreatenedByEnemyBase() -> bool:
    if not IsShipAlive() or not CanDroneAttack():
        return false
    for pBase in vEnemyBases:
        if pBase == null or not is_instance_valid(pBase) or not pBase.bActive:
            continue
        if pBase.has_method("IsShipInAlertRange") and pBase.IsShipInAlertRange():
            return true
    return false

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

func GetAlivePatrolMonsterCount() -> int:
    var nCount = 0
    for pMonster in vMonsters:
        if pMonster == null or not is_instance_valid(pMonster) or not pMonster.bActive:
            continue
        if pMonster.get_parent() != pMonsterRoot:
            continue
        nCount += 1
    return nCount

func GetSpawnViewportSize() -> Vector2:
    return Vector2(pRoute.oEditBounds.size.x, pRoute.oEditBounds.size.y)

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

func GetNearestHostileInRange(vPos: Vector2, nRange: float):
    var pBest = GetNearestMonsterInRange(vPos, nRange)
    var nBestDist = nRange
    if pBest != null:
        nBestDist = vPos.distance_to(pBest.global_position)
    for pBase in vEnemyBases:
        if pBase == null or not is_instance_valid(pBase) or not pBase.bActive:
            continue
        var nDist = vPos.distance_to(pBase.global_position)
        if nDist <= nRange and nDist < nBestDist:
            nBestDist = nDist
            pBest = pBase
    return pBest

func _CanDetectHostile(pMonster, nDetectRadius: float) -> bool:
    if pShip.global_position.distance_to(pMonster.global_position) <= nDetectRadius:
        return true
    if pMonster.has_method("IsAggroActive") and pMonster.IsAggroActive():
        return true
    return false

func GetNearestMonsterInAnchorZone(vFrom: Vector2, nZoneRadius: float):
    var pBest = null
    var nBestDist = INF
    var nDetectRadius = nZoneRadius + 40.0
    for pMonster in vMonsters:
        if pMonster == null or not is_instance_valid(pMonster) or not pMonster.bActive:
            continue
        if not _CanDetectHostile(pMonster, nDetectRadius):
            continue
        var nDist = vFrom.distance_to(pMonster.global_position)
        if nDist < nBestDist:
            nBestDist = nDist
            pBest = pMonster
    for pBase in vEnemyBases:
        if pBase == null or not is_instance_valid(pBase) or not pBase.bActive:
            continue
        if not pBase.has_method("IsShipInAlertRange") or not pBase.IsShipInAlertRange():
            continue
        var nDist = vFrom.distance_to(pBase.global_position)
        if nDist < nBestDist:
            nBestDist = nDist
            pBest = pBase
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
    if not IsShipAlive():
        return null
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

func RegisterBaseGuard(pGuard) -> void:
    if pGuard == null:
        return
    vMonsters.append(pGuard)

func SpawnMissile(vSpawnPos: Vector2, vDirection: Vector2, nDamage: float, pTarget) -> void:
    if not IsShipAlive():
        return
    var pMissile = MissileScene.instance()
    pMissileRoot.add_child(pMissile)
    pMissile.global_position = vSpawnPos
    pMissile.Setup(vDirection, nDamage, pTarget, UnitData.GetMissileSpeed())

func SpawnEnemyMissile(vSpawnPos: Vector2, vDirection: Vector2, nDamage: float, pTarget) -> void:
    if not IsShipAlive():
        return
    var pMissile = MissileScene.instance()
    pMissileRoot.add_child(pMissile)
    pMissile.global_position = vSpawnPos
    pMissile.Setup(vDirection, nDamage, pTarget, UnitData.GetEnemyMissileSpeed(), pMissile.MissileKind.ENEMY)

func SpawnShipPulseMissile(vSpawnPos: Vector2, vDirection: Vector2, nDamage: float, pTarget) -> void:
    if not IsShipAlive():
        return
    var pMissile = MissileScene.instance()
    pMissileRoot.add_child(pMissile)
    pMissile.global_position = vSpawnPos
    pMissile.Setup(vDirection, nDamage, pTarget, UnitData.GetShipPulseSpeed(), pMissile.MissileKind.SHIP_PULSE)

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

func PlayShipPulseLaunchSound(vWorldPos: Vector2) -> void:
    if vShipPulseSfxPlayers.empty():
        return
    var pPlayer = _GetShipPulseSfxPlayer()
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

func _GetShipPulseSfxPlayer() -> AudioStreamPlayer2D:
    for i in range(vShipPulseSfxPlayers.size()):
        var nIndex = (nShipPulseSfxIndex + i) % vShipPulseSfxPlayers.size()
        var pPlayer = vShipPulseSfxPlayers[nIndex]
        if not pPlayer.playing:
            nShipPulseSfxIndex = (nIndex + 1) % vShipPulseSfxPlayers.size()
            return pPlayer
    var pFallback = vShipPulseSfxPlayers[nShipPulseSfxIndex]
    nShipPulseSfxIndex = (nShipPulseSfxIndex + 1) % vShipPulseSfxPlayers.size()
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

func _SetupShipPulseSfx() -> void:
    vShipPulseSfxPlayers.clear()
    for i in range(max(1, nMissileSfxPoolSize)):
        var pPlayer = AudioStreamPlayer2D.new()
        pSfxRoot.add_child(pPlayer)
        var pStream = UnitData.GetShipPulseLaunchSound()
        if pStream != null:
            pStream = pStream.duplicate()
            pStream.loop = false
            pPlayer.stream = pStream
        vShipPulseSfxPlayers.append(pPlayer)

func _ApplyMapLayout() -> void:
    pRoute.oEditBounds = UnitData.GetMapBounds()
    pRoute.vStart = UnitData.GetMapStart()
    pRoute.vDirectionHandle = UnitData.GetMapDefaultDirectionHandle()
    pRoute.nMaxRouteLengthAtFullFuel = UnitData.GetMapMaxRouteLength()
    pRoute.oPreviewBounds = UnitData.GetMapPreviewBounds()
    pRoute.nPreviewMaxDistance = UnitData.GetMapPreviewMaxDistance()
    pShip.global_position = UnitData.GetMapStart()
    pAnchorPoint.global_position = UnitData.GetMapAnchor()
    nGrappleMaxChainLength *= UnitData.GetMapScale() * 0.55
    pShip.nMaxFlightTime *= UnitData.GetMapScale() * 0.85

func _GeneratePlanets() -> void:
    for pChild in pPlanetsRoot.get_children():
        if pChild != null and is_instance_valid(pChild):
            pChild.queue_free()

    var oBounds = UnitData.GetMapBounds()
    var vStart = UnitData.GetMapStart()
    var vAnchor = UnitData.GetMapAnchor()
    var nScale = UnitData.GetMapScale()
    var vLayouts = [
        {"pos": Vector2(480, 610) * nScale, "collision": 42.0, "gravity": 130.0},
        {"pos": Vector2(980, 300) * nScale, "collision": 42.0, "gravity": 150.0},
        {"pos": Vector2(1260, 625) * nScale, "collision": 34.0, "gravity": 110.0, "planet_radius": 34.0},
        {"pos": Vector2(620, 180) * nScale, "collision": 40.0, "gravity": 135.0},
        {"pos": Vector2(420, 420) * nScale, "collision": 36.0, "gravity": 120.0},
        {"pos": Vector2(820, 520) * nScale, "collision": 38.0, "gravity": 128.0},
        {"pos": Vector2(1120, 680) * nScale, "collision": 44.0, "gravity": 145.0},
        {"pos": Vector2(300, 680) * nScale, "collision": 35.0, "gravity": 118.0},
        {"pos": Vector2(1450, 420) * nScale, "collision": 42.0, "gravity": 140.0},
        {"pos": Vector2(520, 120) * nScale, "collision": 36.0, "gravity": 125.0},
    ]
    var vPlaced = []
    for oLayout in vLayouts:
        _AddPlanetFromLayout(oLayout, vPlaced)

    var nTargetCount = 24
    var nMinDist = 360.0
    var nStartClear = 480.0
    var nAnchorClear = 980.0
    var nAttempts = 0
    while vPlaced.size() < nTargetCount and nAttempts < 800:
        nAttempts += 1
        var vPos = Vector2(
            rand_range(oBounds.position.x + 160.0, oBounds.position.x + oBounds.size.x - 160.0),
            rand_range(oBounds.position.y + 160.0, oBounds.position.y + oBounds.size.y - 160.0)
        )
        if vPos.distance_to(vStart) < nStartClear:
            continue
        if vPos.distance_to(vAnchor) < nAnchorClear:
            continue
        if not _IsPlanetSpotValid(vPos, vPlaced, nMinDist):
            continue
        var oRandomLayout = {
            "pos": vPos,
            "collision": rand_range(32.0, 46.0),
            "gravity": rand_range(110.0, 155.0),
        }
        _AddPlanetFromLayout(oRandomLayout, vPlaced)

func _IsPlanetSpotValid(vPos: Vector2, vPlaced: Array, nMinDist: float) -> bool:
    for vOther in vPlaced:
        if vPos.distance_to(vOther) < nMinDist:
            return false
    return true

func _AddPlanetFromLayout(oLayout: Dictionary, vPlaced: Array) -> void:
    var nSizeScale = UnitData.GetPlanetSizeScale()
    var pPlanet = PlanetScene.instance()
    pPlanetsRoot.add_child(pPlanet)
    pPlanet.global_position = oLayout.pos
    pPlanet.nCollisionRadius = oLayout.collision * nSizeScale
    pPlanet.nGravityRadius = oLayout.gravity * nSizeScale
    if oLayout.has("planet_radius"):
        pPlanet.nPlanetRadius = oLayout.planet_radius * nSizeScale
    else:
        pPlanet.nPlanetRadius = oLayout.collision * nSizeScale
    pPlanet.Setup(self)
    vPlaced.append(oLayout.pos)

func _TrySpawnLateEnemyBases() -> void:
    if bLateEnemyBasesSpawned:
        return
    if nPhase != GamePhase.MARCH or not IsShipAlive():
        return
    var vAnchor = pAnchorPoint.global_position
    var nTotalDist = UnitData.GetMapStart().distance_to(vAnchor)
    var nDistToAnchor = pShip.global_position.distance_to(vAnchor)
    if nDistToAnchor > nTotalDist * UnitData.GetLateEnemyBaseSpawnRatio():
        return
    bLateEnemyBasesSpawned = true
    _SpawnLateEnemyBases()

func _SpawnLateEnemyBases() -> void:
    var vAnchor = pAnchorPoint.global_position
    var nScale = UnitData.GetMapScale()
    var vOffsets = [
        Vector2(-920, 520),
        Vector2(-560, -780),
        Vector2(680, 420),
    ]
    for vOffset in vOffsets:
        var pBase = EnemyBaseScene.instance()
        pEnemyBasesRoot.add_child(pBase)
        pBase.global_position = vAnchor + vOffset * (nScale / 6.0)
        pBase.connect("Died", self, "_OnEnemyBaseDied")
        pBase.Setup(self)
        vEnemyBases.append(pBase)

func _SetupEnemyBases() -> void:
    vEnemyBases.clear()
    for pBase in pEnemyBasesRoot.get_children():
        if pBase == null or not is_instance_valid(pBase):
            continue
        if not pBase.has_method("Setup"):
            continue
        pBase.connect("Died", self, "_OnEnemyBaseDied")
        pBase.Setup(self)
        vEnemyBases.append(pBase)

func _SyncRouteFuelRange() -> void:
    pRoute.SetFuelRange(pShip.GetFuel(), pShip.GetMaxFuel(), pShip.GetEffectiveFuelBurnRate())

func _SyncRouteStart() -> void:
    pRoute.SyncStartFromShip(pShip.global_position)

func _RollCardPool(bStartingPool: bool = false) -> void:
    vCards.clear()
    var nSlots = pShip.GetCardSlotCount()
    if bStartingPool:
        vCards = UnitData.GenerateStartingCardPool(nSlots)
        return
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

func _OnEnemyBaseDied(pBase) -> void:
    nGold += nKillGold * 4
    vEnemyBases.erase(pBase)
    if is_instance_valid(pBase):
        pBase.queue_free()
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
    pFlowUi.ShowWin()
    pResultLabel.text = "Anchor reached! Mission complete."
    pResultLabel.add_color_override("font_color", Color(0.45, 0.95, 0.55))
    pPhaseLabel.add_color_override("font_color", Color(0.45, 0.95, 0.55))
    _UpdateUi()

func _OnShipDestroyed() -> void:
    pShip.StopMarch()
    pShip.SetCameraActive(false)
    _SetPhase(GamePhase.LOSE)
    _FreezeCombatOnDefeat()
    pFlowUi.ShowLose()
    pResultLabel.text = "Ship destroyed. Deploy more escort drones."
    pResultLabel.add_color_override("font_color", Color(0.95, 0.45, 0.45))
    pPhaseLabel.add_color_override("font_color", Color(0.95, 0.45, 0.45))
    _UpdateUi()

func _ClearAllMissiles() -> void:
    for pChild in pMissileRoot.get_children():
        if pChild != null and is_instance_valid(pChild):
            pChild.queue_free()

func _FreezeCombatOnDefeat() -> void:
    _ClearAllMissiles()
    for pMonster in vMonsters:
        if pMonster != null and is_instance_valid(pMonster):
            pMonster.set_process(false)
    for pDrone in vDrones:
        if pDrone != null and is_instance_valid(pDrone):
            pDrone.set_process(false)
    for pDrone in vMiningDrones:
        if pDrone != null and is_instance_valid(pDrone):
            pDrone.set_process(false)
    for pBase in vEnemyBases:
        if pBase != null and is_instance_valid(pBase):
            pBase.set_process(false)
    if pShip != null and is_instance_valid(pShip):
        pShip.set_process(false)

func _OnShipFuelDepleted() -> void:
    _UpdateUi()

func _OnShipLevelChanged(nLevel: int) -> void:
    while vCards.size() < pShip.GetCardSlotCount():
        vCards.append(_GenerateSingleCard())
    for pDrone in vDrones:
        if pDrone != null and is_instance_valid(pDrone) and pDrone.has_method("SyncFromShip"):
            pDrone.SyncFromShip()
    for pDrone in vMiningDrones:
        if pDrone != null and is_instance_valid(pDrone) and pDrone.has_method("SyncFromShip"):
            pDrone.SyncFromShip()
    for pBase in vEnemyBases:
        if pBase != null and is_instance_valid(pBase) and pBase.has_method("SyncHpFromShip"):
            pBase.SyncHpFromShip()
    _UpdateUi()

func _OnStartPressed() -> void:
    if CanPlanRoute():
        _BeginRoutePlanning()
        return
    if not CanLaunch():
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
    if nPhase == GamePhase.ANCHOR or nPhase == GamePhase.ANCHOR_PLAN:
        _SyncRouteStart()
        _SyncRouteFuelRange()
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
    _SyncRouteFuelRange()
    _UpdateUi()

func _OnRouteChanged() -> void:
    if nPhase == GamePhase.PREP:
        pShip.ResetPathProgress()
        _SyncRouteStart()
    elif nPhase == GamePhase.ANCHOR_PLAN:
        pShip.ResetFlightState()
        _SyncRouteStart()
    _UpdateUi()

func CanFireGrapple() -> bool:
    return nPhase == GamePhase.MARCH and pShip.bMoving and not pShip.IsBraking()

func _ClearGrapple() -> void:
    if pActiveGrapple != null and is_instance_valid(pActiveGrapple):
        pActiveGrapple.queue_free()
    pActiveGrapple = null
    pShip.ReleaseTether()

func _FireGrapple(vMouseWorld: Vector2) -> void:
    if not CanFireGrapple():
        return

    _ClearGrapple()

    var vDir = vMouseWorld - pShip.global_position
    if vDir.length_squared() <= 64.0:
        vDir = pShip.GetVelocity()
    if vDir.length_squared() <= 1.0:
        vDir = Vector2.RIGHT

    var pGrapple = GrappleAnchorScene.instance()
    pGrappleRoot.add_child(pGrapple)
    pGrapple.connect("Attached", self, "_OnGrappleAttached")
    pGrapple.connect("Missed", self, "_OnGrappleMissed")
    pGrapple.global_position = pShip.global_position + vDir.normalized() * 18.0
    pGrapple.Setup(vDir, pPlanetsRoot, pShip, nGrappleMaxChainLength)
    pActiveGrapple = pGrapple

func _OnGrappleAttached(pPlanet, vLocalOffset, vWorldPos) -> void:
    if not CanDropAnchor():
        _ClearGrapple()
        return
    pShip.AttachTether(pPlanet, vLocalOffset, vWorldPos)
    pShip.StartAnchorBrake()
    _UpdateUi()

func _OnGrappleMissed() -> void:
    pActiveGrapple = null

func GetGrappleChainEndLocal(pShip) -> Dictionary:
    if pActiveGrapple == null or not is_instance_valid(pActiveGrapple):
        return {"valid": false}
    if pShip.IsTethered() or pActiveGrapple.IsAttached():
        return {"valid": false}

    var vLocal = pShip.to_local(pActiveGrapple.global_position)
    var vTowardShip = -vLocal
    if vTowardShip.length_squared() <= 0.001:
        vTowardShip = Vector2.LEFT
    else:
        vTowardShip = vTowardShip.normalized()
    return {"valid": true, "pos": vLocal, "dir": vTowardShip}

func _BeginMarch() -> void:
    _ClearGrapple()
    pRoute.ResetPreviewTrim()
    pRoute.SetEditingEnabled(false)
    _SyncRouteStart()
    _SyncRouteFuelRange()
    pShip.StartMarch()
    pShip.SetCameraActive(true)
    vParallaxOrigin = pShip.global_position
    pSpawnManager.Reset()
    _SetPhase(GamePhase.MARCH)
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
    var oPhaseMuted = Color(0.55, 0.65, 0.78, 0.85)
    var oPhaseAccent = Color(0.45, 0.85, 1.0)
    match nPhase:
        GamePhase.PREP:
            pPhaseLabel.text = "PREP"
            pPhaseLabel.add_color_override("font_color", oPhaseAccent)
            pHintLabel.text = pRoute.GetEditHint() + "  ·  Range %d px" % nFuelRange
        GamePhase.MARCH:
            pPhaseLabel.text = "FLIGHT"
            pPhaseLabel.add_color_override("font_color", oPhaseAccent)
            if pShip.IsBraking():
                pHintLabel.text = "Anchor deployed — braking to a stop."
            elif pShip.IsCoasting():
                pHintLabel.text = "Out of fuel — drifting slowly. Right-click a planet to anchor."
            elif pShip.IsTethered() or pShip.IsBraking():
                pHintLabel.text = "Anchor hooked — braking to a stop."
            else:
                pHintLabel.text = "Fuel draining. Right-click a planet to hook anchor and stop."
        GamePhase.ANCHOR:
            pPhaseLabel.text = "ANCHORED"
            pPhaseLabel.add_color_override("font_color", oPhaseMuted)
            pHintLabel.text = "Mine for fuel/gold, then plan the next route."
        GamePhase.ANCHOR_PLAN:
            pPhaseLabel.text = "PLAN"
            pPhaseLabel.add_color_override("font_color", oPhaseAccent)
            pHintLabel.text = pRoute.GetEditHint() + "  ·  Range ~%d px" % nFuelRange
        GamePhase.WIN:
            pPhaseLabel.text = "VICTORY"
            pPhaseLabel.add_color_override("font_color", Color(0.45, 0.95, 0.55))
            pHintLabel.text = "Press Reset to play again."
        GamePhase.LOSE:
            pPhaseLabel.text = "DEFEAT"
            pPhaseLabel.add_color_override("font_color", Color(0.95, 0.45, 0.45))
            pHintLabel.text = "Press Reset to try again."

    pStatsLabel.text = "LV.%d  HP %d  FUEL %d/%d  GOLD %d\nESCORT %d/%d  MINING %d/%d  KILLS %d  POS (%d,%d)" % [
        pShip.nLevel, int(pShip.nHp), int(pShip.GetFuel()), int(pShip.GetMaxFuel()), nGold,
        vDrones.size(), GetDroneMaxCount(), vMiningDrones.size(), GetMiningDroneMaxCount(), nMonstersKilled,
        int(round(pShip.global_position.x)), int(round(pShip.global_position.y))
    ]
    pSpeedLabel.text = "Launch Speed  %d" % int(round(pShip.nLaunchSpeed))
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
    if event is InputEventMouseButton and event.pressed and event.button_index == BUTTON_RIGHT:
        if CanFireGrapple():
            _FireGrapple(get_global_mouse_position())
            get_tree().set_input_as_handled()
            return

    if event is InputEventKey and event.pressed and not event.echo:
        if event.scancode == KEY_R:
            _OnResetPressed()
