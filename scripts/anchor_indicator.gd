extends Control

export(float) var nEdgeMargin = 32.0
export(float) var nIconRadius = 11.0
export(Color) var oFillColor = Color(0.1, 0.95, 0.65, 0.28)
export(Color) var oRingColor = Color(0.25, 1.0, 0.75, 0.9)
export(Color) var oCrossColor = Color(0.85, 1.0, 0.92, 0.95)

var pAnchor = null
var pShip = null
var bEnabled = true

func Setup(pAnchorNode, pShipNode) -> void:
    pAnchor = pAnchorNode
    pShip = pShipNode
    _RefreshVisibility()

func SetIndicatorVisible(bShow: bool) -> void:
    bEnabled = bShow
    _RefreshVisibility()

func _ready() -> void:
    mouse_filter = Control.MOUSE_FILTER_IGNORE
    rect_min_size = get_viewport_rect().size

func _process(_delta: float) -> void:
    _RefreshVisibility()

func _RefreshVisibility() -> void:
    if not bEnabled or pAnchor == null:
        visible = false
        return

    var bOnScreen = _IsAnchorOnScreen()
    var bShouldShow = not bOnScreen
    if visible != bShouldShow:
        visible = bShouldShow
    if visible:
        update()

func _IsAnchorOnScreen() -> bool:
    var oBounds = _GetEdgeBounds()
    if oBounds.size.x <= 0.0 or oBounds.size.y <= 0.0:
        return false
    return oBounds.has_point(_WorldToLocal(pAnchor.global_position))

func _GetEdgeBounds() -> Rect2:
    return Rect2(
        nEdgeMargin,
        nEdgeMargin,
        rect_size.x - nEdgeMargin * 2.0,
        rect_size.y - nEdgeMargin * 2.0
    )

func _WorldToLocal(vWorldPos: Vector2) -> Vector2:
    var vCanvas = get_viewport().get_canvas_transform().xform(vWorldPos)
    return vCanvas - rect_global_position

func _draw() -> void:
    if not visible or pAnchor == null:
        return

    var oBounds = _GetEdgeBounds()
    if oBounds.size.x <= 0.0 or oBounds.size.y <= 0.0:
        return

    var vAnchorLocal = _WorldToLocal(pAnchor.global_position)
    var vCenter = oBounds.get_center()
    var vToAnchor = vAnchorLocal - vCenter
    if vToAnchor.length_squared() <= 0.001:
        vToAnchor = Vector2.UP
    var vPointerDir = vToAnchor.normalized()
    var vDrawPos = _ClampToRectEdge(vCenter, vPointerDir, oBounds)

    _DrawAnchorIcon(vDrawPos, vPointerDir)

    var nDistance = pShip.global_position.distance_to(pAnchor.global_position) if pShip != null else 0.0
    var sDistance = "%dm" % int(round(nDistance))
    var oFont = get_font("font")
    if oFont != null:
        var vTextSize = oFont.get_string_size(sDistance)
        var vTextPos = vDrawPos + Vector2(-vTextSize.x * 0.5, nIconRadius + 14.0)
        draw_string(oFont, vTextPos, sDistance, oRingColor)

func _DrawAnchorIcon(vPos: Vector2, vPointerDir: Vector2) -> void:
    var nRadius = nIconRadius * 0.9
    draw_circle(vPos, nRadius, oFillColor)
    draw_arc(vPos, nRadius, 0.0, TAU, 24, oRingColor, 2.0, true)
    draw_line(vPos + Vector2(-7, 0), vPos + Vector2(7, 0), oCrossColor, 2.0, true)
    draw_line(vPos + Vector2(0, -7), vPos + Vector2(0, 7), oCrossColor, 2.0, true)

    if vPointerDir.length_squared() > 0.001:
        var vTip = vPos + vPointerDir * (nRadius + 7.0)
        var vSide = Vector2(-vPointerDir.y, vPointerDir.x) * 5.0
        draw_colored_polygon(
            PoolVector2Array([vTip, vPos + vPointerDir * 2.0 + vSide, vPos + vPointerDir * 2.0 - vSide]),
            oRingColor
        )

func _ClampToRectEdge(vCenter: Vector2, vDir: Vector2, oRect: Rect2) -> Vector2:
    var nBestT = INF
    if abs(vDir.x) > 0.0001:
        var nTx = (oRect.position.x - vCenter.x) / vDir.x if vDir.x < 0.0 else (oRect.position.x + oRect.size.x - vCenter.x) / vDir.x
        if nTx >= 0.0:
            nBestT = min(nBestT, nTx)
    if abs(vDir.y) > 0.0001:
        var nTy = (oRect.position.y - vCenter.y) / vDir.y if vDir.y < 0.0 else (oRect.position.y + oRect.size.y - vCenter.y) / vDir.y
        if nTy >= 0.0:
            nBestT = min(nBestT, nTy)
    if nBestT == INF:
        return vCenter
    return vCenter + vDir * nBestT
