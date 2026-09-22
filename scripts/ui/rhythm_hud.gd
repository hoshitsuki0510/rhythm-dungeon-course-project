class_name RhythmHud
extends Control

const COLOR_IDLE := Color(0.43, 0.50, 0.49, 1.0)
const COLOR_READY := Color(0.22, 0.82, 0.74, 1.0)
const COLOR_HIT := Color(0.35, 0.91, 0.55, 1.0)
const COLOR_MISS := Color(0.94, 0.34, 0.30, 1.0)
const COLOR_MARKER := Color(1.0, 0.72, 0.24, 1.0)

var beat_clock
var pulse_flash := 0.0
var judgement_flash := 0.0
var judgement_color := COLOR_IDLE


func bind_clock(clock) -> void:
	beat_clock = clock
	queue_redraw()


func notify_beat() -> void:
	pulse_flash = 1.0
	queue_redraw()


func set_judgement(kind: StringName) -> void:
	match kind:
		&"hit":
			judgement_color = COLOR_HIT
		&"miss":
			judgement_color = COLOR_MISS
		_:
			judgement_color = COLOR_IDLE
	judgement_flash = 1.0
	queue_redraw()


func reset_feedback() -> void:
	pulse_flash = 0.0
	judgement_flash = 0.0
	judgement_color = COLOR_IDLE
	queue_redraw()


func _process(delta: float) -> void:
	pulse_flash = maxf(0.0, pulse_flash - delta * 4.5)
	judgement_flash = maxf(0.0, judgement_flash - delta * 3.5)
	queue_redraw()


func _draw() -> void:
	if beat_clock == null:
		return

	var center := Vector2(size.x * 0.5, 41.0)
	var ring_color := COLOR_READY.lerp(judgement_color, judgement_flash * 0.65)
	draw_circle(center, 27.0 + pulse_flash * 9.0, Color(ring_color, 0.08 + pulse_flash * 0.12))
	draw_arc(center, 22.0 + pulse_flash * 5.0, 0.0, TAU, 48, ring_color, 4.0)
	draw_circle(center, 5.0 + pulse_flash * 4.0, ring_color)

	var bar := Rect2(16.0, 84.0, size.x - 32.0, 15.0)
	draw_rect(bar, Color(0.035, 0.045, 0.042, 1.0))
	var center_x := bar.get_center().x
	var window_pixels: float = beat_clock.timing_window / beat_clock.beat_period * bar.size.x
	draw_rect(
		Rect2(center_x - window_pixels, bar.position.y, window_pixels * 2.0, bar.size.y),
		Color(COLOR_HIT, 0.30)
	)
	draw_line(
		Vector2(center_x, bar.position.y - 5.0),
		Vector2(center_x, bar.end.y + 5.0),
		COLOR_READY,
		2.0
	)
	var marker_x: float = center_x + beat_clock.get_marker_ratio() * bar.size.x * 0.5
	draw_circle(Vector2(marker_x, bar.get_center().y), 7.0, COLOR_MARKER)

	var active_pip: int = (beat_clock.beat_number - 1) % 4
	var pip_gap := 24.0
	var pip_start := center_x - pip_gap * 1.5
	for index in range(4):
		var pip_color := COLOR_READY if index == active_pip else COLOR_IDLE
		draw_circle(Vector2(pip_start + index * pip_gap, 119.0), 4.0, pip_color)
