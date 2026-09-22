extends SceneTree

const StateScript = preload("res://scripts/mvp/mvp_state.gd")
const MvpScene = preload("res://scenes/mvp/mvp_run.tscn")
const BeatClockScript = preload("res://scripts/proto_001/beat_clock.gd")
const RhythmHudScript = preload("res://scripts/mvp/mvp_rhythm_hud.gd")
const SettingsScript = preload("res://scripts/mvp/mvp_settings.gd")
const TRANSITION_ATRIUM_TO_VENTRICLE = preload("res://assets/transitions/trans_atrium_to_ventricle.png")
const TRANSITION_VENTRICLE_TO_ATRIUM = preload("res://assets/transitions/trans_ventricle_to_atrium.png")
const TRANSITION_ATRIUM_TO_VENTRICLE4 = preload("res://assets/transitions/trans_atrium_to_ventricle4.png")
const TRANSITION_ENDING_REVIVAL = preload("res://assets/transitions/trans_ending_revival.png")
var failures: Array[String] = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	_test_room_route_and_combat()
	_test_beat_input_ownership()
	_test_regular_enemy_two_beat_cadence()
	_test_reward_and_guard()
	_test_global_reward_order_and_persistence()
	_test_charge_and_rhythm_shield()
	_test_boss_phase()
	_test_non_box_telegraph_source()
	_test_scene_boot_and_input()
	_test_menu_and_settings()
	_test_room_boundary_and_portal_alignment()
	_test_map_definition_contract()
	_test_pause_and_charge_bindings()
	_test_formal_hud_and_rhythm_track()
	_test_scene_clash_feedback()
	_test_scene_blocked_chase_feedback()
	_test_directional_state_assets()
	_test_directional_state_anchors()
	_test_scene_charge_and_shield_assist()
	_test_scene_death_restart()
	_test_scene_reward_route_and_lock()
	_test_transition_asset_mapping()
	_test_scene_boss_player_death_bpm_reset()
	_test_scene_boss_phase_and_victory()
	await _test_visual_layout_contracts()
	await _test_delayed_presentation_safety()
	if failures.is_empty():
		print("MVP_SMOKE_OK | first_layer_right_atrium five_rooms combat wordless_parry art_tile_grid right_wall_exit generated_fx full_floor_boundary all_actor_visual_centers map_core_visual_center ending_core_visual_center centered_hazards no_box_telegraphs boss_3x3_footprint sweep_three_cell_range visible_sweep_charge no_suction recovery_beat vertical_tween_actual arrival_constant_scale animated_transition pause_shift_charge pause_menu_buttons escape_pause central_boss_portal explicit_interaction single_clear_feedback formal_hud boss_health concise_boss_label combat_only_bpm fast_falling_track centered_reward_cards global_reward_order title_only_hud_key_hint story_endings leech_crawler spit_slug mud_projectile mud_hazard_duration venous_glutton 90_bpm rhythm_shield piercing_wave guard_combo reward_icons buffs action_timeline scene transitions transition_assets no_upper_layer_tint no_transition_color_blocks")
		quit(0)
		return
	for failure in failures:
		push_error("MVP_SMOKE_FAIL | " + failure)
	quit(1)


func _test_room_route_and_combat() -> void:
	var state := StateScript.new()
	_expect(state.room_kind == StateScript.ROOM_START, "starts in start room")
	_expect(state.enter_next_room(), "enters normal room")
	_expect(state.room_kind == StateScript.ROOM_NORMAL, "normal room index")
	var enemy: MvpUnitState = state.enemies[0]
	state.player.cell = Vector2i(5, 1)
	enemy.cell = Vector2i(6, 1)
	var result := state.resolve_turn(&"direction", Vector2i.RIGHT)
	_expect(result.player.kind == "attack", "normal room attack")
	_expect(enemy.hp == 2, "normal enemy takes damage")
	_expect(result.enemies.size() == 1 and result.enemies[0].kind == "windup", "normal enemy spends first beat telegraphing")
	_expect(result.enemies[0].planned_action == "attack", "normal enemy telegraphs attack plan")
	_expect(state.player.hp == state.player.max_hp, "enemy does not hit during windup")
	result = state.resolve_turn(&"wait")
	_expect(result.enemies.size() == 1 and result.enemies[0].kind == "attack", "normal enemy attacks on second beat")
	_expect(state.player.hp == state.player.max_hp - 1, "enemy answers on execution beat")
	enemy.hp = 1
	enemy.clear_enemy_plan()
	result = state.resolve_turn(&"direction", Vector2i.RIGHT)
	_expect(result.room_cleared, "last normal enemy clears room")
	_expect(result.enemies.is_empty(), "dead enemy skips turn")
	_expect(state.room_cleared, "cleared room keeps its exit open")
	result = state.resolve_turn(&"direction", Vector2i.LEFT)
	_expect(not result.room_cleared, "clear feedback is not emitted again while walking to the exit")
	_expect(state.enter_next_room(), "enters reward room")
	_expect(state.room_kind == StateScript.ROOM_REWARD, "reward room index")
	_expect(state.player.hp == state.player.max_hp - 1, "hp carries between rooms")
	_expect(state.choose_reward(1).accepted, "tempo reward accepted")
	_expect(state.buffs.tempo, "tempo reward stored")
	_expect(state.player.attack_damage == 1, "tempo reward keeps baseline damage")
	_expect(state.enter_next_room(), "enters hard room")
	_expect(state.room_kind == StateScript.ROOM_HARD, "hard room index")
	_expect(state.enemies.size() == 2, "hard room has two enemies")
	var ranged_enemy: MvpUnitState = state.enemies[0]
	state.player.cell = Vector2i(5, 1)
	ranged_enemy.cell = Vector2i(7, 1)
	var ranged_result := state.resolve_turn(&"direction", Vector2i.RIGHT)
	_expect(ranged_result.player.kind == "attack", "tempo reward attacks through one empty cell")
	_expect(ranged_result.player.target_id == ranged_enemy.unit_id and ranged_result.player.to == ranged_enemy.cell, "tempo reward reaches the second cell")
	_expect(ranged_enemy.hp == ranged_enemy.max_hp - 1 and state.player.cell == Vector2i(5, 1), "tempo range attack preserves player cell")
	state.room_cleared = true
	_expect(state.enter_next_room(), "enters boss room after hard clear")
	_expect(state.room_kind == StateScript.ROOM_BOSS, "boss room index")
	_expect(state.get_boss() != null and state.get_boss().unit_id == "boss", "first-layer boss uses stable actor id")
	state.room_cleared = true
	state.player.cell = Vector2i(5, 2)
	_expect(state.is_near_next_layer_portal(), "cleared Boss room exposes a central next-layer portal")
	_expect(state.room_kind == StateScript.ROOM_BOSS, "Boss room remains the transition room")


func _test_beat_input_ownership() -> void:
	var clock := BeatClockScript.new()
	clock.bpm = 120.0
	clock.timing_window = 0.10
	clock.lead_in_beats = 1
	clock.start(10.0)
	clock.advance_to(10.61)
	_expect(clock.beat_number == 2, "clock advances after the first beat resolves")
	var stale_late := clock.get_input_timing(10.70)
	_expect(stale_late.target_beat == 1, "late previous input is not assigned to current beat")
	var normal_next := clock.get_input_timing(10.90)
	_expect(normal_next.target_beat == 2, "current beat early window remains usable")
	_expect(normal_next.judgement == clock.TimingJudgement.HIT, "current beat still accepts a normal input")
	clock.chart_offset_seconds = 0.075
	_expect(is_equal_approx(clock.get_judgement_center_time(), 11.075), "mvp chart offset moves judgement center")
	clock.stop()
	clock.free()


