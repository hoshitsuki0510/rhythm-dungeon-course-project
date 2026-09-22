class_name MvpRoomView
extends Control

const StateScript = preload("res://scripts/mvp/mvp_state.gd")
const PLAYER_SHEET = preload("res://assets/sprites/player_sheet.png")
const PLAYER_HURT = preload("res://assets/sprites/player_hurt_down.png")
const PLAYER_DEATH = preload("res://assets/sprites/player_death_down.png")
const ENEMY_SHEET = preload("res://assets/sprites/enemy_siphonling_sheet.png")
const ENEMY_HURT = preload("res://assets/sprites/enemy_siphonling_hurt_down.png")
const ENEMY_DEATH = preload("res://assets/sprites/enemy_siphonling_death_down.png")
const SPIT_SLUG_SHEET = preload("res://assets/sprites/spit_slug_sheet.png")
const VENOUS_GLUTTON_SHEET = preload("res://assets/sprites/venous_glutton_sheet.png")
const PISTON_COLOSSUS_SHEET = preload("res://assets/sprites/piston_colossus_sheet.png")
const OXYGEN_RESERVOIR_SHEET = preload("res://assets/sprites/oxygen_reservoir_sheet.png")
const ARRHYTHMIA_BOSS_SHEET = preload("res://assets/sprites/arrhythmia_boss_sheet.png")
const EFFECTS_ATLAS = preload("res://assets/effects/combat_effects_atlas.png")
const EXIT_PORTAL_SHEET = preload("res://assets/effects/fx_room_exit_portal_sheet.png")
const CLASH_SHEET = preload("res://assets/effects/fx_weapon_clash_sheet.png")
const MUD_PROJECTILE_SHEET = preload("res://assets/effects/mud_projectile_sheet.png")
const BLOOD_SEDIMENT_HAZARD_SHEET = preload("res://assets/effects/blood_sediment_hazard_sheet.png")
const PISTON_STRIKE_SHEET = preload("res://assets/effects/piston_strike_sheet.png")
const PULMONARY_JET_SHEET = preload("res://assets/effects/pulmonary_jet_sheet.png")
const OXYGEN_CHARGE_SHEET = preload("res://assets/effects/oxygen_charge_sheet.png")
const GROUND_SPIKE_WAVE_SHEET = preload("res://assets/effects/ground_spike_wave_sheet.png")
const DEFIBRILLATION_COUNTDOWN_SHEET = preload("res://assets/effects/defibrillation_countdown_sheet.png")
const NOISE_PROJECTILE_SHEET = preload("res://assets/effects/noise_projectile_sheet.png")
const HEART_CORE = preload("res://assets/objects/heart_core_v2.png")
const REWARD_SHRINE = preload("res://assets/objects/reward_shrine.png")
const PORTAL_PRESSURIZED_SHEET = preload("res://assets/objects/portal_pressurized_sheet.png")
const PORTAL_OXYGEN_FLOW_SHEET = preload("res://assets/objects/portal_oxygen_flow_sheet.png")
const PORTAL_PRIME_RESONANCE_SHEET = preload("res://assets/objects/portal_prime_resonance_sheet.png")

const COLOR_WARNING := Color(0.96, 0.28, 0.29, 0.80)
const COLOR_EXIT := Color(0.31, 0.92, 0.62, 0.90)
const COLOR_AMBER := Color(1.0, 0.70, 0.25, 0.88)
const COLOR_MUD := Color(0.48, 0.30, 0.18, 0.88)
const COLOR_MUD_EDGE := Color(0.86, 0.53, 0.22, 0.90)
const COLOR_SHADOW := Color(0.01, 0.02, 0.016, 0.48)
const PLAYER_ACTION_TIME := 0.18
const ENEMY_ACTION_START := 0.20
const ENEMY_ACTION_TIME := 0.18
const ENEMY_ACTION_GAP := 0.02
const ENEMY_WINDUP_TIME := 0.44
const ENEMY_CANCEL_TIME := 0.16
const CLASH_ACTION_TIME := 0.36
const EXIT_TRANSITION_DURATION := 0.56

var room_state: MvpRunState
var background_texture: Texture2D
var actor_layer: Node2D
var player_sprite: Sprite2D
var exit_portal_sprite: Sprite2D
var actor_sprites: Dictionary = {}
var actor_roles: Dictionary = {}
var actor_busy_until: Dictionary = {}
var state_texture_cache: Dictionary = {}
var _opaque_frame_offsets: Dictionary = {}
var _opaque_texture_offsets: Dictionary = {}
var _texture_visual_centroid_offsets: Dictionary = {}
var feedback_layer: Control
var shake_time := 0.0
var shake_strength := 0.0
var flash_time := 0.0
var flash_color := Color.WHITE
var telegraph_time := 0.0
var door_pulse := 0.0
var door_animation_time := 0.0
var _last_layout := Vector2.ZERO
var presentation_generation := 0
var presentation_tweens: Array[Tween] = []


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	actor_layer = Node2D.new()
	actor_layer.name = "ActorLayer"
	actor_layer.z_index = 5
	add_child(actor_layer)
	feedback_layer = Control.new()
	feedback_layer.name = "FeedbackLayer"
	feedback_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	feedback_layer.z_index = 20
	add_child(feedback_layer)


func bind_state(state: MvpRunState) -> void:
	room_state = state
	set_room()


func set_room() -> void:
	if room_state == null:
		return
	_cancel_presentations()
	background_texture = load(room_state.room_background_path) as Texture2D
	for child in actor_layer.get_children():
		child.free()
	for child in feedback_layer.get_children():
		child.free()
	actor_sprites.clear()
	actor_roles.clear()
	actor_busy_until.clear()
	state_texture_cache.clear()
	exit_portal_sprite = _create_exit_portal()
	player_sprite = _create_actor("player", &"player", PLAYER_SHEET)
	for enemy in room_state.enemies:
		_create_actor(enemy.unit_id, enemy.role, _sheet_for_role(enemy.role))
	if room_state.room_kind == StateScript.ROOM_START or room_state.room_kind == StateScript.ROOM_RESTORED:
		# An 11x6 board has no single central tile: its real center lies halfway
		# between the two middle rows. Anchor the heart to that board center and
		# compensate for the generated sprite's top-heavy visible mass.
		_create_object("heart_core", HEART_CORE, Vector2i(5, 2), 1.0, &"board_center", true)
	elif room_state.room_kind == StateScript.ROOM_REWARD:
		_create_object("reward_shrine_left", REWARD_SHRINE, Vector2i(0, 3), 0.9)
		_create_object("reward_shrine_right", REWARD_SHRINE, Vector2i(10, 3), 0.9)
	# Lay out the freshly created actors before any arrival presentation starts.
	# A deferred-only layout leaves a one-frame default-scale/default-position
	# sprite visible during room transitions.
	_layout_all_actors()
	_last_layout = size
	queue_redraw()


func beat_pulse() -> void:
	telegraph_time = 0.34
	door_pulse = 1.0
	for identifier in actor_sprites:
		var sprite: Sprite2D = actor_sprites[identifier]
		var role: StringName = actor_roles[identifier]
		var unit: MvpUnitState = room_state.player if identifier == "player" else _find_unit(identifier)
		if unit == null or not _is_actor_free(identifier):
			continue
		# Regular enemies retain a committed pose between the windup beat and the
		# execution beat.  The Boss still pulses every beat like the original MVP.
		if identifier == "player" or role == &"enemy" or room_state.room_kind == StateScript.ROOM_BOSS:
			var pose := _idle_pose(role)
			if role == &"enemy" and unit.enemy_plan != &"none":
				pose = _enemy_plan_pose(unit)
			_set_pose(sprite, role, pose, unit.facing)
			sprite.position = _actor_position(unit.cell, role, pose, unit.facing)


func telegraph_enemies() -> void:
	telegraph_time = 0.7
	for enemy in room_state.enemies:
		if not enemy.is_alive():
			continue
		if enemy.enemy_plan == &"attack":
			_spawn_effect(7, _cell_center(enemy.enemy_plan_target), 1.4, 0.34, COLOR_WARNING)
		elif enemy.enemy_plan == &"move":
			_spawn_effect(8, _cell_center(enemy.enemy_plan_target), 0.86, 0.28, COLOR_AMBER)
		elif enemy.role == &"slug" and room_state.enemy_intent(enemy) == &"mud":
			var slug_direction: Vector2i = room_state._direction_towards(enemy.cell, room_state.player.cell)
			_spawn_effect(7, _cell_center(enemy.cell + slug_direction), 1.0, 0.30, COLOR_MUD_EDGE)
		elif room_state.enemy_intent(enemy) == &"attack":
			_spawn_effect(7, _cell_center(room_state.player.cell), 1.4, 0.34, COLOR_WARNING)


