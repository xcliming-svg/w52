extends Node2D

const SPEED: float = 240.0
const PLAYER_RADIUS: float = 18.0
var player_position: Vector2 = Vector2(480.0, 270.0)


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
    draw_rect(Rect2(Vector2.ZERO, get_viewport_rect().size), Color(0.07, 0.09, 0.14))
    draw_circle(player_position, PLAYER_RADIUS, Color(0.23, 0.86, 0.66))
    draw_arc(player_position, PLAYER_RADIUS + 2.0, 0.0, TAU, 48, Color(0.85, 1.0, 0.94), 2.0)