func _test_regular_enemy_two_beat_cadence() -> void:
	# Movement also follows the same two-beat contract: telegraph first, then
	# move one cell.  The player can leave a locked attack target before beat 2.
	var move_state := StateScript.new()
	move_state.enter_next_room()
	var mover: MvpUnitState = move_state.enemies[0]
	move_state.player.cell = Vector2i(1, 2)
	mover.cell = Vector2i(6, 3)
	mover.clear_enemy_plan()
	var result := move_state.resolve_turn(&"wait")
	_expect(result.enemies[0].kind == "windup", "distant enemy telegraphs movement")
	_expect(result.enemies[0].planned_action == "move", "distant enemy stores movement plan")
	_expect(mover.cell == Vector2i(6, 3), "movement windup keeps enemy in place")
	result = move_state.resolve_turn(&"wait")
	_expect(result.enemies[0].kind == "move", "distant enemy moves on second beat")
	_expect(mover.cell == Vector2i(5, 3), "movement execution advances one cell")

	var dodge_state := StateScript.new()
	dodge_state.enter_next_room()
	var attacker: MvpUnitState = dodge_state.enemies[0]
	dodge_state.player.cell = Vector2i(5, 1)
	attacker.cell = Vector2i(6, 1)
	attacker.clear_enemy_plan()
	result = dodge_state.resolve_turn(&"wait")
	_expect(result.enemies[0].kind == "windup" and result.enemies[0].planned_action == "attack", "adjacent enemy raises weapon first")
	var hp_before_dodge := dodge_state.player.hp
	result = dodge_state.resolve_turn(&"direction", Vector2i.DOWN)
	_expect(result.player.kind == "move", "player can move during enemy windup")
	_expect(result.enemies[0].cancelled, "enemy attack cancels after target moves")
	_expect(dodge_state.player.hp == hp_before_dodge, "dodging the windup avoids damage")
	_expect(attacker.enemy_plan == &"none", "cancelled attack clears plan")

	# Re-enter range and verify that a fresh two-beat attack still lands.
	dodge_state.player.cell = Vector2i(5, 1)
	attacker.cell = Vector2i(6, 1)
	attacker.clear_enemy_plan()
	result = dodge_state.resolve_turn(&"wait")
	_expect(result.enemies[0].kind == "windup", "enemy can re-arm after a dodge")
	result = dodge_state.resolve_turn(&"wait")
	_expect(result.enemies[0].kind == "attack", "re-armed attack executes on next beat")
	_expect(dodge_state.player.hp == hp_before_dodge - 1, "re-armed attack deals damage")

	# A locked chase target is also deterministic: if the player steps onto the
	# destination before beat two, the enemy stays put and reports a blocked
	# chase rather than silently retargeting.
	var blocked_state := StateScript.new()
	blocked_state.enter_next_room()
	var blocked_enemy: MvpUnitState = blocked_state.enemies[0]
	blocked_state.player.cell = Vector2i(2, 2)
	blocked_enemy.cell = Vector2i(4, 2)
	var blocked_windup := blocked_state.resolve_turn(&"wait")
	_expect(blocked_windup.enemies[0].planned_action == "move", "chase locks a destination on windup")
	blocked_state.player.cell = Vector2i(2, 2)
	var blocked_result := blocked_state.resolve_turn(&"direction", Vector2i.RIGHT)
	_expect(blocked_result.player.kind == "move", "player can occupy a locked chase destination")
	_expect(blocked_result.enemies[0].kind == "none" and blocked_result.enemies[0].cancelled, "locked chase cancels when destination is occupied")
	_expect(blocked_result.enemies[0].reason == "blocked", "blocked chase reports its reason")

	# Meeting a telegraphed attack with a same-direction attack produces a weapon
	# clash. Neither combatant takes damage and a stored charge is not consumed.
	var clash_state := StateScript.new()
	clash_state.enter_next_room()
	var duelist: MvpUnitState = clash_state.enemies[0]
	clash_state.player.cell = Vector2i(5, 1)
	duelist.cell = Vector2i(6, 1)
	clash_state.charged = true
	var clash_windup := clash_state.resolve_turn(&"wait")
	_expect(clash_windup.enemies[0].kind == "windup", "duelist telegraphs before a clash")
	var player_hp_before := clash_state.player.hp
	var enemy_hp_before := duelist.hp
	var clash_result := clash_state.resolve_turn(&"direction", Vector2i.RIGHT)
	_expect(clash_result.player.kind == "clash", "attacking into execution creates a clash")
	_expect(clash_result.enemies.size() == 1 and clash_result.enemies[0].kind == "parried", "enemy execution is reported as parried")
	_expect(clash_result.enemies[0].parried and clash_result.enemies[0].damage == 0, "parried attack deals no damage")
	_expect(clash_state.player.hp == player_hp_before and duelist.hp == enemy_hp_before, "clash preserves both health values")
	_expect(clash_state.charged, "clash retains stored charge")
	_expect(duelist.enemy_plan == &"none", "clash consumes the enemy attack plan")
	var rearm_result := clash_state.resolve_turn(&"wait")
	_expect(rearm_result.enemies[0].kind == "windup", "enemy starts a fresh windup after a clash")

	# The hard-room Spit Slug stays in place and fires on a four-beat cycle.
	var slug_state := StateScript.new()
	slug_state.enter_next_room()
	slug_state.room_cleared = true
	slug_state.enter_next_room()
	slug_state.room_cleared = true
	slug_state.enter_next_room()
	var slug: MvpUnitState = slug_state.enemies[1]
	_expect(slug.role == &"slug", "hard room includes a stationary spit slug")
	for beat in range(2):
		var idle_result := slug_state.resolve_turn(&"wait")
		_expect(idle_result.enemies[1].kind == "hold", "spit slug holds before its telegraph")
	var slug_windup := slug_state.resolve_turn(&"wait")
	_expect(slug_windup.enemies[1].kind == "mud_windup", "spit slug telegraphs on beat three")
	var slug_fire := slug_state.resolve_turn(&"wait")
	_expect(slug_fire.enemies[1].kind == "mud_fire", "spit slug fires on beat four")
	_expect(slug_state.mud_projectiles.size() == 1, "mud projectile enters the room")
	var projectile_start: Vector2i = slug_state.mud_projectiles[0].cell
	slug_state.resolve_turn(&"wait")
	_expect(slug_state.mud_projectiles.size() == 1 and slug_state.mud_projectiles[0].cell != projectile_start, "mud projectile advances one cell per beat")
	var projectile_next: Vector2i = slug_state.mud_projectiles[0].cell + slug_state.mud_projectiles[0].direction
	slug_state.player.cell = projectile_next
	var mud_hit := slug_state.resolve_turn(&"wait")
	_expect(mud_hit.environment.size() == 1 and mud_hit.environment[0].kind == "mud_hit", "mud projectile reports a hit event")
	_expect(slug_state.player.hp == slug_state.player.max_hp - StateScript.MUD_PROJECTILE_DAMAGE, "mud projectile damages the player on contact")
	_expect(slug_state._is_mud_hazard(projectile_next), "mud projectile leaves a temporary hazard")
	slug_state.resolve_turn(&"wait")
	_expect(slug_state._is_mud_hazard(projectile_next), "mud hazard remains for its short duration")
	slug_state.resolve_turn(&"wait")
	_expect(slug_state._is_mud_hazard(projectile_next), "mud hazard remains dangerous for two subsequent beats")
	slug_state.resolve_turn(&"wait")
	_expect(not slug_state._is_mud_hazard(projectile_next), "mud hazard expires after its duration")

	# Firing into an adjacent player cell resolves as an immediate hit instead
	# of spawning a projectile behind the player and silently missing.
	var direct_hit_state := StateScript.new()
	direct_hit_state.enter_next_room()
	direct_hit_state.room_cleared = true
	direct_hit_state.enter_next_room()
	direct_hit_state.room_cleared = true
	direct_hit_state.enter_next_room()
	var direct_slug: MvpUnitState = direct_hit_state.enemies[1]
	direct_slug.cell = Vector2i(4, 2)
	direct_hit_state.player.cell = Vector2i(3, 2)
	direct_slug.cadence_tick = 3
	direct_hit_state.resolve_turn(&"wait")
	var direct_fire := direct_hit_state.resolve_turn(&"wait")
	_expect(direct_fire.enemies[1].kind == "mud_fire" and direct_fire.enemies[1].hit, "adjacent mud firing hits on spawn")
	_expect(direct_hit_state.mud_projectiles.is_empty(), "hit mud shot is not left behind as a projectile")
	_expect(direct_hit_state.player.hp == direct_hit_state.player.max_hp - StateScript.MUD_PROJECTILE_DAMAGE, "adjacent mud firing deals one damage")

	var travel_state := StateScript.new()
	travel_state.mud_projectiles = [{"cell": Vector2i(0, 0), "direction": Vector2i.RIGHT, "ttl": 1}]
	travel_state._advance_mud_projectiles()
	_expect(travel_state.mud_projectiles.size() == 1 and travel_state.mud_projectiles[0].cell == Vector2i(1, 0), "legacy ttl does not truncate a mud shot")
	for _step in range(StateScript.GRID_SIZE.x):
		travel_state._advance_mud_projectiles()
	_expect(travel_state.mud_projectiles.is_empty(), "mud shot leaves the board at the room edge")


func _test_reward_and_guard() -> void:
	var state := StateScript.new()
	state.enter_next_room()
	state.room_cleared = true
	state.enter_next_room()
	_expect(state.choose_reward(2).accepted, "guard reward accepted")
	_expect(state.buffs.guard, "guard reward stored")
	_expect(state.next_shield_combo == StateScript.GUARD_RHYTHM_SHIELD_COMBO, "guard lowers shield combo requirement")
	state.enter_next_room()
	var enemy: MvpUnitState = state.enemies[0]
	var second_enemy: MvpUnitState = state.enemies[1]
	_expect(second_enemy.role == &"slug", "guard receives the stationary slug timeline")
	state.player.cell = Vector2i(1, 2)
	enemy.cell = Vector2i(9, 1)
	second_enemy.cell = Vector2i(8, 4)
	for _step in range(StateScript.GUARD_RHYTHM_SHIELD_COMBO):
		state.resolve_turn(&"direction", Vector2i.RIGHT)
	_expect(state.rhythm_shield, "guard grants rhythm shield after three accurate actions")
	_expect(state.combo == StateScript.GUARD_RHYTHM_SHIELD_COMBO, "guard combo milestone is three")

	# The guard echo changes the cadence only; enemy attacks still deal their
	# normal damage and the echo remains active until the run ends.
	state.player.cell = enemy.cell + Vector2i.LEFT
	enemy.clear_enemy_plan()
	var result := state.resolve_turn(&"wait")
	_expect(result.enemies.size() == 2, "guard receives both enemy timelines")
	_expect(String(result.enemies[0].enemy_id) == enemy.unit_id and String(result.enemies[1].enemy_id) == second_enemy.unit_id, "hard room resolves enemies in stable spawn order")
	_expect(_enemy_result(result.enemies, enemy.unit_id).kind == "windup", "guard target telegraphs before attack")
	_expect(state.player.hp == state.player.max_hp, "guard target does not hit during windup")
	result = state.resolve_turn(&"wait")
	var guard_attack := _enemy_result(result.enemies, enemy.unit_id)
	_expect(guard_attack.kind == "attack" and not guard_attack.shielded, "guard does not replace enemy damage")
	_expect(state.player.hp == state.player.max_hp - enemy.attack_damage, "guard cadence leaves ordinary damage intact")
	_expect(state.buffs.guard, "guard remains active after enemy attack")


func _test_charge_and_rhythm_shield() -> void:
	var shield_clock := BeatClockScript.new()
	shield_clock.timing_window = 0.12
	shield_clock.resolution_window = StateScript.RHYTHM_SHIELD_WINDOW
	var resolved_beats: Array[int] = []
	shield_clock.beat_resolved.connect(func(beat: int) -> void: resolved_beats.append(beat))
	shield_clock.start(10.0)
	shield_clock.advance_to(shield_clock.beat_center_time + 0.16)
	_expect(resolved_beats.is_empty(), "shield window keeps late side open past normal judgement")
	shield_clock.advance_to(shield_clock.beat_center_time + StateScript.RHYTHM_SHIELD_WINDOW + 0.001)
	_expect(resolved_beats == [1], "shield window resolves after assist edge")
	shield_clock.stop()
	shield_clock.free()

	var state := StateScript.new()
	state.enter_next_room()
	var enemy: MvpUnitState = state.enemies[0]
	state.player.cell = Vector2i(5, 1)
	enemy.cell = Vector2i(6, 1)
	var result := state.resolve_turn(&"charge")
	_expect(result.player.kind == "charge", "charge is an active player action")
	_expect(state.charged, "charge stores one layer")
	_expect(state.combo == 1 and state.successful_actions == 1, "charge counts as accurate action")
	_expect(result.enemies[0].kind == "windup" and state.player.hp == state.player.max_hp, "charge beat only telegraphs enemy")
	result = state.resolve_turn(&"charge")
	_expect(state.charged and not result.player.charge_gained, "repeated charge does not stack")
	_expect(result.enemies[0].kind == "attack" and state.player.hp == state.player.max_hp - 1, "second charge beat receives enemy attack")
	state.player.cell = Vector2i(5, 1)
	enemy.cell = Vector2i(6, 1)
	enemy.clear_enemy_plan()
	result = state.resolve_turn(&"direction", Vector2i.RIGHT)
	_expect(result.player.kind == "attack", "charged attack resolves")
	_expect(result.player.charged_attack, "charged attack is marked")
	_expect(result.player.requested_damage == state.player.attack_damage + StateScript.CHARGE_BONUS_DAMAGE, "charged attack adds one damage")
	_expect(not state.charged, "successful attack consumes charge")

	var shield_state := StateScript.new()
	for _step in range(StateScript.RHYTHM_SHIELD_COMBO):
		result = shield_state.resolve_turn(&"direction", Vector2i.RIGHT)
	_expect(shield_state.combo == StateScript.RHYTHM_SHIELD_COMBO, "accurate actions build combo")
	_expect(shield_state.rhythm_shield, "combo threshold grants rhythm shield")
	_expect(bool(result.shield_gained), "turn result reports rhythm shield gain")
	_expect(shield_state.consume_rhythm_shield(), "rhythm shield can be consumed once")
	_expect(not shield_state.consume_rhythm_shield(), "rhythm shield has at most one layer")
	shield_state.resolve_turn(&"miss")
	_expect(shield_state.combo == 0 and shield_state.misses == 1, "unabsorbed miss resets combo and increments misses")
	shield_state.resolve_turn(&"charge")
	_expect(shield_state.charged, "charge can be stored before transition")
	shield_state.enter_next_room()
	_expect(not shield_state.charged, "room entry clears unused charge")
	shield_state.rhythm_shield = true
	shield_state.buffs.tempo = true
	shield_state.finish_run()
	_expect(not shield_state.rhythm_shield and not shield_state.charged, "run finish clears temporary action states")
	_expect(not shield_state.buffs.tempo and shield_state.player.attack_damage == 1, "run finish clears run buffs")