func present_turn(result: Dictionary) -> void:
	if room_state == null:
		return
	var player_result: Dictionary = result.get("player", {})
	var player_kind := String(player_result.get("kind", "wait"))
	if player_kind == "move":
		_animate_move("player", player_result, 0.0)
	elif player_kind == "attack":
		_animate_player_attack(player_result, 0.0)
	elif player_kind == "clash":
		_animate_clash(player_result, 0.0)
	elif player_kind == "charge":
		_animate_charge(player_result, 0.0)
	elif player_kind == "blocked":
		_shake(0.10, 2.0)
		_spawn_floating_text("阻挡", _cell_center(room_state.player.cell), COLOR_AMBER)

	var enemy_results: Array = result.get("enemies", [])
	for environment_result in result.get("environment", []):
		if String(environment_result.get("kind", "")) == "mud_hit":
			var hit_cell: Vector2i = environment_result.get("cell", room_state.player.cell)
			_spawn_effect(6, _cell_center(hit_cell), 1.18, 0.26, Color(0.78, 0.46, 0.24, 0.92))
			show_player_hurt(int(environment_result.get("damage", 1)))
			_start_hurt("player", bool(environment_result.get("killed", false)), hit_cell, presentation_generation)
	# A clash owns the player's transform longer than a normal attack. In the
	# hard room, delay every other enemy until both duelists have completed
	# their recoil so no second tween competes for the player hurt pose.
	var enemy_cursor := CLASH_ACTION_TIME + ENEMY_ACTION_GAP if player_kind == "clash" else ENEMY_ACTION_START
	for index in range(enemy_results.size()):
		var enemy_result: Dictionary = enemy_results[index]
		var enemy_id := String(enemy_result.get("enemy_id", ""))
		var enemy_kind := String(enemy_result.get("kind", "none"))
		if enemy_kind == "windup":
			_animate_enemy_windup(enemy_id, enemy_result, enemy_cursor)
			enemy_cursor += ENEMY_ACTION_TIME + ENEMY_ACTION_GAP
		elif enemy_kind == "move":
			_animate_move(enemy_id, enemy_result, enemy_cursor)
			enemy_cursor += ENEMY_ACTION_TIME + ENEMY_ACTION_GAP
		elif enemy_kind == "attack":
			_animate_enemy_attack(enemy_id, enemy_result, enemy_cursor)
			enemy_cursor += ENEMY_ACTION_TIME + ENEMY_ACTION_GAP
		elif enemy_kind == "mud_windup":
			_animate_enemy_windup(enemy_id, enemy_result, enemy_cursor)
			enemy_cursor += ENEMY_ACTION_TIME + ENEMY_ACTION_GAP
		elif enemy_kind == "mud_fire":
			_show_mud_fire(enemy_result, presentation_generation)
			enemy_cursor += ENEMY_ACTION_TIME + ENEMY_ACTION_GAP
		elif enemy_kind == "mud_summon":
			_show_mud_summon(enemy_result, presentation_generation)
			enemy_cursor += ENEMY_ACTION_TIME + ENEMY_ACTION_GAP
		elif enemy_kind == "sweep_windup":
			_show_sweep_windup(enemy_result, presentation_generation)
			enemy_cursor += ENEMY_ACTION_TIME + ENEMY_ACTION_GAP
		elif enemy_kind == "sweep":
			_show_sweep_result(enemy_result, presentation_generation)
			enemy_cursor += ENEMY_ACTION_TIME + ENEMY_ACTION_GAP
		elif enemy_kind == "recovery":
			_show_boss_recovery(enemy_result, presentation_generation)
			enemy_cursor += ENEMY_ACTION_TIME + ENEMY_ACTION_GAP
		elif enemy_kind == "piston_windup":
			_show_piston_windup(enemy_result, presentation_generation)
			enemy_cursor += ENEMY_ACTION_TIME + ENEMY_ACTION_GAP
		elif enemy_kind == "piston_strike":
			_show_piston_strike(enemy_result, presentation_generation)
			enemy_cursor += ENEMY_ACTION_TIME + ENEMY_ACTION_GAP
		elif enemy_kind == "oxygen_charge":
			_show_oxygen_charge(enemy_result, presentation_generation)
			enemy_cursor += ENEMY_ACTION_TIME + ENEMY_ACTION_GAP
		elif enemy_kind == "oxygen_blast":
			_show_oxygen_blast(enemy_result, presentation_generation)
			enemy_cursor += ENEMY_ACTION_TIME + ENEMY_ACTION_GAP
		elif enemy_kind == "oxygen_stagger":
			_show_oxygen_stagger(enemy_result, presentation_generation)
			enemy_cursor += ENEMY_ACTION_TIME + ENEMY_ACTION_GAP
		elif enemy_kind == "spike_windup":
			_show_spike_windup(enemy_result, presentation_generation)
			enemy_cursor += ENEMY_ACTION_TIME + ENEMY_ACTION_GAP
		elif enemy_kind == "noise_burst":
			_show_noise_burst(enemy_result, presentation_generation)
			enemy_cursor += ENEMY_ACTION_TIME + ENEMY_ACTION_GAP
		elif enemy_kind == "defibrillation":
			_show_defibrillation(enemy_result, presentation_generation)
			enemy_cursor += ENEMY_ACTION_TIME + ENEMY_ACTION_GAP
		elif enemy_kind == "phase_shift":
			_show_phase_shift_effect(enemy_result, presentation_generation)
			enemy_cursor += ENEMY_ACTION_TIME + ENEMY_ACTION_GAP
		elif enemy_kind == "parried":
			# The combined clash tween already owns both actors.
			continue
		elif bool(enemy_result.get("cancelled", false)):
			_animate_enemy_cancelled(enemy_id, enemy_result, enemy_cursor)
			enemy_cursor += ENEMY_CANCEL_TIME + ENEMY_ACTION_GAP

	if bool(result.get("room_cleared", false)):
		var clear_position: Vector2 = _cell_center(player_result.get("to", room_state.player.cell))
		_schedule_room_clear(0.46, clear_position)
	queue_redraw()


func show_room_clear(clear_position: Vector2 = Vector2.INF) -> void:
	var feedback_position := clear_position
	if feedback_position == Vector2.INF:
		feedback_position = _cell_center(room_state.player.cell)
	door_pulse = 1.0
	flash(Color(0.34, 0.95, 0.65, 0.16), 0.42)
	_spawn_effect(12, feedback_position, 2.0, 0.8, Color(0.42, 1.0, 0.73, 0.92))
	_spawn_effect(11, get_exit_door_center(), 1.75, 0.72, COLOR_EXIT)
	_animate_exit_portal_open()
	_spawn_floating_text("能量回流", feedback_position - Vector2(0, 18), COLOR_EXIT)


func play_exit_transition() -> float:
	if not is_instance_valid(player_sprite):
		return EXIT_TRANSITION_DURATION
	_cancel_presentations()
	var generation := presentation_generation
	var start_position := _actor_position(room_state.player.cell, &"player", 2, Vector2i.RIGHT)
	var door_center := get_exit_door_center()
	if is_instance_valid(exit_portal_sprite):
		exit_portal_sprite.frame = 3
		exit_portal_sprite.visible = true
	room_state.player.facing = Vector2i.RIGHT
	_set_pose(player_sprite, &"player", 2, Vector2i.RIGHT)
	var base_scale := player_sprite.scale
	player_sprite.position = start_position
	player_sprite.scale = base_scale
	player_sprite.modulate = Color.WHITE
	player_sprite.visible = true
	door_pulse = 1.0
	actor_busy_until["player"] = Time.get_ticks_msec() / 1000.0 + EXIT_TRANSITION_DURATION
	_spawn_effect(13, start_position, 0.95, 0.38, Color(0.42, 1.0, 0.78, 0.80))
	var tween := _track_tween(player_sprite.create_tween())
	tween.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(player_sprite, "position", start_position - Vector2(8.0, 0.0), 0.08)
	tween.tween_property(player_sprite, "position", door_center - Vector2(18.0, 0.0), 0.32).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_IN)
	tween.parallel().tween_property(player_sprite, "scale", base_scale * Vector2(1.22, 0.78), 0.32)
	tween.parallel().tween_property(player_sprite, "modulate", Color(0.58, 1.0, 0.82, 1.0), 0.24)
	tween.tween_callback(_on_exit_door_contact.bind(door_center, generation))
	tween.tween_property(player_sprite, "position", door_center + Vector2(10.0, 0.0), 0.16).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.parallel().tween_property(player_sprite, "scale", base_scale * Vector2(0.30, 0.72), 0.16)
	tween.parallel().tween_property(player_sprite, "modulate:a", 0.0, 0.16)
	return EXIT_TRANSITION_DURATION


func show_room_arrival() -> void:
	if not is_instance_valid(player_sprite):
		return
	var pose := _idle_pose(&"player")
	var base_scale := Vector2.ONE * _actor_scale_factor(&"player")
	_set_pose(player_sprite, &"player", pose, room_state.player.facing)
	var target_position := _actor_position(room_state.player.cell, &"player", pose, room_state.player.facing)
	player_sprite.position = target_position - Vector2(26.0, 0.0)
	# Room arrival changes position and opacity only. Keep the player's logical
	# tile scale identical before, during, and after the transition.
	player_sprite.scale = base_scale
	player_sprite.modulate = Color(0.55, 1.0, 0.78, 0.0)
	player_sprite.visible = true
	actor_busy_until["player"] = Time.get_ticks_msec() / 1000.0 + 0.30
	_spawn_effect(11, target_position - Vector2(18.0, 0.0), 1.35, 0.46, COLOR_EXIT)
	var tween := _track_tween(player_sprite.create_tween())
	tween.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(player_sprite, "position", target_position, 0.30)
	tween.parallel().tween_property(player_sprite, "modulate", Color.WHITE, 0.22)


func _boss_visual_center(origin: Vector2 = Vector2.INF, cell_size: float = -1.0) -> Vector2:
	if origin != Vector2.INF and cell_size > 0.0:
		return origin + Vector2(room_state.map_definition.grid_size) * cell_size * 0.5
	return _board_center()


func get_exit_door_center() -> Vector2:
	# After the Boss is defeated, the next-layer portal belongs in the room's
	# visual center. Before that moment the same sprite remains the closed right-wall
	# exit used by combat rooms.
	if room_state != null and room_state.room_kind == StateScript.ROOM_BOSS and room_state.room_cleared:
		return _board_center()
	return room_state.map_definition.get_exit_center(size)


func _on_exit_door_contact(door_center: Vector2, generation: int) -> void:
	if generation != presentation_generation:
		return
	door_pulse = 1.0
	_spawn_effect(11, door_center, 2.05, 0.52, Color(0.52, 1.0, 0.78, 0.96))
	_spawn_effect(13, door_center, 1.35, 0.42, Color(0.34, 0.95, 0.74, 0.88))
	flash(Color(0.38, 1.0, 0.76, 0.20), 0.34)
	_shake(0.18, 2.2)


func show_phase_shift() -> void:
	flash(Color(0.92, 0.18, 0.65, 0.18), 0.58)
	_spawn_effect(15, _cell_center(room_state.player.cell), 1.8, 0.72, Color(1.0, 0.26, 0.66, 0.95))
	var boss := room_state.get_primary_enemy()
	if boss != null:
		var sprite: Sprite2D = actor_sprites.get(boss.unit_id)
		if sprite != null:
			_set_pose(sprite, &"boss", _idle_pose(&"boss"), boss.facing)
			sprite.position = _actor_position(boss.cell, &"boss", _idle_pose(&"boss"), boss.facing)
		_spawn_floating_text("BPM SHIFT", _boss_visual_center() - Vector2(0, 30), Color(1.0, 0.43, 0.76, 1.0))
	_shake(0.35, 4.0)


func show_player_hurt(damage: int = 1) -> void:
	flash(Color(0.95, 0.16, 0.22, 0.12), 0.28)
	_spawn_effect(6, _cell_center(room_state.player.cell), 1.15, 0.26, Color(1.0, 0.38, 0.36, 0.9))
	_spawn_floating_text("-%d" % damage, _cell_center(room_state.player.cell) - Vector2(0, 26), Color(1.0, 0.43, 0.40, 1.0))
	_shake(0.16, 3.0)


func show_shield_block() -> void:
	_spawn_effect(13, _cell_center(room_state.player.cell), 1.35, 0.42, Color(0.39, 0.90, 1.0, 0.96))
	_spawn_floating_text("ECHO GUARD", _cell_center(room_state.player.cell) - Vector2(0, 26), Color(0.45, 0.90, 1.0, 1.0))


func show_rhythm_shield_assist() -> void:
	_spawn_effect(13, _cell_center(room_state.player.cell), 1.18, 0.34, Color(0.37, 0.92, 1.0, 0.9))
	_spawn_floating_text("SYNC", _cell_center(room_state.player.cell) - Vector2(0, 27), Color(0.46, 0.94, 1.0, 1.0))


func reset_feedback() -> void:
	_cancel_presentations()
	shake_time = 0.0
	shake_strength = 0.0
	flash_time = 0.0
	telegraph_time = 0.0
	door_pulse = 0.0
	door_animation_time = 0.0
	if is_instance_valid(actor_layer):
		actor_layer.position = Vector2.ZERO
	if is_instance_valid(feedback_layer):
		for child in feedback_layer.get_children():
			child.free()
	queue_redraw()


