extends SceneTree

var failures: Array[String] = []
var clock: BeatClock
var resolved := 0

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	clock = BeatClock.new()
	clock.bpm = 105.0
	clock.timing_window = 0.12
	clock.lead_in_beats = 0
	get_root().add_child(clock)
	clock.beat_resolved.connect(_on_beat_resolved)
	clock.start(0.0)
	# Resolve beat 1. The callback requests the live 140 BPM phase change while
	# BeatClock.advance_to() is still inside its synchronous signal emission.
	clock.advance_to(0.70)
	_expect(resolved == 1, "first beat resolves once")
	_expect(clock.beat_number == 2, "clock advances to the next beat")
	_expect(is_equal_approx(clock.bpm, 140.0), "queued phase shift applies 140 BPM")
	_expect(clock.is_running, "clock keeps running after phase shift")
	_expect(clock.beat_center_time > 0.70, "next beat center stays in the future")
	clock.advance_to(clock.beat_center_time + 0.13)
	_expect(resolved == 2, "next beat resolves after phase shift")
	_expect(clock.beat_number == 3, "beat numbering continues after phase shift")
	if failures.is_empty():
		print("BEAT_CLOCK_PHASE_SHIFT_SMOKE_OK | queued_bpm_change continuous_resolution")
		quit(0)
		return
	for failure in failures:
		push_error("BEAT_CLOCK_PHASE_SHIFT_SMOKE_FAIL | " + failure)
	quit(1)

func _on_beat_resolved(beat: int) -> void:
	resolved += 1
	if beat == 1:
		clock.set_bpm_preserving_phase(140.0)

func _expect(condition: bool, label: String) -> void:
	if not condition:
		failures.append(label)