func _test_boss_phase() -> void:
	var state := StateScript.new()
	state.enter_next_room()
	state.room_cleared = true
	state.enter_next_room()
	state.room_cleared = true
	state.enter_next_room()
	state.room_cleared = true
	state.enter_next_room()
	var boss: MvpUnitState = state.enemies[0]
	_expect(boss.role == &"boss" and boss.unit_id == "boss", "first-layer boss is the venous glutton")
	_expect(is_equal_approx(state.get_bpm(), StateScript.BASE_BPM), "first-layer boss keeps the common bpm")
	var footprint := state.get_boss_footprint_cells(boss)
	_expect(footprint.size() == 9, "boss owns a complete 3x3 logical footprint")
	_expect(footprint.has(boss.cell + Vector2i(-1, -1)) and footprint.has(boss.cell + Vector2i(1, 1)), "boss footprint includes all corner cells")
	_expect(state._enemy_at(boss.cell + Vector2i(-1, 0)) == boss, "attacking a boss footprint edge targets the boss")
	_expect(state._occupied_by_enemy(boss.cell + Vector2i(1, 1)), "boss footprint blocks movement through all occupied cells")
	state.player.cell = Vector2i(1, 2)
	var first := state.resolve_turn(&"wait")
	_expect(first.enemies[0].kind == "mud_summon", "boss first beat summons sediment")
	_expect(state.mud_hazards.size() > 0, "boss sediment creates dangerous cells")
	var second := state.resolve_turn(&"wait")
	_expect(second.enemies[0].kind == "sweep_windup", "boss second beat telegraphs a fan sweep")
	var sweep_cells: Array = second.enemies[0].sweep_cells
	_expect(second.enemies[0].sweep_range == StateScript.BOSS_SWEEP_RANGE, "boss sweep reports its three-cell range")
	_expect(sweep_cells.size() == 7, "horizontal sweep exposes the full seven-cell fan")
	_expect(sweep_cells.has(Vector2i(3, 2)) and sweep_cells.has(Vector2i(1, 1)) and sweep_cells.has(Vector2i(1, 3)), "sweep starts outside the footprint and widens through three rows")
	_expect(not sweep_cells.has(Vector2i(4, 2)) and not sweep_cells.has(boss.cell), "sweep never overlaps the boss 3x3 footprint")
	var hp_before_sweep := state.player.hp
	var third := state.resolve_turn(&"wait")
	_expect(third.enemies[0].kind == "sweep", "boss third beat resolves the sweep")
	_expect(third.enemies[0].hit and state.player.hp == hp_before_sweep - boss.attack_damage, "player inside the declared fan takes sweep damage")
	var player_before_recovery := state.player.cell
	var hp_before_recovery := state.player.hp
	var fourth := state.resolve_turn(&"wait")
	_expect(fourth.enemies[0].kind == "recovery", "boss fourth beat is a readable recovery window")
	_expect(state.player.cell == player_before_recovery and state.player.hp == hp_before_recovery, "recovery never pulls or damages the player")
	_expect(not fourth.enemies[0].has("pulls") and String(fourth.enemies[0].get("intent", "")).find("suction") < 0, "removed suction exposes no pull payload or intent")
	state.player.cell = boss.cell + Vector2i(-2, 0)
	var boss_hp_before_attack := boss.hp
	var edge_attack := state.resolve_turn(&"direction", Vector2i.RIGHT)
	_expect(edge_attack.player.kind == "attack" and edge_attack.player.target_id == boss.unit_id, "player attacks the boss by striking a 3x3 footprint edge")
	_expect(edge_attack.player.contact_cell == boss.cell + Vector2i(-1, 0), "boss attack records the contacted footprint cell")
	_expect(boss.hp == boss_hp_before_attack - state.player.attack_damage, "footprint-edge attack damages the boss once")
	_expect(not state.boss_phase_shift_pending and not state.apply_boss_phase_shift(), "first-layer boss has no bpm phase shift")
	boss.take_damage(boss.hp)
	state.room_cleared = true
	_expect(is_equal_approx(state.get_bpm(), StateScript.BASE_BPM), "boss defeat keeps the base bpm")


func _test_non_box_telegraph_source() -> void:
	var source := FileAccess.get_file_as_string("res://scripts/mvp/mvp_room_view.gd")
	var state_source := FileAccess.get_file_as_string("res://scripts/mvp/mvp_state.gd")
	var controller_source := FileAccess.get_file_as_string("res://scripts/mvp/mvp_controller.gd")
	_expect(source.find("planned_rect") < 0 and source.find("threat_rect") < 0, "enemy plans no longer create target-cell rectangles")
	_expect(source.find("draw_line(enemy_center") < 0, "enemy plans no longer draw connecting direction lines")
	_expect(source.find("draw_rect(hazard_rect") < 0, "mud hazards no longer draw square outlines")
	_expect(source.find("draw_circle(projectile_center") < 0, "mud projectiles no longer draw outline rings")
	_expect(source.find("_draw_action_marker") >= 0 and source.find("_draw_sweep_fan") >= 0 and source.find("_draw_projectile_cell_marker") >= 0, "non-box action markers, sweep fan and projectile cell markers replace framed telegraphs")
	_expect(source.find("_animate_suction") < 0 and state_source.find("_pull_one_cell") < 0, "suction animation and pull logic are absent")
	_expect(state_source.find("\"kind\": \"suction\"") < 0 and controller_source.find("enemy_kind == \"suction\"") < 0, "runtime no longer emits or handles a suction action")


func _test_scene_boot_and_input() -> void:
	var scene := MvpScene.instantiate()
	root.add_child(scene)
	_expect(scene.is_running, "mvp scene starts running")
	_expect(scene.room_state.room_kind == StateScript.ROOM_START, "scene binds start state")
	var clock: BeatClock = scene.beat_clock
	clock.stop()
	var accepted: bool = scene.submit_direction_at(Vector2i.RIGHT, clock.beat_center_time)
	var duplicate: bool = scene.submit_direction_at(Vector2i.DOWN, clock.beat_center_time)
	_expect(accepted, "scene accepts one timed input")
	_expect(not duplicate, "scene locks duplicate input")
	scene._on_beat_resolved(1)
	_expect(scene.room_state.player.cell == Vector2i(2, 2), "scene resolves movement")
	_expect(scene.room_view.player_sprite != null, "scene creates player sprite")
	_expect(scene.room_view.background_texture != null, "scene loads room background")
	# Exercise the presentation path with a hit, enemy answer and death pose.
	scene.room_state.enter_next_room()
	scene.room_view.set_room()
	var enemy: MvpUnitState = scene.room_state.enemies[0]
	scene.room_state.player.cell = Vector2i(5, 1)
	enemy.cell = Vector2i(6, 1)
	enemy.hp = 1
	scene._reset_pending_input()
	scene.pending_action = &"direction"
	scene.pending_direction = Vector2i.RIGHT
	scene.input_locked = true
	scene._on_beat_resolved(2)
	_expect(not enemy.is_alive(), "scene presentation handles enemy death")
	scene.metronome.stop()
	root.remove_child(scene)
	scene.free()


func _test_menu_and_settings() -> void:
	var scene := MvpScene.instantiate()
	root.add_child(scene)
	scene.beat_clock.stop()
	scene._show_main_menu()
	_expect(scene.main_menu_overlay.visible, "main menu overlay is visible")
	_expect(scene.title_background != null, "main menu loads the existing title background bytes")
	var menu_panel: Node = scene.main_menu_overlay.get_node_or_null("MainMenuPanel")
	var menu_labels: Array[Label] = []
	if menu_panel != null:
		for child in menu_panel.get_children():
			if child is Label:
				menu_labels.append(child as Label)
	_expect(menu_labels.size() == 1 and menu_labels[0].text == "律动遗迹", "title screen keeps only the game title text")
	_expect(not scene.gameplay_hud_layer.visible, "title screen hides gameplay HUD while preserving the background")
	_expect(scene.main_menu_start_button.text == "开始游戏", "main menu exposes start button")
	_expect(scene.main_menu_settings_button.text == "设置", "main menu exposes settings button")
	_expect(scene.main_menu_quit_button.text == "退出游戏", "main menu exposes quit button")
	scene._open_settings()
	_expect(scene.settings_overlay.visible and not scene.main_menu_overlay.visible, "settings overlay replaces main menu")
	_expect(scene.settings_volume_slider.min_value == 0.0 and scene.settings_volume_slider.max_value == 100.0, "settings exposes master volume range")
	_expect(scene.settings_offset_slider.min_value == -200.0 and scene.settings_offset_slider.max_value == 200.0, "settings exposes chart offset range")
	var has_offset_hint := false
	for child in scene.settings_panel.get_children():
		if child is Label and (child as Label).text == "EARLY 调低 · LATE 调高":
			has_offset_hint = true
	_expect(has_offset_hint, "settings explains EARLY lower and LATE higher")
	_expect(scene.settings_binding_buttons.size() == SettingsScript.ACTIONS.size(), "settings exposes every configurable action")
	scene._on_master_volume_changed(42.0)
	scene._on_chart_offset_changed(-35.0)
	_expect(is_equal_approx(scene.game_settings.master_volume_percent, 42.0), "volume slider updates settings")
	_expect(is_equal_approx(scene.beat_clock.chart_offset_seconds, -0.035), "offset slider updates beat clock")
	scene.metronome.stop()
	root.remove_child(scene)
	scene.free()


