extends Node2D

export(float) var hold_time_required = 0.2
export(float) var nSpriteRotateSpeed = 0.55
export(float) var nSpriteScale = 0.42
export(Vector2) var vEllipseScale = Vector2(0.46, 0.32) setget SetEllipseScale
export(float) var nEllipseSoftness = 0.04
export(Color) var oGlowColor = Color(0.15, 0.95, 0.55, 0.9)
export(float) var nGlowWidth = 0.16
export(float) var nGlowIntensity = 1.0

onready var pSprite: Sprite = $Sprite

var pShaderMaterial: ShaderMaterial = null
var nTextureRotation = 0.0

func _ready() -> void:
    _SetupSpriteMaterial()

func _process(delta: float) -> void:
    if pShaderMaterial == null or nSpriteRotateSpeed == 0.0:
        return
    nTextureRotation += nSpriteRotateSpeed * delta
    pShaderMaterial.set_shader_param("rotation_angle", nTextureRotation)

func SetEllipseScale(vValue: Vector2) -> void:
    vEllipseScale = vValue
    _UpdateEllipseShaderParams()
    update()

func _SetupSpriteMaterial() -> void:
    if pSprite == null:
        return

    pSprite.scale = Vector2.ONE * nSpriteScale

    var pShader = load("res://shaders/ellipse_mask.shader")
    if pShader == null:
        return

    pShaderMaterial = ShaderMaterial.new()
    pShaderMaterial.shader = pShader
    _UpdateEllipseShaderParams()
    pSprite.material = pShaderMaterial
    update()

func _UpdateEllipseShaderParams() -> void:
    if pShaderMaterial == null:
        return
    pShaderMaterial.set_shader_param("ellipse_scale", vEllipseScale)
    pShaderMaterial.set_shader_param("softness", nEllipseSoftness)
    pShaderMaterial.set_shader_param("glow_color", oGlowColor)
    pShaderMaterial.set_shader_param("glow_width", nGlowWidth)
    pShaderMaterial.set_shader_param("glow_intensity", nGlowIntensity)
    pShaderMaterial.set_shader_param("rotation_angle", nTextureRotation)

func GetEllipseWorldHalfExtents() -> Vector2:
    if pSprite == null or pSprite.texture == null:
        return Vector2(52.0, 52.0)

    var vTexSize = pSprite.texture.get_size()
    return Vector2(
        vTexSize.x * pSprite.scale.x * vEllipseScale.x,
        vTexSize.y * pSprite.scale.y * vEllipseScale.y
    )

func GetDockingRadius() -> float:
    var vHalf = GetEllipseWorldHalfExtents()
    return max(vHalf.x, vHalf.y)

func get_anchor_data():
    var vHalf = GetEllipseWorldHalfExtents()
    return {
        "position": global_position,
        "docking_radius": GetDockingRadius(),
        "ellipse_half_extents": vHalf,
        "hold_time_required": hold_time_required
    }

func is_docked(ship_position: Vector2) -> bool:
    return IsInsideDockEllipse(ship_position)

func IsInsideDockEllipse(world_position: Vector2) -> bool:
    var vLocal = world_position - global_position
    var vHalf = GetEllipseWorldHalfExtents()
    if vHalf.x <= 0.001 or vHalf.y <= 0.001:
        return false

    var nEllipseDist = (vLocal.x * vLocal.x) / (vHalf.x * vHalf.x) \
        + (vLocal.y * vLocal.y) / (vHalf.y * vHalf.y)
    return nEllipseDist <= 1.0

func _draw() -> void:
    _DrawDockEllipse()

func _DrawDockEllipse() -> void:
    var vHalf = GetEllipseWorldHalfExtents()
    var nSteps = 72
    var vPoints = PoolVector2Array()
    vPoints.resize(nSteps)

    for i in range(nSteps):
        var nAngle = TAU * float(i) / float(nSteps)
        vPoints[i] = Vector2(cos(nAngle) * vHalf.x, sin(nAngle) * vHalf.y)

    draw_colored_polygon(vPoints, Color(0.1, 0.95, 0.65, 0.16))

    var vOutline = PoolVector2Array()
    for i in range(nSteps):
        vOutline.append(vPoints[i])
    vOutline.append(vPoints[0])
    draw_polyline(vOutline, Color(0.25, 1.0, 0.75, 0.85), 3.0, true)

    draw_line(Vector2(-vHalf.x * 0.28, 0), Vector2(vHalf.x * 0.28, 0), Color(0.8, 1.0, 0.9), 2.0)
    draw_line(Vector2(0, -vHalf.y * 0.28), Vector2(0, vHalf.y * 0.28), Color(0.8, 1.0, 0.9), 2.0)
