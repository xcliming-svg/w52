extends RefCounted

# DawnBringer 32 solid-color tokens: no gradients or blended highlights.
const BACKGROUND := Color("#000000")
const PANEL := Color("#323c39")
const BORDER := Color("#595652")
const PRIMARY := Color("#d9a066")
const PRIMARY_HOVER := Color("#eec39a")
const TEXT := Color("#eec39a")
const MUTED := Color("#9badb7")
const GAME_BACKGROUND := Color("#222034")
const HEADER := PANEL
const GRID := Color("#595652")
const GRID_BORDER := Color("#696a6a")
const TREE_LINE := Color("#847e87")
const NODE_FILL := PANEL
const LOCKED := GAME_BACKGROUND
const GOLD := PRIMARY
const TEAL := Color("#37946e")
const ENEMY := Color("#8f563b")
const ENEMY_CELL := GAME_BACKGROUND
const ALLY_CELL := PANEL
const DIALOGUE_PANEL := GAME_BACKGROUND
const METAL_LIGHT := Color("#696a6a")
const METAL_MID := Color("#595652")
const METAL_DARK := PANEL
const EDGE_DARK := GAME_BACKGROUND
const BUTTON_SHADE := Color("#8a6f30")
const BUTTON_EDGE := Color("#8f563b")
const BUTTON_DARK := Color("#663931")

const DESIGN_SIZE := Vector2i(640, 360)
const LEFT_WIDTH := 448
const RIGHT_WIDTH := 192
const TOP_BLANK := 36
const FRAME_THICKNESS := 7
const SCREW_DIAMETER := 3
# v8 CSS reference: border-box cut=8; middle inset=2/cut=7;
# dark inner rim inset=6/cut=5; panel core inset=7/cut=4.
# The progressively deeper diagonal cuts keep the 3px screw centered on metal.
const PANEL_IDS := ["L1", "L2", "L3", "R1", "R2", "R3", "R4"]
const DIALOGUE_RECT := Rect2i(4, 251, 426, 43)

# Round one shared set of 20-row boundaries; do not recompute fractional margins.
static func boundary(row: int) -> int:
    return TOP_BLANK + roundi(324.0 * float(row) / 20.0)


static func cell_rect(panel_id: String) -> Rect2i:
    match panel_id:
        "L1":
            return Rect2i(0, boundary(0), LEFT_WIDTH, boundary(3) - boundary(0))
        "L2":
            return Rect2i(0, boundary(3), LEFT_WIDTH, boundary(17) - boundary(3))
        "L3":
            return Rect2i(0, boundary(17), LEFT_WIDTH, boundary(20) - boundary(17))
        "R1":
            return Rect2i(LEFT_WIDTH, boundary(0), RIGHT_WIDTH, boundary(3) - boundary(0))
        "R2":
            return Rect2i(LEFT_WIDTH, boundary(3), RIGHT_WIDTH, boundary(13) - boundary(3))
        "R3":
            return Rect2i(LEFT_WIDTH, boundary(13), RIGHT_WIDTH, boundary(17) - boundary(13))
        "R4":
            return Rect2i(LEFT_WIDTH, boundary(17), RIGHT_WIDTH, boundary(20) - boundary(17))
    push_error("Invalid W52 panel: " + panel_id)
    return Rect2i()


static func frame_rect(panel_id: String) -> Rect2i:
    var cell := cell_rect(panel_id)
    return Rect2i(cell.position + Vector2i(4, 4), cell.size - Vector2i(7, 7))


static func content_rect(panel_id: String) -> Rect2i:
    var frame := frame_rect(panel_id)
    var inset := FRAME_THICKNESS
    return Rect2i(frame.position + Vector2i(inset, inset),
        frame.size - Vector2i(inset * 2, inset * 2))


static func metal_corner_cut(inset: int) -> int:
    match inset:
        0:
            return 8
        2:
            return 7
        6:
            return 5
        7:
            return 4
    push_error("Invalid metal layer inset: %d" % inset)
    return 0


static func screw_origins(panel_id: String) -> Array[Vector2i]:
    var frame := frame_rect(panel_id)
    return [
        frame.position + Vector2i(5, 5),
        Vector2i(frame.end.x - 8, frame.position.y + 5),
        Vector2i(frame.position.x + 5, frame.end.y - 8),
        frame.end - Vector2i(8, 8)
    ]


static func create_layout(root: Control, heading: String, description: String = "", dim_background: bool = false) -> VBoxContainer:
    var background := ColorRect.new()
    background.name = "BackgroundColor"
    background.color = GAME_BACKGROUND if dim_background else BACKGROUND
    background.mouse_filter = Control.MOUSE_FILTER_IGNORE
    root.add_child(background)
    background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    root.move_child(background, 0)

    var center := CenterContainer.new()
    center.name = "Content"
    root.add_child(center)
    center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

    var panel := PanelContainer.new()
    panel.custom_minimum_size = Vector2(290, 0)
    panel.add_theme_stylebox_override("panel", _panel_style())
    center.add_child(panel)

    var column := VBoxContainer.new()
    column.add_theme_constant_override("separation", 7)
    panel.add_child(column)
    column.add_child(make_label(heading, 22, TEXT))
    if not description.is_empty():
        column.add_child(make_label(description, 12, MUTED))
    return column


static func make_label(value: String, font_size: int = 12, color: Color = TEXT) -> Label:
    var label := Label.new()
    label.text = value
    label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    label.add_theme_color_override("font_color", color)
    label.add_theme_font_size_override("font_size", font_size)
    return label


static func make_button(value: String, minimum_size: Vector2 = Vector2(220, 30)) -> Button:
    var button := Button.new()
    button.text = value
    button.custom_minimum_size = minimum_size
    button.size = minimum_size
    button.add_theme_font_size_override("font_size", 13)
    button.add_theme_stylebox_override("normal", _button_style(PRIMARY))
    button.add_theme_stylebox_override("hover", _button_style(PRIMARY_HOVER))
    button.add_theme_stylebox_override("pressed", _button_style(BUTTON_SHADE))
    button.add_theme_stylebox_override("disabled", _button_style(PANEL))
    button.add_theme_stylebox_override("focus", _button_focus())
    button.add_theme_color_override("font_color", GAME_BACKGROUND)
    button.add_theme_color_override("font_hover_color", GAME_BACKGROUND)
    button.add_theme_color_override("font_pressed_color", TEXT)
    button.add_theme_color_override("font_disabled_color", MUTED)
    return button


static func _panel_style() -> StyleBoxFlat:
    var style := StyleBoxFlat.new()
    style.bg_color = PANEL
    style.border_color = BORDER
    style.set_border_width_all(2)
    style.set_corner_radius_all(0)
    style.content_margin_left = 14.0
    style.content_margin_right = 14.0
    style.content_margin_top = 11.0
    style.content_margin_bottom = 11.0
    return style


static func _button_style(color: Color) -> StyleBoxFlat:
    var style := StyleBoxFlat.new()
    style.bg_color = color
    style.border_color = BUTTON_DARK
    style.set_border_width_all(2)
    style.set_corner_radius_all(0)
    style.content_margin_left = 4.0
    style.content_margin_right = 4.0
    style.content_margin_top = 2.0
    style.content_margin_bottom = 2.0
    return style


static func _button_focus() -> StyleBoxFlat:
    var style := StyleBoxFlat.new()
    style.draw_center = false
    style.border_color = MUTED
    style.set_border_width_all(1)
    style.set_corner_radius_all(0)
    return style