func _test_global_reward_order_and_persistence() -> void:
	var state := StateScript.new()
	state.enter_next_room()
	state.enter_next_room()
	var first_options := state.get_reward_options()
	_expect(first_options == [&"tempo", &"guard"], "first reward uses the first two global echoes")
	var first_choice := state.choose_reward(2)
	_expect(first_choice.accepted and first_choice.buff == &"guard", "first layer can choose the second echo")
	_expect(state.buffs.guard and state.selected_echoes == [&"guard"], "selected echo persists in run state")
	state.room_kind = StateScript.ROOM_BOSS
	state.room_index = StateScript.ROOM_BOSS
	state.room_cleared = true
	_expect(state.advance_layer(), "reward state can be carried into the next layer route")
	state.enter_next_room()
	state.enter_next_room()
	var second_options := state.get_reward_options()
	_expect(second_options == [&"tempo", &"impact"], "second layer excludes the selected second echo and offers the next pair")
	var second_choice := state.choose_reward(2)
	_expect(second_choice.accepted and second_choice.buff == &"impact", "second layer can choose its distinct second echo")
	_expect(state.buffs.guard and state.buffs.impact, "rewards remain active across layers")
	_expect(not state.get_reward_options().has(&"guard") and not state.get_reward_options().has(&"impact"), "selected echoes never reappear")


func _test_pause_and_charge_bindings() -> void:
	_expect(InputMap.has_action(&"pause_game"), "project defines a pause action")
	_expect(InputMap.has_action(&"charge_action"), "project defines a charge action")
	var pause_events := InputMap.action_get_events(&"pause_game")
	var charge_events := InputMap.action_get_events(&"charge_action")
	var pause_key := pause_events[0] as InputEventKey if not pause_events.is_empty() else null
	var pause_escape_key := pause_events[1] as InputEventKey if pause_events.size() > 1 else null
	var charge_key := charge_events[0] as InputEventKey if not charge_events.is_empty() else null
	_expect(pause_key != null and pause_key.keycode == KEY_SPACE, "space is bound to pause")
	_expect(pause_escape_key != null and pause_escape_key.keycode == KEY_ESCAPE, "escape is bound to pause")
	_expect(InputMap.has_action(&"interact_action"), "project defines an interaction action")
	var interact_events := InputMap.action_get_events(&"interact_action")
	var interact_key := interact_events[0] as InputEventKey if not interact_events.is_empty() else null
	_expect(interact_key != null and interact_key.keycode == KEY_E, "E is bound to interaction")
	_expect(charge_key != null and charge_key.keycode == KEY_SHIFT and charge_key.location == 1, "left shift is bound to charge")

	var scene := MvpScene.instantiate()
	root.add_child(scene)
	var center_before_pause: float = scene.beat_clock.beat_center_time
	scene._set_game_paused(true)
	_expect(scene.game_paused and paused, "space pause freezes the scene tree")
	_expect(scene.pause_overlay.visible, "pause shows the formal pause overlay")
	_expect(scene.pause_resume_button.text == "继续游戏" and scene.pause_title_button.text == "返回标题", "pause exposes resume and title buttons")
	_expect(not scene._can_submit(), "pause blocks rhythm actions")
	scene.pause_started_time -= 0.75
	scene._set_game_paused(false)
	_expect(not paused and not scene.game_paused, "pause can resume the scene tree")
	_expect(scene.beat_clock.beat_center_time >= center_before_pause + 0.70, "resume shifts the beat center by paused duration")

	scene.beat_clock.beat_center_time = scene.beat_clock.now_seconds()
	scene._reset_pending_input()
	var shift_key := InputEventKey.new()
	shift_key.pressed = true
	shift_key.keycode = KEY_SHIFT
	shift_key.location = 1
	scene._unhandled_key_input(shift_key)
	_expect(scene.pending_action == &"charge", "left shift routes to the beat charge action")
	var space_key := InputEventKey.new()
	space_key.pressed = true
	space_key.keycode = KEY_SPACE
	scene._unhandled_key_input(space_key)
	_expect(scene.game_paused and scene.pause_overlay.visible, "space toggles pause during play")
	scene._unhandled_key_input(space_key)
	_expect(not scene.game_paused and not scene.pause_overlay.visible, "space toggles play back on")
	var escape_key := InputEventKey.new()
	escape_key.pressed = true
	escape_key.keycode = KEY_ESCAPE
	scene._unhandled_key_input(escape_key)
	_expect(scene.game_paused and scene.pause_overlay.visible, "escape toggles pause during play")
	scene._unhandled_key_input(escape_key)
	_expect(not scene.game_paused and not scene.pause_overlay.visible, "escape toggles play back on")
	scene._set_game_paused(true)
	scene.pause_title_button.emit_signal("pressed")
	_expect(scene.main_menu_overlay.visible and not scene.pause_overlay.visible and not scene.game_paused, "pause title button returns to the main menu")
	scene.metronome.stop()
	root.remove_child(scene)
	scene.free()


func _test_formal_hud_and_rhythm_track() -> void:
	var scene := MvpScene.instantiate()
	root.add_child(scene)
	scene.beat_clock.stop()
	_expect(is_equal_approx(StateScript.BASE_BPM, 90.0), "formal mvp base bpm is 90")
	_expect(is_equal_approx(scene.beat_clock.bpm, 90.0), "scene clock starts at 90 bpm")
	_expect(scene.room_view.anchor_left == 0.0 and scene.room_view.anchor_right == 1.0, "formal room view fills the screen")
	_expect(scene.hp_row.get_child_count() == StateScript.PLAYER_MAX_HP, "top-left hud contains one heart per max hp")
	_expect(scene.hp_row.global_position.x < 40.0 and scene.hp_row.global_position.y < 40.0, "heart health is anchored at top left")
	_expect(not scene.boss_health_panel.visible, "boss health stays hidden outside the boss room")
	_expect(not scene.room_title_label.is_visible_in_tree(), "prototype room title is hidden")
	_expect(not scene.status_label.is_visible_in_tree(), "prototype status band is hidden")
	_expect(scene.controls_label.is_visible_in_tree(), "gameplay control instructions are visible below health")
	_expect(scene.controls_label.text.find("WASD") >= 0 and scene.controls_label.text.find("E") >= 0, "gameplay control instructions expose movement and interaction keys")
	_expect(is_equal_approx(scene.rhythm_hud.anchor_left, 0.5) and is_equal_approx(scene.rhythm_hud.anchor_bottom, 1.0), "falling track is bottom centered")
	_expect(is_equal_approx(RhythmHudScript.FALL_LEAD_BEATS, 3.0), "falling notes use the faster three-beat lead")
	scene.beat_clock.chart_offset_seconds = 0.0
	var center_time: float = scene.beat_clock.beat_center_time
	var period: float = scene.beat_clock.beat_period
	var spawn_progress: float = scene.rhythm_hud.get_note_progress(3, center_time)
	var early_progress: float = scene.rhythm_hud.get_note_progress(0, center_time - period)
	var on_beat_progress: float = scene.rhythm_hud.get_note_progress(0, center_time)
	_expect(is_equal_approx(spawn_progress, 0.0), "fourth note spawns three beats before judgement")
	_expect(on_beat_progress > early_progress, "rhythm note advances toward the judgement line")
	_expect(is_equal_approx(on_beat_progress, 1.0), "rhythm note reaches the line on beat")
	var grid_layout: Dictionary = scene.room_view._grid_layout()
	var grid_origin: Vector2 = grid_layout.origin
	var grid_cell_size: float = grid_layout.cell_size
	_expect(grid_origin.is_equal_approx(Vector2(153.0, 95.0)), "gameplay board starts on the painted floor-tile seam")
	_expect(is_equal_approx(grid_cell_size, 60.0), "gameplay cells use the painted 60px tile step")
	var player_center: Vector2 = scene.room_view._cell_center(scene.room_state.player.cell)
	var player_visual_center := _atlas_visual_center(scene.room_view, &"player", scene.room_state.player.cell, 0, scene.room_state.player.facing)
	_expect(player_visual_center.distance_to(player_center) < 0.01, "active player silhouette is visually centered in its tile")
	var door_center: Vector2 = scene.room_view.get_exit_door_center()
	var board_right_edge := grid_origin.x + StateScript.GRID_SIZE.x * grid_cell_size
	_expect(door_center.is_equal_approx(Vector2(850.0, 270.0)), "exit is anchored to the painted right-wall doorway")
	_expect(door_center.x > board_right_edge + 20.0, "wall exit is beyond the last painted floor tile")
	_expect(scene.room_view.exit_portal_sprite != null and scene.room_view.exit_portal_sprite.hframes == 4, "room exit uses the generated four-frame portal sheet")
	scene.metronome.stop()
	root.remove_child(scene)
	scene.free()


func _test_room_boundary_and_portal_alignment() -> void:
	var state := StateScript.new()
	_expect(StateScript.GRID_SIZE == Vector2i(11, 6), "mvp board covers the full 11x6 painted floor")
	state.player.cell = Vector2i(StateScript.GRID_SIZE.x - 1, StateScript.GRID_SIZE.y - 1)
	var blocked := state.resolve_turn(&"direction", Vector2i.RIGHT)
	_expect(blocked.player.kind == "blocked", "right wall blocks only after the final painted floor cell")
	_expect(state.player.cell == Vector2i(StateScript.GRID_SIZE.x - 1, StateScript.GRID_SIZE.y - 1), "player remains on the final floor cell when pushing beyond the wall")

	var scene := MvpScene.instantiate()
	root.add_child(scene)
	scene.beat_clock.stop()
	scene._advance_room()
	scene.beat_clock.stop()
	var enemy: MvpUnitState = scene.room_state.enemies[0]
	enemy.hp = 0
	enemy.alive = false
	scene.room_state.room_cleared = true
	scene.room_state.player.cell = Vector2i(StateScript.GRID_SIZE.x - 3, 2)
	scene.room_view.set_room()
	scene._reset_pending_input()
	scene.pending_action = &"direction"
	scene.pending_direction = Vector2i.RIGHT
	scene.input_locked = true
	scene._on_beat_resolved(1)
	_expect(scene.room_state.player.cell.x == StateScript.GRID_SIZE.x - 2, "walking one cell before the edge does not transition early")
	_expect(not scene.transition_locked, "transition stays unlocked before the final floor cell")
	scene._reset_pending_input()
	scene.pending_action = &"direction"
	scene.pending_direction = Vector2i.RIGHT
	scene.input_locked = true
	scene._on_beat_resolved(2)
	_expect(scene.room_state.player.cell.x == StateScript.GRID_SIZE.x - 1, "player reaches the last painted floor cell")
	_expect(scene.transition_locked, "transition locks exactly at the final floor cell")
	scene._advance_room()
	scene.metronome.stop()
	root.remove_child(scene)
	scene.free()


