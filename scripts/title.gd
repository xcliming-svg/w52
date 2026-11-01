extends Control

signal finished

const UI = preload("res://scripts/ui_style.gd")


func _ready() -> void:
    var column: VBoxContainer = UI.create_layout(self, "W52", "TACTICAL MECH BATTLE")
    column.add_child(UI.make_label("게임 준비 중", 16, UI.MUTED))
    get_tree().create_timer(1.5).timeout.connect(_on_timer_timeout)


func _on_timer_timeout() -> void:
    if is_inside_tree():
        finished.emit()
