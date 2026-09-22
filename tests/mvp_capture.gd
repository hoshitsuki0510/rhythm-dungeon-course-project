extends SceneTree

const MvpScene = preload("res://scenes/mvp/mvp_run.tscn")
const StateScript = preload("res://scripts/mvp/mvp_state.gd")
const TWO_BEAT_CAPTURE_TAIL := 0.72


func _init() -> void:
	call_deferred("_capture")


func _capture() -> void:
	if DisplayServer.get_name().to_lower() == "headless":
		push_error("MVP_CAPTURE_FAIL | a display driver is required; run this script without --headless")
		quit(2)
		return
	var scene = MvpScene.instantiate()
	root.add_child(scene)
	await process_frame
	var mode := OS.get_environment("MVP_CAPTURE_MODE")
	if mode != "start" and mode != "settings":
		# The formal scene opens on the title screen in a display session. Start
		# gameplay before preparing interactive capture modes such as pause.
		scene.start_game()
	scene.beat_clock.stop()
	if mode.is_empty():
		mode = "action"
	var frame_count := _prepare_capture(scene, mode)
	var second_beat_deadline := -1.0
	var second_beat_resolved := false
	if mode == "action" or mode == "death" or mode == "clash":
		# The capture must follow the gameplay clock rather than assuming that
		# every rendered frame is exactly 1/60 s.  This keeps the two-beat proof
		# valid when the window is composited at a different refresh rate.
		second_beat_deadline = scene.beat_clock.now_seconds() + scene.beat_clock.beat_period
	var capture_duration := maxf(float(frame_count) / 60.0, 0.05)
	if second_beat_deadline >= 0.0:
		# Leave enough wall-clock time for the second-beat lunge and its hurt or
		# death tail, even on a high-refresh display that renders 72 frames fast.
		capture_duration = maxf(capture_duration, scene.beat_clock.beat_period + TWO_BEAT_CAPTURE_TAIL)
	var capture_deadline: float = scene.beat_clock.now_seconds() + capture_duration
	while scene.beat_clock.now_seconds() < capture_deadline:
		# Action/clash/death captures intentionally span both halves of the regular
		# enemy's two-beat timeline.  The first resolved beat is the visible
		# windup; the second is scheduled while that pose is still held so the
		# generated AVI shows the actual lunge/impact as well.
		if (
			second_beat_deadline >= 0.0
			and not second_beat_resolved
			and scene.beat_clock.now_seconds() >= second_beat_deadline
		):
			scene._on_beat_resolved(2)
			second_beat_resolved = true
		await process_frame
	if second_beat_deadline >= 0.0 and not second_beat_resolved:
		push_error("MVP_CAPTURE_FAIL | second beat was not reached before capture deadline")
		quit(1)
		return
	var viewport_texture: Texture2D = root.get_viewport().get_texture()
	if viewport_texture == null:
		push_error("MVP_CAPTURE_FAIL | viewport texture unavailable")
		quit(1)
		return
	var image: Image = viewport_texture.get_image()
	if image == null or image.is_empty():
		push_error("MVP_CAPTURE_FAIL | rendered image unavailable")
		quit(1)
		return
	var output_path := OS.get_environment("MVP_CAPTURE_PATH")
	if output_path.is_empty():
		output_path = "/tmp/rhythm-mvp-%s.png" % mode
	var save_error := image.save_png(output_path)
	if save_error != OK:
		push_error("MVP_CAPTURE_FAIL | could not save image (%s)" % save_error)
		quit(1)
		return
	if scene.game_paused:
		scene._set_game_paused(false)
	print("MVP_CAPTURE_OK | %s | %s" % [mode, output_path])
	quit(0)


