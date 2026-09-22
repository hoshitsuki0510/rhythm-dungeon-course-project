class_name MvpRunState
extends RefCounted

const UnitScript = preload("res://scripts/mvp/mvp_unit.gd")
const MapDefinitionScript = preload("res://scripts/mvp/mvp_map_definition.gd")

# The generated room backgrounds share an 11x6 walkable floor made of 60px
# tiles.  The previous 8x5 subset stopped at the middle of the room, so a
# player could be blocked or sent through the exit while several visible floor
# tiles were still ahead.  Keep the logical board on the full painted floor;
# the separate right-wall portal remains the final traversal target.
const GRID_SIZE := Vector2i(11, 6)
const PLAYER_MAX_HP := 5
const BASE_BPM := 90.0
# Compatibility symbol retained for old callers. First-layer Boss pressure is
# room-specific and does not alter the global BPM.
const BOSS_PHASE_BPM := BASE_BPM
const CHARGE_BONUS_DAMAGE := 1
const RHYTHM_SHIELD_COMBO := 4
# The guard echo lowers the combo milestone provisionally to three.  The
# exact reduction remains a first-layer balance question, but its rule is now
# the one stated in the current design: it changes shield cadence rather than
# blocking an enemy hit.
const GUARD_RHYTHM_SHIELD_COMBO := 3
const RHYTHM_SHIELD_WINDOW := 0.20
const PIERCING_WAVE_RANGE := 2
const MUD_PROJECTILE_DAMAGE := 1
const MUD_HAZARD_DURATION := 2
const BOSS_CYCLE_BEATS := 4
const BOSS_FOOTPRINT_RADIUS := 1
const BOSS_SWEEP_RANGE := 3
# The regular Siphonling deliberately uses the same two-beat cadence for
# both chasing and attacking: beat one telegraphs a plan, beat two executes
# it. The first-layer Boss owns a separate four-beat room timeline below.
const REGULAR_ENEMY_BEATS_PER_ACTION := 2

const ROOM_START := 0
const ROOM_NORMAL := 1
const ROOM_REWARD := 2
const ROOM_HARD := 3
const ROOM_BOSS := 4
const ROOM_RESTORED := 5
const ECHO_ORDER: Array[StringName] = [&"tempo", &"guard", &"impact", &"vigor", &"pulse"]
const TOTAL_LAYERS := 4
const LAYER_ONE := 1
const LAYER_TWO := 2
const LAYER_THREE := 3
const LAYER_FOUR := 4

var layer_index := LAYER_ONE
var room_index := ROOM_START
var room_kind := ROOM_START
var map_definition
var room_title := ""
var room_subtitle := ""
var room_background_path := ""
var player: MvpUnitState
var enemies: Array[MvpUnitState] = []
var buffs: Dictionary = {"tempo": false, "guard": false, "impact": false, "vigor": false, "pulse": false}
var selected_echoes: Array[StringName] = []
var turn_number := 0
var combo := 0
var successful_actions := 0
var misses := 0
var charged := false
var rhythm_shield := false
var next_shield_combo := RHYTHM_SHIELD_COMBO
# Temporary debug aid for local gameplay verification. The controller exposes
# the toggle only in debug builds; normal runs keep this disabled.
var infinite_health_test_mode := false
## Legacy Corewarden phase fields kept for old smoke callers; first-layer
## Venous Glutton never mutates them and always reports the common BPM.
var boss_phase := 1
var boss_phase_shift_pending := false
var boss_cycle_beat := 0
var boss_sweep_direction := Vector2i.DOWN
var boss_kind: StringName = &"venous_glutton"
var boss_valve_state: StringName = &"red"
var boss_piston_axis: StringName = &"row"
var boss_piston_index := 2
var boss_charge_beat := 0
var boss_phase_shift_countdown := 0
var boss_conduits_destroyed := 0
var boss_invulnerable := false
var boss_telegraph_cells: Array[Vector2i] = []
var boss_stunned_beats := 0
var mud_hazards: Dictionary = {}
var mud_projectiles: Array[Dictionary] = []
var room_cleared := false
var run_finished := false


func _init() -> void:
	map_definition = MapDefinitionScript.new()
	player = UnitScript.new("player", &"player", Vector2i(1, 2), PLAYER_MAX_HP, 1)
	reset_run()


func reset_run() -> void:
	layer_index = LAYER_ONE
	room_index = ROOM_START
	turn_number = 0
	combo = 0
	successful_actions = 0
	misses = 0
	charged = false
	rhythm_shield = false
	next_shield_combo = RHYTHM_SHIELD_COMBO
	boss_phase = 1
	boss_phase_shift_pending = false
	boss_cycle_beat = 0
	boss_sweep_direction = Vector2i.DOWN
	boss_kind = &"venous_glutton"
	boss_valve_state = &"red"
	boss_piston_axis = &"row"
	boss_piston_index = 2
	boss_charge_beat = 0
	boss_phase_shift_countdown = 0
	boss_conduits_destroyed = 0
	boss_invulnerable = false
	boss_telegraph_cells.clear()
	boss_stunned_beats = 0
	mud_hazards.clear()
	mud_projectiles.clear()
	buffs = {"tempo": false, "guard": false, "impact": false, "vigor": false, "pulse": false}
	selected_echoes.clear()
	run_finished = false
	player.max_hp = PLAYER_MAX_HP
	player.hp = PLAYER_MAX_HP
	player.attack_damage = 1
	_enter_room(ROOM_START)


func enter_next_room() -> bool:
	if room_index >= ROOM_BOSS:
		return false
	_enter_room(room_index + 1)
	return true


func advance_layer() -> bool:
	# The central portal advances directly from one Boss room to the next
	# layer's preparation room. There is intentionally no empty elevator room.
	if room_kind != ROOM_BOSS or not room_cleared or layer_index >= TOTAL_LAYERS:
		return false
	layer_index += 1
	_enter_room(ROOM_START)
	return true


func enter_restored_room() -> void:
	_enter_room(ROOM_RESTORED)
	run_finished = true
	clear_transient_states()



