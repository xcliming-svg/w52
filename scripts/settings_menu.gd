extends Control

signal close_requested

const UI = preload("res://scripts/ui_style.gd")
var settings_store: Node


func _ready() -> void:
    var column: VBoxContainer = UI.create_layout(self, "설정", "음량 및 화면 모드", true)
    _add_volume_row(column, "전체 음량", "Master", float(settings_store.get("master_volume")))
    _add_volume_row(column, "음악 음량", "Music", float(settings_store.get("music_volume")))
    _add_volume_row(column, "효과음 음량", "SFX", float(settings_store.get("sfx_volume")))

    var fullscreen_toggle := CheckButton.new()
    fullscreen_toggle.text = "전체화면"
    fullscreen_toggle.button_pressed = bool(settings_store.get("fullscreen"))
    fullscreen_toggle.add_theme_font_size_override("font_size", 12)
    fullscreen_toggle.add_theme_color_override("font_color", UI.TEXT)
    column.add_child(fullscreen_toggle)
    fullscreen_toggle.toggled.connect(func(enabled: bool) -> void: settings_store.call("set_fullscreen", enabled))

    var back_button: Button = UI.make_button("뒤로 가기")
    column.add_child(back_button)
    back_button.pressed.connect(func() -> void: close_requested.emit())
    back_button.grab_focus()


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
