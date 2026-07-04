extends ColorRect

export(float) var nNebulaParallaxFactor = 0.06
export(float) var nStarParallaxFar = 0.04
export(float) var nStarParallaxNear = 0.14
export(float) var nNebulaIntensity = 0.62
export(Color) var oNebulaColorBlue = Color(0.18, 0.42, 1.0)
export(Color) var oNebulaColorMid = Color(0.38, 0.28, 0.95)
export(Color) var oNebulaColorPurple = Color(0.72, 0.18, 0.92)
export(Color) var oStarColor = Color(0.82, 0.90, 1.0, 0.95)

var vCameraOffset = Vector2.ZERO
var pShaderMaterial = null

func _ready() -> void:
    mouse_filter = Control.MOUSE_FILTER_IGNORE
    color = Color(1, 1, 1, 1)

    var pShader = load("res://shaders/nebula_sky.shader")
    if pShader == null:
        return

    pShaderMaterial = ShaderMaterial.new()
    pShaderMaterial.shader = pShader
    material = pShaderMaterial
    call_deferred("_UpdateShader")

func SetCameraOffset(vOffset: Vector2) -> void:
    vCameraOffset = vOffset
    _UpdateShader()

func _UpdateShader() -> void:
    if pShaderMaterial == null:
        return

    var vSize = rect_size
    if vSize.x <= 1.0 or vSize.y <= 1.0:
        vSize = get_viewport_rect().size

    pShaderMaterial.set_shader_param("viewport_size", vSize)
    pShaderMaterial.set_shader_param("camera_offset", vCameraOffset)
    pShaderMaterial.set_shader_param("nebula_parallax", nNebulaParallaxFactor)
    pShaderMaterial.set_shader_param("star_parallax_far", nStarParallaxFar)
    pShaderMaterial.set_shader_param("star_parallax_near", nStarParallaxNear)
    pShaderMaterial.set_shader_param("nebula_intensity", nNebulaIntensity)
    pShaderMaterial.set_shader_param("nebula_color_blue", oNebulaColorBlue)
    pShaderMaterial.set_shader_param("nebula_color_mid", oNebulaColorMid)
    pShaderMaterial.set_shader_param("nebula_color_purple", oNebulaColorPurple)
    pShaderMaterial.set_shader_param("star_color", oStarColor)

func _notification(what: int) -> void:
    if what == NOTIFICATION_RESIZED:
        call_deferred("_UpdateShader")