func _process(delta: float) -> void:
	shake_time = maxf(0.0, shake_time - delta)
	flash_time = maxf(0.0, flash_time - delta)
	telegraph_time = maxf(0.0, telegraph_time - delta)
	door_pulse = maxf(0.0, door_pulse - delta * 2.8)
	door_animation_time += delta
	if shake_time > 0.0:
		actor_layer.position = Vector2(randf_range(-shake_strength, shake_strength), randf_range(-shake_strength, shake_strength))
	else:
		actor_layer.position = Vector2.ZERO
	if _last_layout != size:
		_last_layout = size
		_layout_all_actors()
	queue_redraw()


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.025, 0.035, 0.033, 1.0))
	if background_texture != null:
		var scene_rect := _scene_rect()
		draw_texture_rect(background_texture, scene_rect, false)
	if room_state == null:
		return
	var layout := _grid_layout()
	var origin: Vector2 = layout.origin
	var cell_size: float = layout.cell_size
	for hazard_cell in room_state.mud_hazards.keys():
		var hazard: Vector2i = hazard_cell
		var hazard_center := _cell_center(hazard, origin, cell_size)
		var hazard_size := Vector2.ONE * cell_size * 0.76
		var hazard_offset := _sheet_frame_offset(BLOOD_SEDIMENT_HAZARD_SHEET, 2, 4)
		var hazard_rect := Rect2(hazard_center - hazard_size * 0.5 - hazard_offset * (hazard_size.x / 32.0), hazard_size)
		draw_texture_rect_region(
			BLOOD_SEDIMENT_HAZARD_SHEET,
			hazard_rect,
			Rect2(64.0, 0.0, 32.0, 32.0),
			Color.WHITE,
		)
	for projectile in room_state.mud_projectiles:
		var projectile_cell: Vector2i = projectile.get("cell", Vector2i.ZERO)
		var projectile_center := _cell_center(projectile_cell, origin, cell_size)
		var projectile_direction: Vector2i = projectile.get("direction", Vector2i.RIGHT)
		var projectile_size := Vector2.ONE * cell_size * 0.64
		var projectile_offset := _sheet_frame_offset(MUD_PROJECTILE_SHEET, 1, 4) * (projectile_size.x / 32.0)
		_draw_projectile_cell_marker(projectile_center, projectile_direction, cell_size)
		draw_set_transform(projectile_center, Vector2(projectile_direction).angle(), Vector2.ONE)
		draw_texture_rect_region(
			MUD_PROJECTILE_SHEET,
			Rect2(-projectile_size * 0.5 - projectile_offset, projectile_size),
			Rect2(32.0, 0.0, 32.0, 32.0),
			Color.WHITE,
		)
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	var boss := room_state.get_boss()
	if boss != null and boss.is_alive() and room_state.room_kind == StateScript.ROOM_BOSS:
		var boss_center := _boss_visual_center(origin, cell_size)
		# One continuous organic shadow communicates the 3x3 body without adding
		# another grid-shaped frame over the floor art.
		draw_circle(boss_center, cell_size * 1.34, Color(0.30, 0.08, 0.15, 0.18))
		if boss.enemy_plan == &"sweep":
			_draw_sweep_fan(boss_center, room_state.boss_sweep_direction, cell_size)
			var charge_pulse := 0.5 + 0.5 * sin(door_animation_time * 10.0)
			draw_arc(boss_center, cell_size * (1.48 + charge_pulse * 0.08), 0.0, TAU, 36, Color(1.0, 0.30, 0.22, 0.72), 5.0)
			draw_arc(boss_center, cell_size * (1.68 + charge_pulse * 0.06), 0.0, TAU, 36, Color(1.0, 0.70, 0.24, 0.48), 3.0)
		if room_state.boss_kind == &"piston_colossus" and not room_state.boss_telegraph_cells.is_empty():
			_draw_line_warning(room_state.boss_telegraph_cells, cell_size, Color(1.0, 0.28, 0.30, 0.58))
		if room_state.boss_kind == &"oxygen_reservoir" and room_state.boss_charge_beat > 0:
			var charge_pulse2 := 0.5 + 0.5 * sin(door_animation_time * 8.0)
			draw_circle(boss_center, cell_size * (1.75 + charge_pulse2 * 0.18), Color(0.20, 0.88, 1.0, 0.12))
			draw_arc(boss_center, cell_size * (1.55 + charge_pulse2 * 0.2), 0.0, TAU, 40, Color(0.30, 0.92, 1.0, 0.80), 4.0)
		if room_state.boss_kind == &"arrhythmia" and not room_state.boss_telegraph_cells.is_empty():
			_draw_line_warning(room_state.boss_telegraph_cells, cell_size, Color(0.86, 0.26, 1.0, 0.50))
	if room_state.is_combat_room() and not room_state.room_cleared:
		for enemy in room_state.enemies:
			if not enemy.is_alive():
				continue
			var enemy_center := _cell_center(enemy.cell, origin, cell_size)
			if enemy.enemy_plan == &"attack":
				draw_arc(enemy_center, cell_size * 0.32 + telegraph_time * 4.0, 0.0, TAU, 24, Color(COLOR_WARNING, 0.70), 2.0)
				_draw_action_marker(_cell_center(enemy.enemy_plan_target, origin, cell_size), enemy.enemy_plan_direction, COLOR_WARNING, true, cell_size)
			elif enemy.enemy_plan == &"move":
				_draw_action_marker(_cell_center(enemy.enemy_plan_target, origin, cell_size), enemy.enemy_plan_direction, COLOR_AMBER, false, cell_size)
			elif room_state.enemy_intent(enemy) == &"attack":
				_draw_action_marker(_cell_center(room_state.player.cell, origin, cell_size), enemy.facing, COLOR_WARNING, true, cell_size)
	_draw_exit_door()
	if flash_time > 0.0:
		draw_rect(Rect2(Vector2.ZERO, size), Color(flash_color, flash_time * 0.34))


func _draw_line_warning(cells: Array[Vector2i], cell_size: float, color: Color) -> void:
	var pulse := 0.72 + 0.20 * sin(door_animation_time * 10.0)
	for cell in cells:
		draw_circle(_cell_center(cell), cell_size * 0.26, Color(color, 0.22 * pulse))
		draw_arc(_cell_center(cell), cell_size * 0.28, 0.0, TAU, 18, Color(color, 0.86), 2.0)


func _draw_action_marker(marker_center: Vector2, direction: Vector2i, color: Color, attack: bool, cell_size: float) -> void:
	var forward := Vector2(direction).normalized()
	if forward == Vector2.ZERO:
		forward = Vector2.DOWN
	var side := Vector2(-forward.y, forward.x)
	var pulse := 0.84 + 0.16 * sin(door_animation_time * 9.0)
	var tip := marker_center + forward * cell_size * 0.22
	var back := marker_center - forward * cell_size * 0.14
	var half_width := cell_size * (0.16 if attack else 0.12) * pulse
	draw_colored_polygon(PackedVector2Array([
		tip,
		back + side * half_width,
		marker_center - forward * cell_size * 0.02,
		back - side * half_width,
	]), Color(color, 0.72 if attack else 0.60))
	draw_circle(marker_center, cell_size * (0.075 if attack else 0.055) * pulse, Color(color, 0.92))


func _draw_projectile_cell_marker(cell_center: Vector2, direction: Vector2i, cell_size: float) -> void:
	# A high-contrast diamond, center bead and arrowhead make the projectile's
	# occupied cell unambiguous against the painted floor without bringing back a
	# square/grid outline.  The marker is deliberately larger than the sprite so
	# its logical cell remains readable even when the projectile art is dark.
	var forward := Vector2(direction).normalized()
	if forward == Vector2.ZERO:
		forward = Vector2.RIGHT
	var side := Vector2(-forward.y, forward.x)
	var pulse := 0.82 + 0.18 * sin(door_animation_time * 12.0)
	var radius := cell_size * 0.43 * pulse
	var diamond := PackedVector2Array([
		cell_center + forward * radius,
		cell_center + side * radius * 0.76,
		cell_center - forward * radius,
		cell_center - side * radius * 0.76,
	])
	draw_colored_polygon(diamond, Color(0.94, 0.20, 0.16, 0.38))
	draw_polyline(PackedVector2Array([diamond[0], diamond[1], diamond[2], diamond[3], diamond[0]]), Color(1.0, 0.78, 0.28, 0.96), 2.0)
	for vertex in diamond:
		draw_circle(vertex, maxf(1.5, cell_size * 0.045), Color(1.0, 0.92, 0.56, 0.96))
	draw_circle(cell_center, cell_size * 0.10, Color(0.16, 0.07, 0.04, 0.90))
	draw_circle(cell_center, cell_size * 0.065, Color(1.0, 0.88, 0.34, 1.0))
	var arrow_tip := cell_center + forward * cell_size * 0.31
	var arrow_base := cell_center + forward * cell_size * 0.13
	var arrow_half := side * cell_size * 0.10
	draw_colored_polygon(PackedVector2Array([arrow_tip, arrow_base + arrow_half, arrow_base - arrow_half]), Color(1.0, 0.46, 0.24, 1.0))


func _draw_sweep_fan(boss_center: Vector2, direction: Vector2i, cell_size: float) -> void:
	var forward := Vector2(direction).normalized()
	if forward == Vector2.ZERO:
		forward = Vector2.DOWN
	var side := Vector2(-forward.y, forward.x)
	var near_center := boss_center + forward * cell_size * 1.36
	var far_center := boss_center + forward * cell_size * (StateScript.BOSS_FOOTPRINT_RADIUS + StateScript.BOSS_SWEEP_RANGE + 0.45)
	var pulse := 0.72 + 0.16 * sin(door_animation_time * 10.0)
	var fan := PackedVector2Array([
		near_center - side * cell_size * 0.24,
		far_center - side * cell_size * 1.42,
		far_center + side * cell_size * 1.42,
		near_center + side * cell_size * 0.24,
	])
	draw_colored_polygon(fan, Color(COLOR_WARNING, pulse * 0.33))
	for depth in range(1, StateScript.BOSS_SWEEP_RANGE + 1):
		var marker_center := boss_center + forward * cell_size * (StateScript.BOSS_FOOTPRINT_RADIUS + depth)
		_draw_action_marker(marker_center, direction, COLOR_WARNING, true, cell_size * (0.84 + depth * 0.06))


func _draw_exit_door() -> void:
	var door_center := get_exit_door_center()
	var door_size: Vector2 = room_state.map_definition.get_exit_size(size)
	var scene_scale: float = _scene_rect().size.x / room_state.map_definition.art_reference_size.x
	var door_rect := Rect2(door_center - door_size * 0.5, door_size)
	var is_open := room_state.can_leave_room()
	var breathe := 0.5 + 0.5 * sin(door_animation_time * 4.2)
	var pulse := clampf(door_pulse + breathe * 0.22, 0.0, 1.0)
	var frame_color := COLOR_EXIT if is_open else Color(0.72, 0.38, 0.20, 0.82)
	# Upper layers use their dedicated central portal art after Boss clear;
	# keep the procedural right-wall hint only while the room is still locked.
	if room_state.layer_index > StateScript.LAYER_ONE and not _is_central_portal_active():
		draw_rect(door_rect.grow((4.0 + pulse * 5.0) * scene_scale), Color(frame_color, 0.035 + pulse * 0.07))
		if not is_open:
			draw_rect(door_rect.grow(1.0 * scene_scale), Color(frame_color, 0.18), false, maxf(1.0, 1.5 * scene_scale))


func _is_central_portal_active() -> bool:
	return room_state != null and room_state.room_kind == StateScript.ROOM_BOSS and room_state.room_cleared


func _central_portal_texture() -> Texture2D:
	match room_state.layer_index:
		StateScript.LAYER_TWO:
			return PORTAL_PRESSURIZED_SHEET
		StateScript.LAYER_THREE:
			return PORTAL_OXYGEN_FLOW_SHEET
		StateScript.LAYER_FOUR:
			return PORTAL_PRIME_RESONANCE_SHEET
		_:
			return EXIT_PORTAL_SHEET


