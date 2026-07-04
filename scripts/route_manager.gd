extends Node2D

signal RouteChanged

export(Vector2) var vStart = Vector2(840, 4440)
export(Vector2) var vDirectionHandle = Vector2(2160, 3900)
export(float) var nMaxRouteLengthAtFullFuel = 4920.0
export(float) var nPreviewFuelBurnRate = 3.5
export(int) var nGravityPreviewSteps = 360
export(float) var nGravityPreviewDelta = 0.05
export(float) var nPreviewLaunchSpeed = 140.0
export(Rect2) var oEditBounds = Rect2(Vector2.ZERO, Vector2(9600, 4740))
export(Rect2) var oPreviewBounds = Rect2(-3600, -3600, 16800, 12600)
export(float) var nPreviewMaxDistance = 36000.0
export(float) var nHandleRadius = 12.0
export(float) var nMinDirectionLength = 32.0

enum RouteHandle { NONE = -1, DIRECTION = 0 }

var bHasRoute = false
var bEditingEnabled = true
var nDraggedHandle = RouteHandle.NONE
var pPlanetsRoot = null
var pShip = null
var nCurrentFuelRange = 0.0
var nPreviewFuel = 0.0
var nPreviewTrimDistance = 0.0

func SetPlanetsRoot(pRoot) -> void:
    pPlanetsRoot = pRoot
    update()

func SetShipReference(pShipNode) -> void:
    pShip = pShipNode

func ResetPreviewTrim() -> void:
    nPreviewTrimDistance = 0.0
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
    ResetPreviewTrim()

func GetRouteLength() -> float:
    return nCurrentFuelRange

func GetFuelRange() -> float:
    return nCurrentFuelRange

func IsDraggingRoute() -> bool:
    return nDraggedHandle != RouteHandle.NONE

func _GetEditFuelRange() -> float:
    if nCurrentFuelRange > 0.0:
        return nCurrentFuelRange
    if bEditingEnabled:
        return nMaxRouteLengthAtFullFuel
    return 0.0

func _GetPreviewFuelAmount() -> float:
    if nPreviewFuel > 0.0:
        return nPreviewFuel
    if bEditingEnabled and pShip != null and is_instance_valid(pShip):
        if pShip.has_method("GetMaxFuelForRoutePlanning"):
            return pShip.GetMaxFuelForRoutePlanning()
        return pShip.GetMaxFuel()
    return 0.0

func SetStartPosition(vPos: Vector2) -> void:
    SyncStartFromShip(vPos)

func SyncStartFromShip(vPos: Vector2) -> void:
    var vDelta = vPos - vStart
    if vDelta.length_squared() <= 0.001:
        return
    vStart = vPos
    if bHasRoute:
        vDirectionHandle += vDelta
        vDirectionHandle = _ClampDirectionToFuelRange(vDirectionHandle)
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
    var nEditRange = _GetEditFuelRange()
    if bHasRoute:
        if nCurrentFuelRange <= 0.0:
            return "Drag direction handle. Refuel before launch."
        return "Drag direction handle. Range is limited by current fuel."
    if nEditRange <= 0.0:
        return "Need fuel before plotting a course."
    if nCurrentFuelRange <= 0.0:
        return "Click to set direction (preview range %d, refuel to launch)." % int(nEditRange)
    return "Click to set launch direction (max range: %d)." % int(nEditRange)

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

        if _GetEditFuelRange() <= 0.0:
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
    ResetPreviewTrim()
    emit_signal("RouteChanged")

func _ClampDirectionToFuelRange(vPos: Vector2) -> Vector2:
    var nEditRange = _GetEditFuelRange()
    if nEditRange <= 0.0:
        return vPos
    var vDelta = vPos - vStart
    var nDist = vDelta.length()
    if nDist <= nEditRange or nDist <= 0.001:
        return vPos
    return vStart + vDelta.normalized() * nEditRange

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
    var nEditRange = _GetEditFuelRange()
    if nEditRange > 0.0 and bEditingEnabled:
        var oRangeFill = Color(0.35, 0.85, 1.0, 0.12 if nCurrentFuelRange > 0.0 else 0.08)
        var oRangeLine = Color(0.35, 0.85, 1.0, 0.35 if nCurrentFuelRange > 0.0 else 0.22)
        draw_arc(vStart, nEditRange, 0.0, TAU, 72, oRangeFill, 1.5, true)
        draw_arc(vStart, nEditRange, 0.0, TAU, 72, oRangeLine, 1.0, true)

    if not bHasRoute:
        return

    var oPreviewColor = Color(0.86, 0.88, 0.92, 0.75)
    var vPreview = _GetPreviewPointsForDraw()
    if vPreview.size() >= 2:
        _DrawDashedPolyline(vPreview, oPreviewColor, 1.0, 8.0, 6.0)

    if bEditingEnabled:
        draw_circle(vDirectionHandle, nHandleRadius, Color(1.0, 0.7, 0.15))
        draw_line(vDirectionHandle - Vector2(8, 0), vDirectionHandle + Vector2(8, 0), Color(1.0, 0.92, 0.45), 2.0, true)
        draw_line(vDirectionHandle - Vector2(0, 8), vDirectionHandle + Vector2(0, 8), Color(1.0, 0.92, 0.45), 2.0, true)

