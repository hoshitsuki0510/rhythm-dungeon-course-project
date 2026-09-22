class_name PrototypeUnitState
extends RefCounted

var cell := Vector2i.ZERO
var start_cell := Vector2i.ZERO
var max_hp := 1
var hp := 1
var attack_damage := 1


func _init(initial_cell: Vector2i, maximum_hp: int, damage: int = 1) -> void:
	start_cell = initial_cell
	max_hp = maximum_hp
	attack_damage = damage
	reset()


func reset() -> void:
	cell = start_cell
	hp = max_hp


func take_damage(amount: int) -> int:
	var previous_hp := hp
	hp = maxi(0, hp - maxi(0, amount))
	return previous_hp - hp


func is_alive() -> bool:
	return hp > 0