func _exit_portal_texture() -> Texture2D:
	if _is_central_portal_active():
		return _central_portal_texture()
	match room_state.layer_index:
		StateScript.LAYER_TWO:
			return PORTAL_PRESSURIZED_SHEET
		StateScript.LAYER_THREE:
			return PORTAL_OXYGEN_FLOW_SHEET
		StateScript.LAYER_FOUR:
			return PORTAL_PRIME_RESONANCE_SHEET
		_:
			return EXIT_PORTAL_SHEET


func _create_exit_portal() -> Sprite2D:
	var sprite := Sprite2D.new()
	sprite.name = "ExitPortal"
	sprite.texture = _exit_portal_texture()
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sprite.centered = true
	sprite.hframes = 4
	sprite.vframes = 1
	sprite.frame = 3 if room_state.can_leave_room() else 0
	sprite.z_index = 3
	actor_layer.add_child(sprite)
	_layout_exit_portal()
	return sprite


func _layout_exit_portal() -> void:
	if not is_instance_valid(exit_portal_sprite):
		return
	var scene_rect := _scene_rect()
	exit_portal_sprite.position = get_exit_door_center()
	var portal_scale: float = scene_rect.size.x / room_state.map_definition.art_reference_size.x
	if room_state.layer_index == StateScript.LAYER_TWO and not _is_central_portal_active():
		portal_scale *= 0.62
	exit_portal_sprite.scale = Vector2.ONE * portal_scale
	exit_portal_sprite.visible = true


func _animate_exit_portal_open() -> void:
	if not is_instance_valid(exit_portal_sprite):
		return
	var generation := presentation_generation
	exit_portal_sprite.texture = _exit_portal_texture()
	exit_portal_sprite.hframes = 4
	exit_portal_sprite.vframes = 1
	exit_portal_sprite.visible = true
	_layout_exit_portal()
	exit_portal_sprite.frame = 0
	var tween := _track_tween(create_tween())
	tween.set_trans(Tween.TRANS_LINEAR).set_ease(Tween.EASE_IN_OUT)
	for next_frame in range(1, 4):
		tween.tween_property(exit_portal_sprite, "frame", next_frame, 0.10)
	tween.tween_callback(_finish_exit_portal_open.bind(generation))


func _finish_exit_portal_open(generation: int) -> void:
	if generation == presentation_generation and is_instance_valid(exit_portal_sprite):
		exit_portal_sprite.frame = 3


func _create_actor(identifier: String, role: StringName, texture: Texture2D) -> Sprite2D:
	var sprite := Sprite2D.new()
	sprite.name = identifier
	sprite.texture = texture
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sprite.centered = true
	sprite.hframes = 4
	sprite.vframes = 4
	sprite.z_index = 5 if role != &"boss" else 6
	# Avoid a default 1x frame while the scene is being laid out or an arrival
	# tween is being prepared. The first visible frame already matches the
	# gameplay tile scale for its role.
	sprite.scale = Vector2.ONE * _actor_scale_factor(role)
	actor_layer.add_child(sprite)
	actor_sprites[identifier] = sprite
	actor_roles[identifier] = role
	if identifier == "player":
		player_sprite = sprite
	return sprite


func _create_object(
	identifier: String,
	texture: Texture2D,
	cell: Vector2i,
	scale_factor: float,
	anchor: StringName = &"cell",
	align_visual_centroid: bool = false
) -> void:
	var sprite := Sprite2D.new()
	sprite.name = identifier
	sprite.texture = texture
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sprite.scale = Vector2.ONE * scale_factor
	sprite.z_index = 2
	sprite.set_meta("object_cell", cell)
	sprite.set_meta("object_anchor", anchor)
	sprite.set_meta("align_visual_centroid", align_visual_centroid)
	actor_layer.add_child(sprite)
	_layout_object(sprite)


func _layout_object(sprite: Sprite2D) -> void:
	if not is_instance_valid(sprite):
		return
	var cell: Vector2i = sprite.get_meta("object_cell")
	var target_position := _board_center() if sprite.get_meta("object_anchor", &"cell") == &"board_center" else _cell_center(cell)
	if bool(sprite.get_meta("align_visual_centroid", false)):
		var visual_offset := get_texture_visual_centroid_offset(sprite.texture)
		if visual_offset != Vector2.INF:
			target_position -= visual_offset * sprite.scale
	sprite.position = target_position


func _layout_all_actors() -> void:
	if room_state == null:
		return
	_layout_exit_portal()
	for identifier in actor_sprites:
		var sprite: Sprite2D = actor_sprites[identifier]
		var unit: MvpUnitState = room_state.player if identifier == "player" else _find_unit(identifier)
		if unit == null:
			continue
		var role: StringName = actor_roles[identifier]
		var idle_pose := _idle_pose(role)
		_set_pose(sprite, role, idle_pose, unit.facing)
		sprite.position = _actor_position(unit.cell, role, idle_pose, unit.facing)
		sprite.visible = unit.is_alive()
	for child in actor_layer.get_children():
		if child is Sprite2D and child.has_meta("object_cell"):
			_layout_object(child as Sprite2D)


func _set_pose(sprite: Sprite2D, role: StringName, pose: int, facing: Vector2i) -> void:
	sprite.texture = _sheet_for_role(role)
	sprite.hframes = 4
	sprite.vframes = 4
	sprite.frame = _direction_row(facing) * 4 + clampi(pose, 0, 3)
	sprite.scale = Vector2.ONE * _actor_scale_factor(role)
	sprite.modulate = Color.WHITE
	sprite.rotation = 0.0


func _sheet_for_role(role: StringName) -> Texture2D:
	if role == &"player":
		return PLAYER_SHEET
	if role == &"slug":
		return SPIT_SLUG_SHEET
	if role == &"boss":
		match room_state.boss_kind if room_state != null else &"venous_glutton":
			&"piston_colossus": return PISTON_COLOSSUS_SHEET
			&"oxygen_reservoir": return OXYGEN_RESERVOIR_SHEET
			&"arrhythmia": return ARRHYTHMIA_BOSS_SHEET
			_: return VENOUS_GLUTTON_SHEET
	return ENEMY_SHEET


func _single_state_texture(role: StringName, death: bool, facing: Vector2i) -> Texture2D:
	var direction := _direction_name(facing)
	var prefix := "player"
	if role == &"enemy":
		prefix = "enemy_siphonling"
	elif role == &"slug":
		prefix = "spit_slug"
	elif role == &"boss":
		prefix = "venous_glutton"
		if room_state != null:
			prefix = String(room_state.boss_kind) + "_boss" if room_state.boss_kind == &"arrhythmia" else String(room_state.boss_kind)
	var state := "death" if death else "hurt"
	var cache_key := "%s_%s_%s" % [prefix, state, direction]
	if state_texture_cache.has(cache_key):
		return state_texture_cache[cache_key] as Texture2D
	var candidate := "res://assets/sprites/%s_%s_%s.png" % [prefix, state, direction]
	if ResourceLoader.exists(candidate):
		var texture := load(candidate) as Texture2D
		if texture != null:
			state_texture_cache[cache_key] = texture
			return texture
	# Keep a documented down-facing fallback if a future art revision omits one
	# direction. The current generated batch supplies all 20 directional files.
	if role == &"player":
		return PLAYER_DEATH if death else PLAYER_HURT
	if role == &"enemy" or role == &"slug":
		return ENEMY_DEATH if death else ENEMY_HURT
	return null


func _set_single_pose(sprite: Sprite2D, role: StringName, death: bool, facing: Vector2i = Vector2i.DOWN) -> void:
	var state_texture := _single_state_texture(role, death, facing)
	if state_texture != null:
		sprite.texture = state_texture
		sprite.hframes = 1
		sprite.vframes = 1
		sprite.frame = 0
		sprite.scale = Vector2.ONE * _actor_scale_factor(role)
		sprite.rotation = 0.0
		return
	# Fallback for a missing future Boss state: retain its atlas attack frame so
	# the sprite remains visible instead of displaying an invalid texture.
	if role == &"boss":
		_set_pose(sprite, role, 3, facing)
		return


func _direction_name(facing: Vector2i) -> String:
	if abs(facing.x) > abs(facing.y):
		return "right" if facing.x > 0 else "left"
	if facing.y < 0:
		return "up"
	return "down"


func _state_actor_position(cell: Vector2i, role: StringName, death: bool, facing: Vector2i) -> Vector2:
	var scale_factor: float = _actor_scale_factor(role)
	var texture := _single_state_texture(role, death, facing)
	var opaque_offset := _opaque_texture_offset(texture)
	if opaque_offset != Vector2.INF:
		return _cell_center(cell) - opaque_offset * scale_factor
	return _actor_position(cell, role, _idle_pose(role), facing)


func _animate_move(identifier: String, result: Dictionary, delay: float) -> void:
	var sprite: Sprite2D = actor_sprites.get(identifier)
	if sprite == null:
		return
	var generation := presentation_generation
	var role: StringName = actor_roles.get(identifier, &"enemy")
	var from_cell: Vector2i = result.get("from", Vector2i.ZERO)
	var to_cell: Vector2i = result.get("to", from_cell)
	var direction := to_cell - from_cell
	var pose := _idle_pose(role) if role == &"boss" else (1 if room_state.turn_number % 2 == 0 else 2)
	var target := _actor_position(to_cell, role, pose, direction)
	var tween := _track_tween(sprite.create_tween())
	tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	if delay > 0.0:
		tween.tween_interval(delay)
	tween.tween_callback(_begin_actor_pose.bind(identifier, role, pose, direction, from_cell, generation))
	tween.tween_property(sprite, "position", target, PLAYER_ACTION_TIME if role == &"player" else ENEMY_ACTION_TIME)
	tween.tween_callback(_on_move_complete.bind(identifier, to_cell, generation))
	tween.tween_callback(_finish_actor_animation.bind(identifier, role, generation))
	actor_busy_until[identifier] = Time.get_ticks_msec() / 1000.0 + delay + ENEMY_ACTION_TIME + 0.02


func _animate_player_attack(result: Dictionary, delay: float) -> void:
	var identifier := "player"
	var sprite: Sprite2D = actor_sprites.get(identifier)
	if sprite == null:
		return
	var generation := presentation_generation
	var direction: Vector2i = result.get("direction", Vector2i.RIGHT)
	var from_cell: Vector2i = result.get("from", Vector2i.ZERO)
	var start := _actor_position(from_cell, &"player", 3, direction)
	var reach := 0.46 if bool(result.get("charged_attack", false)) else 0.38
	var lunge: Vector2 = start + Vector2(direction) * _grid_layout().cell_size * reach
	var tween := _track_tween(sprite.create_tween())
	tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	if delay > 0.0:
		tween.tween_interval(delay)
	tween.tween_callback(_begin_actor_pose.bind(identifier, &"player", 3, direction, from_cell, generation))
	tween.tween_property(sprite, "position", lunge, PLAYER_ACTION_TIME * 0.52)
	tween.tween_callback(_on_player_attack_impact.bind(result, generation))
	tween.tween_property(sprite, "position", start, PLAYER_ACTION_TIME * 0.48)
	tween.tween_callback(_finish_actor_animation.bind(identifier, &"player", generation))
	actor_busy_until[identifier] = Time.get_ticks_msec() / 1000.0 + delay + PLAYER_ACTION_TIME + 0.02


