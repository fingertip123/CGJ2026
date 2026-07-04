tool
extends Node2D

export(Vector2) var vSize = Vector2(1024, 490) setget SetSize
export(float) var nGridSize = 64.0 setget SetGridSize
export(Color) var oBackgroundColor = Color(0.07, 0.09, 0.12) setget SetBackgroundColor
export(Color) var oGridColor = Color(0.16, 0.2, 0.28, 0.35) setget SetGridColor

func SetSize(vValue: Vector2) -> void:
    vSize = vValue
    update()

func SetGridSize(nValue: float) -> void:
    nGridSize = nValue
    update()

func SetBackgroundColor(oValue: Color) -> void:
    oBackgroundColor = oValue
    update()

func SetGridColor(oValue: Color) -> void:
    oGridColor = oValue
    update()

func _draw() -> void:
    draw_rect(Rect2(Vector2.ZERO, vSize), oBackgroundColor)

    if nGridSize <= 0.0:
        return

    for x in range(0, int(vSize.x) + 1, int(nGridSize)):
        draw_line(Vector2(x, 0), Vector2(x, vSize.y), oGridColor, 1.0)
    for y in range(0, int(vSize.y) + 1, int(nGridSize)):
        draw_line(Vector2(0, y), Vector2(vSize.x, y), oGridColor, 1.0)
