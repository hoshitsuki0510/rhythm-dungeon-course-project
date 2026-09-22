extends SceneTree

const BeatClockScript = preload("res://scripts/proto_001/beat_clock.gd")
const RoomStateScript = preload("res://scripts/proto_001/room_state.gd")
const PrototypeScene = preload("res://scenes/prototypes/proto_001_room.tscn")

var failures: Array[String] = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	_test_beat_clock()
	_test_room_turn_order()
	_test_scene_and_input_lock()

	if failures.is_empty():
		print("PROTO_001_SMOKE_OK | clock timing input_lock move miss attack enemy_turn victory defeat restart scene")
		quit(0)
		return

	for failure in failures:
		push_error("PROTO_001_SMOKE_FAIL | " + failure)
	quit(1)


func _test_beat_clock() -> void:
	var clock = BeatClockScript.new()
	clock.bpm = 120.0
	clock.timing_window = 0.10
	clock.lead_in_beats = 1
	var started: Array[int] = []
	var resolved: Array[int] = []
	clock.beat_started.connect(func(index: int) -> void: started.append(index))
	clock.beat_resolved.connect(func(index: int) -> void: resolved.append(index))
	clock.start(10.0)

	_expect_close(clock.beat_period, 0.5, "clock period")
	_expect_close(clock.beat_center_time, 10.5, "clock lead-in")
	_expect(
		clock.judge_time(10.50) == clock.TimingJudgement.HIT,
		"timing hit judgement"
	)
	_expect(
		clock.judge_time(10.35) == clock.TimingJudgement.EARLY,
		"timing early judgement"
	)
	_expect(
		clock.judge_time(10.65) == clock.TimingJudgement.LATE,
		"timing late judgement"
	)

	clock.advance_to(10.50)
	_expect(started == [1], "beat started signal")
	clock.advance_to(10.61)
	_expect(resolved == [1], "beat resolved signal")
	_expect(clock.beat_number == 2, "beat number advances")
	# A late press that arrives after beat 1 has resolved must not be rounded
	# into beat 2.  This is the regression for the cascading early-miss bug.
	var stale_late := clock.get_input_timing(10.70)
	_expect(stale_late.target_beat == 1, "late input keeps ownership of resolved beat")
	_expect(stale_late.judgement == clock.TimingJudgement.LATE, "stale late input is reported as late")
	var next_beat := clock.get_input_timing(10.90)
	_expect(next_beat.target_beat == 2, "next beat early window remains available")
	_expect(next_beat.judgement == clock.TimingJudgement.HIT, "next beat can still be hit after stale input")
	clock.chart_offset_seconds = 0.075
	_expect_close(clock.get_judgement_center_time(), 11.075, "chart offset shifts judgement center")
	_expect(clock.get_input_timing(10.975).target_beat == 2, "chart offset applies to input ownership")
	var cues: Array[int] = []
	clock.beat_cue_requested.connect(func(index: int) -> void: cues.append(index))
	clock.start(20.0)
	clock.advance_to(20.5 - clock.audio_lead_time)
	clock.advance_to(20.5)
	_expect(cues == [1], "audio cue emits once per beat")
	clock.stop()
	clock.free()


