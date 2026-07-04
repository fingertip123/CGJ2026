extends Control

const UiTheme = preload("res://scripts/ui_theme.gd")

onready var pTitleLabel = $VBox/HeaderRow/TitleLabel
onready var pPhaseLabel = $VBox/HeaderRow/PhaseLabel
onready var pHintLabel = $VBox/HintLabel
onready var pStatsLabel = $VBox/StatsLabel
onready var pResultLabel = $VBox/ResultLabel
onready var pSpeedLabel = $VBox/SpeedBlock/SpeedLabel

func _ready() -> void:
    UiTheme.ApplyToControl(self)
    UiTheme.StyleLabel(pTitleLabel, UiTheme.C_ACCENT)
    UiTheme.StyleLabel(pPhaseLabel, UiTheme.C_TEXT_MUTED)
    UiTheme.StyleLabel(pHintLabel, UiTheme.C_TEXT_MUTED)
    UiTheme.StyleLabel(pStatsLabel, UiTheme.C_TEXT)
    UiTheme.StyleLabel(pResultLabel, UiTheme.C_TEXT)
    UiTheme.StyleLabel(pSpeedLabel, UiTheme.C_TEXT_MUTED)
    pTitleLabel.text = "ARCHOR"
    pHintLabel.autowrap = true
    pResultLabel.autowrap = true

func _draw() -> void:
    var oRect = Rect2(Vector2.ZERO, rect_size)
    draw_rect(oRect, UiTheme.C_BG)
    draw_rect(oRect, UiTheme.C_BORDER, false, 1.5)

    var nCorner = 10.0
    var oAccent = Color(0.45, 0.85, 1.0, 0.85)
    draw_line(Vector2(0, 0), Vector2(nCorner, 0), oAccent, 1.5, true)
    draw_line(Vector2(0, 0), Vector2(0, nCorner), oAccent, 1.5, true)
    draw_line(Vector2(rect_size.x, 0), Vector2(rect_size.x - nCorner, 0), oAccent, 1.5, true)
    draw_line(Vector2(rect_size.x, 0), Vector2(rect_size.x, nCorner), oAccent, 1.5, true)