func _test_map_definition_contract() -> void:
	var state := StateScript.new()
	_expect(state.map_definition.map_id == &"right_atrium_11x6", "state exposes the first-layer map definition")
	_expect(state.map_definition.grid_size == Vector2i(11, 6), "map definition owns the logical grid size")
	state.enter_next_room()
	for enemy in state.enemies:
		_expect(state.map_definition.is_inside(enemy.cell), "enemy starts inside the map definition")
	_expect(state.map_definition.is_inside(state.player.cell), "player starts inside the map definition")

	var scene := MvpScene.instantiate()
	root.add_child(scene)
	scene.beat_clock.stop()
	_expect(scene.room_view.room_state.map_definition == scene.room_state.map_definition, "view and combat share one map definition instance")
	_expect(scene.room_view.get_exit_door_center().is_equal_approx(Vector2(850.0, 270.0)), "map definition owns the right-wall exit anchor")
	scene.metronome.stop()
	root.remove_child(scene)
	scene.free()


func _test_scene_clash_feedback() -> void:
	var scene := MvpScene.instantiate()
	root.add_child(scene)
	scene.beat_clock.stop()
	scene._advance_room()
	scene.beat_clock.stop()
	var enemy: MvpUnitState = scene.room_state.enemies[0]
	scene.room_state.player.cell = enemy.cell + Vector2i.LEFT
	scene.room_view.set_room()
	scene._reset_pending_input()
	scene._on_beat_resolved(1)
	_expect(enemy.enemy_plan == &"attack", "scene enemy raises its weapon before clash")
	var player_hp_before: int = scene.room_state.player.hp
	var enemy_hp_before: int = enemy.hp
	scene.pending_action = &"direction"
	scene.pending_direction = Vector2i.RIGHT
	scene.input_locked = true
	scene._on_beat_resolved(2)
	_expect(scene.status_label.text.find("弹刀") >= 0, "scene reports weapon clash")
	_expect(scene.room_state.player.hp == player_hp_before and enemy.hp == enemy_hp_before, "scene clash does not change health")
	_expect(enemy.enemy_plan == &"none", "scene clash clears telegraphed attack")
	_expect(scene.room_view.actor_busy_until.has("player") and scene.room_view.actor_busy_until.has(enemy.unit_id), "scene clash animates both actors")
	var actor_children_before: int = scene.room_view.actor_layer.get_child_count()
	scene.room_view._on_clash_impact({
		"from": scene.room_state.player.cell,
		"to": enemy.cell,
		"direction": Vector2i.RIGHT,
		"target_id": enemy.unit_id,
	}, scene.room_view.presentation_generation)
	_expect(scene.room_view.actor_layer.get_child_count() >= actor_children_before + 4, "scene clash layers directional slashes, spark and pulse")
	var has_generated_clash_sheet := false
	for child in scene.room_view.actor_layer.get_children():
		if child is Sprite2D and _texture_path_matches((child as Sprite2D).texture, "fx_weapon_clash_sheet.png"):
			has_generated_clash_sheet = true
	_expect(has_generated_clash_sheet, "scene clash uses the generated four-frame clash sheet")
	var has_clash_caption := false
	for child in scene.room_view.feedback_layer.get_children():
		if child is Label and (child as Label).text.find("弹刀") >= 0:
			has_clash_caption = true
	_expect(not has_clash_caption, "scene clash uses animation without a floating caption")
	scene.metronome.stop()
	root.remove_child(scene)
	scene.free()

	# In the hard room, the second actor is a stationary mud turret. It must not
	# be treated as another melee duelist when the first actor clashes.
	var hard_scene := MvpScene.instantiate()
	root.add_child(hard_scene)
	hard_scene.beat_clock.stop()
	while hard_scene.room_state.room_kind < StateScript.ROOM_HARD:
		hard_scene.room_state.enter_next_room()
	var duelist: MvpUnitState = hard_scene.room_state.enemies[0]
	var second_enemy: MvpUnitState = hard_scene.room_state.enemies[1]
	hard_scene.room_state.player.cell = Vector2i(5, 1)
	duelist.cell = Vector2i(6, 1)
	second_enemy.cell = Vector2i(5, 2)
	duelist.enemy_plan = &"attack"
	duelist.enemy_plan_target = hard_scene.room_state.player.cell
	duelist.enemy_plan_direction = Vector2i.LEFT
	second_enemy.clear_enemy_plan()
	hard_scene.room_view.set_room()
	var hard_result: Dictionary = hard_scene.room_state.resolve_turn(&"direction", Vector2i.RIGHT)
	hard_scene.room_view.present_turn(hard_result)
	_expect(hard_result.player.kind == "clash" and (hard_result.enemies[1].kind == "hold" or hard_result.enemies[1].kind == "mud_windup"), "hard room keeps the mud turret timeline after clash")
	hard_scene.metronome.stop()
	root.remove_child(hard_scene)
	hard_scene.free()


func _test_scene_blocked_chase_feedback() -> void:
	var scene := MvpScene.instantiate()
	root.add_child(scene)
	scene.beat_clock.stop()
	scene._advance_room()
	scene.beat_clock.stop()
	var enemy: MvpUnitState = scene.room_state.enemies[0]
	scene.room_state.player.cell = Vector2i(2, 2)
	enemy.cell = Vector2i(4, 2)
	scene.room_view.set_room()
	scene._reset_pending_input()
	scene._on_beat_resolved(1)
	_expect(scene.room_state.enemies[0].enemy_plan == &"move", "scene stores the chase plan before execution")
	_expect(scene.status_label.text.find("蓄势") >= 0, "scene labels a chase windup")
	scene.pending_action = &"direction"
	scene.pending_direction = Vector2i.RIGHT
	scene.input_locked = true
	scene._on_beat_resolved(2)
	_expect(scene.room_state.player.cell == Vector2i(3, 2), "scene lets player occupy the locked chase destination")
	_expect(scene.status_label.text.find("追击受阻") >= 0, "scene reports blocked chase distinctly")
	_expect(scene.status_label.text.find("挥空") < 0, "blocked chase is not mislabeled as a whiff")
	scene.metronome.stop()
	root.remove_child(scene)
	scene.free()


func _test_directional_state_assets() -> void:
	var scene := MvpScene.instantiate()
	root.add_child(scene)
	scene.beat_clock.stop()
	var directions := {
		"down": Vector2i.DOWN,
		"left": Vector2i.LEFT,
		"right": Vector2i.RIGHT,
		"up": Vector2i.UP,
	}
	var view: MvpRoomView = scene.room_view
	for direction_name in directions:
		var direction: Vector2i = directions[direction_name]
		scene.room_state.player.facing = direction
		view._start_hurt("player", false, scene.room_state.player.cell, view.presentation_generation)
		_expect(_texture_path_matches(view.player_sprite.texture, "player_hurt_%s.png" % direction_name), "player hurt uses %s asset" % direction_name)
		view.reset_feedback()
		scene.room_state.player.facing = direction
		view._start_hurt("player", true, scene.room_state.player.cell, view.presentation_generation)
		_expect(_texture_path_matches(view.player_sprite.texture, "player_death_%s.png" % direction_name), "player death uses %s asset" % direction_name)
		view.reset_feedback()

	scene._advance_room()
	scene.beat_clock.stop()
	var enemy: MvpUnitState = scene.room_state.enemies[0]
	view = scene.room_view
	for direction_name in directions:
		var direction: Vector2i = directions[direction_name]
		enemy.facing = direction
		view._start_hurt(enemy.unit_id, false, enemy.cell, view.presentation_generation)
		var enemy_sprite: Sprite2D = view.actor_sprites.get(enemy.unit_id)
		_expect(_texture_path_matches(enemy_sprite.texture, "enemy_siphonling_hurt_%s.png" % direction_name), "enemy hurt uses %s asset" % direction_name)
		view.reset_feedback()
		enemy.facing = direction
		view._start_hurt(enemy.unit_id, true, enemy.cell, view.presentation_generation)
		enemy_sprite = view.actor_sprites.get(enemy.unit_id)
		_expect(_texture_path_matches(enemy_sprite.texture, "enemy_siphonling_death_%s.png" % direction_name), "enemy death uses %s asset" % direction_name)
		view.reset_feedback()

	scene.room_state._enter_room(StateScript.ROOM_HARD)
	view.set_room()
	var slug: MvpUnitState = null
	for candidate in scene.room_state.enemies:
		if candidate.role == &"slug":
			slug = candidate
			break
	_expect(slug != null, "hard room exposes the spit-slug art role")
	if slug != null:
		for direction_name in directions:
			var direction: Vector2i = directions[direction_name]
			slug.facing = direction
			view._start_hurt(slug.unit_id, false, slug.cell, view.presentation_generation)
			var slug_sprite: Sprite2D = view.actor_sprites.get(slug.unit_id)
			_expect(_texture_path_matches(slug_sprite.texture, "spit_slug_hurt_%s.png" % direction_name), "spit slug hurt uses %s asset" % direction_name)
			view.reset_feedback()
			slug.facing = direction
			view._start_hurt(slug.unit_id, true, slug.cell, view.presentation_generation)
			slug_sprite = view.actor_sprites.get(slug.unit_id)
			_expect(_texture_path_matches(slug_sprite.texture, "spit_slug_death_%s.png" % direction_name), "spit slug death uses %s asset" % direction_name)
			view.reset_feedback()

	scene.restart_run()
	scene.beat_clock.stop()
	_advance_scene_to_boss(scene)
	scene.beat_clock.stop()
	var boss: MvpUnitState = scene.room_state.enemies[0]
	view = scene.room_view
	for direction_name in directions:
		var direction: Vector2i = directions[direction_name]
		boss.facing = direction
		view._start_hurt("boss", false, boss.cell, view.presentation_generation)
		var boss_sprite: Sprite2D = view.actor_sprites.get("boss")
		_expect(_texture_path_matches(boss_sprite.texture, "venous_glutton_hurt_%s.png" % direction_name), "boss hurt uses %s asset" % direction_name)
		view.reset_feedback()
		boss.facing = direction
		view._start_hurt("boss", true, boss.cell, view.presentation_generation)
		boss_sprite = view.actor_sprites.get("boss")
		_expect(_texture_path_matches(boss_sprite.texture, "venous_glutton_death_%s.png" % direction_name), "boss death uses %s asset" % direction_name)
		view.reset_feedback()

	scene.metronome.stop()
	root.remove_child(scene)
	scene.free()


func _texture_path_matches(texture: Texture2D, suffix: String) -> bool:
	return texture != null and String(texture.resource_path).ends_with(suffix)


func _atlas_visual_center(view: MvpRoomView, role: StringName, cell: Vector2i, pose: int, facing: Vector2i) -> Vector2:
	var texture := view._sheet_for_role(role)
	var image := texture.get_image()
	var frame_size := 64 if role == &"boss" else 32
	var row := view._direction_row(facing)
	var frame_origin := Vector2i(pose * frame_size, row * frame_size)
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
	var sprite_position := view._actor_position(cell, role, pose, facing)
	return sprite_position + (opaque_center - Vector2.ONE * frame_size * 0.5) * view._actor_scale_factor(role)


