class_name PrototypeRoomState
extends RefCounted

const UnitStateScript = preload("res://scripts/proto_001/unit_state.gd")

const GRID_SIZE := Vector2i(8, 5)
const PLAYER_START := Vector2i(1, 2)
const ENEMY_START := Vector2i(6, 2)
const PLAYER_MAX_HP := 4
const ENEMY_MAX_HP := 3

var player = UnitStateScript.new(PLAYER_START, PLAYER_MAX_HP)
var enemy = UnitStateScript.new(ENEMY_START, ENEMY_MAX_HP)
var turn_number := 0


func reset() -> void:
	player.reset()
	enemy.reset()
	turn_number = 0


func resolve_turn(action_kind: StringName, direction: Vector2i = Vector2i.ZERO) -> Dictionary:
	turn_number += 1
	var player_result := _resolve_player_action(action_kind, direction)
	var enemy_result := _empty_action("none")
	if enemy.is_alive():
		enemy_result = _resolve_enemy_action()

	return {
		"player": player_result,
		"enemy": enemy_result,
		"room_cleared": not enemy.is_alive(),
		"player_defeated": not player.is_alive(),
		"turn_number": turn_number,
	}


func is_inside(cell: Vector2i) -> bool:
	return cell.x >= 0 and cell.y >= 0 and cell.x < GRID_SIZE.x and cell.y < GRID_SIZE.y


func is_enemy_threatening_player() -> bool:
	return enemy.is_alive() and _manhattan(enemy.cell, player.cell) == 1


func _resolve_player_action(action_kind: StringName, direction: Vector2i) -> Dictionary:
	if action_kind != &"direction":
		return _empty_action("wait")
	if direction == Vector2i.ZERO:
		return _empty_action("blocked")

	var target: Vector2i = player.cell + direction
	if not is_inside(target):
		return _empty_action("blocked")
	if target == enemy.cell and enemy.is_alive():
		var damage := enemy.take_damage(player.attack_damage)
		return {
			"kind": "attack",
			"damage": damage,
			"from": player.cell,
			"to": enemy.cell,
		}

	var previous_cell: Vector2i = player.cell
	player.cell = target
	return {
		"kind": "move",
		"damage": 0,
		"from": previous_cell,
		"to": player.cell,
	}


func _resolve_enemy_action() -> Dictionary:
	if _manhattan(enemy.cell, player.cell) == 1:
		var damage := player.take_damage(enemy.attack_damage)
		return {
			"kind": "attack",
			"damage": damage,
			"from": enemy.cell,
			"to": player.cell,
		}

	var delta: Vector2i = player.cell - enemy.cell
	var step := Vector2i.ZERO
	if abs(delta.x) >= abs(delta.y) and delta.x != 0:
		step.x = int(sign(delta.x))
	elif delta.y != 0:
		step.y = int(sign(delta.y))

	var previous_cell: Vector2i = enemy.cell
	var target: Vector2i = enemy.cell + step
	if is_inside(target) and target != player.cell:
		enemy.cell = target
	return {
		"kind": "move" if enemy.cell != previous_cell else "none",
		"damage": 0,
		"from": previous_cell,
		"to": enemy.cell,
	}


func _empty_action(kind: String) -> Dictionary:
	return {
		"kind": kind,
		"damage": 0,
		"from": Vector2i.ZERO,
		"to": Vector2i.ZERO,
	}


func _manhattan(first: Vector2i, second: Vector2i) -> int:
	return absi(first.x - second.x) + absi(first.y - second.y)
