extends Node2D

const BezierUtil = preload("res://scripts/bezier_util.gd")

export(Vector2) var vStart = Vector2(100, 500)
export(Vector2) var vControl1 = Vector2(280, 460)
export(Vector2) var vControl2 = Vector2(760, 180)
export(Vector2) var vEnd = Vector2(940, 100)
export(int) var nCurveSegments = 64

func GetPositionAt(t: float) -> Vector2:
    return BezierUtil.SampleCubic(vStart, vControl1, vControl2, vEnd, clamp(t, 0.0, 1.0))

func GetNormalAt(t: float) -> Vector2:
    return BezierUtil.NormalAt(vStart, vControl1, vControl2, vEnd, t)

func GetSideSpawnPosition(t: float, nSide: int, nDistance: float) -> Vector2:
    var vCenter = GetPositionAt(t)
    var vNormal = GetNormalAt(t)
    if nSide < 0:
        vNormal *= -1.0
    return vCenter + vNormal * nDistance

func _draw() -> void:
    var vCurve = BezierUtil.SamplePolyline(vStart, vControl1, vControl2, vEnd, nCurveSegments)
    for i in range(vCurve.size() - 1):
        draw_line(vCurve[i], vCurve[i + 1], Color(0.35, 0.75, 0.95, 0.85), 4.0, true)

    draw_circle(vStart, 14.0, Color(0.35, 0.9, 0.45))
    draw_circle(vEnd, 16.0, Color(1.0, 0.7, 0.15))
    draw_arc(vEnd, 22.0, 0.0, TAU, 32, Color(1.0, 0.7, 0.15, 0.25), 2.0, true)