func _animate_clash(result: Dictionary, delay: float) -> void:
	var player: Sprite2D = actor_sprites.get("player")
	var enemy_id := String(result.get("target_id", ""))
	var enemy: Sprite2D = actor_sprites.get(enemy_id)
	if player == null or enemy == null:
		return
	var generation := presentation_generation
	var direction: Vector2i = result.get("direction", Vector2i.RIGHT)
	var enemy_direction := -direction
	var player_cell: Vector2i = result.get("from", Vector2i.ZERO)
	var enemy_cell: Vector2i = result.get("to", player_cell + direction)
	var cell_size: float = _grid_layout().cell_size
	var player_start := _actor_position(player_cell, &"player", 3, direction)
	var enemy_start := _actor_position(enemy_cell, &"enemy", 3, enemy_direction)
	var player_contact := player_start + Vector2(direction) * cell_size * 0.27
	var enemy_contact := enemy_start - Vector2(direction) * cell_size * 0.27
	var player_recoil := player_start - Vector2(direction) * cell_size * 0.13
	var enemy_recoil := enemy_start + Vector2(direction) * cell_size * 0.13
	var player_scale := Vector2.ONE * (cell_size / 32.0)
	var enemy_scale := Vector2.ONE * (cell_size / 32.0)
	var tilt_sign := -1.0 if direction.x > 0 or direction.y > 0 else 1.0
	var player_contact_tilt := 0.075 * tilt_sign
	var enemy_contact_tilt := -player_contact_tilt
	var approach_time := CLASH_ACTION_TIME * 0.25
	var hitstop_time := CLASH_ACTION_TIME * 0.12
	var recoil_time := CLASH_ACTION_TIME * 0.25
	var return_time := CLASH_ACTION_TIME - approach_time - hitstop_time - recoil_time
	var tween := _track_tween(create_tween())
	if delay > 0.0:
		tween.tween_interval(delay)
	tween.tween_callback(_begin_actor_pose.bind("player", &"player", 3, direction, player_cell, generation))
	tween.tween_callback(_begin_actor_pose.bind(enemy_id, &"enemy", 3, enemy_direction, enemy_cell, generation))
	tween.tween_property(player, "position", player_contact, approach_time).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.parallel().tween_property(enemy, "position", enemy_contact, approach_time).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.parallel().tween_property(player, "scale", player_scale * 1.07, approach_time)
	tween.parallel().tween_property(enemy, "scale", enemy_scale * 1.07, approach_time)
	tween.parallel().tween_property(player, "rotation", player_contact_tilt, approach_time)
	tween.parallel().tween_property(enemy, "rotation", enemy_contact_tilt, approach_time)
	tween.tween_callback(_on_clash_impact.bind(result, generation))
	# A short hit-stop lets the crossed attack frames and spark carry the meaning
	# without a floating "parry" caption.
	tween.tween_interval(hitstop_time)
	tween.tween_property(player, "position", player_recoil, recoil_time).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(enemy, "position", enemy_recoil, recoil_time).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(player, "scale", player_scale * 0.90, recoil_time)
	tween.parallel().tween_property(enemy, "scale", enemy_scale * 0.90, recoil_time)
	tween.parallel().tween_property(player, "rotation", -player_contact_tilt * 1.8, recoil_time)
	tween.parallel().tween_property(enemy, "rotation", -enemy_contact_tilt * 1.8, recoil_time)
	tween.parallel().tween_property(player, "modulate", Color.WHITE, recoil_time)
	tween.parallel().tween_property(enemy, "modulate", Color.WHITE, recoil_time)
	tween.tween_property(player, "position", player_start, return_time).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(enemy, "position", enemy_start, return_time).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(player, "scale", player_scale, return_time)
	tween.parallel().tween_property(enemy, "scale", enemy_scale, return_time)
	tween.parallel().tween_property(player, "rotation", 0.0, return_time)
	tween.parallel().tween_property(enemy, "rotation", 0.0, return_time)
	tween.tween_callback(_finish_actor_animation.bind("player", &"player", generation))
	tween.tween_callback(_finish_actor_animation.bind(enemy_id, &"enemy", generation))
	var busy_until := Time.get_ticks_msec() / 1000.0 + delay + CLASH_ACTION_TIME + 0.02
	actor_busy_until["player"] = busy_until
	actor_busy_until[enemy_id] = busy_until


func _animate_enemy_windup(identifier: String, result: Dictionary, delay: float) -> void:
	var sprite: Sprite2D = actor_sprites.get(identifier)
	if sprite == null:
		return
	var generation := presentation_generation
	var role: StringName = actor_roles.get(identifier, &"enemy")
	var planned_action := String(result.get("planned_action", result.get("intent", "move")))
	var direction: Vector2i = result.get("direction", Vector2i.LEFT)
	var from_cell: Vector2i = result.get("from", Vector2i.ZERO)
	var pose := 3 if planned_action == "attack" else _enemy_step_pose()
	var base_scale: Vector2 = Vector2.ONE * _actor_scale_factor(role)
	var base_position: Vector2 = _actor_position(from_cell, role, pose, direction)
	var pull_direction: Vector2 = Vector2(direction)
	if pull_direction.length_squared() > 0.0:
		pull_direction = pull_direction.normalized()
	else:
		pull_direction = Vector2.LEFT
	var prep_position: Vector2 = base_position - pull_direction * _grid_layout().cell_size * (0.12 if planned_action == "attack" else 0.06)
	var prep_scale: Vector2 = base_scale * (1.12 if planned_action == "attack" else 1.07)
	var tilt: float = _windup_tilt(direction, planned_action == "attack")
	var windup_tint: Color = Color(1.0, 0.72, 0.68, 1.0) if planned_action == "attack" else Color(1.0, 0.88, 0.62, 1.0)
	var tween := _track_tween(sprite.create_tween())
	tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	if delay > 0.0:
		tween.tween_interval(delay)
	tween.tween_callback(_begin_actor_pose.bind(identifier, role, pose, direction, from_cell, generation))
	tween.tween_callback(_show_enemy_windup.bind(result, generation))
	tween.tween_property(sprite, "position", prep_position, 0.12)
	tween.parallel().tween_property(sprite, "scale", prep_scale, 0.12)
	tween.parallel().tween_property(sprite, "rotation", tilt, 0.12)
	tween.parallel().tween_property(sprite, "modulate", windup_tint, 0.12)
	# Leave the enemy visibly loaded until the next beat.  beat_pulse() will
	# re-anchor the committed pose immediately before the execution resolves.
	tween.tween_property(sprite, "scale", base_scale * (1.04 if planned_action == "attack" else 1.02), 0.18)
	tween.parallel().tween_property(sprite, "rotation", tilt * 0.55, 0.18)
	actor_busy_until[identifier] = Time.get_ticks_msec() / 1000.0 + delay + ENEMY_WINDUP_TIME + 0.02


func _animate_enemy_cancelled(identifier: String, result: Dictionary, delay: float) -> void:
	var sprite: Sprite2D = actor_sprites.get(identifier)
	if sprite == null:
		return
	var generation := presentation_generation
	var role: StringName = actor_roles.get(identifier, &"enemy")
	var direction: Vector2i = result.get("direction", Vector2i.LEFT)
	var from_cell: Vector2i = result.get("from", Vector2i.ZERO)
	var target_cell: Vector2i = result.get("to", from_cell)
	var planned_action := String(result.get("planned_action", result.get("intent", "attack")))
	var idle_pose := _idle_pose(role)
	var base_scale: Vector2 = Vector2.ONE * _actor_scale_factor(role)
	var tween := _track_tween(sprite.create_tween())
	tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	if delay > 0.0:
		tween.tween_interval(delay)
	tween.tween_callback(_begin_actor_pose.bind(identifier, role, idle_pose, direction, from_cell, generation))
	tween.tween_callback(_show_enemy_cancelled.bind(target_cell, planned_action, generation))
	tween.tween_property(sprite, "scale", base_scale * 0.92, ENEMY_CANCEL_TIME * 0.45)
	tween.tween_property(sprite, "scale", base_scale, ENEMY_CANCEL_TIME * 0.55)
	tween.tween_callback(_finish_actor_animation.bind(identifier, role, generation))
	actor_busy_until[identifier] = Time.get_ticks_msec() / 1000.0 + delay + ENEMY_CANCEL_TIME + 0.02


func _animate_enemy_attack(identifier: String, result: Dictionary, delay: float) -> void:
	var sprite: Sprite2D = actor_sprites.get(identifier)
	if sprite == null:
		return
	var generation := presentation_generation
	var role: StringName = actor_roles.get(identifier, &"enemy")
	var direction: Vector2i = result.get("direction", Vector2i.LEFT)
	var from_cell: Vector2i = result.get("from", Vector2i.ZERO)
	var start := _actor_position(from_cell, role, 3, direction)
	var lunge: Vector2 = start + Vector2(direction) * _grid_layout().cell_size * (0.34 if role == &"boss" else 0.40)
	# Regular enemies already spent the previous beat in their windup.  Keep a
	# tiny same-beat prelude only for the Boss, whose legacy one-beat action
	# remains unchanged.
	var windup := minf(0.08, delay) if role == &"boss" else 0.0
	var tween := _track_tween(sprite.create_tween())
	tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	if delay - windup > 0.0:
		tween.tween_interval(delay - windup)
	if role == &"boss":
		tween.tween_callback(_show_enemy_windup.bind(result, generation))
	if windup > 0.0:
		tween.tween_interval(windup)
	tween.tween_callback(_begin_actor_pose.bind(identifier, role, 3, direction, from_cell, generation))
	tween.tween_property(sprite, "position", lunge, ENEMY_ACTION_TIME * 0.5)
	tween.tween_callback(_on_enemy_attack_impact.bind(result, generation))
	tween.tween_property(sprite, "position", start, ENEMY_ACTION_TIME * 0.5)
	tween.tween_callback(_finish_actor_animation.bind(identifier, role, generation))
	actor_busy_until[identifier] = Time.get_ticks_msec() / 1000.0 + delay + ENEMY_ACTION_TIME + 0.02


func _show_mud_fire(result: Dictionary, generation: int) -> void:
	if generation != presentation_generation:
		return
	var spawn_cell: Vector2i = result.get("to", Vector2i.ZERO)
	var direction: Vector2i = result.get("direction", Vector2i.RIGHT)
	_spawn_sheet_effect(MUD_PROJECTILE_SHEET, _cell_center(spawn_cell), 0.92, 0.30, Color.WHITE, 4)
	_spawn_effect(7, _cell_center(spawn_cell), 0.92, 0.28, COLOR_MUD_EDGE)
	_spawn_effect(8, _cell_center(spawn_cell), 0.72, 0.34, COLOR_MUD)
	# The projectile itself is rendered from room_state.mud_projectiles on the
	# next frame; this burst communicates the exact firing beat without adding a
	# second physics owner.
	if bool(result.get("hit", false)):
		show_player_hurt(int(result.get("damage", 1)))
		_start_hurt("player", bool(result.get("killed", false)), spawn_cell, generation)
		_spawn_floating_text("泥浆弹命中", _cell_center(spawn_cell) - Vector2(0, 24), COLOR_MUD_EDGE)
	else:
		_spawn_floating_text("泥浆弹 → %s" % _direction_name(direction), _cell_center(spawn_cell) - Vector2(0, 24), COLOR_MUD_EDGE)