func _test_room_turn_order() -> void:
	var room = RoomStateScript.new()
	var result := room.resolve_turn(&"direction", Vector2i.RIGHT)
	_expect(room.player.cell == Vector2i(2, 2), "player moves one cell")
	_expect(room.enemy.cell == Vector2i(5, 2), "enemy follows after player")
	_expect(result.player.kind == "move", "move result kind")
	_expect(result.enemy.kind == "move", "enemy move result kind")

	room.reset()
	result = room.resolve_turn(&"wait")
	_expect(room.player.cell == RoomStateScript.PLAYER_START, "wait keeps player still")
	_expect(room.enemy.cell == Vector2i(5, 2), "wait still advances enemy")
	_expect(room.player.hp == RoomStateScript.PLAYER_MAX_HP, "wait has no direct damage")

	room.player.cell = Vector2i(4, 2)
	room.enemy.cell = Vector2i(5, 2)
	room.enemy.hp = room.enemy.max_hp
	result = room.resolve_turn(&"direction", Vector2i.RIGHT)
	_expect(room.enemy.hp == room.enemy.max_hp - 1, "adjacent player attack")
	_expect(room.player.hp == RoomStateScript.PLAYER_MAX_HP - 1, "surviving enemy attacks after player")
	_expect(result.enemy.kind == "attack", "enemy attack result kind")

	room.reset()
	room.player.cell = Vector2i(4, 2)
	room.enemy.cell = Vector2i(5, 2)
	room.enemy.hp = 1
	result = room.resolve_turn(&"direction", Vector2i.RIGHT)
	_expect(result.room_cleared, "last enemy clears room")
	_expect(result.enemy.kind == "none", "defeated enemy skips its turn")
	_expect(room.player.hp == RoomStateScript.PLAYER_MAX_HP, "victory skips enemy damage")

	room.reset()
	_expect(room.player.cell == RoomStateScript.PLAYER_START, "restart player position")
	_expect(room.enemy.cell == RoomStateScript.ENEMY_START, "restart enemy position")
	_expect(room.turn_number == 0, "restart turn counter")

	var final_result := {}
	for _turn in range(12):
		final_result = room.resolve_turn(&"wait")
		if final_result.player_defeated:
			break
	_expect(final_result.player_defeated, "enemy can defeat player")
	_expect(room.player.hp == 0, "defeat clamps player hp")


func _test_scene_and_input_lock() -> void:
	var scene = PrototypeScene.instantiate()
	root.add_child(scene)
	var clock = scene.get_node("%BeatClock")
	clock.stop()
	_expect(scene.is_running, "scene starts running")
	_expect(scene.room_state.player.cell == RoomStateScript.PLAYER_START, "scene binds room state")

	var accepted: bool = scene.submit_direction_at(Vector2i.RIGHT, clock.beat_center_time)
	var duplicate: bool = scene.submit_direction_at(Vector2i.LEFT, clock.beat_center_time)
	_expect(accepted, "first input accepted")
	_expect(not duplicate, "second input in beat rejected")
	scene._on_beat_resolved(1)
	_expect(scene.room_state.player.cell == Vector2i(2, 2), "accepted input resolves once")
	_expect(scene.beat_label.text == "BEAT  02", "resolved beat shows next beat number")
	_expect(scene.judge_label.text == "READY", "resolved beat returns judgement to ready")

	scene.restart_room()
	clock.stop()
	var miss_accepted: bool = scene.submit_direction_at(
		Vector2i.RIGHT,
		clock.beat_center_time - clock.timing_window - 0.05
	)
	_expect(miss_accepted, "miss input is consumed")
	scene._on_beat_resolved(1)
	_expect(scene.room_state.player.cell == RoomStateScript.PLAYER_START, "miss blocks player action")
	_expect(scene.room_state.player.hp == RoomStateScript.PLAYER_MAX_HP, "miss has no direct damage")
	_expect(scene.room_state.enemy.cell == Vector2i(5, 2), "miss still advances enemy")

	scene.room_state.player.cell = Vector2i(1, 2)
	scene.room_state.enemy.cell = Vector2i(2, 2)
	scene.room_state.player.hp = 1
	scene._reset_pending_input()
	scene._on_beat_resolved(2)
	_expect(not scene.is_running, "scene reaches defeat state")
	_expect(scene.end_overlay.visible, "defeat shows result overlay")
	scene.restart_button.pressed.emit()
	clock.stop()
	_expect(scene.room_state.turn_number == 0, "scene restart resets room")
	_expect(not scene.end_overlay.visible, "scene restart hides result")
	root.remove_child(scene)
	scene.free()


func _expect(condition: bool, label: String) -> void:
	if not condition:
		failures.append(label)


func _expect_close(actual: float, expected: float, label: String) -> void:
	if not is_equal_approx(actual, expected):
		failures.append("%s (%f != %f)" % [label, actual, expected])
