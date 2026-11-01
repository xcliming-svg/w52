extends RefCounted

# Future art and typography can be assigned without changing the screen logic.
const BACKGROUND := Color("#111923")
const PANEL := Color("#172a38")
const BORDER := Color("#506b7e")
const PRIMARY := Color("#24465a")
const PRIMARY_HOVER := Color("#315d75")
const TEXT := Color("#e3edf6")
const MUTED := Color("#90a6b9")
# Existing gameplay placeholder colors are centralized for a future palette change.
const GAME_BACKGROUND := Color(0.07, 0.09, 0.14)
const PLAYER_FILL := Color(0.23, 0.86, 0.66)
const PLAYER_OUTLINE := Color(0.85, 1.0, 0.94)
static var custom_font: Font = null


static func create_layout(root: Control, heading: String, description: String = "", dim_background: bool = false) -> VBoxContainer:
    var background := ColorRect.new()
    background.name = "BackgroundColor"
    background.color = Color(0.0, 0.0, 0.0, 0.72) if dim_background else BACKGROUND
    background.mouse_filter = Control.MOUSE_FILTER_IGNORE
    root.add_child(background)
    background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    root.move_child(background, 0)

    var center := CenterContainer.new()
    center.name = "Content"
    root.add_child(center)
    center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

    var panel := PanelContainer.new()
    panel.custom_minimum_size = Vector2(350.0, 0.0)
    panel.add_theme_stylebox_override("panel", _panel_style())
    center.add_child(panel)

    var column := VBoxContainer.new()
    column.add_theme_constant_override("separation", 12)
    panel.add_child(column)
    column.add_child(make_label(heading, 32, TEXT))
    if not description.is_empty():
        column.add_child(make_label(description, 14, MUTED))
    return column


static func make_label(value: String, font_size: int = 18, color: Color = TEXT) -> Label:
    var label := Label.new()
    label.text = value
    label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    label.add_theme_color_override("font_color", color)
    label.add_theme_font_size_override("font_size", font_size)
    if custom_font != null:
        label.add_theme_font_override("font", custom_font)
    return label


static func make_button(value: String) -> Button:
    var button := Button.new()
    button.text = value
    button.custom_minimum_size = Vector2(280.0, 42.0)
    button.add_theme_stylebox_override("normal", _button_style(PRIMARY))
    button.add_theme_stylebox_override("hover", _button_style(PRIMARY_HOVER))
    button.add_theme_stylebox_override("pressed", _button_style(BORDER))
    button.add_theme_stylebox_override("disabled", _button_style(PANEL))
    button.add_theme_stylebox_override("focus", _button_focus())
    button.add_theme_color_override("font_color", TEXT)
    button.add_theme_color_override("font_hover_color", TEXT)
    button.add_theme_color_override("font_pressed_color", TEXT)
    button.add_theme_color_override("font_disabled_color", MUTED)
    if custom_font != null:
        button.add_theme_font_override("font", custom_font)
    return button


static func _panel_style() -> StyleBoxFlat:
    var style := StyleBoxFlat.new()
    style.bg_color = PANEL
    style.border_color = BORDER
    style.set_border_width_all(1)
    style.set_corner_radius_all(5)
    style.content_margin_left = 32.0
    style.content_margin_right = 32.0
    style.content_margin_top = 28.0
    style.content_margin_bottom = 28.0
    return style


static func _button_style(color: Color) -> StyleBoxFlat:
    var style := StyleBoxFlat.new()
    style.bg_color = color
    style.border_color = BORDER
    style.set_border_width_all(1)
    style.set_corner_radius_all(3)
    style.content_margin_left = 12.0
    style.content_margin_right = 12.0
    return style


static func _button_focus() -> StyleBoxFlat:
    var style := StyleBoxFlat.new()
    style.bg_color = Color.TRANSPARENT
    style.border_color = MUTED
    style.set_border_width_all(2)
    style.set_corner_radius_all(3)
    return style