func set_infinite_health_test_mode(enabled: bool) -> void:
	infinite_health_test_mode = enabled
	if enabled and player != null:
		player.hp = player.max_hp
		player.alive = true


func _take_player_damage(amount: int) -> int:
	if infinite_health_test_mode:
		if player != null:
			player.hp = player.max_hp
			player.alive = true
		return 0
	return player.take_damage(amount)


func consume_rhythm_shield() -> bool:
	if not rhythm_shield:
		return false
	rhythm_shield = false
	return true


func clear_transient_states() -> void:
	charged = false
	rhythm_shield = false


func finish_run() -> void:
	run_finished = true
	boss_phase_shift_pending = false
	clear_transient_states()
	buffs = {"tempo": false, "guard": false, "impact": false, "vigor": false, "pulse": false}
	selected_echoes.clear()
	player.attack_damage = 1


func get_reward_options() -> Array[StringName]:
	var options: Array[StringName] = []
	for echo_id in ECHO_ORDER:
		if not selected_echoes.has(echo_id):
			options.append(echo_id)
			if options.size() == 2:
				break
	return options


func get_echo_definition(echo_id: StringName) -> Dictionary:
	return {
		"tempo": {"label": "穿甲音波", "detail": "普通攻击延伸至前方两格"},
		"guard": {"label": "共鸣护盾", "detail": "3 次连续有效行动获得护盾"},
		"impact": {"label": "余震增幅", "detail": "蓄力攻击额外获得 1 点伤害"},
		"vigor": {"label": "心室扩容", "detail": "最大生命值 +1，并立即恢复 1 点"},
		"pulse": {"label": "回响修复", "detail": "进入新房间时恢复 1 点生命"},
	}.get(echo_id, {"label": "未知回响", "detail": "暂未配置"})


func choose_reward(choice: int) -> Dictionary:
	if room_kind != ROOM_REWARD:
		return {"accepted": false, "reason": "not_reward_room"}
	var options := get_reward_options()
	var option_index := choice - 1
	if option_index < 0 or option_index >= options.size():
		return {"accepted": false, "reason": "invalid_choice"}
	var echo_id: StringName = options[option_index]
	selected_echoes.append(echo_id)
	buffs[echo_id] = true
	match echo_id:
		&"guard":
			next_shield_combo = _shield_combo_requirement()
		&"vigor":
			player.max_hp += 1
			player.hp = mini(player.max_hp, player.hp + 1)
	return {"accepted": true, "buff": echo_id, "label": get_echo_definition(echo_id).label}


func resolve_turn(action_kind: StringName, direction: Vector2i = Vector2i.ZERO) -> Dictionary:
	var was_room_cleared := room_cleared
	var phase_was_pending := boss_phase_shift_pending
	turn_number += 1
	var player_result := _empty_action("wait")
	if action_kind == &"direction":
		player_result = _resolve_player_direction(direction)
	elif action_kind == &"charge":
		var was_charged := charged
		charged = true
		player_result = {
			"kind": "charge",
			"damage": 0,
			"from": player.cell,
			"to": player.cell,
			"direction": player.facing,
			"charge_gained": not was_charged,
		}
	elif action_kind == &"wait":
		player_result = _empty_action("wait")
	else:
		player_result = _empty_action("miss")

	var enemy_results: Array[Dictionary] = []
	var environment_results: Array[Dictionary] = []
	var shield_gained := false
	var shield_combo_step := _shield_combo_requirement()
	if player_result.kind == "move" or player_result.kind == "attack" or player_result.kind == "charge" or player_result.kind == "clash":
		successful_actions += 1
		combo += 1
		if combo >= next_shield_combo:
			if not rhythm_shield:
				rhythm_shield = true
				shield_gained = true
				next_shield_combo += shield_combo_step
	else:
		combo = 0
		next_shield_combo = shield_combo_step
		if player_result.kind == "miss":
			misses += 1

	if not _has_living_enemies():
		if room_kind == ROOM_NORMAL or room_kind == ROOM_HARD or room_kind == ROOM_BOSS:
			room_cleared = true
		if room_cleared:
			charged = false
			if room_kind == ROOM_BOSS:
				boss_phase_shift_pending = false
		return _make_turn_result(player_result, enemy_results, environment_results, shield_gained, room_cleared and not was_room_cleared)

	# Existing mud bullets advance once per beat before the newly scheduled
	# enemy actions. A projectile that reaches the player becomes a short-lived
	# hazard and deals one point of damage.
	environment_results.append_array(_advance_mud_projectiles())

	var phase_shift_just_started := boss_phase_shift_pending and not phase_was_pending
	if phase_shift_just_started:
		enemy_results.append({"kind":"defibrillation", "enemy_id":"boss", "damage":0, "countdown":boss_phase_shift_countdown, "phase":"warning", "four_beat":true})
		return _make_turn_result(player_result, enemy_results, environment_results, shield_gained, room_cleared and not was_room_cleared)

	var clashed_enemy_id := String(player_result.get("target_id", "")) if player_result.kind == "clash" else ""
	for enemy in enemies:
		if not enemy.is_alive():
			continue
		if enemy.unit_id == clashed_enemy_id:
			enemy_results.append(_resolve_clashed_enemy(enemy))
			continue
		var enemy_result: Dictionary = _resolve_enemy_action(enemy)
		enemy_results.append(enemy_result)
		if not player.is_alive():
			break

	return _make_turn_result(player_result, enemy_results, environment_results, shield_gained, room_cleared and not was_room_cleared)


func apply_boss_phase_shift() -> bool:
	if layer_index != LAYER_FOUR or not boss_phase_shift_pending or boss_phase_shift_countdown > 0:
		return false
	boss_phase = 2
	boss_phase_shift_pending = false
	boss_invulnerable = false
	return true


func get_bpm() -> float:
	if layer_index == LAYER_FOUR and boss_phase == 2:
		return 140.0
	return 105.0 if layer_index == LAYER_FOUR and room_kind == ROOM_BOSS else BASE_BPM


func get_room_label() -> String:
	if room_kind == ROOM_RESTORED:
		return "%dF · CLEAR" % layer_index
	return "%dF · %02d / 05" % [layer_index, mini(room_index + 1, 5)]