func _BuildGravityPreview() -> PoolVector2Array:
    var vPoints = PoolVector2Array()
    var vPos = vStart
    var vVelocity = GetDirection() * nPreviewLaunchSpeed
    var nFuelLeft = _GetPreviewFuelAmount()
    vPoints.append(vPos)

    for i in range(nGravityPreviewSteps):
        nFuelLeft -= nPreviewFuelBurnRate * nGravityPreviewDelta
        if nFuelLeft <= 0.0:
            break
        vVelocity += GetGravityAcceleration(vPos) * nGravityPreviewDelta
        vPos += vVelocity * nGravityPreviewDelta
        vPoints.append(vPos)
        if not oPreviewBounds.has_point(vPos):
            break
        if vStart.distance_to(vPos) >= nPreviewMaxDistance:
            break

    return vPoints

func _GetPreviewPointsForDraw() -> PoolVector2Array:
    var vPreview = _BuildGravityPreview()
    if bEditingEnabled:
        return vPreview

    if pShip == null:
        return PoolVector2Array()
    if not is_instance_valid(pShip):
        return PoolVector2Array()
    if not pShip.bMoving:
        return PoolVector2Array()

    _AdvancePreviewTrim(vPreview, pShip.global_position)
    return _TrimPreviewFromDistance(vPreview, nPreviewTrimDistance)

func _process(_delta: float) -> void:
    if not bEditingEnabled and bHasRoute and pShip != null and is_instance_valid(pShip) and pShip.bMoving:
        update()

func _AdvancePreviewTrim(vPoints, vShipPos: Vector2) -> void:
    if vPoints.size() < 2:
        return

    var nCumulative = 0.0
    var nBestTotal = 0.0
    var nBestDistSq = INF

    for i in range(1, vPoints.size()):
        var vFrom = vPoints[i - 1]
        var vTo = vPoints[i]
        var vSeg = vTo - vFrom
        var nLenSq = vSeg.length_squared()
        var nSegLen = 0.0
        if nLenSq > 0.001:
            nSegLen = sqrt(nLenSq)
        var t = 0.0
        if nLenSq > 0.001:
            t = clamp((vShipPos - vFrom).dot(vSeg) / nLenSq, 0.0, 1.0)
        var vClosest = vFrom.linear_interpolate(vTo, t)
        var nDistSq = vShipPos.distance_squared_to(vClosest)
        var nDistAlong = nCumulative + nSegLen * t
        if nDistSq < nBestDistSq:
            nBestDistSq = nDistSq
            nBestTotal = nDistAlong
        nCumulative += nSegLen

    nPreviewTrimDistance = max(nPreviewTrimDistance, nBestTotal)

func _TrimPreviewFromDistance(vPoints, nTrimDistance: float):
    if vPoints.size() < 2 or nTrimDistance <= 0.0:
        return vPoints

    var nCumulative = 0.0
    var vTrimmed = PoolVector2Array()

    for i in range(1, vPoints.size()):
        var vFrom = vPoints[i - 1]
        var vTo = vPoints[i]
        var nSegLen = vFrom.distance_to(vTo)
        var nNextCumulative = nCumulative + nSegLen

        if nTrimDistance >= nNextCumulative:
            nCumulative = nNextCumulative
            continue

        if vTrimmed.size() == 0:
            var nRemain = nTrimDistance - nCumulative
            var t = 0.0
            if nSegLen > 0.001:
                t = clamp(nRemain / nSegLen, 0.0, 1.0)
            vTrimmed.append(vFrom.linear_interpolate(vTo, t))

        vTrimmed.append(vTo)
        nCumulative = nNextCumulative

    return vTrimmed

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
