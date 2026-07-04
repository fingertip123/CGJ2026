extends Control

export(Rect2) var oWorldBounds = Rect2(0, 0, 1600, 790)
export(float) var nMapPadding = 10.0

var pShip = null
var pAnchor = null
var pPlanetsRoot = null

func Setup(pShipNode, pAnchorNode, pPlanetsRootNode, oBounds: Rect2 = Rect2()) -> void:
    pShip = pShipNode
    pAnchor = pAnchorNode
    pPlanetsRoot = pPlanetsRootNode
    if oBounds.size != Vector2.ZERO:
        oWorldBounds = oBounds
    else:
        _AutoFitBounds()
    update()

func _ready() -> void:
    mouse_filter = Control.MOUSE_FILTER_IGNORE

func _process(_delta: float) -> void:
    update()

func _AutoFitBounds() -> void:
    var oBounds = Rect2()
    var bHasPoint = false

    for pNode in [pShip, pAnchor]:
        if pNode == null or not is_instance_valid(pNode):
            continue
        var vPos = pNode.global_position
        if not bHasPoint:
            oBounds = Rect2(vPos, Vector2.ZERO)
            bHasPoint = true
        else:
            oBounds = oBounds.expand(vPos)

    if pPlanetsRoot != null and is_instance_valid(pPlanetsRoot):
        for pPlanet in pPlanetsRoot.get_children():
            if pPlanet == null or not is_instance_valid(pPlanet):
                continue
            var vPos = pPlanet.global_position
            if not bHasPoint:
                oBounds = Rect2(vPos, Vector2.ZERO)
                bHasPoint = true
            else:
                oBounds = oBounds.expand(vPos)

    if bHasPoint:
        oWorldBounds = oBounds.grow(80.0)

func _GetMapRect() -> Rect2:
    return Rect2(
        nMapPadding,
        nMapPadding,
        rect_size.x - nMapPadding * 2.0,
        rect_size.y - nMapPadding * 2.0
    )

func _GetMapScale() -> float:
    var oMap = _GetMapRect()
    if oWorldBounds.size.x <= 0.0 or oWorldBounds.size.y <= 0.0:
        return 1.0
    return min(oMap.size.x / oWorldBounds.size.x, oMap.size.y / oWorldBounds.size.y)

func _GetMapOffset() -> Vector2:
    var oMap = _GetMapRect()
    var vContentSize = oWorldBounds.size * _GetMapScale()
    return oMap.position + (oMap.size - vContentSize) * 0.5

func _WorldToMap(vWorld: Vector2) -> Vector2:
    return _GetMapOffset() + (vWorld - oWorldBounds.position) * _GetMapScale()

func _WorldDistanceToMap(nWorldDistance: float) -> float:
    return nWorldDistance * _GetMapScale()

func _draw() -> void:
    draw_rect(Rect2(Vector2.ZERO, rect_size), Color(0.04, 0.06, 0.11, 0.92))
    draw_rect(Rect2(Vector2.ZERO, rect_size), Color(0.28, 0.38, 0.55, 0.75), false, 1.5)

    var oMap = _GetMapRect()
    draw_rect(oMap, Color(0.07, 0.09, 0.15, 0.9))
    draw_rect(oMap, Color(0.18, 0.24, 0.36, 0.55), false, 1.0)

    var vWorldRectPos = _WorldToMap(oWorldBounds.position)
    var vWorldRectEnd = _WorldToMap(oWorldBounds.position + oWorldBounds.size)
    draw_rect(Rect2(vWorldRectPos, vWorldRectEnd - vWorldRectPos), Color(0.12, 0.16, 0.24, 0.35), false, 1.0)

    _DrawCameraView()
    _DrawPlanets()
    _DrawAnchor()
    _DrawShip()

    var oFont = get_font("font")
    if oFont != null:
        draw_string(oFont, Vector2(8, 14), "Map", Color(0.75, 0.82, 0.95, 0.9))

func _DrawCameraView() -> void:
    if pShip == null or not is_instance_valid(pShip):
        return

    var pCamera = pShip.get_node_or_null("Camera2D")
    if pCamera == null or not pCamera.current:
        return

    var vViewportSize = get_viewport_rect().size
    var vZoom = pCamera.zoom if pCamera.zoom.x > 0.001 else Vector2.ONE
    var vHalfSize = Vector2(vViewportSize.x / vZoom.x, vViewportSize.y / vZoom.y) * 0.5
    var vCenter = pShip.global_position
    var oCameraRect = Rect2(vCenter - vHalfSize, vHalfSize * 2.0)

    var vTopLeft = _WorldToMap(oCameraRect.position)
    var vBottomRight = _WorldToMap(oCameraRect.position + oCameraRect.size)
    draw_rect(Rect2(vTopLeft, vBottomRight - vTopLeft), Color(0.95, 0.9, 0.55, 0.18))
    draw_rect(Rect2(vTopLeft, vBottomRight - vTopLeft), Color(0.95, 0.9, 0.55, 0.55), false, 1.0)

func _DrawPlanets() -> void:
    if pPlanetsRoot == null or not is_instance_valid(pPlanetsRoot):
        return

    for pPlanet in pPlanetsRoot.get_children():
        if pPlanet == null or not is_instance_valid(pPlanet):
            continue

        var vPos = _WorldToMap(pPlanet.global_position)
        var nGravityRadius = pPlanet.nGravityRadius
        var nPlanetRadius = pPlanet.nPlanetRadius
        var nGravityMapRadius = max(2.0, _WorldDistanceToMap(nGravityRadius))
        var nPlanetMapRadius = max(2.5, _WorldDistanceToMap(nPlanetRadius))

        draw_circle(vPos, nGravityMapRadius, Color(0.35, 0.55, 0.95, 0.12))
        draw_circle(vPos, nPlanetMapRadius, Color(0.45, 0.55, 0.95, 0.95))
        draw_arc(vPos, nPlanetMapRadius, 0.0, TAU, 16, Color(0.75, 0.85, 1.0, 0.8), 1.0, true)

func _DrawAnchor() -> void:
    if pAnchor == null or not is_instance_valid(pAnchor):
        return

    var vPos = _WorldToMap(pAnchor.global_position)
    var nRadius = 5.0
    draw_circle(vPos, nRadius, Color(0.1, 0.95, 0.65, 0.35))
    draw_arc(vPos, nRadius, 0.0, TAU, 20, Color(0.25, 1.0, 0.75, 0.95), 1.5, true)
    draw_line(vPos + Vector2(-5, 0), vPos + Vector2(5, 0), Color(0.85, 1.0, 0.92), 1.5, true)
    draw_line(vPos + Vector2(0, -5), vPos + Vector2(0, 5), Color(0.85, 1.0, 0.92), 1.5, true)

func _DrawShip() -> void:
    if pShip == null or not is_instance_valid(pShip):
        return

    var vPos = _WorldToMap(pShip.global_position)
    var vVelocity = pShip.GetVelocity() if pShip.has_method("GetVelocity") else Vector2.ZERO

    if vVelocity.length_squared() > 4.0:
        var vDir = vVelocity.normalized()
        var vTip = vPos + vDir * 7.0
        var vSide = Vector2(-vDir.y, vDir.x) * 4.0
        draw_colored_polygon(PoolVector2Array([vTip, vPos - vDir * 2.0 + vSide, vPos - vDir * 2.0 - vSide]), Color(0.45, 0.85, 1.0, 0.95))
    else:
        draw_circle(vPos, 4.0, Color(0.45, 0.85, 1.0, 0.95))

    draw_circle(vPos, 2.0, Color(0.9, 0.96, 1.0))
