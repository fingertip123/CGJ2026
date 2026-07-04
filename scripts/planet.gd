tool
extends Node2D

const UnitData = preload("res://scripts/unit_data.gd")

export(float) var nPlanetRadius = 14.0 setget SetPlanetRadius
export(float) var nGravityRadius = 120.0 setget SetGravityRadius
export(float) var nPlanetMass = 360000.0
export(float) var nMinGravityDistance = 12.0
export(bool) var bHasDefenseTower = true setget SetHasDefenseTower
export(float) var nDefenseRange = 50.0 setget SetDefenseRange
export(float) var nDefenseDamage = 10.0
export(float) var nDefenseInterval = 0.9
export(Color) var oPlanetColor = Color(0.45, 0.55, 0.95) setget SetPlanetColor
export(Color) var oGravityColor = Color(0.45, 0.75, 1.0, 0.12) setget SetGravityColor
export(int) var nFuelDepositBase = 70 setget SetFuelDepositBase
export(int) var nGoldDepositBase = 45 setget SetGoldDepositBase
export(int) var nFuelDepositVariance = 20
export(int) var nGoldDepositVariance = 15

var pGame = null
var nDefenseCooldown = 0.0
var nFuelRemaining = 0
var nGoldRemaining = 0
var bDepositsInitialized = false
var pGravityRipples = null

onready var pSprite = $Sprite
onready var pCollisionShape = $StaticBody2D/CollisionShape2D

func _ready() -> void:
    _SyncCollisionShape()
    pGravityRipples = get_node_or_null("GravityRipples")
    _ApplySprite()
    if Engine.editor_hint and not bDepositsInitialized:
        _InitDeposits()
        update()

func _ApplySprite() -> void:
    if pSprite == null:
        return
    var pTexture = UnitData.GetPlanetTexture()
    if pTexture == null:
        return
    pSprite.texture = pTexture
    var vTexSize = pTexture.get_size()
    var nMaxTex = max(vTexSize.x, vTexSize.y)
    if nMaxTex <= 0.001:
        return
    var nScale = (nPlanetRadius * 2.0) / nMaxTex
    pSprite.scale = Vector2(nScale, nScale)

func Setup(pGameNode) -> void:
    pGame = pGameNode
    nDefenseCooldown = 0.0
    if not bDepositsInitialized:
        _InitDeposits()
    update()

func _InitDeposits() -> void:
    var nFuelMin = max(0, nFuelDepositBase - nFuelDepositVariance)
    var nFuelMax = nFuelDepositBase + nFuelDepositVariance
    var nGoldMin = max(0, nGoldDepositBase - nGoldDepositVariance)
    var nGoldMax = nGoldDepositBase + nGoldDepositVariance
    if Engine.editor_hint:
        nFuelRemaining = nFuelDepositBase
        nGoldRemaining = nGoldDepositBase
    else:
        nFuelRemaining = randi() % (nFuelMax - nFuelMin + 1) + nFuelMin
        nGoldRemaining = randi() % (nGoldMax - nGoldMin + 1) + nGoldMin
    bDepositsInitialized = true

func SetFuelDepositBase(nValue: int) -> void:
    nFuelDepositBase = max(0, nValue)
    update()

func SetGoldDepositBase(nValue: int) -> void:
    nGoldDepositBase = max(0, nValue)
    update()

func HasMineableResources() -> bool:
    return nFuelRemaining > 0 or nGoldRemaining > 0

func GetFuelRemaining() -> int:
    return nFuelRemaining

func GetGoldRemaining() -> int:
    return nGoldRemaining

func ExtractResources(nFuelWant: float, nGoldWant: int) -> Dictionary:
    var nFuel = int(min(nFuelWant, float(nFuelRemaining)))
    var nGold = min(nGoldWant, nGoldRemaining)
    nFuelRemaining = max(0, nFuelRemaining - nFuel)
    nGoldRemaining = max(0, nGoldRemaining - nGold)
    update()
    return {"fuel": float(nFuel), "gold": nGold}

func GetDepositRatio() -> float:
    var nTotal = max(1, nFuelDepositBase + nGoldDepositBase)
    var nLeft = nFuelRemaining + nGoldRemaining
    return clamp(float(nLeft) / float(nTotal), 0.0, 1.0)