func _prepare_capture(scene: MvpController, mode: String) -> int:
	match mode:
		"start":
			scene.room_view.set_room()
			scene._refresh_ui()
			return 3
		"vertical":
			scene.room_state.player.cell = Vector2i(4, 4)
			scene.room_state.player.facing = Vector2i.UP
			scene.room_view.set_room()
			scene._reset_pending_input()
			scene.pending_action = &"direction"
			scene.pending_direction = Vector2i.UP
			scene.input_locked = true
			scene._on_beat_resolved(1)
			return 12
		"pause":
			scene._set_game_paused(true)
			return 4
		"settings":
			scene._show_main_menu()
			scene._open_settings()
			return 4
		"transition":
			_enter_room(scene, StateScript.ROOM_NORMAL)
			scene.room_state.room_cleared = true
			scene.room_state.player.cell = Vector2i(StateScript.GRID_SIZE.x - 1, 2)
			scene.room_view.set_room()
			scene._schedule_next_room()
			return 15
		"charge":
			_enter_room(scene, StateScript.ROOM_NORMAL)
			var enemy: MvpUnitState = scene.room_state.enemies[0]
			scene.room_state.player.cell = Vector2i(2, 2)
			enemy.cell = Vector2i(6, 1)
			scene.room_state.rhythm_shield = true
			scene.room_view.set_room()
			scene._reset_pending_input()
			scene.pending_action = &"charge"
			scene.input_locked = true
			scene._on_beat_resolved(1)
			return 7
		"reward":
			_enter_room(scene, StateScript.ROOM_REWARD)
			scene.room_view.set_room()
			scene.is_running = false
			scene.reward_overlay.visible = true
			scene._refresh_ui()
			return 3
		"mud":
			_enter_room(scene, StateScript.ROOM_HARD)
			scene.room_state.player.cell = Vector2i(3, 4)
			scene.room_view.set_room()
			for _beat in range(4):
				var mud_result: Dictionary = scene.room_state.resolve_turn(&"wait")
				scene.room_view.present_turn(mud_result)
			scene._refresh_ui()
			return 18
		"boss":
			_enter_room(scene, StateScript.ROOM_BOSS)
			scene.room_view.set_room()
			scene.room_state.player.cell = Vector2i(1, 2)
			scene.room_state.boss_cycle_beat = 1
			var charge_result: Dictionary = scene.room_state.resolve_turn(&"wait")
			scene.room_view.present_turn(charge_result)
			scene._refresh_ui()
			return 24
		"boss2", "boss3", "boss4":
			var upper_layer := int(mode.trim_prefix("boss"))
			scene.room_state.layer_index = upper_layer
			scene.room_state._enter_room(StateScript.ROOM_BOSS)
			scene.room_view.set_room()
			var boss_result: Dictionary = scene.room_state.resolve_turn(&"wait")
			scene.room_view.present_turn(boss_result)
			scene._refresh_ui()
			return 30
		"layer_transition1", "layer_transition2", "layer_transition3", "ending_transition":
			var transition_layer := 4 if mode == "ending_transition" else int(mode.trim_prefix("layer_transition"))
			scene.room_state.layer_index = transition_layer
			scene.room_state._enter_room(StateScript.ROOM_BOSS)
			scene.room_state.room_cleared = true
			scene.room_view.set_room()
			scene._refresh_ui()
			scene._schedule_next_room()
			return 28
		"death":
			_enter_room(scene, StateScript.ROOM_NORMAL)
			var enemy: MvpUnitState = scene.room_state.enemies[0]
			scene.room_state.player.cell = enemy.cell + Vector2i.LEFT
			scene.room_state.player.hp = 1
			scene.room_view.set_room()
			scene._reset_pending_input()
			scene._on_beat_resolved(1)
			return 72
		"clash":
			_enter_room(scene, StateScript.ROOM_NORMAL)
			var enemy: MvpUnitState = scene.room_state.enemies[0]
			scene.room_state.player.cell = enemy.cell + Vector2i.LEFT
			scene.room_view.set_room()
			scene._reset_pending_input()
			# Beat one raises the enemy weapon; the scheduled second beat below
			# resolves the player's matching attack into the combined clash tween.
			scene._on_beat_resolved(1)
			scene.pending_action = &"direction"
			scene.pending_direction = Vector2i.RIGHT
			scene.input_locked = true
			return 72
		"victory":
			_enter_room(scene, StateScript.ROOM_BOSS)
			scene.room_state.room_cleared = true
			scene.room_state.player.cell = Vector2i(5, 2)
			scene.room_view.set_room()
			scene._refresh_ui()
			scene._finish_run(true)
			return 30
		_:
			_enter_room(scene, StateScript.ROOM_NORMAL)
			var enemy: MvpUnitState = scene.room_state.enemies[0]
			scene.room_state.player.cell = Vector2i(5, 1)
			enemy.cell = Vector2i(6, 1)
			enemy.hp = 2
			scene.room_view.set_room()
			scene._reset_pending_input()
			scene.pending_action = &"direction"
			scene.pending_direction = Vector2i.RIGHT
			scene.input_locked = true
			scene._on_beat_resolved(1)
			return 72


func _enter_room(scene: MvpController, target_room: int) -> void:
	while scene.room_state.room_kind < target_room and scene.room_state.room_kind < StateScript.ROOM_BOSS:
		scene.room_state.enter_next_room()
