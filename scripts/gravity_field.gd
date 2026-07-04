tool
extends Sprite

const nTextureSize = 256

export(float) var nGravityRadius = 120.0 setget SetRadius
export(Color) var oFieldColor = Color(0.45, 0.75, 1.0, 0.1) setget SetFieldColor
export(float) var nWaveStrength = 0.06 setget SetWaveStrength

var pShaderMaterial = null

func _ready() -> void:
    centered = true
    show_behind_parent = true
    z_index = -1
    texture = _CreateWhiteTexture()
    _SetupMaterial()
    _ApplyScale()

func SetRadius(nValue: float) -> void:
    nGravityRadius = max(1.0, nValue)
    _ApplyScale()

func SetFieldColor(oValue: Color) -> void:
    oFieldColor = oValue
    _UpdateShader()

func SetWaveStrength(nValue: float) -> void:
    nWaveStrength = clamp(nValue, 0.0, 0.2)
    _UpdateShader()

func SyncFromPlanet(pPlanet) -> void:
    if pPlanet == null:
        return
    nGravityRadius = pPlanet.nGravityRadius
    oFieldColor = Color(pPlanet.oGravityColor.r, pPlanet.oGravityColor.g, pPlanet.oGravityColor.b, min(pPlanet.oGravityColor.a, 0.14))
    _ApplyScale()
    _UpdateShader()

func _SetupMaterial() -> void:
    var pShader = load("res://shaders/gravity_field.shader")
    if pShader == null:
        return
    pShaderMaterial = ShaderMaterial.new()
    pShaderMaterial.shader = pShader
    material = pShaderMaterial
    _UpdateShader()

func _UpdateShader() -> void:
    if pShaderMaterial == null:
        return
    pShaderMaterial.set_shader_param("field_color", oFieldColor)
    pShaderMaterial.set_shader_param("wave_strength", nWaveStrength)

func _ApplyScale() -> void:
    if texture == null:
        return
    var nScale = nGravityRadius * 2.0 / float(nTextureSize)
    scale = Vector2(nScale, nScale)

func _CreateWhiteTexture() -> ImageTexture:
    var pImage = Image.new()
    pImage.create(nTextureSize, nTextureSize, false, Image.FORMAT_RGBA8)
    pImage.fill(Color(1, 1, 1, 1))
    var pTexture = ImageTexture.new()
    pTexture.create_from_image(pImage)
    return pTexture