func is_combat_room() -> bool:
	return room_kind == ROOM_NORMAL or room_kind == ROOM_HARD or room_kind == ROOM_BOSS


func can_leave_room() -> bool:
	if room_kind == ROOM_START or room_kind == ROOM_REWARD:
		return true
	return room_cleared


func is_at_exit() -> bool:
	return player.cell.x >= map_definition.grid_size.x - 1


func is_near_next_layer_portal() -> bool:
	# The boss-room portal is centered between the four middle tiles of the
	# 11x6 board. Allow the four adjacent center tiles plus their immediate
	# cardinal approach tiles so the player can reach it naturally.
	if room_kind != ROOM_BOSS or not room_cleared or run_finished:
		return false
	var board_center := Vector2(map_definition.grid_size) * 0.5
	var center_distance := absf(float(player.cell.x) - board_center.x) + absf(float(player.cell.y) - board_center.y)
	# The central portal is a large visual object, and even-sized boards place it
	# between cells. Allow the adjacent approach cells so pressing E at the
	# portal edge is reliable on every upper-layer map.
	return center_distance <= 2.5


func enemy_intent(enemy: MvpUnitState) -> StringName:
	if enemy == null or not enemy.is_alive():
		return &"none"
	# Once a regular enemy has committed to a plan, expose that plan instead of
	# recomputing intent from the player's new position.  This keeps the HUD and
	# telegraph faithful to the action the player can actually dodge.
	if enemy.role == &"enemy" and enemy.enemy_plan != &"none":
		return enemy.enemy_plan
	if enemy.role == &"slug":
		return &"mud" if enemy.cadence_tick >= 3 else &"hold"
	if enemy.role == &"boss":
		if enemy.enemy_plan != &"none":
			return enemy.enemy_plan
		match boss_kind:
			&"piston_colossus":
				return &"piston"
			&"oxygen_reservoir":
				return &"charge"
			&"arrhythmia":
				return &"spikes" if boss_phase == 1 else &"noise_burst"
			_:
				match boss_cycle_beat:
					0:
						return &"mud"
					1, 2:
						return &"sweep"
					3:
						return &"recovery"
	var distance := _manhattan(enemy.cell, player.cell)
	if distance == 1:
		return &"attack"
	return &"move"


func get_primary_enemy() -> MvpUnitState:
	for enemy in enemies:
		if enemy.is_alive():
			return enemy
	return null


func get_boss() -> MvpUnitState:
	for enemy in enemies:
		if enemy.role == &"boss":
			return enemy
	return null


func get_boss_display_name() -> String:
	return {
		1: "静脉吸附者·泥鳃",
		2: "失衡阀卫·活塞巨像",
		3: "充盈巨母·血脉核心",
		4: "杂音支配者·律畸",
	}.get(layer_index, "Boss")


func get_chamber_display_name() -> String:
	return {
		1: "右心房",
		2: "右心室",
		3: "左心房",
		4: "左心室",
	}.get(layer_index, "心腔")


func _layer_background_path() -> String:
	return {
		LAYER_TWO: "res://assets/backgrounds/room_right_ventricle.png",
		LAYER_THREE: "res://assets/backgrounds/room_left_atrium.png",
		LAYER_FOUR: "res://assets/backgrounds/room_left_ventricle.png",
	}.get(layer_index, "res://assets/backgrounds/heartcore_forest_room.png")


