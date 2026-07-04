extends CPUParticles2D

export(float) var nRearOffset = 20.0

var pAircraft = null

func _ready() -> void:
    z_index = -1
    pAircraft = get_parent().get_node_or_null("Aircraft")
    _SetupParticles()
    emitting = false

func _SetupParticles() -> void:
    amount = 32
    lifetime = 0.38
    preprocess = 0.15
    explosiveness = 0.08
    randomness = 0.35
    emission_shape = CPUParticles2D.EMISSION_SHAPE_POINT
    direction = Vector2(0, 1)
    spread = 20.0
    gravity = Vector2.ZERO
    initial_velocity = 110.0
    initial_velocity_random = 0.4
    angular_velocity = 0.0
    angular_velocity_random = 0.0
    scale_amount = 3.5
    scale_amount_random = 0.45
    color = Color(1.0, 0.72, 0.22, 0.9)

    var pGradient = Gradient.new()
    pGradient.add_point(0.0, Color(1.0, 0.98, 0.82, 1.0))
    pGradient.add_point(0.35, Color(1.0, 0.58, 0.12, 0.85))
    pGradient.add_point(1.0, Color(0.75, 0.18, 0.05, 0.0))
    var pGradientTexture = GradientTexture.new()
    pGradientTexture.gradient = pGradient
    color_ramp = pGradientTexture

func SetActive(bActive: bool) -> void:
    emitting = bActive

func _process(_delta: float) -> void:
    if pAircraft == null:
        return
    rotation = pAircraft.rotation
    position = Vector2(0.0, nRearOffset).rotated(rotation)
