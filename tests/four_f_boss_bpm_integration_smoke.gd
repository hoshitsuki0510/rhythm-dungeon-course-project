extends SceneTree

# Regression coverage for the 4F arrhythmia Boss half-health BPM switch.
# upper_layers_smoke drives the pure state machine and beat_clock_phase_shift_smoke
# drives the pure clock; neither exercises the real controller receiving
# beat_resolved from a running BeatClock and queuing the BPM change from inside
# that synchronous emission. The user-reported freeze lived exactly there.
const StateScript = preload("res://scripts/mvp/mvp_state.gd")
const MvpScene = preload("res://scenes/mvp/mvp_run.tscn")
const FRAME_STEP := 1.0 / 120.0
var failures: Array[String] = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	_test_four_f_boss_bpm_integration()
	if failures.is_empty():
		print("FOUR_F_BOSS_BPM_INTEGRATION_OK | half_health_trigger queued_bpm_change_from_signal continuous_beats post_shift_input_and_resolution no_controller_lock_leak")
		quit(0)
		return
	for failure in failures:
		push_error("FOUR_F_BOSS_BPM_INTEGRATION_FAIL | " + failure)
	quit(1)


func _test_four_f_boss_bpm_integration() -> void:
	var scene := MvpScene.instantiate()
	root.add_child(scene)
	scene.beat_clock.stop()
	# Isolate the persisted player chart offset (user://mvp_settings.cfg) so the
	# judgement centre is exactly beat_center_time inside this test.
	scene.configure_timing(0.0)
	scene._jump_debug_room(StateScript.LAYER_FOUR, StateScript.ROOM_BOSS)
	scene.beat_clock.stop()
	var clock: BeatClock = scene.beat_clock
	var boss: MvpUnitState = scene.room_state.get_boss()
	_expect(boss != null and scene.room_state.boss_kind == &"arrhythmia", "debug jump loads the 4F arrhythmia boss")
	_expect(is_equal_approx(clock.bpm, 105.0), "4F boss room arms the clock at 105 bpm")
	if boss == null:
		_finish(scene)
		return

	# Stand next to the boss and drop it to exactly half health with one hit so
	# the four-beat defibrillation countdown starts on the same resolution.
	scene.room_state.player.cell = boss.cell + Vector2i.LEFT
	boss.hp = int(boss.max_hp / 2) + 1
	var beats_before_shift := 0
	clock.start(100.0)
	_expect(scene.submit_direction_at(Vector2i.RIGHT, clock.beat_center_time), "half-health attack input is accepted")

	# Pump frames like _process would until the phase shift beat resolves.
	while not (scene.room_state.boss_phase == 2 and clock.bpm > 139.0):
		var center := clock.beat_center_time
		_pump(clock, center, center + clock.beat_period)
		beats_before_shift += 1
		if beats_before_shift > 12:
			_expect(false, "phase shift resolves within a bounded number of beats (stuck after %d beats, bpm %.1f, pending %s)" % [beats_before_shift, clock.bpm, str(scene.room_state.boss_phase_shift_pending)])
			_finish(scene)
			return
	_expect(scene.room_state.boss_phase == 2, "half health triggers the phase shift through the live clock")
	_expect(is_equal_approx(clock.bpm, 140.0), "queued bpm applies after the signal emission returns")

	# The freeze report: after the shift the beat line stops advancing and input
	# no longer resolves. Move the player out of the boss's up/down/left rays
	# (gameplay-safe cell, boss rays cannot reach x > boss.x) and press a charge
	# every beat for 14 beats; each beat must resolve and accept the input.
	scene.room_state.player.cell = boss.cell + Vector2i(3, 0)
	scene.room_view.set_room()
	var beat_at_shift := clock.beat_number
	var center_after_shift := clock.beat_center_time
	_expect(center_after_shift > 100.0 + FRAME_STEP, "next beat centre stays in the future after the shift")
	for _press in range(14):
		var center := clock.beat_center_time
		var accepted: bool = scene.submit_charge_at(center)
		_expect(accepted, "post-shift beat still accepts input")
		_pump(clock, center, center + clock.beat_period)
		_expect(clock.beat_number > beat_at_shift, "post-shift beats keep resolving (beat %d)" % clock.beat_number)
		if clock.beat_number <= beat_at_shift:
			_finish(scene)
			return
		beat_at_shift = clock.beat_number
		_expect(scene.is_running and not scene.resolving, "controller stays live after the shift")
		if not scene.is_running or scene.resolving:
			_finish(scene)
			return
		_expect(scene.room_state.charged, "post-shift charge action resolves on the beat")
	_expect(is_equal_approx(clock.bpm, 140.0), "clock keeps the shifted bpm afterwards")
	_expect(scene.room_state.boss_phase == 2 and not scene.room_state.boss_phase_shift_pending, "shift state stays settled")
	_finish(scene)


func _pump(clock: BeatClock, from_t: float, to_t: float) -> void:
	var t := from_t
	while t < to_t:
		t += FRAME_STEP
		clock.advance_to(minf(t, to_t))


func _finish(scene: Node) -> void:
	scene.metronome.stop()
	root.remove_child(scene)
	scene.free()


func _expect(condition: bool, label: String) -> void:
	if not condition:
		failures.append(label)