func _enter_room(index: int) -> void:
	var carried_hp := player.hp
	map_definition.configure_for_layer(layer_index)
	room_index = index
	room_kind = index
	room_cleared = false
	boss_phase = 1
	boss_phase_shift_pending = false
	boss_cycle_beat = 0
	boss_sweep_direction = Vector2i.DOWN
	boss_valve_state = &"red"
	boss_piston_axis = &"row"
	boss_piston_index = 2
	boss_charge_beat = 0
	boss_phase_shift_countdown = 0
	boss_conduits_destroyed = 0
	boss_invulnerable = false
	boss_telegraph_cells.clear()
	boss_stunned_beats = 0
	mud_hazards.clear()
	mud_projectiles.clear()
	charged = false
	enemies.clear()
	match index:
		ROOM_START:
			room_title = _layer_room_title("整备前厅")
			room_subtitle = "起始整备房 · 校准本层的第一拍"
			room_background_path = "res://assets/backgrounds/heartcore_forest_room.png"
			player.start_cell = Vector2i(1, 2)
			player.hp = player.max_hp
			player.attack_damage = 1
		ROOM_NORMAL:
			room_title = _layer_room_title("常规战斗房")
			room_subtitle = _layer_subtitle("两拍行动教学")
			room_background_path = "res://assets/backgrounds/heartcore_forest_room.png"
			player.start_cell = Vector2i(1, 2)
			if layer_index == LAYER_TWO:
				enemies.append(UnitScript.new("gear_stalker_1", &"enemy", Vector2i(7, 1), 3, 1))
				enemies.append(UnitScript.new("gear_stalker_2", &"enemy", Vector2i(7, 3), 3, 1))
			elif layer_index == LAYER_THREE:
				enemies.append(UnitScript.new("spore_pod_1", &"slug", Vector2i(7, 1), 3, 1))
				enemies.append(UnitScript.new("vigor_sentinel_1", &"enemy", Vector2i(7, 3), 4, 1))
			elif layer_index == LAYER_FOUR:
				enemies.append(UnitScript.new("noise_scuttler_1", &"enemy", Vector2i(7, 1), 3, 1))
				enemies.append(UnitScript.new("arrhythmic_phantom_1", &"enemy", Vector2i(7, 3), 3, 1))
			else:
				enemies.append(UnitScript.new("leech_crawler_1", &"enemy", Vector2i(9, 2), 3, 1))
		ROOM_REWARD:
			room_title = _layer_room_title("回响祭坛")
			room_subtitle = "回响奖励房 · 选择一枚局内强化"
			room_background_path = "res://assets/backgrounds/room_reward.png"
			player.start_cell = Vector2i(1, 2)
		ROOM_HARD:
			room_title = _layer_room_title("较难战斗房")
			room_subtitle = _layer_subtitle("混合阻击 · 先读预警再走位")
			room_background_path = "res://assets/backgrounds/room_hard.png"
			player.start_cell = Vector2i(1, 2)
			if layer_index == LAYER_TWO:
				enemies.append(UnitScript.new("gear_stalker_1", &"enemy", Vector2i(7, 1), 3, 1))
				enemies.append(UnitScript.new("steam_vent_1", &"slug", Vector2i(5, 3), 4, 1))
				enemies.append(UnitScript.new("gear_stalker_2", &"enemy", Vector2i(7, 2), 3, 1))
			elif layer_index == LAYER_THREE:
				enemies.append(UnitScript.new("spore_pod_1", &"slug", Vector2i(7, 1), 3, 1))
				enemies.append(UnitScript.new("vigor_sentinel_1", &"enemy", Vector2i(5, 3), 4, 1))
				enemies.append(UnitScript.new("spore_pod_2", &"slug", Vector2i(7, 2), 3, 1))
			elif layer_index == LAYER_FOUR:
				enemies.append(UnitScript.new("noise_scuttler_1", &"enemy", Vector2i(7, 1), 3, 1))
				enemies.append(UnitScript.new("arrhythmic_phantom_1", &"enemy", Vector2i(6, 4), 3, 1))
				enemies.append(UnitScript.new("noise_scuttler_2", &"enemy", Vector2i(7, 2), 3, 1))
			else:
				enemies.append(UnitScript.new("leech_crawler_1", &"enemy", Vector2i(9, 1), 3, 1))
				enemies.append(UnitScript.new("spit_slug_1", &"slug", Vector2i(8, 4), 3, 1))
		ROOM_BOSS:
			room_title = _layer_boss_title()
			room_subtitle = _layer_boss_subtitle()
			room_background_path = "res://assets/backgrounds/room_boss.png"
			player.start_cell = Vector2i(1, 2)
			if layer_index == LAYER_TWO:
				boss_kind = &"piston_colossus"
				enemies.append(UnitScript.new("boss", &"boss", Vector2i(4, 2), 8, 1))
			elif layer_index == LAYER_THREE:
				boss_kind = &"oxygen_reservoir"
				enemies.append(UnitScript.new("boss", &"boss", Vector2i(5, 2), 8, 1))
			elif layer_index == LAYER_FOUR:
				boss_kind = &"arrhythmia"
				enemies.append(UnitScript.new("boss", &"boss", Vector2i(4, 2), 10, 1))
			else:
				boss_kind = &"venous_glutton"
				enemies.append(UnitScript.new("boss", &"boss", Vector2i(5, 2), 6, 1))
		ROOM_RESTORED:
			room_title = "%dF · 心核复苏" % layer_index
			room_subtitle = "最终复苏流程"
			room_background_path = "res://assets/backgrounds/room_restored.png"
			player.start_cell = Vector2i(3, 2)
			room_cleared = true
	# Each upper layer now uses its generated shared map for every playable room.
	# The separate restored ending keeps its dedicated first-layer ending art.
	if layer_index > LAYER_ONE and index != ROOM_RESTORED:
		room_background_path = _layer_background_path()
	player.reset()
	if index == ROOM_START or index == ROOM_RESTORED or index == ROOM_BOSS:
		player.hp = player.max_hp
	else:
		player.hp = clampi(carried_hp, 1, player.max_hp)
	if index != ROOM_START and index != ROOM_RESTORED and bool(buffs.get("pulse", false)):
		player.hp = mini(player.max_hp, player.hp + 1)
	turn_number = 0
	combo = 0
	next_shield_combo = _shield_combo_requirement()


func _layer_room_title(suffix: String) -> String:
	var names := {1: "右心房", 2: "右心室", 3: "左心房", 4: "左心室"}
	return "%s · %s" % [names.get(layer_index, "心腔"), suffix]


func _layer_subtitle(suffix: String) -> String:
	return "%dF · %s" % [layer_index, suffix]


func _layer_boss_title() -> String:
	var names := {1: "静脉吸附者·泥鳃", 2: "失衡阀卫·活塞巨像", 3: "充盈巨母·血脉核心", 4: "杂音支配者·律畸"}
	return "%s · %s" % [_layer_room_title("核心"), names.get(layer_index, "Boss")]


func _layer_boss_subtitle() -> String:
	var details := {1: "3×3 巨体 · 血沉泥浆与三格扇扫", 2: "红蓝瓣膜 · 行列冲压预警", 3: "四拍喷流充能 · 可被打断", 4: "105 BPM → 140 BPM · 除颤换相"}
	return "%dF Boss 房 · %s" % [layer_index, details.get(layer_index, "特殊节律")]


