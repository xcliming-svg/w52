extends Control

signal finished

const UI = preload("res://scripts/ui_style.gd")


func _ready() -> void:
    var column: VBoxContainer = UI.create_layout(self, "W52", "TACTICAL MECH BATTLE")
    # Keep the optional logo slot editable in title.tscn and in the panel layout.
    var logo_art := get_node("LogoArt") as TextureRect
    logo_art.reparent(column)
    column.move_child(logo_art, 0)
    column.add_child(UI.make_label("게임 준비 중", 26, UI.MUTED))
    get_tree().create_timer(1.5).timeout.connect(_on_timer_timeout)


func _on_timer_timeout() -> void:
    if is_inside_tree():
        finished.emit()
