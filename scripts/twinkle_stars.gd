extends ColorRect

export(Vector2) var vSize = Vector2(1600, 900)
export(int) var nTwinkleStarCount = 90
export(Color) var oTwinkleColor = Color(0.92, 0.97, 1.0, 0.85)
export(float) var nStarParallaxFactor = 0.12
export(float) var nCellSize = 110.0

var vCameraOffset = Vector2.ZERO
var pShaderMaterial = null

func _ready() -> void:
    mouse_filter = Control.MOUSE_FILTER_IGNORE
    color = Color(1, 1, 1, 1)

    var pShader = load("res://shaders/twinkle_stars.shader")
    if pShader == null:
        return

    pShaderMaterial = ShaderMaterial.new()
    pShaderMaterial.shader = pShader
    material = pShaderMaterial
    _UpdateShader()

func SetCameraOffset(vOffset: Vector2) -> void:
    vCameraOffset = vOffset
    _UpdateShader()

func _UpdateShader() -> void:
    if pShaderMaterial == null:
        return

    var nCells = max(1.0, floor(vSize.x / nCellSize) * floor(vSize.y / nCellSize))
    var nDensity = clamp(float(nTwinkleStarCount) / nCells, 0.005, 0.35)

    pShaderMaterial.set_shader_param("viewport_size", vSize)
    pShaderMaterial.set_shader_param("camera_offset", vCameraOffset)
    pShaderMaterial.set_shader_param("star_parallax", nStarParallaxFactor)
    pShaderMaterial.set_shader_param("twinkle_color", oTwinkleColor)
    pShaderMaterial.set_shader_param("twinkle_density", nDensity)
    pShaderMaterial.set_shader_param("cell_size", nCellSize)