func _resolve_player_direction(direction: Vector2i) -> Dictionary:
	if direction == Vector2i.ZERO:
		return _empty_action("blocked")
	player.facing = direction
	var target := player.cell + direction
	if not _is_inside(target):
		return _empty_action("blocked")
	var target_enemy: MvpUnitState = _enemy_at(target)
	if target_enemy == null and bool(buffs.get("tempo", false)):
		# The piercing echo extends a normal direction attack through one empty
		# cell.  The player stays on the origin cell; only the logical target
		# becomes two cells away so movement and presentation remain decoupled.
		var ranged_target := player.cell + direction * PIERCING_WAVE_RANGE
		if _is_inside(ranged_target):
			target_enemy = _enemy_at(ranged_target)
			if target_enemy != null:
				target = ranged_target
	if target_enemy != null:
		# A regular enemy that already raised its weapon is committed to an
		# attack on this exact cell. Meeting that execution beat with an attack
		# produces a weapon clash: neither side deals damage and the enemy plan
		# is consumed below instead of passing both attacks through each other.
		if (
			target_enemy.role == &"enemy"
			and target_enemy.enemy_plan == &"attack"
			and target_enemy.enemy_plan_target == player.cell
			and _manhattan(target_enemy.cell, player.cell) == 1
		):
			return {
				"kind": "clash",
				"damage": 0,
				"from": player.cell,
				"to": target_enemy.cell,
				"target_id": target_enemy.unit_id,
				"direction": direction,
				"charged_attack": false,
				"charge_retained": charged,
			}
		if target_enemy.role == &"boss" and layer_index == LAYER_THREE and boss_charge_beat > 0:
			var interrupted_damage := target_enemy.take_damage(player.attack_damage + (CHARGE_BONUS_DAMAGE if charged else 0))
			boss_charge_beat = 0
			boss_stunned_beats = 1
			target_enemy.clear_enemy_plan()
			charged = false
			return {
				"kind": "attack",
				"damage": interrupted_damage,
				"requested_damage": interrupted_damage,
				"charged_attack": false,
				"from": player.cell,
				"to": target_enemy.cell,
				"contact_cell": target,
				"target_id": target_enemy.unit_id,
				"direction": direction,
				"interrupted": true,
				"killed": not target_enemy.is_alive(),
			}
		var charged_attack := charged
		var requested_damage := player.attack_damage + (CHARGE_BONUS_DAMAGE if charged_attack else 0) + (1 if charged_attack and bool(buffs.get("impact", false)) else 0)
		var damage := 0 if (target_enemy.role == &"boss" and boss_invulnerable) else target_enemy.take_damage(requested_damage)
		if target_enemy.role == &"boss" and layer_index == LAYER_FOUR and boss_phase == 1 and target_enemy.hp <= int(target_enemy.max_hp / 2) and not boss_phase_shift_pending:
			boss_phase_shift_pending = true
			boss_phase_shift_countdown = 4
			boss_invulnerable = true
		if charged_attack:
			charged = false
		return {
			"kind": "attack",
			"damage": damage,
			"requested_damage": requested_damage,
			"charged_attack": charged_attack,
			"charge_bonus": CHARGE_BONUS_DAMAGE + (1 if bool(buffs.get("impact", false)) else 0) if charged_attack else 0,
			"from": player.cell,
			"to": target_enemy.cell,
			"contact_cell": target,
			"target_id": target_enemy.unit_id,
			"direction": direction,
			"killed": not target_enemy.is_alive(),
		}
	if _occupied_by_enemy(target):
		return _empty_action("blocked")
	var previous := player.cell
	player.cell = target
	var mud_damage := 0
	if _is_mud_hazard(target):
		mud_damage = MUD_PROJECTILE_DAMAGE
		_take_player_damage(mud_damage)
	return {
		"kind": "move",
		"damage": mud_damage,
		"from": previous,
		"to": target,
		"direction": direction,
		"hazard": mud_damage > 0,
	}


func _resolve_clashed_enemy(enemy: MvpUnitState) -> Dictionary:
	var planned_direction := enemy.enemy_plan_direction
	var planned_target := enemy.enemy_plan_target
	enemy.facing = planned_direction
	enemy.clear_enemy_plan()
	return {
		"kind": "parried",
		"enemy_id": enemy.unit_id,
		"damage": 0,
		"from": enemy.cell,
		"to": planned_target,
		"direction": planned_direction,
		"intent": "attack",
		"planned_action": "attack",
		"phase": "execute",
		"two_beat": true,
		"parried": true,
		"cancelled": true,
		"reason": "weapon_clash",
	}


func _resolve_enemy_action(enemy: MvpUnitState) -> Dictionary:
	if enemy.role == &"slug":
		return _resolve_slug_action(enemy)
	if enemy.role == &"enemy":
		return _resolve_regular_enemy_action(enemy)
	return _resolve_boss_action(enemy)


func _resolve_slug_action(slug: MvpUnitState) -> Dictionary:
	# The slug is a stationary four-beat turret. Beat three telegraphs a
	# cardinal shot; beat four creates a projectile one cell in front of it.
	if slug.enemy_plan == &"mud":
		var direction := slug.enemy_plan_direction
		var spawn_cell := slug.cell + direction
		slug.clear_enemy_plan()
		slug.cadence_tick = 0
		var spawned := _is_inside(spawn_cell)
		var hit := spawned and player.is_alive() and player.cell == spawn_cell
		if spawned:
			if hit:
				_take_player_damage(MUD_PROJECTILE_DAMAGE)
				_add_mud_hazard(spawn_cell, MUD_HAZARD_DURATION)
			else:
				# The projectile remains active until it reaches the room edge.  The
				# ttl field is retained for old callers, but no longer truncates a
				# cardinal shot before it has crossed the board.
				mud_projectiles.append({"cell": spawn_cell, "direction": direction, "ttl": map_definition.grid_size.x + map_definition.grid_size.y})
		return {
			"kind": "mud_fire",
			"enemy_id": slug.unit_id,
			"from": slug.cell,
			"to": spawn_cell,
			"direction": direction,
			"planned_action": "mud",
			"phase": "execute",
			"spawned": spawned,
			"hit": hit,
			"killed": not player.is_alive() if hit else false,
			"damage": MUD_PROJECTILE_DAMAGE if hit else 0,
		}

	slug.cadence_tick += 1
	if slug.cadence_tick >= 3:
		var direction := _direction_towards(slug.cell, player.cell)
		slug.enemy_plan = &"mud"
		slug.enemy_plan_target = slug.cell + direction
		slug.enemy_plan_direction = direction
		return {
			"kind": "mud_windup",
			"enemy_id": slug.unit_id,
			"damage": 0,
			"from": slug.cell,
			"to": slug.enemy_plan_target,
			"direction": direction,
			"intent": "mud",
			"planned_action": "mud",
			"phase": "windup",
			"beats_remaining": 1,
			"four_beat": true,
		}
	return {
		"kind": "hold",
		"enemy_id": slug.unit_id,
		"damage": 0,
		"from": slug.cell,
		"to": slug.cell,
		"direction": slug.facing,
		"intent": "hold",
		"planned_action": "hold",
		"phase": "idle",
		"four_beat": true,
	}