func _sprite_visual_center(sprite: Sprite2D) -> Vector2:
	var image := sprite.texture.get_image()
	var frame_width := image.get_width() / maxi(sprite.hframes, 1)
	var frame_height := image.get_height() / maxi(sprite.vframes, 1)
	var column := sprite.frame % maxi(sprite.hframes, 1)
	var row := floori(float(sprite.frame) / float(maxi(sprite.hframes, 1)))
	var frame_origin := Vector2i(column * frame_width, row * frame_height)
	var min_pixel := Vector2i(frame_width, frame_height)
	var max_pixel := Vector2i(-1, -1)
	for y in range(frame_height):
		for x in range(frame_width):
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
	return sprite.position + (opaque_center - Vector2(frame_width, frame_height) * 0.5) * sprite.scale


func _texture_alpha_centroid_offset(texture: Texture2D) -> Vector2:
	var image := texture.get_image()
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
	return weighted_position / total_alpha - Vector2(image.get_width(), image.get_height()) * 0.5


func _sprite_alpha_centroid(sprite: Sprite2D) -> Vector2:
	return sprite.position + _texture_alpha_centroid_offset(sprite.texture) * sprite.scale


func _texture_rect_alpha_centroid(texture_rect: TextureRect) -> Vector2:
	var texture_size := Vector2(texture_rect.texture.get_width(), texture_rect.texture.get_height())
	var render_scale := minf(texture_rect.size.x / texture_size.x, texture_rect.size.y / texture_size.y)
	return texture_rect.position + texture_rect.size * 0.5 + _texture_alpha_centroid_offset(texture_rect.texture) * render_scale


func _test_directional_state_anchors() -> void:
	var scene := MvpScene.instantiate()
	root.add_child(scene)
	scene.beat_clock.stop()
	var directions := [Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP]
	var view: MvpRoomView = scene.room_view

	# Every generated atlas uses different transparent padding per frame. Verify
	# the visible silhouette itself, rather than Sprite2D.position, for every
	# active player/enemy/slug/Boss pose and direction.
	var atlas_roles: Array[StringName] = [&"player", &"enemy", &"slug", &"boss"]
	var sample_cell := Vector2i(5, 2)
	for role in atlas_roles:
		for direction in directions:
			for pose in range(4):
				var visual_center := _atlas_visual_center(view, role, sample_cell, pose, direction)
				_expect(visual_center.distance_to(view._cell_center(sample_cell)) < 0.01, "%s pose %d is visually centered for %s" % [role, pose, view._direction_name(direction)])

	for direction in directions:
		scene.room_state.player.facing = direction
		var tile_center: Vector2 = view._cell_center(scene.room_state.player.cell)
		view._start_hurt("player", false, scene.room_state.player.cell, view.presentation_generation)
		var expected_position: Vector2 = view._state_actor_position(scene.room_state.player.cell, &"player", false, direction)
		_expect(view.player_sprite.position.distance_to(expected_position) < 0.01, "player hurt anchor follows %s" % view._direction_name(direction))
		_expect(_sprite_visual_center(view.player_sprite).distance_to(tile_center) < 0.01, "player hurt silhouette stays at tile center for %s" % view._direction_name(direction))
		view.reset_feedback()

	scene._advance_room()
	scene.beat_clock.stop()
	var enemy: MvpUnitState = scene.room_state.enemies[0]
	for direction in directions:
		enemy.facing = direction
		view._start_hurt(enemy.unit_id, true, enemy.cell, view.presentation_generation)
		var enemy_sprite: Sprite2D = view.actor_sprites.get(enemy.unit_id)
		var enemy_expected: Vector2 = view._state_actor_position(enemy.cell, &"enemy", true, direction)
		_expect(enemy_sprite.position.distance_to(enemy_expected) < 0.01, "enemy death anchor follows %s" % view._direction_name(direction))
		_expect(_sprite_visual_center(enemy_sprite).distance_to(view._cell_center(enemy.cell)) < 0.01, "enemy death silhouette stays at tile center for %s" % view._direction_name(direction))
		view.reset_feedback()

	# Enter the mixed room and verify the slug's single-frame states too.
	scene.room_state.room_cleared = true
	scene._advance_room()
	scene._advance_room()
	scene.beat_clock.stop()
	var slug: MvpUnitState = scene.room_state.enemies[1]
	for direction in directions:
		slug.facing = direction
		view._start_hurt(slug.unit_id, false, slug.cell, view.presentation_generation)
		var slug_sprite: Sprite2D = view.actor_sprites.get(slug.unit_id)
		_expect(_sprite_visual_center(slug_sprite).distance_to(view._cell_center(slug.cell)) < 0.01, "slug hurt silhouette stays at tile center for %s" % view._direction_name(direction))
		view.reset_feedback()

	scene.restart_run()
	scene.beat_clock.stop()
	_advance_scene_to_boss(scene)
	scene.beat_clock.stop()
	var boss: MvpUnitState = scene.room_state.enemies[0]
	boss.facing = Vector2i.UP
	view._start_hurt("boss", false, boss.cell, view.presentation_generation)
	var boss_sprite: Sprite2D = view.actor_sprites.get("boss")
	var boss_expected: Vector2 = view._state_actor_position(boss.cell, &"boss", false, Vector2i.UP)
	_expect(boss_sprite.position.distance_to(boss_expected) < 0.01, "boss up hurt anchor follows first-layer correction")
	_expect(_sprite_visual_center(boss_sprite).distance_to(view._cell_center(boss.cell)) < 0.01, "boss hurt silhouette stays at footprint center")
	view.reset_feedback()

	scene.metronome.stop()
	root.remove_child(scene)
	scene.free()


func _test_scene_charge_and_shield_assist() -> void:
	var scene := MvpScene.instantiate()
	root.add_child(scene)
	var clock: BeatClock = scene.beat_clock
	clock.stop()
	_expect(scene.submit_charge_at(clock.beat_center_time), "scene accepts timed charge")
	_expect(scene.pending_action == &"charge", "left shift path locks charge action")
	scene._on_beat_resolved(1)
	_expect(scene.room_state.charged, "scene charge reaches run state")
	_expect(scene.status_label.text.find("蓄力") >= 0, "charge reports status")

	scene.room_state.rhythm_shield = true
	scene.room_state.combo = StateScript.RHYTHM_SHIELD_COMBO
	scene.room_state.next_shield_combo = StateScript.RHYTHM_SHIELD_COMBO * 2
	scene._refresh_ui()
	_expect(is_equal_approx(clock.get_resolution_window(), StateScript.RHYTHM_SHIELD_WINDOW), "ready shield extends late resolution edge")
	var start_cell: Vector2i = scene.room_state.player.cell
	var assist_time := clock.beat_center_time + 0.16
	_expect(scene.submit_direction_at(Vector2i.RIGHT, assist_time), "shield assist accepts slight miss")
	_expect(scene.pending_shield_assist, "controller marks rhythm shield assist")
	_expect(not scene.room_state.rhythm_shield, "assist consumes rhythm shield at input")
	_expect(scene.judge_label.text.find("SYNC") >= 0, "assist judgement is visible")
	scene._on_beat_resolved(2)
	_expect(scene.room_state.player.cell == start_cell + Vector2i.RIGHT, "assisted action resolves normally")
	_expect(scene.room_state.combo == StateScript.RHYTHM_SHIELD_COMBO + 1, "assist preserves combo")
	_expect(is_equal_approx(clock.get_resolution_window(), clock.timing_window), "consumed shield restores normal resolution edge")

	scene.room_state.rhythm_shield = true
	scene._refresh_ui()
	var miss_time := clock.beat_center_time + StateScript.RHYTHM_SHIELD_WINDOW + 0.01
	_expect(scene.submit_direction_at(Vector2i.RIGHT, miss_time), "far miss still locks the beat")
	_expect(scene.pending_action == &"miss", "far miss is not absorbed")
	_expect(scene.room_state.rhythm_shield, "far miss does not waste rhythm shield")
	scene._on_beat_resolved(3)
	_expect(scene.room_state.combo == 0, "far miss resets combo")
	_expect(scene.room_state.misses == 1, "state remains sole miss counter")
	scene.metronome.stop()
	root.remove_child(scene)
	scene.free()


func _test_scene_death_restart() -> void:
	var scene := MvpScene.instantiate()
	root.add_child(scene)
	scene.beat_clock.stop()
	scene._advance_room()
	scene.beat_clock.stop()
	var enemy: MvpUnitState = scene.room_state.enemies[0]
	scene.room_state.player.cell = enemy.cell + Vector2i.LEFT
	scene.room_state.player.hp = 1
	scene._reset_pending_input()
	scene._on_beat_resolved(1)
	_expect(scene.room_state.player.hp == 1, "scene windup does not damage player")
	_expect(scene.is_running, "scene remains running during enemy windup")
	_expect(not scene.end_overlay.visible, "windup does not show defeat overlay")
	scene._on_beat_resolved(2)
	_expect(scene.room_state.player.hp == 0, "scene death clamps hp on execution beat")
	_expect(not scene.is_running, "scene stops after player defeat")
	_expect(scene.end_overlay.visible, "player defeat shows end overlay")
	_expect(scene.end_title.text == "心核沉寂", "defeat overlay title")
	_expect(scene.end_body.text.find("等待下一次共鸣") >= 0, "defeat overlay uses story feedback")
	_expect(scene.end_body.text.find("倒在右心房") >= 0 and scene.end_body.text.find("战斗房") < 0, "defeat overlay names only the chamber")
	_expect(scene.end_body.text.find("有效行动") < 0 and scene.end_body.text.find("失拍") < 0, "defeat overlay omits prototype action statistics")
	_expect(scene.restart_button.text == "重新挑战", "defeat restart action matches the game tone")
	_expect(not scene._can_submit(), "defeat blocks further input")

	# Exercise the actual restart button signal; no clock time is needed.
	scene.restart_button.pressed.emit()
	scene.beat_clock.stop()
	_expect(scene.room_state.room_kind == StateScript.ROOM_START, "restart returns to start room")
	_expect(scene.room_state.player.hp == scene.room_state.player.max_hp, "restart restores player hp")
	_expect(scene.room_state.turn_number == 0, "restart resets turn counter")
	_expect(not scene.room_state.buffs.tempo and not scene.room_state.buffs.guard, "restart clears buffs")
	_expect(not scene.end_overlay.visible, "restart hides end overlay")
	_expect(scene.is_running, "restart resumes run")
	scene.metronome.stop()
	root.remove_child(scene)
	scene.free()


