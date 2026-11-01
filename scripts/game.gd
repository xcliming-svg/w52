extends Node2D

const UI = preload("res://scripts/ui_style.gd")
signal defeated

const SPEED: float = 240.0
const PLAYER_RADIUS: float = 18.0
var player_position: Vector2 = Vector2(480.0, 270.0)


func restore_position(pos: Vector2) -> void:
    var size := get_viewport_rect().size
    player_position = Vector2(
        clampf(pos.x, PLAYER_RADIUS, size.x - PLAYER_RADIUS),
        clampf(pos.y, PLAYER_RADIUS, size.y - PLAYER_RADIUS)
    )
    queue_redraw()


func _process(delta: float) -> void:
    var direction := Vector2.ZERO
    if Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT):
        direction.x -= 1.0
    if Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT):
        direction.x += 1.0
    if Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP):
        direction.y -= 1.0
    if Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN):
        direction.y += 1.0

    var viewport_size := get_viewport_rect().size
    player_position += direction.normalized() * SPEED * delta
    player_position.x = clampf(player_position.x, PLAYER_RADIUS, viewport_size.x - PLAYER_RADIUS)
    player_position.y = clampf(player_position.y, PLAYER_RADIUS, viewport_size.y - PLAYER_RADIUS)
    queue_redraw()


func _draw() -> void:
    draw_rect(Rect2(Vector2.ZERO, get_viewport_rect().size), UI.GAME_BACKGROUND)
    draw_circle(player_position, PLAYER_RADIUS, UI.PLAYER_FILL)
    draw_arc(player_position, PLAYER_RADIUS + 2.0, 0.0, TAU, 48, UI.PLAYER_OUTLINE, 2.0)
