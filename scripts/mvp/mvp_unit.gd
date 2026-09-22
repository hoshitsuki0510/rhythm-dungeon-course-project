class_name MvpUnitState
extends RefCounted

var unit_id: String
var role: StringName
var cell := Vector2i.ZERO
var start_cell := Vector2i.ZERO
var max_hp := 1
var hp := 1
var attack_damage := 1
var facing := Vector2i.DOWN
var alive := true
# Regular enemies spend one beat telegraphing a plan and the next beat
# carrying it out. These fields keep that two-beat plan independent for each
# enemy; the Boss leaves them unused and keeps its faster special cadence.
var enemy_plan: StringName = &"none"
var enemy_plan_target := Vector2i.ZERO
var enemy_plan_direction := Vector2i.DOWN
# Role-specific cadence state. Siphonlings leave this at zero; the first
# layer's fixed Spit Slug uses it to fire on a predictable four-beat cycle.
var cadence_tick := 0


func _init(identifier: String, unit_role: StringName, initial_cell: Vector2i,
		maximum_hp: int, damage: int = 1) -> void:
	unit_id = identifier
	role = unit_role
	start_cell = initial_cell
	max_hp = maximum_hp
	attack_damage = damage
	reset()


func reset() -> void:
	cell = start_cell
	hp = max_hp
	alive = true
	facing = Vector2i.DOWN
	cadence_tick = 0
	clear_enemy_plan()


func clear_enemy_plan() -> void:
	enemy_plan = &"none"
	enemy_plan_target = Vector2i.ZERO
	enemy_plan_direction = Vector2i.DOWN


func take_damage(amount: int) -> int:
	var previous_hp := hp
	hp = maxi(0, hp - maxi(0, amount))
	alive = hp > 0
	return previous_hp - hp


func is_alive() -> bool:
	return alive and hp > 0