func _test_scene_reward_route_and_lock() -> void:
	var scene := MvpScene.instantiate()
	root.add_child(scene)
	scene.beat_clock.stop()

	# Enter the first combat room, then exercise the locked exit transition.
	scene._advance_room()
	scene.beat_clock.stop()
	scene.room_state.room_cleared = true
	scene.room_state.player.cell = Vector2i(StateScript.GRID_SIZE.x - 1, scene.room_state.player.cell.y)
	scene._schedule_next_room()
	_expect(scene.transition_locked, "room exit locks transition")
	_expect(not scene.is_running, "room exit pauses run")
	_expect(scene.transition_overlay.visible, "room exit shows transition overlay")
	_expect(scene.transition_label.text.find("深入") >= 0, "room exit uses traversal copy instead of replaying clear feedback")
	_expect(scene.transition_streaks.is_empty(), "room exit has no procedural color blocks")
	_expect(scene.room_view.actor_busy_until.has("player"), "room exit animates the player into the wall doorway")
	var locked_room: int = scene.room_state.room_kind
	scene._schedule_next_room()
	_expect(scene.room_state.room_kind == locked_room, "locked room exit cannot duplicate")
	# Invoke the deferred callback directly instead of waiting for its tween.
	scene._advance_room()
	_expect(scene.room_state.room_kind == StateScript.ROOM_REWARD, "transition enters reward room")
	_expect(scene.reward_overlay.visible, "reward room shows reward overlay")
	_expect(scene.reward_body.text == "选择一项增益", "reward overlay uses concise instruction")
	_expect(scene.status_label.text == "选择一项增益", "reward status uses concise instruction")
	_expect(scene.reward_body.text.find("跨层") < 0 and scene.reward_body.text.find("取得") < 0, "reward overlay hides implementation wording")
	_expect(scene.status_label.text.find("跨层") < 0 and scene.status_label.text.find("取得") < 0, "reward status hides implementation wording")
	_expect(not scene.is_running, "reward overlay pauses run")
	_expect(not scene.beat_clock.is_running, "reward overlay stops beat clock")
	_expect(not scene.transition_locked, "reward overlay releases transition lock")
	_expect(not scene._can_submit(), "reward overlay blocks combat input")
	_expect(scene.reward_tempo_button.text.is_empty() and scene.reward_guard_button.text.is_empty(), "reward cards do not mix shortcut numbers into button text")
	var tempo_content: Node = scene.reward_tempo_button.get_node_or_null("Content")
	var guard_content: Node = scene.reward_guard_button.get_node_or_null("Content")
	_expect(tempo_content is VBoxContainer and guard_content is VBoxContainer, "reward cards use centered vertical content")
	if tempo_content is VBoxContainer and guard_content is VBoxContainer:
		var tempo_title := tempo_content.get_node_or_null("Title") as Label
		var tempo_detail := tempo_content.get_node_or_null("Detail") as Label
		var tempo_shortcut := tempo_content.get_node_or_null("Shortcut") as Label
		var guard_title := guard_content.get_node_or_null("Title") as Label
		var guard_shortcut := guard_content.get_node_or_null("Shortcut") as Label
		_expect(tempo_title != null and tempo_detail != null and guard_title != null, "reward card labels exist")
		_expect(tempo_title != null and tempo_title.horizontal_alignment == HORIZONTAL_ALIGNMENT_CENTER, "reward title text is centered")
		_expect(tempo_detail != null and tempo_detail.horizontal_alignment == HORIZONTAL_ALIGNMENT_CENTER, "reward detail text is centered")
		_expect(guard_title != null and guard_title.horizontal_alignment == HORIZONTAL_ALIGNMENT_CENTER, "second reward text is centered")
		_expect(tempo_detail != null and tempo_detail.text.find("两格") >= 0, "tempo reward explains its two-cell range")
		var guard_detail := guard_content.get_node_or_null("Detail") as Label
		_expect(guard_detail != null and guard_detail.text.find("3 次") >= 0, "guard reward explains its three-combo cadence")
		_expect(tempo_shortcut != null and tempo_detail != null and tempo_shortcut.text == "1" and tempo_shortcut.get_index() > tempo_detail.get_index(), "shortcut 1 occupies its own bottom line")
		_expect(guard_shortcut != null and guard_title != null and guard_shortcut.text == "2" and guard_shortcut.get_index() > guard_title.get_index(), "shortcut 2 occupies its own bottom line")

	# Every reward in the global order now has a real runtime icon, not a blank placeholder.
	var expected_icons := {
		&"tempo": "echo_tempo.png",
		&"guard": "echo_guard.png",
		&"impact": "echo_impact.png",
		&"vigor": "echo_vigor.png",
		&"pulse": "echo_pulse.png",
	}
	for echo_id in StateScript.ECHO_ORDER:
		var definition: Dictionary = scene.room_state.get_echo_definition(echo_id)
		scene._set_reward_button_content(scene.reward_tempo_button, definition, echo_id)
		var icon := scene.reward_tempo_button.get_node("Content/Icon") as TextureRect
		_expect(icon != null and icon.texture != null, "reward icon loads for %s" % echo_id)
		if icon != null and icon.texture != null:
			_expect(icon.texture.resource_path.ends_with(expected_icons[echo_id]), "reward icon maps for %s" % echo_id)

	# Keyboard choice is routed through the same controller selection method.
	var guard_key := InputEventKey.new()
	guard_key.pressed = true
	guard_key.physical_keycode = KEY_2
	scene._unhandled_key_input(guard_key)
	_expect(scene.room_state.buffs.guard, "keyboard selects guard reward")
	_expect(scene.room_state.next_shield_combo == StateScript.GUARD_RHYTHM_SHIELD_COMBO, "keyboard reward applies guard cadence")
	_expect(not scene.reward_overlay.visible, "reward overlay hides after choice")
	_expect(scene.transition_locked, "reward choice locks transition")
	_expect(scene.transition_overlay.visible, "reward choice shows transition overlay")
	var tempo_key := InputEventKey.new()
	tempo_key.pressed = true
	tempo_key.physical_keycode = KEY_1
	scene._unhandled_key_input(tempo_key)
	_expect(not scene.room_state.buffs.tempo, "locked reward ignores second choice")
	# Complete the deferred reward transition without sleeping.
	scene._advance_room()
	_expect(scene.room_state.room_kind == StateScript.ROOM_HARD, "reward choice enters hard room")
	_expect(scene.room_state.enemies.size() == 2, "hard room has two enemies after choice")
	_expect(scene.room_state.buffs.guard, "guard buff carries into hard room")
	_expect(scene.is_running, "hard room resumes run")
	_expect(not scene.transition_locked, "hard room releases transition lock")
	scene.metronome.stop()
	root.remove_child(scene)
	scene.free()


func _test_transition_asset_mapping() -> void:
	var scene := MvpScene.instantiate()
	root.add_child(scene)
	scene.beat_clock.stop()
	var transition_assets := [
		[StateScript.LAYER_ONE, TRANSITION_ATRIUM_TO_VENTRICLE],
		[StateScript.LAYER_TWO, TRANSITION_VENTRICLE_TO_ATRIUM],
		[StateScript.LAYER_THREE, TRANSITION_ATRIUM_TO_VENTRICLE4],
		[StateScript.LAYER_FOUR, TRANSITION_ENDING_REVIVAL],
	]
	for layer_and_texture in transition_assets:
		scene.room_state.layer_index = int(layer_and_texture[0])
		scene.room_state.room_kind = StateScript.ROOM_BOSS
		var selected: Texture2D = scene._get_layer_transition_texture()
		_expect(selected == layer_and_texture[1], "layer %d maps to its generated transition art" % int(layer_and_texture[0]))
		scene._prepare_transition_overlay("test", selected)
		_expect(scene.transition_art.visible and scene.transition_art.texture == selected, "layer %d transition art is visible" % int(layer_and_texture[0]))
		_expect(scene.transition_streaks.is_empty(), "generated transition has no procedural color blocks")
		scene._reset_transition_visuals()
	scene.room_state.layer_index = StateScript.LAYER_FOUR
	scene.room_state.room_kind = StateScript.ROOM_BOSS
	scene._prepare_transition_overlay("心核复苏", scene._get_layer_transition_texture())
	_expect(scene.transition_label.text == "心核复苏", "final transition avoids a fifth-floor label")
	scene._prepare_transition_overlay("fallback", null)
	_expect(not scene.transition_art.visible and scene.transition_streaks.is_empty(), "non-layer transition has no procedural color blocks")
	scene.metronome.stop()
	root.remove_child(scene)
	scene.free()


func _test_scene_boss_phase_and_victory() -> void:
	var scene := MvpScene.instantiate()
	root.add_child(scene)
	scene.beat_clock.stop()
	_advance_scene_to_boss(scene)
	scene.beat_clock.stop()
	_expect(scene.room_state.room_kind == StateScript.ROOM_BOSS, "scene reaches boss room")
	var boss: MvpUnitState = scene.room_state.enemies[0]
	_expect(boss.unit_id == "boss" and scene.room_state.room_title.find("泥鳃") >= 0, "scene identifies the venous glutton")
	_expect(scene.boss_health_panel.visible, "boss room shows the top health bar")
	_expect(scene.boss_health_label.text == "静脉吸附者·泥鳃", "boss health title shows identity only")
	scene.room_state.player.hp = 1
	scene.room_state._enter_room(StateScript.ROOM_BOSS)
	_expect(scene.room_state.player.hp == scene.room_state.player.max_hp, "entering a boss room restores full health")
	scene.room_view.set_room()
	boss = scene.room_state.enemies[0]
	scene._refresh_ui()
	_expect(is_equal_approx(scene.boss_health_bar.max_value, float(boss.max_hp)), "boss health bar uses boss max hp")
	_expect(is_equal_approx(scene.boss_health_bar.value, float(boss.hp)), "boss health bar starts at current hp")
	scene.room_state.player.cell = Vector2i(3, 2)
	boss.cell = Vector2i(5, 2)
	scene._reset_pending_input()
	scene._on_beat_resolved(1)
	_expect(scene.room_state.boss_cycle_beat == 1, "boss scene advances its four-beat timeline")
	_expect(scene.room_state.mud_hazards.size() > 0, "boss scene exposes sediment hazards")
	scene._on_beat_resolved(2)
	_expect(boss.enemy_plan == &"sweep", "boss scene stores the sweep telegraph")
	_expect(scene.status_label.text.find("横扫蓄力") >= 0 and scene.intent_label.text.find("3 格") >= 0, "boss scene states the visible charge and sweep range")
	scene._on_beat_resolved(3)
	scene._on_beat_resolved(4)
	_expect(scene.room_state.boss_cycle_beat == 0, "boss scene returns to the start of its bar")
	_expect(scene.status_label.text.find("安全输出拍") >= 0, "boss recovery replaces the removed suction beat")
	_expect(is_equal_approx(scene.beat_clock.bpm, StateScript.BASE_BPM), "boss scene never changes global bpm")

	# Kill the boss, approach the central portal, and invoke interaction.
	boss.hp = 1
	scene.room_state.player.cell = Vector2i(4, 2)
	boss.cell = Vector2i(6, 2)
	scene._reset_pending_input()
	scene.pending_action = &"direction"
	scene.pending_direction = Vector2i.RIGHT
	scene.input_locked = true
	scene._on_beat_resolved(3)
	_expect(not boss.is_alive(), "boss is defeated")
	_expect(scene.room_state.room_cleared, "boss defeat opens exit")
	_expect(is_equal_approx(scene.boss_health_bar.value, 0.0), "boss health bar reaches zero on defeat")
	_expect(is_equal_approx(scene.beat_clock.bpm, StateScript.BASE_BPM), "boss defeat ends the combat bpm shift")
	_expect(scene.rhythm_hud.phase_warning <= 0.0, "boss defeat clears the phase warning")
	_expect(not scene.end_overlay.visible, "boss defeat waits for exit transition")
	_expect(scene.room_view.get_exit_door_center().distance_to(scene.room_view._board_center()) < 0.1, "boss defeat moves the portal to the board center")
	scene.room_state.player.cell = Vector2i(5, 2)
	_expect(scene.room_state.is_near_next_layer_portal(), "player can approach the central next-layer portal")
	var interact_key := InputEventKey.new()
	interact_key.pressed = true
	interact_key.keycode = KEY_E
	scene._unhandled_key_input(interact_key)
	_expect(scene.transition_locked, "portal interaction locks transition")
	scene._advance_room()
	_expect(scene.room_state.room_kind == StateScript.ROOM_START, "portal enters next layer start room directly")
	_expect(scene.room_state.layer_index == StateScript.LAYER_TWO, "portal advances to second layer")
	_expect(not scene.room_state.run_finished, "portal transition keeps the run alive")
	_expect(not scene.end_overlay.visible, "non-final Boss does not show ending overlay")
	_expect(scene.room_state.room_title.find("右心室") >= 0, "next layer identifies the right ventricle")
	_expect(scene.is_running, "next layer resumes run")
	_expect(not scene.transition_overlay.visible, "portal transition hides transition overlay")
	_expect(not scene.transition_locked, "portal transition releases transition lock")
	_expect(not scene.boss_health_panel.visible, "next layer start hides the boss health bar")
	_expect(is_equal_approx(scene.beat_clock.bpm, StateScript.BASE_BPM), "next layer start restores base bpm")
	scene.metronome.stop()
	root.remove_child(scene)
	scene.free()


