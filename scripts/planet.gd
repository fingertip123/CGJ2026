tool
extends Node2D

export(float) var nPlanetRadius = 42.0 setget SetPlanetRadius
export(float) var nGravityRadius = 180.0 setget SetGravityRadius
export(float) var nGravityStrength = 280.0
export(bool) var bHasDefenseTower = true setget SetHasDefenseTower
export(float) var nDefenseRange = 150.0 setget SetDefenseRange
export(float) var nDefenseDamage = 10.0
export(float) var nDefenseInterval = 0.9
export(Color) var oPlanetColor = Color(0.45, 0.55, 0.95) setget SetPlanetColor
export(Color) var oGravityColor = Color(0.45, 0.75, 1.0, 0.12) setget SetGravityColor

var pGame = null
var nDefenseCooldown = 0.0

func Setup(pGameNode) -> void:
    pGame = pGameNode
    nDefenseCooldown = 0.0
    update()

func SetPlanetRadius(nValue: float) -> void:
    nPlanetRadius = max(1.0, nValue)
    update()

func SetGravityRadius(nValue: float) -> void:
    nGravityRadius = max(nPlanetRadius, nValue)
    update()

func SetHasDefenseTower(bValue: bool) -> void:
    bHasDefenseTower = bValue
    update()

func SetDefenseRange(nValue: float) -> void:
    nDefenseRange = max(0.0, nValue)
    update()

func SetPlanetColor(oValue: Color) -> void:
    oPlanetColor = oValue
    update()

func SetGravityColor(oValue: Color) -> void:
    oGravityColor = oValue
    update()

func IsInsideGravity(vWorldPos: Vector2) -> bool:
    return global_position.distance_to(vWorldPos) <= nGravityRadius

func GetGravityAcceleration(vWorldPos: Vector2) -> Vector2:
    var vToPlanet = global_position - vWorldPos
    var nDist = vToPlanet.length()
    if nDist <= 0.001 or nDist > nGravityRadius:
        return Vector2.ZERO

    var nFalloff = 1.0 - clamp(nDist / nGravityRadius, 0.0, 1.0)
    return vToPlanet.normalized() * nGravityStrength * nFalloff

func _process(delta: float) -> void:
    if Engine.editor_hint:
        return
    if not bHasDefenseTower:
        return

    nDefenseCooldown = max(0.0, nDefenseCooldown - delta)

func CanAttack(vWorldPos: Vector2) -> bool:
    return bHasDefenseTower and global_position.distance_to(vWorldPos) <= nDefenseRange

func TryAttack(pTarget) -> bool:
    if not bHasDefenseTower or nDefenseCooldown > 0.0:
        return false
    if pTarget == null or not is_instance_valid(pTarget) or not (pTarget is Node2D):
        return false
    if not CanAttack(pTarget.global_position):
        return false
    if not pTarget.has_method("TakeDamage"):
        return false

    nDefenseCooldown = nDefenseInterval
    pTarget.TakeDamage(nDefenseDamage)
    return true

func _draw() -> void:
    draw_circle(Vector2.ZERO, nGravityRadius, oGravityColor)
    draw_arc(Vector2.ZERO, nGravityRadius, 0.0, TAU, 72, Color(oGravityColor.r, oGravityColor.g, oGravityColor.b, 0.35), 2.0, true)

    if bHasDefenseTower:
        draw_arc(Vector2.ZERO, nDefenseRange, 0.0, TAU, 64, Color(1.0, 0.35, 0.25, 0.18), 1.5, true)

    draw_circle(Vector2.ZERO, nPlanetRadius, oPlanetColor.darkened(0.12))
    draw_circle(Vector2(-nPlanetRadius * 0.18, -nPlanetRadius * 0.18), nPlanetRadius * 0.72, oPlanetColor)
    draw_arc(Vector2.ZERO, nPlanetRadius + 4.0, 0.15, PI - 0.15, 48, Color(0.85, 0.9, 1.0, 0.3), 2.0, true)

    if bHasDefenseTower:
        var vBase = Vector2(0, -nPlanetRadius - 4.0)
        draw_rect(Rect2(vBase - Vector2(8, 10), Vector2(16, 12)), Color(0.75, 0.28, 0.2))
        draw_line(vBase - Vector2(0, 10), vBase - Vector2(0, 24), Color(1.0, 0.55, 0.35), 3.0, true)