func _show_mud_summon(result: Dictionary, generation: int) -> void:
	if generation != presentation_generation:
		return
	for hazard_cell in result.get("hazard_cells", []):
		_spawn_sheet_effect(BLOOD_SEDIMENT_HAZARD_SHEET, _cell_center(hazard_cell), 0.92, 0.34, Color.WHITE, 4)
		_spawn_effect(8, _cell_center(hazard_cell), 0.78, 0.34, COLOR_MUD_EDGE)


func _show_sweep_windup(result: Dictionary, generation: int) -> void:
	if generation != presentation_generation:
		return
	var boss := room_state.get_boss()
	if boss == null:
		return
	var sprite: Sprite2D = actor_sprites.get(boss.unit_id)
	var boss_center := _boss_visual_center()
	for sweep_cell in result.get("sweep_cells", []):
		_spawn_effect(7, _cell_center(sweep_cell), 0.70, 0.30, Color(COLOR_WARNING, 0.74))
	_spawn_effect(9, boss_center, 2.65, 0.54, Color(1.0, 0.28, 0.24, 0.95))
	_spawn_effect(15, boss_center, 2.20, 0.54, Color(1.0, 0.62, 0.22, 0.84))
	_spawn_floating_text("横扫蓄力 · 外缘 3 格", boss_center - Vector2(0, _grid_layout().cell_size * 1.36), COLOR_WARNING)
	if sprite == null:
		return
	var base_scale := Vector2.ONE * _actor_scale_factor(&"boss")
	var charge_scale := base_scale * 1.18
	_set_pose(sprite, &"boss", 3, boss.facing)
	sprite.position = _actor_position(boss.cell, &"boss", 3, boss.facing)
	var tween := _track_tween(sprite.create_tween())
	tween.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(sprite, "scale", charge_scale, 0.16)
	tween.parallel().tween_property(sprite, "modulate", Color(1.0, 0.46, 0.36, 1.0), 0.16)
	tween.tween_property(sprite, "scale", base_scale * 1.10, 0.24).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.parallel().tween_property(sprite, "modulate", Color(1.0, 0.70, 0.48, 1.0), 0.24)
	actor_busy_until[boss.unit_id] = Time.get_ticks_msec() / 1000.0 + 0.54


func _show_sweep_result(result: Dictionary, generation: int) -> void:
	if generation != presentation_generation:
		return
	var target_cell: Vector2i = result.get("to", room_state.player.cell)
	var hit := bool(result.get("hit", false))
	_spawn_effect(1, _cell_center(target_cell), 1.42, 0.28, COLOR_WARNING if hit else COLOR_AMBER)
	if hit:
		show_player_hurt(int(result.get("damage", 1)))
		_start_hurt("player", bool(result.get("killed", false)), target_cell, generation)
	var boss := room_state.get_boss()
	if boss != null:
		_spawn_effect(1, _boss_visual_center(), 2.25, 0.30, Color(1.0, 0.54, 0.24, 0.90))
		_shake(0.18, 4.2)


func _show_boss_recovery(_result: Dictionary, generation: int) -> void:
	if generation != presentation_generation:
		return
	var boss := room_state.get_boss()
	if boss == null:
		return
	var sprite: Sprite2D = actor_sprites.get(boss.unit_id)
	var boss_center := _boss_visual_center()
	_spawn_effect(10, boss_center, 2.1, 0.32, Color(0.42, 0.88, 0.82, 0.72))
	_spawn_floating_text("横扫后摇 · 安全输出拍", boss_center - Vector2(0, _grid_layout().cell_size * 1.28), Color(0.52, 0.96, 0.82, 1.0))
	if sprite != null:
		var base_scale := Vector2.ONE * _actor_scale_factor(&"boss")
		var tween := _track_tween(sprite.create_tween())
		tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tween.tween_property(sprite, "scale", base_scale * Vector2(1.10, 0.86), 0.12)
		tween.parallel().tween_property(sprite, "modulate", Color(0.66, 0.82, 0.78, 1.0), 0.12)
		tween.tween_property(sprite, "scale", base_scale, 0.18)
		tween.parallel().tween_property(sprite, "modulate", Color.WHITE, 0.18)


func _show_piston_windup(result: Dictionary, generation: int) -> void:
	if generation != presentation_generation:
		return
	var cells: Array = result.get("cells", [])
	if cells.is_empty():
		return
	var axis := String(result.get("axis", "row"))
	var valve_state := String(result.get("valve_state", "red"))
	var tint := Color(1.0, 0.30, 0.28, 0.94) if valve_state == "red" else Color(0.28, 0.78, 1.0, 0.94)
	var center_cell: Vector2i = cells[cells.size() / 2]
	var effect := _spawn_sheet_effect(PISTON_STRIKE_SHEET, _cell_center(center_cell), 0.86, 0.48, tint, 4)
	if effect != null:
		effect.rotation = PI / 2.0 if axis == "column" else 0.0
	_spawn_floating_text("冲压预警 · %s" % ("列" if axis == "column" else "行"), _cell_center(center_cell) - Vector2(0, _grid_layout().cell_size * 0.9), tint)


func _show_piston_strike(result: Dictionary, generation: int) -> void:
	if generation != presentation_generation:
		return
	var cells: Array = result.get("cells", [])
	var axis := String(result.get("axis", "row"))
	var tint := Color(1.0, 0.36, 0.30, 0.98) if String(result.get("valve_state", "red")) == "red" else Color(0.32, 0.84, 1.0, 0.98)
	var stride := maxi(1, cells.size() / 5)
	for index in range(0, cells.size(), stride):
		var cell: Vector2i = cells[index]
		var effect := _spawn_sheet_effect(PISTON_STRIKE_SHEET, _cell_center(cell), 0.94, 0.46, tint, 4)
		if effect != null:
			effect.rotation = PI / 2.0 if axis == "column" else 0.0
	if bool(result.get("hit", false)):
		show_player_hurt(int(result.get("damage", 1)))
		_start_hurt("player", bool(result.get("killed", false)), room_state.player.cell, generation)
	_shake(0.16, 3.5)


func _show_oxygen_charge(result: Dictionary, generation: int) -> void:
	if generation != presentation_generation:
		return
	var boss := room_state.get_boss()
	if boss == null:
		return
	var center := _boss_visual_center()
	var charge_beat := int(result.get("charge_beat", room_state.boss_charge_beat))
	_spawn_sheet_effect(OXYGEN_CHARGE_SHEET, center, 1.45, 0.54, Color(0.66, 0.96, 1.0, 0.98), 4)
	_spawn_floating_text("充能 %d/4 · 可打断" % charge_beat, center - Vector2(0, _grid_layout().cell_size * 1.36), Color(0.48, 0.94, 1.0, 1.0))


func _show_oxygen_blast(result: Dictionary, generation: int) -> void:
	if generation != presentation_generation:
		return
	var boss := room_state.get_boss()
	if boss == null:
		return
	var center := _boss_visual_center()
	_spawn_sheet_effect(PULMONARY_JET_SHEET, center, 1.65, 0.62, Color.WHITE, 4)
	_spawn_effect(15, center, 2.6, 0.48, Color(0.30, 0.90, 1.0, 0.84))
	if bool(result.get("hit", false)):
		show_player_hurt(int(result.get("damage", 1)))
		_start_hurt("player", bool(result.get("killed", false)), room_state.player.cell, generation)
	_shake(0.18, 4.0)


func _show_oxygen_stagger(_result: Dictionary, generation: int) -> void:
	if generation != presentation_generation:
		return
	var boss := room_state.get_boss()
	if boss == null:
		return
	var center := _boss_visual_center()
	_spawn_effect(10, center, 2.0, 0.36, Color(0.42, 0.96, 1.0, 0.86))
	_spawn_floating_text("充能中断", center - Vector2(0, _grid_layout().cell_size * 1.20), Color(0.52, 0.98, 1.0, 1.0))


func _show_spike_windup(result: Dictionary, generation: int) -> void:
	if generation != presentation_generation:
		return
	var cells: Array = result.get("cells", [])
	var direction: Vector2i = result.get("direction", Vector2i.DOWN)
	var tint := Color(0.74, 0.28, 1.0, 0.96)
	var stride := maxi(1, cells.size() / 5)
	for index in range(0, cells.size(), stride):
		var cell: Vector2i = cells[index]
		var effect := _spawn_sheet_effect(GROUND_SPIKE_WAVE_SHEET, _cell_center(cell), 0.94, 0.56, tint, 4)
		if effect != null:
			effect.rotation = Vector2(direction).angle()
	var boss := room_state.get_boss()
	if boss != null:
		_spawn_floating_text("地刺预警", _boss_visual_center() - Vector2(0, _grid_layout().cell_size * 1.36), tint)


func _show_noise_burst(result: Dictionary, generation: int) -> void:
	if generation != presentation_generation:
		return
	var boss := room_state.get_boss()
	if boss == null:
		return
	var center := _boss_visual_center()
	var directions := [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT]
	for direction in directions:
		var effect_position: Vector2 = center + Vector2(direction) * _grid_layout().cell_size * 0.58
		var effect := _spawn_sheet_effect(NOISE_PROJECTILE_SHEET, effect_position, 0.92, 0.50, Color(0.92, 0.40, 1.0, 0.98), 4)
		if effect != null:
			effect.rotation = Vector2(direction).angle()
	_spawn_effect(9, center, 2.2, 0.42, Color(0.90, 0.25, 1.0, 0.78))
	if bool(result.get("hit", false)):
		show_player_hurt(int(result.get("damage", 1)))
		_start_hurt("player", bool(result.get("killed", false)), room_state.player.cell, generation)
	_shake(0.16, 3.8)


func _show_defibrillation(result: Dictionary, generation: int) -> void:
	if generation != presentation_generation:
		return
	var boss := room_state.get_boss()
	if boss == null:
		return
	var center := _boss_visual_center()
	var countdown := int(result.get("countdown", 4))
	_spawn_sheet_effect(DEFIBRILLATION_COUNTDOWN_SHEET, center, 1.65, 0.54, Color.WHITE, 4)
	_spawn_floating_text("除颤 %d" % countdown, center - Vector2(0, _grid_layout().cell_size * 1.36), Color(1.0, 0.44, 0.92, 1.0))


func _show_phase_shift_effect(_result: Dictionary, generation: int) -> void:
	if generation != presentation_generation:
		return
	var boss := room_state.get_boss()
	if boss == null:
		return
	var center := _boss_visual_center()
	_spawn_sheet_effect(DEFIBRILLATION_COUNTDOWN_SHEET, center, 2.15, 0.68, Color(1.0, 0.76, 1.0, 1.0), 4)
	flash(Color(0.88, 0.30, 1.0, 0.26), 0.26)
	_shake(0.22, 5.0)


func _animate_charge(result: Dictionary, delay: float) -> void:
	var sprite: Sprite2D = actor_sprites.get("player")
	if sprite == null:
		return
	var generation := presentation_generation
	var unit := room_state.player
	var idle_pose := _idle_pose(&"player")
	var base_scale: Vector2 = Vector2.ONE * (_grid_layout().cell_size / 32.0)
	var tween := _track_tween(sprite.create_tween())
	if delay > 0.0:
		tween.tween_interval(delay)
	tween.tween_callback(_begin_actor_pose.bind("player", &"player", idle_pose, unit.facing, unit.cell, generation))
	tween.tween_callback(_on_charge_started.bind(bool(result.get("charge_gained", false)), generation))
	tween.tween_property(sprite, "scale", base_scale * 1.13, PLAYER_ACTION_TIME * 0.5).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(sprite, "scale", base_scale, PLAYER_ACTION_TIME * 0.5)
	tween.tween_callback(_finish_actor_animation.bind("player", &"player", generation))
	actor_busy_until["player"] = Time.get_ticks_msec() / 1000.0 + delay + PLAYER_ACTION_TIME + 0.02


