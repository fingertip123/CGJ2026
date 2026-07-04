extends Node2D

signal RouteChanged

export(Vector2) var vStart = Vector2(140, 740)
export(Vector2) var vDirectionHandle = Vector2(360, 650)
export(float) var nMaxRouteLengthAtFullFuel = 820.0
export(float) var nPreviewFuelBurnRate = 5.5
export(int) var nGravityPreviewSteps = 360
export(float) var nGravityPreviewDelta = 0.05
export(float) var nPreviewLaunchSpeed = 140.0
export(Rect2) var oEditBounds = Rect2(Vector2.ZERO, Vector2(1600, 790))
export(float) var nHandleRadius = 12.0
export(float) var nMinDirectionLength = 32.0

enum RouteHandle { NONE = -1, DIRECTION = 0 }

var bHasRoute = false
var bEditingEnabled = true
var nDraggedHandle = RouteHandle.NONE
var pPlanetsRoot = null
var nCurrentFuelRange = 0.0
var nPreviewFuel = 0.0

func SetPlanetsRoot(pRoot) -> void:
    pPlanetsRoot = pRoot
    update()

func SetPreviewLaunchSpeed(nValue: float) -> void:
    nPreviewLaunchSpeed = nValue
    update()

func SetFuelRange(nFuelAmount: float, nMaxFuelAmount: float, nBurnRate: float) -> void:
    var nRatio = 0.0 if nMaxFuelAmount <= 0.0 else clamp(nFuelAmount / nMaxFuelAmount, 0.0, 1.0)
    nCurrentFuelRange = nRatio * nMaxRouteLengthAtFullFuel
    nPreviewFuel = max(0.0, nFuelAmount)
    nPreviewFuelBurnRate = max(0.001, nBurnRate)
    if bHasRoute:
        vDirectionHandle = _ClampDirectionToFuelRange(vDirectionHandle)
    update()

func ClearRoute() -> void:
    bHasRoute = false
    nDraggedHandle = RouteHandle.NONE
    update()

func GetRouteLength() -> float:
    return nCurrentFuelRange

func GetFuelRange() -> float:
    return nCurrentFuelRange

func SetStartPosition(vPos: Vector2) -> void:
    var vClamped = _ClampToEditBounds(vPos)
    if vStart.distance_to(vClamped) < 0.01:
        return
    vStart = vClamped
    update()

func SetEditingEnabled(bEnabled: bool) -> void:
    bEditingEnabled = bEnabled
    if not bEditingEnabled:
        nDraggedHandle = RouteHandle.NONE
    update()

func HasRoute() -> bool:
    return bHasRoute

func GetStartPosition() -> Vector2:
    return vStart

func GetDirection() -> Vector2:
    if not bHasRoute:
        return Vector2.RIGHT
    var vDir = vDirectionHandle - vStart
    if vDir.length_squared() <= 0.001:
        return Vector2.RIGHT
    return vDir.normalized()

func GetGravityAcceleration(vWorldPos: Vector2) -> Vector2:
    var vAcceleration = Vector2.ZERO
    if pPlanetsRoot == null or not is_instance_valid(pPlanetsRoot):
        return vAcceleration

    for pPlanet in pPlanetsRoot.get_children():
        if pPlanet != null and is_instance_valid(pPlanet) and pPlanet.has_method("GetGravityAcceleration"):
            vAcceleration += pPlanet.GetGravityAcceleration(vWorldPos)
    return vAcceleration

func GetEditHint() -> String:
    if bHasRoute:
        return "Drag direction handle. Range is limited by current fuel."
    if nCurrentFuelRange <= 0.0:
        return "Need fuel before plotting a course."
    return "Click to set launch direction (max range: %d)." % int(nCurrentFuelRange)

func GetPositionAt(t: float) -> Vector2:
    if not bHasRoute:
        return vStart
    return vStart + GetDirection() * GetRouteLength() * clamp(t, 0.0, 1.0)

func GetNormalAt(t: float) -> Vector2:
    if not bHasRoute:
        return Vector2(0, -1)
    var vDir = GetDirection()
    return Vector2(-vDir.y, vDir.x).normalized()

func GetSideSpawnPosition(t: float, nSide: int, nDistance: float) -> Vector2:
    var vCenter = GetPositionAt(t)
    var vNormal = GetNormalAt(t)
    if nSide < 0:
        vNormal *= -1.0
    return vCenter + vNormal * nDistance

func _unhandled_input(event: InputEvent) -> void:
    if not bEditingEnabled:
        return

    if event is InputEventMouseMotion:
        if nDraggedHandle != RouteHandle.NONE:
            _SetDirectionHandle(_ClampToEditBounds(get_global_mouse_position()))
            get_tree().set_input_as_handled()
        return

    if not (event is InputEventMouseButton):
        return
    if event.button_index != BUTTON_LEFT:
        return

    var vRawMouse = get_global_mouse_position()
    var vMouse = _ClampToEditBounds(vRawMouse)
    if event.pressed:
        if not oEditBounds.has_point(vRawMouse):
            return

        if nCurrentFuelRange <= 0.0:
            return

        if bHasRoute and _FindHandleAt(vMouse) != RouteHandle.NONE:
            nDraggedHandle = RouteHandle.DIRECTION
            get_tree().set_input_as_handled()
            return

        if vStart.distance_to(vMouse) >= nMinDirectionLength:
            _SetDirectionHandle(vMouse)
            nDraggedHandle = RouteHandle.DIRECTION
            get_tree().set_input_as_handled()
            return
    else:
        if nDraggedHandle != RouteHandle.NONE:
            nDraggedHandle = RouteHandle.NONE
            get_tree().set_input_as_handled()

