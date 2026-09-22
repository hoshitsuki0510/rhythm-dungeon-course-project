class_name MvpRhythmHud
extends Control

const COLOR_IDLE := Color(0.28, 0.38, 0.35, 1.0)
const COLOR_READY := Color(0.25, 0.88, 0.76, 1.0)
const COLOR_HIT := Color(0.43, 1.0, 0.62, 1.0)
const COLOR_MISS := Color(1.0, 0.34, 0.34, 1.0)
const COLOR_MARKER := Color(1.0, 0.72, 0.25, 1.0)
const COLOR_PHASE := Color(1.0, 0.25, 0.72, 1.0)
const COLOR_SHIELD := Color(0.42, 0.88, 1.0, 1.0)
# Four notes still fill the lane, but the farthest one now enters three beats
# before judgement instead of four, increasing visible travel speed by 33%.
const FALL_LEAD_BEATS := 3.0
const NOTE_COUNT := 4
const TRACK_TOP := 20.0
const JUDGEMENT_Y := 120.0

var beat_clock: BeatClock
var pulse := 0.0
var judgement_flash := 0.0
var judgement_color := COLOR_IDLE
var phase_warning := 0.0
var charge_ready := false
var shield_ready := false
var shield_window := 0.20


func bind_clock(clock: BeatClock) -> void:
	beat_clock = clock
	queue_redraw()


func notify_beat() -> void:
	pulse = 1.0
	queue_redraw()


func set_judgement(kind: StringName) -> void:
	if kind == &"hit":
		judgement_color = COLOR_HIT
	elif kind == &"shield":
		judgement_color = COLOR_SHIELD
	elif kind == &"miss":
		judgement_color = COLOR_MISS
	else:
		judgement_color = COLOR_IDLE
	judgement_flash = 1.0
	queue_redraw()


func set_action_states(has_charge: bool, has_shield: bool, assist_window: float) -> void:
	charge_ready = has_charge
	shield_ready = has_shield
	shield_window = assist_window
	queue_redraw()


func set_phase_warning(active: bool) -> void:
	phase_warning = 1.0 if active else 0.0
	queue_redraw()


func reset_feedback() -> void:
	pulse = 0.0
	judgement_flash = 0.0
	judgement_color = COLOR_IDLE
	phase_warning = 0.0
	charge_ready = false
	shield_ready = false
	queue_redraw()


# The public progress helper makes the visual track testable without sampling a
# rendered frame: 0 is the spawn edge and 1 is the judgement line.
func get_note_progress(note_offset: int, sample_time: float = -1.0) -> float:
	if beat_clock == null:
		return 0.0
	var now := sample_time if sample_time >= 0.0 else beat_clock.now_seconds()
	var target_time := beat_clock.get_judgement_center_time(beat_clock.beat_number + note_offset)
	return 1.0 - (target_time - now) / (beat_clock.beat_period * FALL_LEAD_BEATS)


func _process(delta: float) -> void:
	pulse = maxf(0.0, pulse - delta * 4.8)
	judgement_flash = maxf(0.0, judgement_flash - delta * 3.5)
	phase_warning = maxf(0.0, phase_warning - delta * 0.65)
	queue_redraw()


