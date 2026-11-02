extends RefCounted

# Future art and typography can be assigned without changing the screen logic.
const BACKGROUND := Color("#111923")
const PANEL := Color("#172a38")
const BORDER := Color("#506b7e")
const PRIMARY := Color("#24465a")
const PRIMARY_HOVER := Color("#315d75")
const TEXT := Color("#e9eff5")
const MUTED := Color("#9dafc1")
const GAME_BACKGROUND := Color("#101c29")
const DESIGN_SIZE := Vector2i(1920, 1080)
const LEFT_WIDTH := 1376
const RIGHT_WIDTH := 544
const HEADER_HEIGHT := 84
const TREE_HEIGHT := 892
const HELP_HEIGHT := 104
const BATTLEFIELD_HEIGHT := 652
const LOG_HEIGHT := 240
const ACTION_HEIGHT := 104
const CELL_SIZE := 46
const HEADER := Color("#182737")
const GRID := Color("#1c2c3e")
const GRID_BORDER := Color("#345164")
const TREE_LINE := Color("#496b7c")
const NODE_FILL := Color("#1f4b50")
const LOCKED := Color("#253744")
const GOLD := Color("#d8ad62")
const TEAL := Color("#61d6c6")
const ENEMY := Color("#d9776a")
const ENEMY_CELL := Color("#503035")
const ALLY_CELL := Color("#153e3d")
const DIALOGUE_PANEL := Color("#223347")
# Pixel UI Fantasy Free: retain W52's dark content and Korean typography,
# while using the pack's actual border and parchment button state sprites.
const PIXEL_PANEL: Texture2D = preload("res://assets/ui/pixel_fantasy/frame.png")
const PIXEL_BUTTON_NORMAL: Texture2D = preload("res://assets/ui/pixel_fantasy/button_normal.png")
const PIXEL_BUTTON_HOVER: Texture2D = preload("res://assets/ui/pixel_fantasy/button_hover.png")
const PIXEL_BUTTON_PRESSED: Texture2D = preload("res://assets/ui/pixel_fantasy/button_pressed.png")
const PIXEL_BUTTON_DISABLED: Texture2D = preload("res://assets/ui/pixel_fantasy/button_disabled.png")
const PIXEL_SCALE := 3
const BUTTON_INK := Color("#291c14")
const BUTTON_DISABLED_INK := Color("#30333b")


static func create_layout(root: Control, heading: String, description: String = "", dim_background: bool = false) -> VBoxContainer:
    var background := ColorRect.new()
    root.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
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
    panel.custom_minimum_size = Vector2(640.0, 0.0)
    panel.add_theme_stylebox_override("panel", _panel_style())
    center.add_child(panel)

    var column := VBoxContainer.new()
    column.add_theme_constant_override("separation", 24)
    panel.add_child(column)
    column.add_child(make_label(heading, 52, TEXT))
    if not description.is_empty():
        column.add_child(make_label(description, 26, MUTED))
    return column


static func make_label(value: String, font_size: int = 28, color: Color = TEXT) -> Label:
    var label := Label.new()
    label.text = value
    label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    label.add_theme_color_override("font_color", color)
    label.add_theme_font_size_override("font_size", font_size)
    return label


static func make_button(value: String, minimum_size: Vector2 = Vector2(500.0, 74.0)) -> Button:
    var button := Button.new()
    button.text = value
    button.custom_minimum_size = minimum_size
    button.size = minimum_size
    button.add_theme_font_size_override("font_size", 29)
    button.add_theme_stylebox_override("normal", _pixel_box(PIXEL_BUTTON_NORMAL, 5, Vector2(20, 0)))
    button.add_theme_stylebox_override("hover", _pixel_box(PIXEL_BUTTON_HOVER, 5, Vector2(20, 0)))
    button.add_theme_stylebox_override("pressed", _pixel_box(PIXEL_BUTTON_PRESSED, 5, Vector2(20, 0)))
    button.add_theme_stylebox_override("disabled", _pixel_box(PIXEL_BUTTON_DISABLED, 5, Vector2(20, 0)))
    button.add_theme_stylebox_override("focus", _button_focus())
    button.add_theme_color_override("font_color", BUTTON_INK)
    button.add_theme_color_override("font_hover_color", BUTTON_INK)
    button.add_theme_color_override("font_pressed_color", BUTTON_INK)
    button.add_theme_color_override("font_hover_pressed_color", BUTTON_INK)
    button.add_theme_color_override("font_disabled_color", BUTTON_DISABLED_INK)
    return button


static func _panel_style() -> StyleBoxTexture:
    # Source panel has a tan center that would reduce contrast with W52's light text.
    # Replace only the 12x12 center tile with W52 PANEL; preserve the 6px
    # hand-drawn outline. Nearest 3x keeps all edges pixel-aligned.
    return _pixel_box(PIXEL_PANEL, 6, Vector2(50, 40), PANEL)


static func _pixel_box(source: Texture2D, margin_px: int, content: Vector2, center_color: Color = Color.TRANSPARENT) -> StyleBoxTexture:
    var image: Image = source.get_image()
    if center_color.a > 0.0:
        var inset := margin_px
        image.fill_rect(Rect2i(inset, inset,
            image.get_width() - inset * 2, image.get_height() - inset * 2), center_color)
    image.resize(image.get_width() * PIXEL_SCALE, image.get_height() * PIXEL_SCALE, Image.INTERPOLATE_NEAREST)
    var style := StyleBoxTexture.new()
    style.texture = ImageTexture.create_from_image(image)
    style.set_texture_margin_all(float(margin_px * PIXEL_SCALE))
    style.axis_stretch_horizontal = StyleBoxTexture.AXIS_STRETCH_MODE_TILE
    style.axis_stretch_vertical = StyleBoxTexture.AXIS_STRETCH_MODE_TILE
    style.draw_center = true
    style.content_margin_left = content.x
    style.content_margin_right = content.x
    style.content_margin_top = content.y
    style.content_margin_bottom = content.y
    return style


static func _button_style(color: Color) -> StyleBoxFlat:
    var style := StyleBoxFlat.new()
    style.bg_color = color
    style.border_color = BORDER
    style.set_border_width_all(1)
    style.set_corner_radius_all(10)
    style.content_margin_left = 20.0
    style.content_margin_right = 20.0
    return style


static func _button_focus() -> StyleBoxFlat:
    var style := StyleBoxFlat.new()
    style.bg_color = Color.TRANSPARENT
    style.border_color = MUTED
    style.set_border_width_all(2)
    style.set_corner_radius_all(3)
    return style
