extends RefCounted

# Future art and typography can be assigned without changing the screen logic.
const BACKGROUND := Color("#191716")
const PANEL := Color("#29231f")
const BORDER := Color("#8a6650")
const PRIMARY := Color("#60473b")
const PRIMARY_HOVER := Color("#805b42")
const TEXT := Color("#f0e2cd")
const MUTED := Color("#c3ad99")
const GAME_BACKGROUND := Color("#191a1c")
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
const HEADER := Color("#32251f")
const GRID := Color("#292727")
const GRID_BORDER := Color("#62514b")
const TREE_LINE := Color("#846f60")
const NODE_FILL := Color("#385252")
const LOCKED := Color("#3c3733")
const GOLD := Color("#e0af6d")
const TEAL := Color("#84d0c3")
const ENEMY := Color("#d18068")
const ENEMY_CELL := Color("#513431")
const ALLY_CELL := Color("#274440")
const DIALOGUE_PANEL := Color("#312924")
# Pixel UI Fantasy Free: retain W52's dark content and Korean typography,
# while using the pack's actual border and parchment button state sprites.
const PIXEL_PANEL: Texture2D = preload("res://assets/ui/pixel_fantasy/frame.png")
const PIXEL_BUTTON_NORMAL: Texture2D = preload("res://assets/ui/pixel_fantasy/button_normal.png")
const PIXEL_BUTTON_HOVER: Texture2D = preload("res://assets/ui/pixel_fantasy/button_hover.png")
const PIXEL_BUTTON_PRESSED: Texture2D = preload("res://assets/ui/pixel_fantasy/button_pressed.png")
const PIXEL_BUTTON_DISABLED: Texture2D = preload("res://assets/ui/pixel_fantasy/button_disabled.png")
const PIXEL_SCALE := 3
const BUTTON_INK := Color("#291c14")
const BUTTON_DISABLED_INK := Color("#4b453e")
const SLIDER_TRACK: Texture2D = preload("res://assets/ui/pixel_fantasy/slider.png")
const SLIDER_FILL: Texture2D = preload("res://assets/ui/pixel_fantasy/slider_fill.png")
const GRABBER: Texture2D = preload("res://assets/ui/pixel_fantasy/grabber.png")
const GRABBER_HOVER: Texture2D = preload("res://assets/ui/pixel_fantasy/grabber_hover.png")
const GRABBER_DISABLED: Texture2D = preload("res://assets/ui/pixel_fantasy/grabber_disabled.png")
const CHECKBOX_ON: Texture2D = preload("res://assets/ui/pixel_fantasy/checkbox_on.png")
const CHECKBOX_OFF: Texture2D = preload("res://assets/ui/pixel_fantasy/checkbox_off.png")
const SCROLL_TRACK: Texture2D = preload("res://assets/ui/pixel_fantasy/scrollbar_track.png")
const SCROLL_GRABBER: Texture2D = preload("res://assets/ui/pixel_fantasy/scrollbar_grabber.png")
const SCROLL_GRABBER_HOVER: Texture2D = preload("res://assets/ui/pixel_fantasy/scrollbar_grabber_hover.png")
const SCROLL_GRABBER_PRESSED: Texture2D = preload("res://assets/ui/pixel_fantasy/scrollbar_grabber_pressed.png")
const TAB_ON: Texture2D = preload("res://assets/ui/pixel_fantasy/tab_selected.png")
const TAB_OFF: Texture2D = preload("res://assets/ui/pixel_fantasy/tab_unselected.png")
const TAB_HOVER: Texture2D = preload("res://assets/ui/pixel_fantasy/tab_hover.png")
const PIXEL_FOCUS: Texture2D = preload("res://assets/ui/pixel_fantasy/focus.png")


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


static func style_speed_tab(active: bool) -> StyleBoxTexture:
    return _pixel_box(TAB_ON if active else TAB_OFF, 4, Vector2.ZERO)