func _SetDirectionHandle(vPos: Vector2) -> void:
    vPos = _ClampDirectionToFuelRange(vPos)
    if vStart.distance_to(vPos) < nMinDirectionLength:
        return
    vDirectionHandle = vPos
    bHasRoute = true
    emit_signal("RouteChanged")
    update()

func _ClampDirectionToFuelRange(vPos: Vector2) -> Vector2:
    if nCurrentFuelRange <= 0.0:
        return vPos
    var vDelta = vPos - vStart
    var nDist = vDelta.length()
    if nDist <= nCurrentFuelRange or nDist <= 0.001:
        return vPos
    return vStart + vDelta.normalized() * nCurrentFuelRange

func _FindHandleAt(vPos: Vector2) -> int:
    var nGrabRadius = nHandleRadius + 6.0
    if bHasRoute and vPos.distance_to(vDirectionHandle) <= nGrabRadius:
        return RouteHandle.DIRECTION
    return RouteHandle.NONE

func _ClampToEditBounds(vPos: Vector2) -> Vector2:
    return Vector2(
        clamp(vPos.x, oEditBounds.position.x, oEditBounds.position.x + oEditBounds.size.x),
        clamp(vPos.y, oEditBounds.position.y, oEditBounds.position.y + oEditBounds.size.y)
    )

func _draw() -> void:
    if nCurrentFuelRange > 0.0 and bEditingEnabled:
        draw_arc(vStart, nCurrentFuelRange, 0.0, TAU, 72, Color(0.35, 0.85, 1.0, 0.12), 1.5, true)
        draw_arc(vStart, nCurrentFuelRange, 0.0, TAU, 72, Color(0.35, 0.85, 1.0, 0.35), 1.0, true)

    if not bHasRoute:
        draw_circle(vStart, nHandleRadius, Color(0.35, 0.9, 0.45))
        return

    var vPreview = _BuildGravityPreview()
    for i in range(vPreview.size() - 1):
        draw_line(vPreview[i], vPreview[i + 1], Color(0.35, 0.75, 0.95, 0.85), 4.0, true)
    _DrawDashedPolyline(vPreview, Color(0.92, 0.94, 0.96, 0.86), 2.0, 10.0, 14.0)

    draw_circle(vStart, 14.0, Color(0.35, 0.9, 0.45))
    draw_line(vStart, vDirectionHandle, Color(0.45, 0.75, 1.0, 0.45), 2.0, true)
    draw_circle(vDirectionHandle, nHandleRadius, Color(1.0, 0.7, 0.15))
    draw_line(vDirectionHandle - Vector2(8, 0), vDirectionHandle + Vector2(8, 0), Color(1.0, 0.92, 0.45), 2.0, true)
    draw_line(vDirectionHandle - Vector2(0, 8), vDirectionHandle + Vector2(0, 8), Color(1.0, 0.92, 0.45), 2.0, true)

func _BuildGravityPreview() -> PoolVector2Array:
    var vPoints = PoolVector2Array()
    var vPos = vStart
    var vVelocity = GetDirection() * nPreviewLaunchSpeed
    var nFuelLeft = nPreviewFuel
    vPoints.append(vPos)

    for i in range(nGravityPreviewSteps):
        nFuelLeft -= nPreviewFuelBurnRate * nGravityPreviewDelta
        if nFuelLeft <= 0.0:
            break
        vVelocity += GetGravityAcceleration(vPos) * nGravityPreviewDelta
        vPos += vVelocity * nGravityPreviewDelta
        vPoints.append(vPos)
        if vPos.distance_to(vStart) > nCurrentFuelRange * 1.35:
            break
        if not oEditBounds.has_point(vPos):
            break

    return vPoints

func _DrawDashedPolyline(vPoints, oColor: Color, nWidth: float, nDashLength: float, nDashGap: float) -> void:
    if vPoints.size() < 2:
        return

    var nPatternLength = nDashLength + nDashGap
    if nPatternLength <= 0.001:
        return

    var nPatternDistance = 0.0
    for i in range(1, vPoints.size()):
        var vFrom = vPoints[i - 1]
        var vTo = vPoints[i]
        var vSegment = vTo - vFrom
        var nSegmentLength = vSegment.length()
        if nSegmentLength <= 0.001:
            continue

        var vDir = vSegment / nSegmentLength
        var nSegmentDistance = 0.0
        while nSegmentDistance < nSegmentLength:
            var nPatternOffset = fmod(nPatternDistance, nPatternLength)
            var bDrawingDash = nPatternOffset < nDashLength
            var nRemainingPattern = nDashLength - nPatternOffset if bDrawingDash else nPatternLength - nPatternOffset
            var nStep = min(nRemainingPattern, nSegmentLength - nSegmentDistance)
            if bDrawingDash:
                draw_line(vFrom + vDir * nSegmentDistance, vFrom + vDir * (nSegmentDistance + nStep), oColor, nWidth, true)
            nSegmentDistance += nStep
            nPatternDistance += nStep
