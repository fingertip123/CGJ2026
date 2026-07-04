tool
extends Node2D

export(Vector2) var vSize = Vector2(1600, 790) setget SetSize
export(float) var nGridSize = 80.0 setget SetGridSize
export(int) var nStarCount = 120 setget SetStarCount
export(Color) var oBackgroundColor = Color(0.015, 0.02, 0.045) setget SetBackgroundColor
export(Color) var oGridColor = Color(0.13, 0.17, 0.28, 0.16) setget SetGridColor
export(Color) var oStarColor = Color(0.85, 0.92, 1.0, 0.75) setget SetStarColor

func SetSize(vValue: Vector2) -> void:
    vSize = vValue
    update()

func SetGridSize(nValue: float) -> void:
    nGridSize = nValue
    update()

func SetStarCount(nValue: int) -> void:
    nStarCount = max(0, nValue)
    update()

func SetBackgroundColor(oValue: Color) -> void:
    oBackgroundColor = oValue
    update()

func SetGridColor(oValue: Color) -> void:
    oGridColor = oValue
    update()

func SetStarColor(oValue: Color) -> void:
    oStarColor = oValue
    update()

func _draw() -> void:
    draw_rect(Rect2(Vector2.ZERO, vSize), oBackgroundColor)

    _DrawStars()

    if nGridSize <= 0.0:
        return

    for x in range(0, int(vSize.x) + 1, int(nGridSize)):
        draw_line(Vector2(x, 0), Vector2(x, vSize.y), oGridColor, 1.0)
    for y in range(0, int(vSize.y) + 1, int(nGridSize)):
        draw_line(Vector2(0, y), Vector2(vSize.x, y), oGridColor, 1.0)

func _DrawStars() -> void:
    if nStarCount <= 0 or vSize.x <= 0.0 or vSize.y <= 0.0:
        return

    for i in range(nStarCount):
        var nX = fmod(float(i * 157 + 43), vSize.x)
        var nY = fmod(float(i * 263 + 91), vSize.y)
        var nRadius = 0.8 + float((i * 17) % 4) * 0.25
        var nAlpha = 0.28 + float((i * 29) % 55) / 100.0
        draw_circle(Vector2(nX, nY), nRadius, Color(oStarColor.r, oStarColor.g, oStarColor.b, nAlpha))
