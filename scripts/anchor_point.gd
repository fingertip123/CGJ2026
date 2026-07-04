extends Node2D

export(float) var docking_radius = 52.0 setget set_docking_radius
export(float) var hold_time_required = 0.2
export(float) var nSpriteRotateSpeed = 0.55
export(float) var nSpriteScale = 0.42
export(Vector2) var vEllipseScale = Vector2(0.46, 0.32)
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

func _UpdateEllipseShaderParams() -> void:
    if pShaderMaterial == null:
        return
    pShaderMaterial.set_shader_param("ellipse_scale", vEllipseScale)
    pShaderMaterial.set_shader_param("softness", nEllipseSoftness)
    pShaderMaterial.set_shader_param("glow_color", oGlowColor)
    pShaderMaterial.set_shader_param("glow_width", nGlowWidth)
    pShaderMaterial.set_shader_param("glow_intensity", nGlowIntensity)
    pShaderMaterial.set_shader_param("rotation_angle", nTextureRotation)

func set_docking_radius(value):
    docking_radius = value
    update()

func get_anchor_data():
    return {
        "position": global_position,
        "docking_radius": docking_radius,
        "hold_time_required": hold_time_required
    }

func is_docked(ship_position):
    return ship_position.distance_to(global_position) <= docking_radius

func _draw():
    draw_circle(Vector2.ZERO, docking_radius, Color(0.1, 0.95, 0.65, 0.16))
    draw_arc(Vector2.ZERO, docking_radius, 0.0, PI * 2.0, 80, Color(0.25, 1.0, 0.75, 0.85), 3.0)
    draw_line(Vector2(-14, 0), Vector2(14, 0), Color(0.8, 1.0, 0.9), 2.0)
    draw_line(Vector2(0, -14), Vector2(0, 14), Color(0.8, 1.0, 0.9), 2.0)