func SetGravityRadius(nValue: float) -> void:
    nGravityRadius = max(nPlanetRadius, nValue)
    if pGravityRipples != null:
        pGravityRipples.SyncFromPlanet()
    update()

func SetPlanetRadius(nValue: float) -> void:
    nPlanetRadius = max(1.0, nValue)
    _ApplySprite()
    _SyncCollisionShape()
    if pGravityRipples != null:
        pGravityRipples.SyncFromPlanet()
    update()

func GetPlanetRadius() -> float:
    return nPlanetRadius

func _SyncCollisionShape() -> void:
    if pCollisionShape == null:
        return
    var pShape = pCollisionShape.shape
    if pShape == null or not (pShape is CircleShape2D):
        pShape = CircleShape2D.new()
        pCollisionShape.shape = pShape
    pShape.radius = nPlanetRadius

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
    if pGravityRipples != null:
        pGravityRipples.SyncFromPlanet()
    update()

func IsInsideGravity(vWorldPos: Vector2) -> bool:
    return global_position.distance_to(vWorldPos) <= nGravityRadius

func GetGravityAcceleration(vWorldPos: Vector2) -> Vector2:
    var vToPlanet = global_position - vWorldPos
    var nDistSq = vToPlanet.length_squared()
    var nMaxDistSq = nGravityRadius * nGravityRadius
    if nDistSq >= nMaxDistSq or nDistSq <= 0.001:
        return Vector2.ZERO

    var nMinDist = max(nPlanetRadius, nMinGravityDistance)
    var nSafeDistSq = max(nDistSq, nMinDist * nMinDist)
    var nAccel = nPlanetMass / nSafeDistSq
    return vToPlanet.normalized() * nAccel

func GetCircularOrbitSpeed(nOrbitRadius: float) -> float:
    var nRadius = clamp(nOrbitRadius, nMinGravityDistance, nGravityRadius)
    return sqrt(nPlanetMass / nRadius)

func _process(delta: float) -> void:
    if pGravityRipples != null and pGravityRipples.Tick(delta):
        update()

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

    if pGravityRipples != null:
        pGravityRipples.DrawRipples(self)

    if bHasDefenseTower:
        draw_arc(Vector2.ZERO, nDefenseRange, 0.0, TAU, 64, Color(1.0, 0.35, 0.25, 0.18), 1.5, true)

    if bHasDefenseTower:
        var vBase = Vector2(0, -nPlanetRadius - 4.0)
        draw_rect(Rect2(vBase - Vector2(8, 10), Vector2(16, 12)), Color(0.75, 0.28, 0.2))
        draw_line(vBase - Vector2(0, 10), vBase - Vector2(0, 24), Color(1.0, 0.55, 0.35), 3.0, true)

    _DrawResourceBars()

func _DrawResourceBars() -> void:
    var vBase = Vector2(-nPlanetRadius, nPlanetRadius + 10.0)
    var nBarW = nPlanetRadius * 2.0
    var nBarH = 4.0

    draw_rect(Rect2(vBase, Vector2(nBarW, nBarH)), Color(0.08, 0.08, 0.12))
    var nFuelRatio = 0.0 if nFuelDepositBase <= 0 else clamp(float(nFuelRemaining) / float(max(1, nFuelDepositBase + nFuelDepositVariance)), 0.0, 1.0)
    draw_rect(Rect2(vBase, Vector2(nBarW * nFuelRatio, nBarH)), Color(0.35, 0.85, 1.0))

    var vGoldBase = vBase + Vector2(0, 6)
    draw_rect(Rect2(vGoldBase, Vector2(nBarW, nBarH)), Color(0.08, 0.08, 0.12))
    var nGoldRatio = 0.0 if nGoldDepositBase <= 0 else clamp(float(nGoldRemaining) / float(max(1, nGoldDepositBase + nGoldDepositVariance)), 0.0, 1.0)
    draw_rect(Rect2(vGoldBase, Vector2(nBarW * nGoldRatio, nBarH)), Color(0.95, 0.78, 0.25))