func _resolve_regular_enemy_action(enemy: MvpUnitState) -> Dictionary:
	# A plan is consumed on the following beat.  It is intentionally not
	# recomputed here: the player gets a real opportunity to step away from a
	# telegraphed attack or to redirect the enemy's already-committed step.
	if enemy.enemy_plan != &"none":
		var plan := enemy.enemy_plan
		var planned_target := enemy.enemy_plan_target
		var planned_direction := enemy.enemy_plan_direction
		enemy.clear_enemy_plan()
		if plan == &"attack":
			enemy.facing = planned_direction
			var target_still_there := player.is_alive() and player.cell == planned_target
			var target_in_range := _manhattan(enemy.cell, player.cell) == 1
			if not target_still_there or not target_in_range:
				return {
					"kind": "none",
					"enemy_id": enemy.unit_id,
					"damage": 0,
					"from": enemy.cell,
					"to": planned_target,
					"direction": planned_direction,
					"intent": "attack",
					"planned_action": "attack",
					"phase": "execute",
					"two_beat": true,
					"cancelled": true,
					"reason": "target_moved",
				}
			var damage := enemy.attack_damage
			_take_player_damage(damage)
			return {
				"kind": "attack",
				"enemy_id": enemy.unit_id,
				"damage": damage,
				"from": enemy.cell,
				"to": player.cell,
				"direction": enemy.facing,
				"shielded": false,
				"killed": not player.is_alive(),
				"intent": "attack",
				"planned_action": "attack",
				"phase": "execute",
				"two_beat": true,
			}

		if plan == &"move":
			var previous := enemy.cell
			var valid_target := (
				_is_inside(planned_target)
				and planned_target != previous
				and planned_target != player.cell
				and _manhattan(previous, planned_target) == 1
				and not _occupied_by_enemy(planned_target, enemy)
			)
			if valid_target:
				enemy.cell = planned_target
				enemy.facing = planned_direction
			return {
				"kind": "move" if enemy.cell != previous else "none",
				"enemy_id": enemy.unit_id,
				"damage": 0,
				"from": previous,
				"to": enemy.cell,
				"direction": planned_direction,
				"intent": "move",
				"planned_action": "move",
				"phase": "execute",
				"two_beat": true,
				"cancelled": enemy.cell == previous,
				"reason": "blocked" if enemy.cell == previous else "",
			}

	# No pending plan: spend this beat telegraphing the next action.
	var distance := _manhattan(enemy.cell, player.cell)
	if distance == 1:
		enemy.facing = _direction_towards(enemy.cell, player.cell)
		enemy.enemy_plan = &"attack"
		enemy.enemy_plan_target = player.cell
		enemy.enemy_plan_direction = enemy.facing
		return _regular_enemy_windup(enemy, &"attack", player.cell, enemy.facing)

	var delta := player.cell - enemy.cell
	var step := _chase_step(delta)
	enemy.facing = step if step != Vector2i.ZERO else enemy.facing
	enemy.enemy_plan = &"move"
	enemy.enemy_plan_target = enemy.cell + step
	enemy.enemy_plan_direction = enemy.facing
	return _regular_enemy_windup(enemy, &"move", enemy.enemy_plan_target, enemy.facing)


func _regular_enemy_windup(enemy: MvpUnitState, plan: StringName, target: Vector2i, direction: Vector2i) -> Dictionary:
	return {
		"kind": "windup",
		"enemy_id": enemy.unit_id,
		"damage": 0,
		"from": enemy.cell,
		"to": target,
		"direction": direction,
		"intent": plan,
		"planned_action": plan,
		"phase": "windup",
		"beats_remaining": REGULAR_ENEMY_BEATS_PER_ACTION - 1,
		"two_beat": true,
	}


func _resolve_boss_action(enemy: MvpUnitState) -> Dictionary:
	if layer_index == LAYER_TWO:
		return _resolve_piston_boss(enemy)
	if layer_index == LAYER_THREE:
		return _resolve_oxygen_boss(enemy)
	if layer_index == LAYER_FOUR:
		return _resolve_arrhythmia_boss(enemy)
	return _resolve_venous_glutton(enemy)


func _resolve_piston_boss(enemy: MvpUnitState) -> Dictionary:
	if enemy.enemy_plan == &"piston":
		var cells := _line_cells(boss_piston_axis, boss_piston_index)
		boss_telegraph_cells = cells
		enemy.clear_enemy_plan()
		var hit := cells.has(player.cell)
		if hit:
			_take_player_damage(enemy.attack_damage)
		return {"kind":"piston_strike", "enemy_id":enemy.unit_id, "damage":enemy.attack_damage if hit else 0, "hit":hit, "axis":boss_piston_axis, "index":boss_piston_index, "cells":cells, "phase":"execute", "planned_action":"piston"}
	boss_valve_state = "blue" if boss_valve_state == &"red" else "red"
	boss_piston_axis = &"row" if boss_cycle_beat % 2 == 0 else &"column"
	boss_piston_index = player.cell.y if boss_piston_axis == &"row" else player.cell.x
	boss_telegraph_cells = _line_cells(boss_piston_axis, boss_piston_index)
	enemy.enemy_plan = &"piston"
	boss_cycle_beat = (boss_cycle_beat + 1) % 4
	return {"kind":"piston_windup", "enemy_id":enemy.unit_id, "damage":0, "axis":boss_piston_axis, "index":boss_piston_index, "cells":_line_cells(boss_piston_axis, boss_piston_index), "valve_state":boss_valve_state, "phase":"windup", "planned_action":"piston"}