func _test_scene_boss_player_death_bpm_reset() -> void:
	var scene := MvpScene.instantiate()
	root.add_child(scene)
	scene.beat_clock.stop()
	_advance_scene_to_boss(scene)
	scene.beat_clock.stop()
	scene.beat_clock.bpm = scene.room_state.get_bpm()
	_expect(is_equal_approx(scene.beat_clock.bpm, StateScript.BASE_BPM), "living venous glutton uses the common bpm")
	scene.room_state.player.hp = 0
	scene._finish_run(false)
	_expect(scene.room_state.run_finished, "boss-room player death finishes the run")
	_expect(is_equal_approx(scene.beat_clock.bpm, StateScript.BASE_BPM), "player death leaves boss combat bpm")
	_expect(scene.rhythm_hud.phase_warning <= 0.0, "player death clears boss phase warning")
	scene.metronome.stop()
	root.remove_child(scene)
	scene.free()


func _test_visual_layout_contracts() -> void:
	var scene := MvpScene.instantiate()
	root.add_child(scene)
	scene.beat_clock.stop()
	var view: MvpRoomView = scene.room_view

	# The opening heart is a map landmark rather than an occupiable unit. On an
	# even-height 11x6 board it must sit between the two central rows, with the
	# generated texture's actual alpha mass centered on the board midpoint.
	var map_core := view.actor_layer.get_node_or_null("heart_core") as Sprite2D
	_expect(map_core != null, "opening room creates its heart core landmark")
	if map_core != null:
		_expect(_sprite_alpha_centroid(map_core).distance_to(view._board_center()) < 0.01, "map heart visible mass is centered on the complete board")

	# A new room must expose the player at the normal gameplay scale from the
	# first visible frame; the arrival tween may move/fade, but never resize it.
	scene._advance_room()
	scene.beat_clock.stop()
	var normal_scale := Vector2.ONE * view._actor_scale_factor(&"player")
	_expect(view.player_sprite.scale.is_equal_approx(normal_scale), "room arrival starts at the normal player scale")
	await create_timer(0.12).timeout
	_expect(view.player_sprite.scale.is_equal_approx(normal_scale), "room arrival keeps the player scale during the slide")
	await create_timer(0.24).timeout
	_expect(view.player_sprite.scale.is_equal_approx(normal_scale), "room arrival ends at the normal player scale")

	# Exercise a real vertical tween. The visible silhouette must stay on the
	# same column while travelling and land on the destination tile center.
	var from_cell := Vector2i(4, 3)
	var to_cell := Vector2i(4, 2)
	scene.room_state.player.cell = to_cell
	scene.room_state.player.facing = Vector2i.UP
	view.set_room()
	scene.beat_clock.stop()
	view._animate_move("player", {"from": from_cell, "to": to_cell}, 0.0)
	await create_timer(0.08).timeout
	var mid_center := _sprite_visual_center(view.player_sprite)
	var from_center := view._cell_center(from_cell)
	var to_center := view._cell_center(to_cell)
	_expect(absf(mid_center.x - from_center.x) < 0.01, "vertical movement keeps the silhouette on the tile column")
	_expect(mid_center.y < from_center.y and mid_center.y > to_center.y, "vertical movement interpolates between tile centers")
	await create_timer(0.16).timeout
	var landed_center := _sprite_visual_center(view.player_sprite)
	_expect(landed_center.distance_to(to_center) < 0.01, "vertical movement lands the silhouette on the destination tile center")

	# Center the generated heart's alpha-weighted visual mass in the gap between
	# the title and result copy, not merely its top-heavy TextureRect bounds.
	scene._finish_run(false)
	var title_bottom: float = scene.end_title.position.y + scene.end_title.size.y
	var copy_top: float = scene.end_body.position.y
	var expected_emblem_center := Vector2(scene.end_panel.size.x * 0.5, (title_bottom + copy_top) * 0.5)
	var emblem_visual_center: Vector2 = _texture_rect_alpha_centroid(scene.end_emblem)
	_expect(scene.end_emblem.size.is_equal_approx(Vector2(64.0, 64.0)), "ending core uses its fixed render size")
	_expect(emblem_visual_center.distance_to(expected_emblem_center) < 0.01, "ending core visible mass is centered between title and result copy")
	await create_timer(0.04).timeout
	_expect(scene.end_emblem.size.is_equal_approx(Vector2(64.0, 64.0)), "ending core size remains fixed after a frame")
	_expect(_texture_rect_alpha_centroid(scene.end_emblem).distance_to(expected_emblem_center) < 0.01, "ending core visible mass remains centered after a frame")

	scene.metronome.stop()
	root.remove_child(scene)
	scene.free()


func _test_delayed_presentation_safety() -> void:
	var scene := MvpScene.instantiate()
	root.add_child(scene)
	scene.beat_clock.stop()

	# A surviving enemy is hurt first, then spends the same beat telegraphing its
	# answer. Both actors must return to atlas poses after the ordered timeline.
	scene._advance_room()
	scene.beat_clock.stop()
	var enemy: MvpUnitState = scene.room_state.enemies[0]
	scene.room_state.player.cell = Vector2i(5, 1)
	enemy.cell = Vector2i(6, 1)
	enemy.hp = 3
	scene.room_view.set_room()
	scene._reset_pending_input()
	scene.pending_action = &"direction"
	scene.pending_direction = Vector2i.RIGHT
	scene.input_locked = true
	scene._on_beat_resolved(1)
	_expect(scene.room_state.player.hp == scene.room_state.player.max_hp, "presentation keeps player safe during enemy windup")
	_expect(scene.status_label.text.find("举刀") >= 0, "controller labels the enemy windup")
	await create_timer(0.72).timeout
	_expect(scene.room_view.player_sprite.visible, "player remains visible after hurt recovery")
	_expect(scene.room_view.player_sprite.hframes == 4, "player hurt restores atlas pose")
	_expect(is_equal_approx(scene.room_view.player_sprite.modulate.a, 1.0), "player hurt restores opacity")
	var enemy_sprite: Sprite2D = scene.room_view.actor_sprites.get(enemy.unit_id)
	_expect(enemy_sprite != null and enemy_sprite.hframes == 4, "enemy hurt then answer restores atlas pose")

	# Restarting during a pending death must invalidate all old presentation
	# callbacks so they cannot kill the new run's player sprite.
	scene.room_state.player.cell = enemy.cell + Vector2i.LEFT
	scene.room_state.player.hp = 1
	scene._reset_pending_input()
	scene._on_beat_resolved(2)
	var generation_before_restart: int = scene.room_view.presentation_generation
	scene.restart_run()
	scene.beat_clock.stop()
	await create_timer(0.48).timeout
	_expect(scene.room_state.room_kind == StateScript.ROOM_START, "death restart stays in start room")
	_expect(scene.room_view.presentation_generation > generation_before_restart, "restart invalidates old presentation generation")
	_expect(scene.room_view.player_sprite.visible, "old death callback cannot hide new player")
	_expect(is_equal_approx(scene.room_view.player_sprite.modulate.a, 1.0), "old death callback cannot fade new player")

	# Restarting during a room transition must also cancel the old controller
	# tween; otherwise its delayed callback advances the new run unexpectedly.
	scene.room_state.player.cell = Vector2i(StateScript.GRID_SIZE.x - 1, 2)
	scene._schedule_next_room()
	_expect(scene.transition_tween != null, "transition tween exists before restart")
	scene.restart_run()
	scene.beat_clock.stop()
	await create_timer(0.62).timeout
	_expect(scene.room_state.room_kind == StateScript.ROOM_START, "transition restart stays in start room")
	_expect(scene.transition_tween == null, "restart clears transition tween")
	_expect(not scene.transition_overlay.visible, "restart keeps transition overlay hidden")
	scene.metronome.stop()
	root.remove_child(scene)
	scene.free()


func _advance_scene_to_boss(scene: Node) -> void:
	# Start -> normal -> reward -> hard -> boss; reward tween callbacks are
	# intentionally bypassed by calling the controller's private callbacks.
	scene._advance_room()
	scene._advance_room()
	scene._choose_reward(1)
	scene._advance_room()
	scene._advance_room()


func _enemy_result(results: Array, enemy_id: String) -> Dictionary:
	for result in results:
		if String(result.get("enemy_id", "")) == enemy_id:
			return result
	return {}


func _expect(condition: bool, label: String) -> void:
	if not condition:
		failures.append(label)