func _draw() -> void:
	if beat_clock == null:
		return
	var lane_center := size.x * 0.5
	var lane_rect := Rect2(lane_center - 46.0, 12.0, 92.0, size.y - 18.0)
	var accent := COLOR_PHASE if phase_warning > 0.0 else COLOR_READY
	var feedback := accent.lerp(judgement_color, judgement_flash * 0.72)

	# A compact, game-world-friendly note highway replaces the former debug
	# ring and timing meter. Notes travel from the upper spawn edge toward the
	# horizontal line at the bottom, like a conventional rhythm-game lane.
	draw_rect(lane_rect, Color(0.008, 0.018, 0.016, 0.86), true)
	draw_rect(lane_rect, Color(accent, 0.34), false, 1.0)
	draw_line(Vector2(lane_center - 28.0, TRACK_TOP), Vector2(lane_center - 28.0, JUDGEMENT_Y), Color(accent, 0.22), 1.0)
	draw_line(Vector2(lane_center + 28.0, TRACK_TOP), Vector2(lane_center + 28.0, JUDGEMENT_Y), Color(accent, 0.22), 1.0)
	for guide_y in [38.0, 62.0, 86.0]:
		_draw_down_chevron(Vector2(lane_center, guide_y), Color(accent, 0.13))

	var track_distance := JUDGEMENT_Y - TRACK_TOP
	var timing_pixels := maxf(4.0, beat_clock.timing_window / (beat_clock.beat_period * FALL_LEAD_BEATS) * track_distance)
	if shield_ready:
		var shield_pixels := maxf(timing_pixels, shield_window / (beat_clock.beat_period * FALL_LEAD_BEATS) * track_distance)
		draw_rect(Rect2(lane_center - 42.0, JUDGEMENT_Y - shield_pixels, 84.0, shield_pixels * 2.0), Color(COLOR_SHIELD, 0.10), true)
	draw_rect(Rect2(lane_center - 42.0, JUDGEMENT_Y - timing_pixels, 84.0, timing_pixels * 2.0), Color(COLOR_HIT, 0.13), true)

	for note_offset in range(NOTE_COUNT):
		var progress := get_note_progress(note_offset)
		if progress < -0.08 or progress > 1.18:
			continue
		var note_y := lerpf(TRACK_TOP, JUDGEMENT_Y, progress)
		var is_downbeat := (beat_clock.beat_number + note_offset - 1) % 4 == 0
		var note_color := COLOR_MARKER if is_downbeat else COLOR_READY
		if phase_warning > 0.0:
			note_color = note_color.lerp(COLOR_PHASE, 0.44)
		var line_proximity := 1.0 - clampf(absf(progress - 1.0) / 0.20, 0.0, 1.0)
		_draw_note(Vector2(lane_center, note_y), 7.0 + line_proximity * 2.0 + pulse * line_proximity * 2.0, note_color, line_proximity)

	# The judgement line is deliberately the strongest fixed landmark. A small
	# pulse and result flash reinforce successful timing without adding text or
	# diagnostic numbers to the permanent game screen.
	draw_rect(Rect2(lane_center - 50.0, JUDGEMENT_Y - 2.0, 100.0, 4.0), Color(feedback, 0.18 + judgement_flash * 0.22), true)
	draw_line(Vector2(lane_center - 50.0, JUDGEMENT_Y), Vector2(lane_center + 50.0, JUDGEMENT_Y), feedback, 2.0 + pulse * 1.5)
	draw_line(Vector2(lane_center - 50.0, JUDGEMENT_Y - 6.0), Vector2(lane_center - 50.0, JUDGEMENT_Y + 6.0), feedback, 2.0)
	draw_line(Vector2(lane_center + 50.0, JUDGEMENT_Y - 6.0), Vector2(lane_center + 50.0, JUDGEMENT_Y + 6.0), feedback, 2.0)
	if charge_ready:
		draw_arc(Vector2(lane_center, JUDGEMENT_Y), 17.0 + pulse * 2.0, PI, TAU, 20, COLOR_MARKER, 2.0)


func _draw_down_chevron(center: Vector2, color: Color) -> void:
	draw_polyline(PackedVector2Array([
		center + Vector2(-8.0, -3.0),
		center + Vector2(0.0, 3.0),
		center + Vector2(8.0, -3.0),
	]), color, 1.0)


func _draw_note(center: Vector2, radius: float, color: Color, glow: float) -> void:
	if glow > 0.0:
		draw_circle(center, radius + 7.0 + pulse * glow * 2.0, Color(color, 0.06 + glow * 0.10))
	var diamond := PackedVector2Array([
		center + Vector2(0.0, -radius),
		center + Vector2(radius, 0.0),
		center + Vector2(0.0, radius),
		center + Vector2(-radius, 0.0),
	])
	draw_colored_polygon(diamond, Color(color, 0.92))
	draw_polyline(PackedVector2Array([
		diamond[0], diamond[1], diamond[2], diamond[3], diamond[0],
	]), Color.WHITE.lerp(color, 0.45), 1.5)
	draw_circle(center, maxf(1.5, radius * 0.22), Color(1.0, 0.96, 0.74, 0.9))
