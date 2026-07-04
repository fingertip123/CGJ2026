tool
extends Node2D

export(float) var nSpawnInterval = 2.4
export(float) var nExpandDuration = 2.2
export(float) var nRingWidth = 1.5
export(float) var nMaxAlpha = 0.32
export(float) var nInnerPadding = 6.0

var nSpawnTimer = 0.0
var vRipples = []
var nInnerRadius = 20.0
var nOuterRadius = 120.0
var oRippleColor = Color(0.45, 0.75, 1.0, 1.0)
var pPlanet = null

func _ready() -> void:
    pPlanet = get_parent()
    nSpawnTimer = randf() * nSpawnInterval
    SyncFromPlanet()

func SyncFromPlanet() -> void:
    if pPlanet == null:
        return
    nInnerRadius = pPlanet.nPlanetRadius + nInnerPadding
    nOuterRadius = pPlanet.nGravityRadius
    oRippleColor = pPlanet.oGravityColor

func Tick(delta: float) -> bool:
    if pPlanet == null or nOuterRadius <= nInnerRadius:
        return false

    SyncFromPlanet()
    nSpawnTimer -= delta
    if nSpawnTimer <= 0.0:
        vRipples.append({"progress": 0.0})
        nSpawnTimer = nSpawnInterval + randf() * 0.5

    var bNeedsRedraw = vRipples.size() > 0
    var i = 0
    while i < vRipples.size():
        vRipples[i].progress += delta / max(nExpandDuration, 0.001)
        if vRipples[i].progress >= 1.0:
            vRipples.remove(i)
        else:
            i += 1

    return bNeedsRedraw or vRipples.size() > 0

func DrawRipples(pCanvas) -> void:
    if vRipples.empty() or nOuterRadius <= nInnerRadius:
        return

    for oRipple in vRipples:
        var nT = clamp(oRipple.progress, 0.0, 1.0)
        var nEaseT = nT * nT
        var nRadius = lerp(nOuterRadius, nInnerRadius, nEaseT)
        var nAlpha = sin(nT * PI) * nMaxAlpha
        if nAlpha <= 0.005:
            continue
        var oColor = Color(oRippleColor.r, oRippleColor.g, oRippleColor.b, nAlpha)
        pCanvas.draw_arc(Vector2.ZERO, nRadius, 0.0, TAU, 56, oColor, nRingWidth, true)
