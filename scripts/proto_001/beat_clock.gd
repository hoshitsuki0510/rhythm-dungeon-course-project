class_name BeatClock
extends Node

signal beat_started(beat_number: int)
signal beat_resolved(beat_number: int)
signal beat_cue_requested(beat_number: int)

enum TimingJudgement {
	HIT,
	EARLY,
	LATE,
}

const MAX_CATCH_UP_BEATS := 8

@export_range(40.0, 240.0, 1.0) var bpm := 100.0
@export_range(0.03, 0.25, 0.005) var timing_window := 0.12
# Negative keeps the original behavior: resolve as soon as timing_window ends.
# A caller may temporarily extend only the late resolution edge without
# widening the normal HIT judgement (used by the MVP rhythm shield).
@export var resolution_window := -1.0
@export_range(0, 4, 1) var lead_in_beats := 1

var is_running := false
var beat_number := 1
var beat_center_time := 0.0
## Shifts visual notes and input judgement relative to the audible click.
## Positive values make the chart arrive later; negative values earlier.
var chart_offset_seconds := 0.0
## Audio output is requested this many seconds before the audible beat center.
var audio_lead_time := 0.0
var _cue_emitted := false
var _started_emitted := false
var _advancing := false
var _pending_bpm := -1.0


var beat_period: float:
	get:
		return 60.0 / bpm


func _process(_delta: float) -> void:
	if is_running:
		advance_to(now_seconds())


func start(at_time_seconds: float = -1.0) -> void:
	_pending_bpm = -1.0
	_advancing = false
	var start_time := at_time_seconds
	if start_time < 0.0:
		start_time = now_seconds()
	beat_number = 1
	beat_center_time = start_time + beat_period * lead_in_beats
	_cue_emitted = false
	_started_emitted = false
	is_running = true


func stop() -> void:
	is_running = false
	_pending_bpm = -1.0
	_advancing = false


func set_bpm_preserving_phase(new_bpm: float) -> void:
	# A beat_resolved signal is emitted synchronously from advance_to(). Queue
	# live tempo changes while that loop is advancing; changing the clock's
	# cursor from inside a signal callback can otherwise make the same beat get
	# re-evaluated or leave the controller resolving forever.
	var clamped_bpm := clampf(new_bpm, 40.0, 240.0)
	if _advancing:
		_pending_bpm = clamped_bpm
		return
	_apply_bpm_preserving_phase(clamped_bpm, now_seconds())


func _apply_bpm_preserving_phase(new_bpm: float, reference_time: float) -> void:
	bpm = new_bpm
	if is_running:
		beat_center_time = reference_time + beat_period
		_cue_emitted = false
		_started_emitted = false


func advance_to(sample_time: float) -> void:
	_advancing = true
	for _step in range(MAX_CATCH_UP_BEATS):
		if not _cue_emitted and sample_time >= beat_center_time - audio_lead_time:
			_cue_emitted = true
			beat_cue_requested.emit(beat_number)
		var judgement_center := get_judgement_center_time()
		if not _started_emitted and sample_time >= judgement_center:
			_started_emitted = true
			beat_started.emit(beat_number)
		if sample_time < judgement_center + get_resolution_window():
			_advancing = false
			return

		beat_resolved.emit(beat_number)
		if not is_running:
			_advancing = false
			return
		beat_number += 1
		if _pending_bpm >= 0.0:
			var next_bpm := _pending_bpm
			_pending_bpm = -1.0
			_apply_bpm_preserving_phase(next_bpm, sample_time)
		else:
			beat_center_time += beat_period
			_cue_emitted = false
			_started_emitted = false
	_advancing = false


func judge_time(sample_time: float = -1.0) -> TimingJudgement:
	var offset := get_timing_offset(sample_time)
	return judgement_from_offset(offset)


func judgement_from_offset(offset: float) -> TimingJudgement:
	if absf(offset) <= timing_window:
		return TimingJudgement.HIT
	if offset < 0.0:
		return TimingJudgement.EARLY
	return TimingJudgement.LATE


func get_timing_offset(sample_time: float = -1.0) -> float:
	var resolved_time := sample_time
	if resolved_time < 0.0:
		resolved_time = now_seconds()
	return resolved_time - get_judgement_center_time()


func get_judgement_center_time(target_beat_number: int = -1) -> float:
	var target := beat_number if target_beat_number < 0 else target_beat_number
	return beat_center_time + float(target - beat_number) * beat_period + chart_offset_seconds


func get_input_timing(sample_time: float = -1.0) -> Dictionary:
	var resolved_time := sample_time
	if resolved_time < 0.0:
		resolved_time = now_seconds()
	var current_center := get_judgement_center_time()
	# Inputs are owned by exactly one live beat.  Nearest-beat rounding looks
	# attractive, but it turns a late press in the dead space after beat N into
	# an early press for beat N+1.  That consumes the next beat and creates the
	# cascading failure users feel after one slow input.  Use the midpoint only
	# on the *past* side: a press closer to the already-resolved beat is reported
	# as stale and cannot consume the current beat.  The future side stays owned
	# by the current beat so ordinary early/late misses retain their old rules.
	var target_beat := beat_number
	var previous_center := current_center - beat_period
	var ownership_midpoint := (previous_center + current_center) * 0.5
	if beat_number > 1 and resolved_time < ownership_midpoint:
		target_beat -= 1
	var target_center := get_judgement_center_time(target_beat)
	var offset := resolved_time - target_center
	return {
		"target_beat": target_beat,
		"current_beat": beat_number,
		"offset": offset,
		"judgement": judgement_from_offset(offset),
	}


func get_marker_ratio(sample_time: float = -1.0) -> float:
	var half_period := beat_period * 0.5
	return clampf(get_timing_offset(sample_time) / half_period, -1.0, 1.0)


func get_resolution_window() -> float:
	return maxf(timing_window, resolution_window if resolution_window >= 0.0 else timing_window)


func now_seconds() -> float:
	return float(Time.get_ticks_usec()) / 1_000_000.0