func _begin_actor_pose(identifier: String, role: StringName, pose: int, facing: Vector2i, cell: Vector2i, generation: int) -> void:
	if generation != presentation_generation:
		return
	var sprite: Sprite2D = actor_sprites.get(identifier)
	if sprite == null or not is_instance_valid(sprite):
		return
	_set_pose(sprite, role, pose, facing)
	sprite.position = _actor_position(cell, role, pose, facing)
	sprite.visible = true


func _on_move_complete(identifier: String, cell: Vector2i, generation: int) -> void:
	if generation != presentation_generation:
		return
	var tint := Color(0.38, 0.96, 0.76, 0.62) if identifier == "player" else Color(0.72, 0.52, 0.32, 0.38)
	_spawn_effect(8, _cell_center(cell), 0.72, 0.20, tint)


func _on_charge_started(gained: bool, generation: int) -> void:
	if generation != presentation_generation:
		return
	_spawn_effect(9, _cell_center(room_state.player.cell), 1.12, 0.36, Color(1.0, 0.72, 0.25, 0.92))
	_spawn_floating_text("CHARGE" if gained else "CHARGE MAX", _cell_center(room_state.player.cell) - Vector2(0, 26), COLOR_AMBER)


func _on_player_attack_impact(result: Dictionary, generation: int) -> void:
	if generation != presentation_generation:
		return
	var direction: Vector2i = result.get("direction", Vector2i.RIGHT)
	var target_cell: Vector2i = result.get("to", room_state.player.cell)
	var charged_attack := bool(result.get("charged_attack", false))
	_spawn_effect(_slash_effect_index(direction), _cell_center(target_cell), 1.55 if charged_attack else 1.25, 0.28, Color(1.0, 0.88, 0.48, 1.0) if charged_attack else Color.WHITE)
	_spawn_floating_text("-%d" % int(result.get("damage", 0)), _cell_center(target_cell) - Vector2(0, 24), COLOR_AMBER if charged_attack else Color.WHITE)
	_shake(0.14 if charged_attack else 0.08, 3.6 if charged_attack else 1.8)
	var target_id := String(result.get("target_id", ""))
	if target_id != "":
		_start_hurt(target_id, bool(result.get("killed", false)), target_cell, generation)


func _on_clash_impact(result: Dictionary, generation: int) -> void:
	if generation != presentation_generation:
		return
	var player_cell: Vector2i = result.get("from", room_state.player.cell)
	var enemy_cell: Vector2i = result.get("to", player_cell)
	var direction: Vector2i = result.get("direction", Vector2i.RIGHT)
	var midpoint := (_cell_center(player_cell) + _cell_center(enemy_cell)) * 0.5
	# Existing art supplies directional slashes and a generic impact spark, but
	# not a dedicated multi-frame weapon-clash effect. Layer those assets and let
	# the simultaneous attack poses, hit-stop and recoil communicate the parry.
	_spawn_effect(_slash_effect_index(direction), midpoint, 1.12, 0.24, Color(0.58, 1.0, 0.94, 0.88))
	_spawn_effect(_slash_effect_index(-direction), midpoint, 1.12, 0.24, Color(1.0, 0.73, 0.34, 0.88))
	_spawn_sheet_effect(CLASH_SHEET, midpoint, 1.82, 0.34, Color(1.0, 0.96, 0.72, 1.0), 4)
	_spawn_effect(10, midpoint, 1.16, 0.42, Color(0.48, 1.0, 0.90, 0.76))
	var player: Sprite2D = actor_sprites.get("player")
	var enemy: Sprite2D = actor_sprites.get(String(result.get("target_id", "")))
	if player != null:
		player.modulate = Color(0.70, 1.0, 0.94, 1.0)
	if enemy != null:
		enemy.modulate = Color(1.0, 0.72, 0.40, 1.0)
	flash(Color(1.0, 0.86, 0.45, 0.20), 0.18)
	_shake(0.22, 5.0)


func _show_enemy_windup(result: Dictionary, generation: int) -> void:
	if generation != presentation_generation:
		return
	var target_cell: Vector2i = result.get("to", room_state.player.cell)
	var planned_action := String(result.get("planned_action", result.get("intent", "move")))
	var effect_color := Color(1.0, 0.28, 0.25, 0.82) if planned_action == "attack" else Color(1.0, 0.68, 0.25, 0.76)
	_spawn_effect(7 if planned_action == "attack" else 8, _cell_center(target_cell), 1.08 if planned_action == "attack" else 0.82, 0.22, effect_color)
	var caption := "举刀 · 下一拍攻击" if planned_action == "attack" else ("蓄势 · 下一拍泥浆" if planned_action == "mud" else "蓄势 · 下一拍追击")
	_spawn_floating_text(caption, _cell_center(target_cell) - Vector2(0, 24), effect_color)


func _show_enemy_cancelled(target_cell: Vector2i, planned_action: String, generation: int) -> void:
	if generation != presentation_generation:
		return
	var color := Color(0.46, 0.88, 0.92, 0.86) if planned_action == "attack" else Color(1.0, 0.72, 0.30, 0.84)
	_spawn_effect(10, _cell_center(target_cell), 0.92, 0.24, color)
	_spawn_floating_text("挥空 · 已躲开" if planned_action == "attack" else "追击受阻", _cell_center(target_cell) - Vector2(0, 24), Color(color, 1.0))


func _on_enemy_attack_impact(result: Dictionary, generation: int) -> void:
	if generation != presentation_generation:
		return
	var target_cell: Vector2i = result.get("to", room_state.player.cell)
	_spawn_effect(0, _cell_center(target_cell), 1.1, 0.24, Color(1.0, 0.66, 0.34, 0.92))
	if bool(result.get("shielded", false)):
		show_shield_block()
	else:
		var damage := int(result.get("damage", 0))
		show_player_hurt(damage)
		_start_hurt("player", bool(result.get("killed", false)), target_cell, generation)


func _start_hurt(identifier: String, killed: bool, cell: Vector2i, generation: int) -> void:
	if generation != presentation_generation:
		return
	var sprite: Sprite2D = actor_sprites.get(identifier)
	if sprite == null or not is_instance_valid(sprite):
		return
	var role: StringName = actor_roles.get(identifier, &"enemy")
	var unit: MvpUnitState = room_state.player if identifier == "player" else _find_unit(identifier)
	var facing := unit.facing if unit != null else Vector2i.DOWN
	var state_texture := _single_state_texture(role, killed, facing)
	_set_single_pose(sprite, role, killed, facing)
	if state_texture != null:
		sprite.position = _state_actor_position(cell, role, killed, facing)
	elif role == &"boss":
		# Keep the documented Boss fallback on the atlas attack pose aligned.
		sprite.position = _actor_position(cell, role, 3, facing)
	sprite.modulate = Color.WHITE
	actor_busy_until[identifier] = maxf(float(actor_busy_until.get(identifier, 0.0)), Time.get_ticks_msec() / 1000.0 + (0.36 if killed else 0.10))
	if killed:
		_spawn_effect(5, sprite.position, 1.25 if role == &"boss" else 1.1, 0.34, Color(1.0, 0.42, 0.34, 0.95))
		var death_tween := _track_tween(sprite.create_tween())
		death_tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		death_tween.tween_property(sprite, "scale", Vector2.ZERO, 0.34)
		death_tween.parallel().tween_property(sprite, "modulate:a", 0.0, 0.34)
		death_tween.tween_callback(_hide_sprite.bind(sprite, generation))
		return
	sprite.modulate = Color(1.0, 0.40, 0.40, 1.0)
	var original_scale: Vector2 = Vector2.ONE * _actor_scale_factor(role)
	var hurt_tween := _track_tween(sprite.create_tween())
	hurt_tween.tween_property(sprite, "modulate", Color.WHITE, 0.09)
	hurt_tween.tween_callback(_finish_hurt_animation.bind(identifier, role, original_scale, cell, facing, generation))


func _finish_actor_animation(identifier: String, role: StringName, generation: int) -> void:
	if generation != presentation_generation:
		return
	var sprite: Sprite2D = actor_sprites.get(identifier)
	if sprite == null or not is_instance_valid(sprite):
		return
	var unit: MvpUnitState = room_state.player if identifier == "player" else _find_unit(identifier)
	if unit != null and unit.is_alive():
		var idle_pose := _idle_pose(role)
		_set_pose(sprite, role, idle_pose, unit.facing)
		sprite.position = _actor_position(unit.cell, role, idle_pose, unit.facing)


func _finish_hurt_animation(identifier: String, role: StringName, original_scale: Vector2, cell: Vector2i, facing: Vector2i, generation: int) -> void:
	if generation != presentation_generation:
		return
	var sprite: Sprite2D = actor_sprites.get(identifier)
	var unit: MvpUnitState = room_state.player if identifier == "player" else _find_unit(identifier)
	if sprite == null or unit == null or not unit.is_alive():
		return
	var idle_pose := _idle_pose(role)
	_set_pose(sprite, role, idle_pose, facing)
	sprite.scale = original_scale
	sprite.position = _actor_position(cell, role, idle_pose, facing)


func _hide_sprite(sprite: Sprite2D, generation: int) -> void:
	if generation == presentation_generation and is_instance_valid(sprite):
		sprite.visible = false


func _schedule_room_clear(delay: float, clear_position: Vector2) -> void:
	var generation := presentation_generation
	var tween := _track_tween(create_tween())
	tween.tween_interval(delay)
	tween.tween_callback(_show_room_clear_if_current.bind(generation, clear_position))


func _show_room_clear_if_current(generation: int, clear_position: Vector2) -> void:
	if generation == presentation_generation:
		show_room_clear(clear_position)


func _spawn_effect(cell_index: int, effect_position: Vector2, scale_factor: float, duration: float, tint: Color) -> void:
	var effect := Sprite2D.new()
	effect.texture = EFFECTS_ATLAS
	effect.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	effect.region_enabled = true
	effect.region_rect = Rect2((cell_index % 4) * 32, floori(float(cell_index) / 4.0) * 32, 32, 32)
	effect.position = effect_position
	effect.scale = Vector2.ONE * (_grid_layout().cell_size / 32.0) * scale_factor
	effect.modulate = tint
	effect.z_index = 12
	actor_layer.add_child(effect)
	var tween := _track_tween(effect.create_tween())
	tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(effect, "scale", effect.scale * 1.22, duration * 0.45)
	tween.parallel().tween_property(effect, "modulate:a", 0.0, duration)
	tween.tween_callback(effect.queue_free)