static func style_speed_hover() -> StyleBoxTexture:
    return _pixel_box(TAB_HOVER, 4, Vector2.ZERO)


static func decorate_slider(slider: HSlider) -> void:
    # 8x5 images use 3/2/3/2 source-pixel slice borders.
    slider.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
    slider.add_theme_stylebox_override("slider", _sliced_box(SLIDER_TRACK, Vector4i(3, 2, 3, 2)))
    slider.add_theme_stylebox_override("grabber_area", _sliced_box(SLIDER_FILL, Vector4i(3, 2, 3, 2)))
    slider.add_theme_stylebox_override("grabber_area_highlight", _sliced_box(SLIDER_FILL, Vector4i(3, 2, 3, 2)))
    slider.add_theme_icon_override("grabber", _pixel_icon(GRABBER))
    slider.add_theme_icon_override("grabber_highlight", _pixel_icon(GRABBER_HOVER))
    slider.add_theme_icon_override("grabber_disabled", _pixel_icon(GRABBER_DISABLED))


static func decorate_checkbox(check: CheckBox) -> void:
    check.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
    check.add_theme_icon_override("checked", _pixel_icon(CHECKBOX_ON))
    check.add_theme_icon_override("unchecked", _pixel_icon(CHECKBOX_OFF))
    check.add_theme_icon_override("checked_disabled", _pixel_icon(CHECKBOX_ON))
    check.add_theme_icon_override("unchecked_disabled", _pixel_icon(CHECKBOX_OFF))
    check.add_theme_color_override("font_color", TEXT)
    check.add_theme_color_override("font_hover_color", TEXT)
    check.add_theme_color_override("font_pressed_color", TEXT)
    check.add_theme_constant_override("h_separation", 12)


static func decorate_log_scroll(scroll: VScrollBar) -> void:
    scroll.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
    scroll.add_theme_stylebox_override("scroll", _sliced_box(SCROLL_TRACK, Vector4i(2, 2, 2, 2)))
    scroll.add_theme_stylebox_override("scroll_focus", _sliced_box(SCROLL_TRACK, Vector4i(2, 2, 2, 2)))
    scroll.add_theme_stylebox_override("grabber", _sliced_box(SCROLL_GRABBER, Vector4i(2, 2, 2, 2)))
    scroll.add_theme_stylebox_override("grabber_highlight", _sliced_box(SCROLL_GRABBER_HOVER, Vector4i(2, 2, 2, 2)))
    scroll.add_theme_stylebox_override("grabber_pressed", _sliced_box(SCROLL_GRABBER_PRESSED, Vector4i(2, 2, 2, 2)))
    scroll.custom_minimum_size.x = 18.0


static func _pixel_icon(source: Texture2D) -> Texture2D:
    var image: Image = source.get_image()
    image.resize(image.get_width() * PIXEL_SCALE, image.get_height() * PIXEL_SCALE, Image.INTERPOLATE_NEAREST)
    return ImageTexture.create_from_image(image)


static func _sliced_box(source: Texture2D, margins: Vector4i) -> StyleBoxTexture:
    var style := StyleBoxTexture.new()
    style.texture = _pixel_icon(source)
    style.texture_margin_left = margins.x * PIXEL_SCALE
    style.texture_margin_top = margins.y * PIXEL_SCALE
    style.texture_margin_right = margins.z * PIXEL_SCALE
    style.texture_margin_bottom = margins.w * PIXEL_SCALE
    style.axis_stretch_horizontal = StyleBoxTexture.AXIS_STRETCH_MODE_TILE
    style.axis_stretch_vertical = StyleBoxTexture.AXIS_STRETCH_MODE_TILE
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


static func _button_focus() -> StyleBoxTexture:
    var style := _sliced_box(PIXEL_FOCUS, Vector4i(4, 4, 4, 4))
    style.draw_center = false
    return style
