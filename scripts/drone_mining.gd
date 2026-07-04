extends Node2D

const UnitData = preload("res://scripts/unit_data.gd")

enum MiningState { IDLE, TRAVEL_TO, MINING, RETURNING }

var nState = MiningState.IDLE
var nMoveSpeed = 105.0
var nOrbitSpeed = 1.4
var nOrbitRadius = 50.0
var nOrbitAngle = 0.0
var nOrbitSlotOffset = 0.0
var nMineTimer = 0.0
var nMineDuration = 1.5
var nFuelCargo = 0.0
var nGoldCargo = 0
var oColor = Color(0.95, 0.72, 0.25)
var pGame = null
var pShip = null
var pTargetPlanet = null
var bActive = true

onready var pSprite = $Sprite

func Setup(pManager, pShipNode, nSlotIndex: int, nSlotTotal: int) -> void:
    pGame = pManager
    pShip = pShipNode
    nOrbitSlotOffset = UnitData.GetOrbitSlotAngle(nSlotIndex, nSlotTotal)

    var oStats = UnitData.GetMiningStats()
    nMoveSpeed = oStats.move_speed
    nOrbitSpeed = oStats.orbit_speed
    nOrbitRadius = pShip.nAnchorRadius * oStats.orbit_radius_ratio
    oColor = oStats.color
    bActive = true
    nOrbitAngle = nOrbitSlotOffset
    _ApplySprite()
    _ResetMission()
    position = _GetOrbitPosition()
    update()

func SyncFromShip() -> void:
    if pShip == null or not is_instance_valid(pShip):
        return
    var oStats = UnitData.GetMiningStats()
    nOrbitRadius = pShip.nAnchorRadius * oStats.orbit_radius_ratio

func _ApplySprite() -> void:
    if pSprite == null:
        return
    var nScale = UnitData.GetMiningTextureScale()
    pSprite.texture = UnitData.GetMiningTexture()
    pSprite.scale = Vector2(nScale, nScale)

func IsIdle() -> bool:
    return bActive and nState == MiningState.IDLE

func CanDeploy() -> bool:
    return IsIdle() and pTargetPlanet == null

func DeployTo(pPlanet) -> void:
    if not CanDeploy() or pPlanet == null or not is_instance_valid(pPlanet):
        return
    if not pPlanet.has_method("HasMineableResources") or not pPlanet.HasMineableResources():
        return
    pTargetPlanet = pPlanet
    nState = MiningState.TRAVEL_TO
    update()

func _ResetMission() -> void:
    nState = MiningState.IDLE
    nMineTimer = 0.0
    nFuelCargo = 0.0
    nGoldCargo = 0
    pTargetPlanet = null

func _process(delta: float) -> void:
    if not bActive or pShip == null or not is_instance_valid(pShip):
        return
    if pGame == null or not pGame.IsShipAlive():
        return

    nOrbitAngle += nOrbitSpeed * delta

    match nState:
        MiningState.IDLE:
            global_position = _GetOrbitPosition()
        MiningState.TRAVEL_TO:
            _MoveTowards(_GetPlanetCenter(), delta)
            if global_position.distance_to(_GetPlanetCenter()) <= 8.0:
                nState = MiningState.MINING
                var oStats = UnitData.GetMiningStats()
                nMineDuration = rand_range(oStats.mine_time_min, oStats.mine_time_max)
                nMineTimer = nMineDuration
        MiningState.MINING:
            global_position = _GetPlanetCenter()
            nMineTimer -= delta
            if nMineTimer <= 0.0:
                _CollectCargo()
                nState = MiningState.RETURNING
        MiningState.RETURNING:
            _MoveTowards(pShip.global_position, delta)
            if global_position.distance_to(pShip.global_position) <= 14.0:
                _DeliverCargo()
                _ResetMission()

    update()

func _GetPlanetCenter() -> Vector2:
    if pTargetPlanet != null and is_instance_valid(pTargetPlanet):
        return pTargetPlanet.global_position
    return global_position

func _CollectCargo() -> void:
    if pTargetPlanet == null or not is_instance_valid(pTargetPlanet):
        return
    if not pTargetPlanet.has_method("ExtractResources"):
        return
    var oStats = UnitData.GetMiningStats()
    var oYield = pTargetPlanet.ExtractResources(oStats.fuel_per_trip, oStats.gold_per_trip)
    nFuelCargo = oYield.fuel
    nGoldCargo = oYield.gold

func _DeliverCargo() -> void:
    if pGame != null and pGame.has_method("OnMiningDroneDelivered"):
        pGame.OnMiningDroneDelivered(nFuelCargo, nGoldCargo)
    nFuelCargo = 0.0
    nGoldCargo = 0

func _MoveTowards(vTarget: Vector2, delta: float) -> void:
    var vToTarget = vTarget - global_position
    var nDist = vToTarget.length()
    if nDist <= 0.001:
        return
    var nStep = nMoveSpeed * delta
    if nStep >= nDist:
        global_position = vTarget
    else:
        global_position += vToTarget.normalized() * nStep

func _GetOrbitPosition() -> Vector2:
    var vDir = Vector2(cos(nOrbitAngle + nOrbitSlotOffset * 0.12), sin(nOrbitAngle + nOrbitSlotOffset * 0.12))
    return pShip.global_position + vDir * nOrbitRadius

func _draw() -> void:
    if nState == MiningState.MINING:
        draw_arc(Vector2.ZERO, 14.0, 0.0, TAU, 24, Color(0.95, 0.78, 0.25, 0.35), 2.0, true)

    if nState == MiningState.RETURNING and (nFuelCargo > 0.0 or nGoldCargo > 0):
        draw_circle(Vector2(0, -12), 3.0, Color(0.35, 0.85, 1.0))
        draw_circle(Vector2(6, -10), 2.5, Color(0.95, 0.78, 0.25))