func _spawn_sheet_effect(texture: Texture2D, effect_position: Vector2, scale_factor: float, duration: float, tint: Color, frame_count: int) -> Sprite2D:
	if texture == null or frame_count <= 0:
		return null
	var effect := Sprite2D.new()
	effect.texture = texture
	effect.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	effect.centered = true
	effect.hframes = frame_count
	effect.vframes = 1
	effect.frame = 0
	effect.scale = Vector2.ONE * (_grid_layout().cell_size / 32.0) * scale_factor
	# Generated effect frames can carry asymmetric transparent padding. Anchor
	# the first visible silhouette to the requested logical center as well.
	effect.position = effect_position - _sheet_frame_offset(texture, 0, frame_count) * effect.scale
	effect.modulate = tint
	effect.z_index = 13
	actor_layer.add_child(effect)
	var tween := _track_tween(effect.create_tween())
	tween.set_trans(Tween.TRANS_LINEAR).set_ease(Tween.EASE_IN_OUT)
	# Generated sheets already reserve their last frame for fragments/fade.
	# Keep the readable windup and impact frames fully opaque, then fade only
	# during the short tail instead of washing out the entire animation.
	tween.tween_method(_set_sheet_frame.bind(effect), 0.0, float(frame_count - 1), duration * 0.78)
	tween.tween_property(effect, "modulate:a", 0.0, duration * 0.22)
	tween.tween_callback(effect.queue_free)
	return effect


func _set_sheet_frame(value: float, effect: Sprite2D) -> void:
	if is_instance_valid(effect):
		effect.frame = clampi(roundi(value), 0, effect.hframes - 1)


func _spawn_floating_text(message: String, text_position: Vector2, color: Color) -> void:
	var label := Label.new()
	label.text = message
	label.position = text_position - Vector2(40.0, 12.0)
	label.size = Vector2(80.0, 24.0)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_outline_color", Color(0.02, 0.025, 0.02, 0.9))
	label.add_theme_constant_override("outline_size", 4)
	label.add_theme_font_size_override("font_size", 16)
	feedback_layer.add_child(label)
	var tween := _track_tween(label.create_tween())
	tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(label, "position", label.position - Vector2(0, 22), 0.55)
	tween.parallel().tween_property(label, "modulate:a", 0.0, 0.55)
	tween.tween_callback(label.queue_free)


func _find_unit(identifier: String) -> MvpUnitState:
	if room_state == null:
		return null
	for enemy in room_state.enemies:
		if enemy.unit_id == identifier:
			return enemy
	return null


func _idle_pose(role: StringName) -> int:
	if role == &"boss":
		return 1
	return 0


func _enemy_plan_pose(unit: MvpUnitState) -> int:
	if unit.enemy_plan == &"attack":
		return 3
	return _enemy_step_pose()


func _enemy_step_pose() -> int:
	return 1 if room_state != null and room_state.turn_number % 2 == 0 else 2


func _windup_tilt(direction: Vector2i, attack: bool) -> float:
	if not attack:
		return 0.0
	if direction == Vector2i.LEFT:
		return 0.08
	if direction == Vector2i.RIGHT:
		return -0.08
	return 0.045 if direction == Vector2i.UP else -0.045


func _track_tween(tween: Tween) -> Tween:
	presentation_tweens.append(tween)
	tween.finished.connect(_forget_tween.bind(tween), CONNECT_ONE_SHOT)
	return tween


func _forget_tween(tween: Tween) -> void:
	presentation_tweens.erase(tween)


func _cancel_presentations() -> void:
	presentation_generation += 1
	for tween in presentation_tweens:
		if tween != null and tween.is_valid():
			tween.kill()
	presentation_tweens.clear()
	actor_busy_until.clear()


func _is_actor_free(identifier: String) -> bool:
	var now := Time.get_ticks_msec() / 1000.0
	return float(actor_busy_until.get(identifier, 0.0)) <= now


func _actor_position(cell: Vector2i, role: StringName, pose: int, facing: Vector2i) -> Vector2:
	var correction := _frame_correction(role, pose, facing)
	var scale_factor: float = _actor_scale_factor(role)
	# Boss logical occupancy stays integer-cell based for combat, but its visual
	# anchor follows the actual board midpoint. This matters on even-width maps
	# such as 3F, whose visual center falls between two cells.
	var anchor := _board_center() if role == &"boss" and room_state.layer_index > StateScript.LAYER_ONE else _cell_center(cell)
	return anchor + correction * scale_factor


func _actor_scale_factor(role: StringName) -> float:
	var cell_size: float = _grid_layout().cell_size
	# The first-layer Boss has a real 3x3 logical footprint. Its 64px source
	# frame is scaled to that same three-cell span around the center cell.
	return cell_size * 3.0 / 64.0 if role == &"boss" else cell_size / 32.0


func _frame_correction(role: StringName, pose: int, facing: Vector2i) -> Vector2:
	var row := _direction_row(facing)
	var frame_size := 64 if role == &"boss" else 32
	# Every actor sheet has independently padded generated frames. Derive both
	# axes from the current opaque silhouette for player, crawler, slug and Boss
	# so the art center, not the transparent canvas center, sits on the grid.
	var offset := _opaque_frame_offset(_sheet_for_role(role), row, pose, frame_size)
	return -offset if offset != Vector2.INF else Vector2.ZERO


func _opaque_frame_offset(texture: Texture2D, row: int, pose: int, frame_size: int) -> Vector2:
	if texture == null or frame_size <= 0:
		return Vector2.INF
	var key := "%s:%d:%d:%d" % [texture.resource_path, frame_size, row, clampi(pose, 0, 3)]
	if _opaque_frame_offsets.has(key):
		return _opaque_frame_offsets[key] as Vector2
	var image: Image = texture.get_image()
	if image == null:
		return Vector2.INF
	var frame_origin := Vector2i(clampi(pose, 0, 3) * frame_size, row * frame_size)
	if frame_origin.x < 0 or frame_origin.y < 0 or frame_origin.x + frame_size > image.get_width() or frame_origin.y + frame_size > image.get_height():
		return Vector2.INF
	var min_pixel := Vector2i(frame_size, frame_size)
	var max_pixel := Vector2i(-1, -1)
	for y in range(frame_size):
		for x in range(frame_size):
			if image.get_pixel(frame_origin.x + x, frame_origin.y + y).a > 0.01:
				min_pixel.x = mini(min_pixel.x, x)
				min_pixel.y = mini(min_pixel.y, y)
				max_pixel.x = maxi(max_pixel.x, x)
				max_pixel.y = maxi(max_pixel.y, y)
	if max_pixel.x < 0:
		return Vector2.INF
	var opaque_center := Vector2(
			float(min_pixel.x + max_pixel.x + 1) * 0.5,
			float(min_pixel.y + max_pixel.y + 1) * 0.5
	)
	var offset := opaque_center - Vector2.ONE * frame_size * 0.5
	_opaque_frame_offsets[key] = offset
	return offset


func _opaque_texture_offset(texture: Texture2D) -> Vector2:
	if texture == null:
		return Vector2.INF
	var key := texture.resource_path
	if _opaque_texture_offsets.has(key):
		return _opaque_texture_offsets[key] as Vector2
	var image := texture.get_image()
	if image == null or image.is_empty():
		return Vector2.INF
	var min_pixel := Vector2i(image.get_width(), image.get_height())
	var max_pixel := Vector2i(-1, -1)
	for y in range(image.get_height()):
		for x in range(image.get_width()):
			if image.get_pixel(x, y).a > 0.01:
				min_pixel.x = mini(min_pixel.x, x)
				min_pixel.y = mini(min_pixel.y, y)
				max_pixel.x = maxi(max_pixel.x, x)
				max_pixel.y = maxi(max_pixel.y, y)
	if max_pixel.x < 0:
		return Vector2.INF
	var opaque_center := Vector2(
		float(min_pixel.x + max_pixel.x + 1) * 0.5,
		float(min_pixel.y + max_pixel.y + 1) * 0.5
	)
	var offset := opaque_center - Vector2(image.get_width(), image.get_height()) * 0.5
	_opaque_texture_offsets[key] = offset
	return offset


func get_texture_visual_centroid_offset(texture: Texture2D) -> Vector2:
	if texture == null:
		return Vector2.INF
	var key := texture.resource_path
	if _texture_visual_centroid_offsets.has(key):
		return _texture_visual_centroid_offsets[key] as Vector2
	var image := texture.get_image()
	if image == null or image.is_empty():
		return Vector2.INF
	var weighted_position := Vector2.ZERO
	var total_alpha := 0.0
	for y in range(image.get_height()):
		for x in range(image.get_width()):
			var alpha := image.get_pixel(x, y).a
			if alpha <= 0.01:
				continue
			weighted_position += Vector2(float(x) + 0.5, float(y) + 0.5) * alpha
			total_alpha += alpha
	if total_alpha <= 0.0:
		return Vector2.INF
	var visual_centroid := weighted_position / total_alpha
	var offset := visual_centroid - Vector2(image.get_width(), image.get_height()) * 0.5
	_texture_visual_centroid_offsets[key] = offset
	return offset


func _sheet_frame_offset(texture: Texture2D, frame: int, frame_count: int) -> Vector2:
	if texture == null or frame_count <= 0:
		return Vector2.ZERO
	var key := "%s:horizontal:%d:%d" % [texture.resource_path, frame_count, frame]
	if _opaque_frame_offsets.has(key):
		return _opaque_frame_offsets[key] as Vector2
	var image := texture.get_image()
	if image == null or image.is_empty():
		return Vector2.ZERO
	var frame_size := floori(float(image.get_width()) / float(frame_count))
	var frame_origin := Vector2i(clampi(frame, 0, frame_count - 1) * frame_size, 0)
	var min_pixel := Vector2i(frame_size, image.get_height())
	var max_pixel := Vector2i(-1, -1)
	for y in range(image.get_height()):
		for x in range(frame_size):
			if image.get_pixel(frame_origin.x + x, y).a > 0.01:
				min_pixel.x = mini(min_pixel.x, x)
				min_pixel.y = mini(min_pixel.y, y)
				max_pixel.x = maxi(max_pixel.x, x)
				max_pixel.y = maxi(max_pixel.y, y)
	if max_pixel.x < 0:
		return Vector2.ZERO
	var opaque_center := Vector2(
		float(min_pixel.x + max_pixel.x + 1) * 0.5,
		float(min_pixel.y + max_pixel.y + 1) * 0.5
	)
	var offset := opaque_center - Vector2(float(frame_size), float(image.get_height())) * 0.5
	_opaque_frame_offsets[key] = offset
	return offset


func _direction_row(direction: Vector2i) -> int:
	if direction == Vector2i.UP:
		return 3
	if direction == Vector2i.LEFT:
		return 1
	if direction == Vector2i.RIGHT:
		return 2
	return 0


func _slash_effect_index(direction: Vector2i) -> int:
	if direction == Vector2i.LEFT:
		return 1
	if direction == Vector2i.RIGHT:
		return 2
	if direction == Vector2i.UP:
		return 3
	return 0


func _grid_layout() -> Dictionary:
	return room_state.map_definition.get_grid_layout(size)


func _board_center() -> Vector2:
	return room_state.map_definition.get_board_center(size)


func _scene_rect() -> Rect2:
	return room_state.map_definition.get_scene_rect(size)


func _cell_center(cell: Vector2i, origin: Vector2 = Vector2.INF, cell_size: float = -1.0) -> Vector2:
	var actual_origin := origin
	var actual_cell_size := cell_size
	if origin == Vector2.INF:
		var layout := _grid_layout()
		actual_origin = layout.origin
		actual_cell_size = layout.cell_size
	return actual_origin + Vector2(cell) * actual_cell_size + Vector2.ONE * actual_cell_size * 0.5


func _shake(duration: float, strength: float) -> void:
	shake_time = maxf(shake_time, duration)
	shake_strength = maxf(shake_strength, strength)


func flash(color: Color, duration: float) -> void:
	flash_color = color
	flash_time = maxf(flash_time, duration)
