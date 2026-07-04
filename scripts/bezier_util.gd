extends Reference

static func SampleCubic(p0: Vector2, p1: Vector2, p2: Vector2, p3: Vector2, t: float) -> Vector2:
    var u = 1.0 - t
    return (
        u * u * u * p0
        + 3.0 * u * u * t * p1
        + 3.0 * u * t * t * p2
        + t * t * t * p3
    )

static func TangentCubic(p0: Vector2, p1: Vector2, p2: Vector2, p3: Vector2, t: float) -> Vector2:
    var u = 1.0 - t
    return (
        3.0 * u * u * (p1 - p0)
        + 6.0 * u * t * (p2 - p1)
        + 3.0 * t * t * (p3 - p2)
    )

static func SamplePolyline(p0: Vector2, p1: Vector2, p2: Vector2, p3: Vector2, nSegments: int) -> PoolVector2Array:
    var vPoints = PoolVector2Array()
    for i in range(nSegments + 1):
        var t = float(i) / float(nSegments)
        vPoints.append(SampleCubic(p0, p1, p2, p3, t))
    return vPoints

static func NormalAt(p0: Vector2, p1: Vector2, p2: Vector2, p3: Vector2, t: float) -> Vector2:
    var vTangent = TangentCubic(p0, p1, p2, p3, clamp(t, 0.0, 1.0))
    if vTangent.length_squared() < 0.001:
        return Vector2(0, -1)
    return Vector2(-vTangent.y, vTangent.x).normalized()
