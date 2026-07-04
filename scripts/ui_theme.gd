extends Reference

const C_BG = Color(0.04, 0.06, 0.11, 0.92)
const C_BORDER = Color(0.28, 0.38, 0.55, 0.75)
const C_INNER = Color(0.07, 0.09, 0.15, 0.9)
const C_ACCENT = Color(0.45, 0.85, 1.0)
const C_TEXT = Color(0.85, 0.92, 1.0, 0.95)
const C_TEXT_MUTED = Color(0.55, 0.65, 0.78, 0.85)
const C_TEXT_DIM = Color(0.38, 0.46, 0.58, 0.75)
const C_SUCCESS = Color(0.45, 0.95, 0.55)
const C_DANGER = Color(0.95, 0.45, 0.45)

static func MakeFlatBox(oBg: Color, oBorder: Color, nBorder: int = 1) -> StyleBoxFlat:
    var pBox = StyleBoxFlat.new()
    pBox.bg_color = oBg
    pBox.border_width_left = nBorder
    pBox.border_width_top = nBorder
    pBox.border_width_right = nBorder
    pBox.border_width_bottom = nBorder
    pBox.border_color = oBorder
    pBox.content_margin_left = 10
    pBox.content_margin_top = 6
    pBox.content_margin_right = 10
    pBox.content_margin_bottom = 6
    return pBox

static func BuildTheme() -> Theme:
    var pTheme = Theme.new()

    var oBtnNormal = MakeFlatBox(Color(0.08, 0.11, 0.18, 0.95), Color(0.28, 0.38, 0.55, 0.55))
    var oBtnHover = MakeFlatBox(Color(0.11, 0.15, 0.24, 0.98), Color(0.45, 0.85, 1.0, 0.65))
    var oBtnPressed = MakeFlatBox(Color(0.06, 0.09, 0.16, 0.98), Color(0.35, 0.75, 0.95, 0.85))
    var oBtnDisabled = MakeFlatBox(Color(0.06, 0.08, 0.12, 0.65), Color(0.18, 0.22, 0.32, 0.35))

    pTheme.set_stylebox("normal", "Button", oBtnNormal)
    pTheme.set_stylebox("hover", "Button", oBtnHover)
    pTheme.set_stylebox("pressed", "Button", oBtnPressed)
    pTheme.set_stylebox("disabled", "Button", oBtnDisabled)
    pTheme.set_stylebox("focus", "Button", oBtnHover)

    pTheme.set_color("font_color", "Button", C_TEXT)
    pTheme.set_color("font_color_hover", "Button", C_ACCENT)
    pTheme.set_color("font_color_pressed", "Button", C_TEXT)
    pTheme.set_color("font_color_disabled", "Button", C_TEXT_DIM)

    var oSlider = MakeFlatBox(Color(0.12, 0.16, 0.24, 0.9), Color(0.22, 0.30, 0.45, 0.45))
    oSlider.content_margin_top = 4
    oSlider.content_margin_bottom = 4
    pTheme.set_stylebox("slider", "HSlider", oSlider)

    var oGrabber = MakeFlatBox(C_ACCENT, Color(0.75, 0.92, 1.0, 0.95))
    oGrabber.content_margin_left = 3
    oGrabber.content_margin_right = 3
    oGrabber.content_margin_top = 3
    oGrabber.content_margin_bottom = 3
    pTheme.set_stylebox("grabber", "HSlider", oGrabber)
    pTheme.set_stylebox("grabber_highlight", "HSlider", oGrabber)

    return pTheme

static func StyleLabel(pLabel: Label, oColor: Color = C_TEXT) -> void:
    pLabel.add_color_override("font_color", oColor)
    pLabel.add_constant_override("line_spacing", 2)

static func ApplyToControl(pRoot: Control) -> void:
    pRoot.theme = BuildTheme()
