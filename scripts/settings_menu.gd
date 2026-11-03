extends Control

signal close_requested

const UI = preload("res://scripts/ui_style.gd")
var settings_store: Node
var fullscreen_toggle: CheckButton


func _ready() -> void:
    var column: VBoxContainer = UI.create_layout(self, "설정", "음량 및 화면 모드", true)
    _add_volume_row(column, "전체 음량", "Master", float(settings_store.get("master_volume")))
    _add_volume_row(column, "음악 음량", "Music", float(settings_store.get("music_volume")))
    _add_volume_row(column, "효과음 음량", "SFX", float(settings_store.get("sfx_volume")))

    fullscreen_toggle = CheckButton.new()
    fullscreen_toggle.text = "전체화면"
    fullscreen_toggle.set_pressed_no_signal(bool(settings_store.call("is_fullscreen")))
    fullscreen_toggle.add_theme_font_size_override("font_size", 12)
    fullscreen_toggle.add_theme_color_override("font_color", UI.TEXT)
    column.add_child(fullscreen_toggle)
    if OS.has_feature("web"):
        # Web security requires the request while the original mouse/key event
        # is active. Handle that event in _input, before GUI signal dispatch.
        # A browser Esc can also leave fullscreen without toggling this button.
        get_window().size_changed.connect(_sync_fullscreen_on_resize)
    else:
        fullscreen_toggle.toggled.connect(func(enabled: bool) -> void: settings_store.call("set_fullscreen", enabled))

    var back_button: Button = UI.make_button("뒤로 가기")
    column.add_child(back_button)
    back_button.pressed.connect(func() -> void: close_requested.emit())
    back_button.grab_focus()


func _input(event: InputEvent) -> void:
    if not OS.has_feature("web") or fullscreen_toggle == null:
        return
    if event is InputEventMouseButton:
        var mouse := event as InputEventMouseButton
        if mouse.button_index == MOUSE_BUTTON_LEFT \
                and fullscreen_toggle.get_global_rect().has_point(mouse.position):
            if mouse.pressed:
                fullscreen_toggle.grab_focus()
                _toggle_web_fullscreen()
            # Consume press and release so BaseButton does not toggle again.
            get_viewport().set_input_as_handled()
    elif event is InputEventKey:
        var key := event as InputEventKey
        if fullscreen_toggle.has_focus() and (key.keycode == KEY_SPACE \
                or key.keycode == KEY_ENTER or key.keycode == KEY_KP_ENTER):
            if key.pressed and not key.echo:
                _toggle_web_fullscreen()
            get_viewport().set_input_as_handled()


func _toggle_web_fullscreen() -> void:
    var enabled := not bool(settings_store.call("is_fullscreen"))
    # Calling from _input retains the browser's trusted user gesture.
    settings_store.call("set_fullscreen", enabled)
    fullscreen_toggle.set_pressed_no_signal(enabled)


func _sync_fullscreen_on_resize() -> void:
    # Resize/fullscreen exit is asynchronous in browsers; inspect window state
    # after the resize notification rather than using cached settings.
    call_deferred("_sync_fullscreen_indicator")


func _sync_fullscreen_indicator() -> void:
    if is_instance_valid(fullscreen_toggle):
        fullscreen_toggle.set_pressed_no_signal(bool(settings_store.call("is_fullscreen")))


func _add_volume_row(column: VBoxContainer, label_text: String, bus_name: String, volume: float) -> void:
    var row := HBoxContainer.new()
    row.add_theme_constant_override("separation", 8)
    var name_label: Label = UI.make_label(label_text, 12)
    name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
    name_label.custom_minimum_size.x = 86.0
    row.add_child(name_label)

    var slider := HSlider.new()
    slider.min_value = 0.0
    slider.max_value = 100.0
    slider.step = 1.0
    slider.value = volume * 100.0
    slider.custom_minimum_size = Vector2(150.0, 18.0)
    slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    row.add_child(slider)
    column.add_child(row)
    slider.value_changed.connect(func(value: float) -> void: settings_store.call("set_volume", bus_name, value / 100.0))
