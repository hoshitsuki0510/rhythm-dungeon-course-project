class_name PrototypeRoomView
extends Control

const RoomStateScript = preload("res://scripts/proto_001/room_state.gd")

const FLOOR_DARK := Color(0.105, 0.145, 0.125, 1.0)
const FLOOR_LIGHT := Color(0.135, 0.185, 0.145, 1.0)
const GRID_LINE := Color(0.24, 0.31, 0.25, 0.55)
const WALL := Color(0.20, 0.22, 0.20, 1.0)
const WALL_EDGE := Color(0.38, 0.40, 0.34, 1.0)
const PLAYER_COLOR := Color(0.23, 0.82, 0.88, 1.0)
const PLAYER_CORE := Color(0.88, 1.0, 0.96, 1.0)
const ENEMY_COLOR := Color(0.92, 0.31, 0.30, 1.0)
const ENEMY_CORE := Color(1.0, 0.70, 0.28, 1.0)
const SHADOW := Color(0.01, 0.015, 0.012, 0.45)

var room_state
var player_hit_flash := 0.0
var enemy_hit_flash := 0.0
var action_flash := 0.0


func bind_room(state) -> void:
	room_state = state
	queue_redraw()


func show_player_hit() -> void:
	player_hit_flash = 1.0
	action_flash = 1.0


func show_enemy_hit() -> void:
	enemy_hit_flash = 1.0
	action_flash = 1.0


func show_action() -> void:
	action_flash = 1.0


func reset_feedback() -> void:
	player_hit_flash = 0.0
	enemy_hit_flash = 0.0
	action_flash = 0.0
	queue_redraw()


func _process(delta: float) -> void:
	player_hit_flash = maxf(0.0, player_hit_flash - delta * 5.5)
	enemy_hit_flash = maxf(0.0, enemy_hit_flash - delta * 5.5)
	action_flash = maxf(0.0, action_flash - delta * 7.0)
	queue_redraw()


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.055, 0.065, 0.058, 1.0))
	if room_state == null:
		return

	var layout := _grid_layout()
	var origin: Vector2 = layout.origin
	var cell_size: float = layout.cell_size
	var board_size := Vector2(RoomStateScript.GRID_SIZE) * cell_size

	draw_rect(Rect2(origin - Vector2(13.0, 13.0), board_size + Vector2(26.0, 26.0)), WALL)
	draw_rect(Rect2(origin - Vector2(13.0, 13.0), board_size + Vector2(26.0, 26.0)), WALL_EDGE, false, 2.0)
	_draw_door(origin, cell_size, false)
	_draw_door(origin, cell_size, true)

	for y in range(RoomStateScript.GRID_SIZE.y):
		for x in range(RoomStateScript.GRID_SIZE.x):
			var cell := Vector2i(x, y)
			var rect := Rect2(origin + Vector2(cell) * cell_size, Vector2.ONE * cell_size)
			var floor_color := FLOOR_LIGHT if (x + y) % 2 == 0 else FLOOR_DARK
			draw_rect(rect, floor_color)
			draw_rect(rect, GRID_LINE, false, 1.0)

	if room_state.is_enemy_threatening_player():
		var warning_rect := _cell_rect(room_state.player.cell, origin, cell_size).grow(-4.0)
		var warning_color := Color(ENEMY_COLOR, 0.28 + 0.18 * action_flash)
		draw_rect(warning_rect, warning_color, false, 4.0)

	_draw_player(origin, cell_size)
	if room_state.enemy.is_alive():
		_draw_enemy(origin, cell_size)


func _draw_door(origin: Vector2, cell_size: float, right_side: bool) -> void:
	var x := origin.x - 13.0
	if right_side:
		x = origin.x + RoomStateScript.GRID_SIZE.x * cell_size - 3.0
	var y := origin.y + cell_size * 2.0 + 9.0
	var door_rect := Rect2(Vector2(x, y), Vector2(16.0, cell_size - 18.0))
	var door_color := Color(0.79, 0.58, 0.20, 1.0)
	if right_side and not room_state.enemy.is_alive():
		door_color = Color(0.33, 0.84, 0.52, 1.0)
	draw_rect(door_rect, door_color)


func _draw_player(origin: Vector2, cell_size: float) -> void:
	var center := _cell_center(room_state.player.cell, origin, cell_size)
	var radius := cell_size * 0.28
	draw_ellipse_shadow(center, radius)
	var color := Color.WHITE if player_hit_flash > 0.0 else PLAYER_COLOR
	var points := PackedVector2Array([
		center + Vector2(0.0, -radius),
		center + Vector2(radius, 0.0),
		center + Vector2(0.0, radius),
		center + Vector2(-radius, 0.0),
	])
	draw_colored_polygon(points, color)
	draw_circle(center, radius * 0.35, PLAYER_CORE)
	_draw_health_bar(center, cell_size, room_state.player.hp, room_state.player.max_hp, PLAYER_COLOR)


func _draw_enemy(origin: Vector2, cell_size: float) -> void:
	var center := _cell_center(room_state.enemy.cell, origin, cell_size)
	var radius := cell_size * 0.28
	draw_ellipse_shadow(center, radius)
	var color := Color.WHITE if enemy_hit_flash > 0.0 else ENEMY_COLOR
	draw_circle(center, radius, color)
	draw_circle(center, radius * 0.34, ENEMY_CORE)
	draw_line(center + Vector2(-radius * 0.55, -radius * 0.30), center + Vector2(-2.0, 1.0), WALL, 3.0)
	draw_line(center + Vector2(radius * 0.55, -radius * 0.30), center + Vector2(2.0, 1.0), WALL, 3.0)
	_draw_health_bar(center, cell_size, room_state.enemy.hp, room_state.enemy.max_hp, ENEMY_COLOR)


func draw_ellipse_shadow(center: Vector2, radius: float) -> void:
	draw_set_transform(center + Vector2(0.0, radius * 0.75), 0.0, Vector2(1.0, 0.42))
	draw_circle(Vector2.ZERO, radius * 0.88, SHADOW)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func _draw_health_bar(center: Vector2, cell_size: float, hp: int, max_hp: int, color: Color) -> void:
	var width := cell_size * 0.62
	var background := Rect2(center + Vector2(-width * 0.5, -cell_size * 0.39), Vector2(width, 5.0))
	draw_rect(background, Color(0.02, 0.025, 0.02, 0.85))
	var ratio := float(hp) / float(max_hp)
	draw_rect(Rect2(background.position, Vector2(background.size.x * ratio, background.size.y)), color)


func _grid_layout() -> Dictionary:
	var available := size - Vector2(54.0, 54.0)
	var cell_size := minf(
		available.x / RoomStateScript.GRID_SIZE.x,
		available.y / RoomStateScript.GRID_SIZE.y
	)
	cell_size = floorf(cell_size)
	var board_size := Vector2(RoomStateScript.GRID_SIZE) * cell_size
	return {
		"origin": (size - board_size) * 0.5,
		"cell_size": cell_size,
	}


func _cell_center(cell: Vector2i, origin: Vector2, cell_size: float) -> Vector2:
	return origin + Vector2(cell) * cell_size + Vector2.ONE * cell_size * 0.5


func _cell_rect(cell: Vector2i, origin: Vector2, cell_size: float) -> Rect2:
	return Rect2(origin + Vector2(cell) * cell_size, Vector2.ONE * cell_size)
