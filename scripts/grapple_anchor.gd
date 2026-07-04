extends Node2D

signal Attached(pPlanet, vLocalOffset, vWorldPos)
signal Missed

export(float) var nSpeed = 520.0
export(float) var nMaxChainLength = 480.0
export(float) var nHitPadding = 4.0

var vVelocity = Vector2.ZERO
var bAttached = false
var pPlanet = null
var vLocalOffset = Vector2.ZERO
var pPlanetsRoot = null
var pShip = null

func Setup(vDirection: Vector2, pPlanetsRootNode, pShipNode, nChainLengthLimit: float = -1.0) -> void:
    pPlanetsRoot = pPlanetsRootNode
    pShip = pShipNode
    if nChainLengthLimit > 0.0:
        nMaxChainLength = nChainLengthLimit
    vVelocity = vDirection.normalized() * nSpeed if vDirection.length_squared() > 0.001 else Vector2.RIGHT * nSpeed
    bAttached = false
    pPlanet = null
    update()

func IsAttached() -> bool:
    return bAttached

func GetPlanet() -> Node:
    return pPlanet

func _process(delta: float) -> void:
    if bAttached:
        if pPlanet == null or not is_instance_valid(pPlanet):
            queue_free()
            return
        global_position = pPlanet.global_position + vLocalOffset
        update()
        return

    var vMotion = vVelocity * delta
    global_position += vMotion

    if pShip == null or not is_instance_valid(pShip):
        emit_signal("Missed")
        queue_free()
        return

    if pShip.global_position.distance_to(global_position) >= nMaxChainLength:
        emit_signal("Missed")
        queue_free()
        return

    _TryAttachToPlanet()
    update()

func _TryAttachToPlanet() -> void:
    if pPlanetsRoot == null or not is_instance_valid(pPlanetsRoot):
        return

    for pNode in pPlanetsRoot.get_children():
        if pNode == null or not is_instance_valid(pNode):
            continue
        if not pNode.has_method("GetCollisionRadius"):
            continue

        var vToAnchor = global_position - pNode.global_position
        var nDist = vToAnchor.length()
        var nPlanetRadius = pNode.GetCollisionRadius()
        if nDist > nPlanetRadius + nHitPadding:
            continue

        var vDir = Vector2.RIGHT if nDist <= 0.001 else vToAnchor / nDist
        vLocalOffset = vDir * nPlanetRadius
        pPlanet = pNode
        bAttached = true
        global_position = pPlanet.global_position + vLocalOffset
        emit_signal("Attached", pPlanet, vLocalOffset, global_position)
        return