func _resolve_oxygen_boss(enemy: MvpUnitState) -> Dictionary:
	if boss_stunned_beats > 0:
		boss_stunned_beats -= 1
		return {"kind":"oxygen_stagger", "enemy_id":enemy.unit_id, "damage":0, "phase":"stagger", "planned_action":"stagger"}
	if boss_charge_beat > 0:
		if boss_charge_beat >= 4:
			boss_charge_beat = 0
			enemy.clear_enemy_plan()
			boss_telegraph_cells = _all_board_cells()
			var hit := _all_board_cells().has(player.cell)
			if hit:
				_take_player_damage(enemy.attack_damage)
			return {"kind":"oxygen_blast", "enemy_id":enemy.unit_id, "damage":enemy.attack_damage if hit else 0, "hit":hit, "cells":_all_board_cells(), "phase":"execute", "planned_action":"blast"}
		boss_charge_beat += 1
		boss_telegraph_cells = _all_board_cells()
		enemy.enemy_plan = &"charge"
		return {"kind":"oxygen_charge", "enemy_id":enemy.unit_id, "damage":0, "charge_beat":boss_charge_beat, "phase":"charge", "planned_action":"charge", "interruptible":true}
	boss_charge_beat = 1
	boss_telegraph_cells = _all_board_cells()
	enemy.enemy_plan = &"charge"
	return {"kind":"oxygen_charge", "enemy_id":enemy.unit_id, "damage":0, "charge_beat":boss_charge_beat, "phase":"charge", "planned_action":"charge", "interruptible":true}


func _resolve_arrhythmia_boss(enemy: MvpUnitState) -> Dictionary:
	if boss_phase_shift_pending:
		boss_phase_shift_countdown -= 1
		if boss_phase_shift_countdown <= 0:
			apply_boss_phase_shift()
			return {"kind":"phase_shift", "enemy_id":enemy.unit_id, "damage":0, "phase":2, "four_beat":true}
		return {"kind":"defibrillation", "enemy_id":enemy.unit_id, "damage":0, "countdown":boss_phase_shift_countdown, "phase":"warning", "four_beat":true}
	if boss_phase == 1:
		var direction := _direction_towards(enemy.cell, player.cell)
		var cells := _line_cells("row" if direction.x != 0 else "column", player.cell.y if direction.x != 0 else player.cell.x)
		boss_telegraph_cells = cells
		return {"kind":"spike_windup", "enemy_id":enemy.unit_id, "damage":0, "direction":direction, "cells":cells, "phase":1, "planned_action":"spikes"}
	var directions := [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT]
	var cells2: Array[Vector2i] = []
	for direction2 in directions:
		cells2.append_array(_ray_cells(enemy.cell, direction2, 4))
	boss_telegraph_cells = cells2
	var hit := cells2.has(player.cell)
	if hit:
		_take_player_damage(enemy.attack_damage)
	return {"kind":"noise_burst", "enemy_id":enemy.unit_id, "damage":enemy.attack_damage if hit else 0, "hit":hit, "cells":cells2, "phase":2, "planned_action":"noise_burst"}


func _resolve_venous_glutton(enemy: MvpUnitState) -> Dictionary:
	var cycle := boss_cycle_beat
	boss_cycle_beat = (boss_cycle_beat + 1) % BOSS_CYCLE_BEATS
	match cycle:
		0:
			boss_telegraph_cells.clear()
			var spawned_cells: Array[Vector2i] = []
			for offset: Vector2i in [Vector2i(-2, 0), Vector2i(2, 0), Vector2i(0, -2), Vector2i(0, 2)]:
				var hazard_cell: Vector2i = enemy.cell + offset
				if _is_inside(hazard_cell) and hazard_cell != player.cell:
					_add_mud_hazard(hazard_cell, MUD_HAZARD_DURATION)
					spawned_cells.append(hazard_cell)
			return {"kind":"mud_summon", "enemy_id":enemy.unit_id, "damage":0, "from":enemy.cell, "to":enemy.cell, "hazard_cells":spawned_cells, "intent":"mud", "planned_action":"mud", "phase":"telegraph", "four_beat":true}
		1:
			boss_telegraph_cells = get_boss_sweep_cells(enemy, _direction_towards(enemy.cell, player.cell))
			boss_sweep_direction = _direction_towards(enemy.cell, player.cell)
			enemy.facing = boss_sweep_direction
			enemy.enemy_plan = &"sweep"
			return {"kind":"sweep_windup", "enemy_id":enemy.unit_id, "damage":0, "from":enemy.cell, "to":player.cell, "direction":boss_sweep_direction, "sweep_cells":get_boss_sweep_cells(enemy, boss_sweep_direction), "sweep_range":BOSS_SWEEP_RANGE, "intent":"sweep", "planned_action":"sweep", "phase":"windup", "four_beat":true}
		2:
			var sweep_direction := boss_sweep_direction
			enemy.clear_enemy_plan()
			var sweep_cells := get_boss_sweep_cells(enemy, sweep_direction)
			boss_telegraph_cells = sweep_cells
			var sweep_hit := sweep_cells.has(player.cell)
			if sweep_hit:
				_take_player_damage(enemy.attack_damage)
			return {"kind":"sweep", "enemy_id":enemy.unit_id, "damage":enemy.attack_damage if sweep_hit else 0, "from":enemy.cell, "to":player.cell, "direction":sweep_direction, "sweep_cells":sweep_cells, "sweep_range":BOSS_SWEEP_RANGE, "hit":sweep_hit, "killed":not player.is_alive(), "intent":"sweep", "planned_action":"sweep", "phase":"execute", "four_beat":true}
		_:
			boss_telegraph_cells.clear()
			enemy.clear_enemy_plan()
			return {"kind":"recovery", "enemy_id":enemy.unit_id, "damage":0, "from":enemy.cell, "to":enemy.cell, "direction":enemy.facing, "intent":"recovery", "planned_action":"recovery", "phase":"recovery", "four_beat":true}


func _line_cells(axis: StringName, index: int) -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	if axis == &"row":
		for x in range(map_definition.grid_size.x): cells.append(Vector2i(x, index))
	else:
		for y in range(map_definition.grid_size.y): cells.append(Vector2i(index, y))
	return cells


func _ray_cells(origin: Vector2i, direction: Vector2i, length: int) -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	for step in range(1, length + 1):
		var cell := origin + direction * step
		if _is_inside(cell): cells.append(cell)
	return cells


func _all_board_cells() -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	for y in range(map_definition.grid_size.y):
		for x in range(map_definition.grid_size.x): cells.append(Vector2i(x, y))
	return cells


func _advance_mud_projectiles() -> Array[Dictionary]:
	var results: Array[Dictionary] = []
	for cell in mud_hazards.keys():
		if int(mud_hazards[cell]) < turn_number:
			mud_hazards.erase(cell)
	var remaining: Array[Dictionary] = []
	for projectile in mud_projectiles:
		var current_cell: Vector2i = projectile.get("cell", Vector2i.ZERO)
		var direction: Vector2i = projectile.get("direction", Vector2i.RIGHT)
		var next_cell := current_cell + direction
		var ttl := int(projectile.get("ttl", map_definition.grid_size.x + map_definition.grid_size.y)) - 1
		if not _is_inside(next_cell):
			continue
		projectile["cell"] = next_cell
		projectile["ttl"] = ttl
		_add_mud_hazard(next_cell, MUD_HAZARD_DURATION)
		if player.is_alive() and player.cell == next_cell:
			_take_player_damage(MUD_PROJECTILE_DAMAGE)
			results.append({
				"kind": "mud_hit",
				"cell": next_cell,
				"damage": MUD_PROJECTILE_DAMAGE,
				"killed": not player.is_alive(),
			})
			continue
		remaining.append(projectile)
	mud_projectiles = remaining
	return results


func _add_mud_hazard(cell: Vector2i, duration: int) -> void:
	if not _is_inside(cell):
		return
	mud_hazards[cell] = maxi(int(mud_hazards.get(cell, 0)), turn_number + duration)


func _is_mud_hazard(cell: Vector2i) -> bool:
	return mud_hazards.has(cell) and int(mud_hazards[cell]) >= turn_number


func get_boss_footprint_cells(boss: MvpUnitState = null) -> Array[Vector2i]:
	var current_boss := boss if boss != null else get_boss()
	var cells: Array[Vector2i] = []
	if current_boss == null:
		return cells
	for y in range(-BOSS_FOOTPRINT_RADIUS, BOSS_FOOTPRINT_RADIUS + 1):
		for x in range(-BOSS_FOOTPRINT_RADIUS, BOSS_FOOTPRINT_RADIUS + 1):
			var cell := current_boss.cell + Vector2i(x, y)
			if _is_inside(cell):
				cells.append(cell)
	return cells


func get_boss_sweep_cells(boss: MvpUnitState, direction: Vector2i) -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	if boss == null or direction == Vector2i.ZERO:
		return cells
	var forward := direction
	var side := Vector2i(-forward.y, forward.x)
	# The sweep begins outside the 3x3 body. It reaches three cells from that
	# edge: one cell at the tip, then a three-cell-wide fan for the final two
	# rows. Returning the actual cells keeps combat and the visual telegraph on
	# one authoritative definition.
	for depth in range(1, BOSS_SWEEP_RANGE + 1):
		var lateral_limit := 0 if depth == 1 else BOSS_FOOTPRINT_RADIUS
		for lateral in range(-lateral_limit, lateral_limit + 1):
			var cell := boss.cell + forward * (BOSS_FOOTPRINT_RADIUS + depth) + side * lateral
			if _is_inside(cell):
				cells.append(cell)
	return cells


func _empty_action(kind: String) -> Dictionary:
	return {
		"kind": kind,
		"damage": 0,
		"from": player.cell,
		"to": player.cell,
		"direction": Vector2i.ZERO,
	}


func _make_turn_result(
	player_result: Dictionary,
	enemy_results: Array[Dictionary],
	environment_results: Array[Dictionary],
	shield_gained: bool,
	room_cleared_now: bool
) -> Dictionary:
	return {
		"player": player_result,
		"enemies": enemy_results,
		"environment": environment_results,
		# This field is an event, not the persistent room state. It is true only
		# on the exact turn that kills the last enemy, so clear feedback cannot
		# replay on every step toward an already-open exit.
		"room_cleared": room_cleared_now,
		"player_defeated": not player.is_alive(),
		"turn_number": turn_number,
		"phase_shift_pending": boss_phase_shift_pending,
		"shield_gained": shield_gained,
		"layer": layer_index,
		"boss_phase": boss_phase,
		"boss_kind": boss_kind,
	}


func _enemy_at(cell: Vector2i) -> MvpUnitState:
	for enemy in enemies:
		if enemy.is_alive() and _enemy_occupies_cell(enemy, cell):
			return enemy
	return null


func _occupied_by_enemy(cell: Vector2i, ignored: MvpUnitState = null) -> bool:
	for enemy in enemies:
		if enemy != ignored and enemy.is_alive() and _enemy_occupies_cell(enemy, cell):
			return true
	return false


func _enemy_occupies_cell(enemy: MvpUnitState, cell: Vector2i) -> bool:
	if enemy.role == &"boss":
		return (
			absi(enemy.cell.x - cell.x) <= BOSS_FOOTPRINT_RADIUS
			and absi(enemy.cell.y - cell.y) <= BOSS_FOOTPRINT_RADIUS
		)
	return enemy.cell == cell


func _find_enemy(identifier: String) -> MvpUnitState:
	for enemy in enemies:
		if enemy.unit_id == identifier:
			return enemy
	return null


func _has_living_enemies() -> bool:
	for enemy in enemies:
		if enemy.is_alive():
			return true
	return false


func _is_inside(cell: Vector2i) -> bool:
	return map_definition.is_inside(cell)


func _manhattan(first: Vector2i, second: Vector2i) -> int:
	return absi(first.x - second.x) + absi(first.y - second.y)


func _direction_towards(from: Vector2i, to: Vector2i) -> Vector2i:
	var delta := to - from
	if abs(delta.x) >= abs(delta.y) and delta.x != 0:
		return Vector2i(sign(delta.x), 0)
	if delta.y != 0:
		return Vector2i(0, sign(delta.y))
	return Vector2i.DOWN


func _chase_step(delta: Vector2i) -> Vector2i:
	var step := Vector2i.ZERO
	if abs(delta.x) >= abs(delta.y) and delta.x != 0:
		step.x = int(sign(delta.x))
	elif delta.y != 0:
		step.y = int(sign(delta.y))
	return step


func _shield_combo_requirement() -> int:
	return GUARD_RHYTHM_SHIELD_COMBO if bool(buffs.get("guard", false)) else RHYTHM_SHIELD_COMBO
