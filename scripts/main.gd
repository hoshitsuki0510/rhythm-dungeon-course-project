extends Control

const BPM := 100.0
const BEAT_PERIOD := 60.0 / BPM
const TIMING_WINDOW := 0.18
const GRID_SIZE := Vector2i(7, 5)
const GRID_ORIGIN := Vector2(48.0, 130.0)
const CELL_SIZE := 64.0
const PLAYER_START := Vector2i(1, 2)
const ENEMY_START := Vector2i(5, 2)
const PLAYER_MAX_HP := 4
const ENEMY_MAX_HP := 3

const BG := Color(0.025, 0.043, 0.075, 1.0)
const PANEL := Color(0.055, 0.082, 0.13, 1.0)
const GRID_A := Color(0.075, 0.115, 0.16, 1.0)
const GRID_B := Color(0.06, 0.095, 0.14, 1.0)
const CYAN := Color(0.20, 0.90, 0.98, 1.0)
const BLUE := Color(0.22, 0.68, 1.0, 1.0)
const RED := Color(0.95, 0.30, 0.36, 1.0)
const GREEN := Color(0.34, 0.92, 0.58, 1.0)
const AMBER := Color(1.0, 0.72, 0.24, 1.0)
const MUTED := Color(0.54, 0.64, 0.73, 1.0)

@onready var metronome: AudioStreamPlayer = $Metronome
@onready var hud_label: Label = %HudLabel
@onready var status_label: Label = %StatusLabel
@onready var end_overlay: ColorRect = %EndOverlay
@onready var end_title: Label = %EndTitle
@onready var end_body: Label = %EndBody

var player_cell := PLAYER_START
var enemy_cell := ENEMY_START
var player_hp := PLAYER_MAX_HP
var enemy_hp := ENEMY_MAX_HP
var combo := 0
var beat_index := 0
var beat_center_time := 0.0
var beat_pulsed := false
var beat_input_locked := false
var has_pending_action := false
var pending_direction := Vector2i.ZERO
var pending_miss := false
var is_running := true
var pulse_flash := 0.0
var player_hit_flash := 0.0
var feedback_text := "准备：黄点进入绿色区域时按方向键"
var feedback_color := CYAN
var click_stream: AudioStreamWAV


func _ready() -> void:
	click_stream = _build_click_stream()
	_reset_demo()
	if DisplayServer.get_name() == "headless":
		call_deferred("_run_headless_smoke")


func _process(delta: float) -> void:
	pulse_flash = maxf(0.0, pulse_flash - delta * 5.0)
	player_hit_flash = maxf(0.0, player_hit_flash - delta * 6.0)
	if is_running:
		_advance_beat_clock(_now_seconds())
	_update_hud()
	queue_redraw()


func _unhandled_key_input(event: InputEvent) -> void:
	if not event is InputEventKey:
		return
	var key_event := event as InputEventKey
	if not key_event.pressed or key_event.echo:
		return

	var physical_code := key_event.physical_keycode
	if physical_code == KEY_R or key_event.keycode == KEY_R:
		_reset_demo()
		get_viewport().set_input_as_handled()
		return
	if not is_running:
		if physical_code == KEY_ENTER or key_event.keycode == KEY_ENTER:
			_reset_demo()
			get_viewport().set_input_as_handled()
		return

	var direction := Vector2i.ZERO
	if key_event.is_action_pressed("ui_up") or physical_code == KEY_W:
		direction = Vector2i.UP
	elif key_event.is_action_pressed("ui_down") or physical_code == KEY_S:
		direction = Vector2i.DOWN
	elif key_event.is_action_pressed("ui_left") or physical_code == KEY_A:
		direction = Vector2i.LEFT
	elif key_event.is_action_pressed("ui_right") or physical_code == KEY_D:
		direction = Vector2i.RIGHT
	else:
		return

	_submit_direction(direction)
	get_viewport().set_input_as_handled()


func _submit_direction(direction: Vector2i) -> void:
	if beat_input_locked:
		_set_feedback("本拍已有输入，等待下一拍", MUTED)
		return

	var offset := _now_seconds() - beat_center_time
	beat_input_locked = true
	if absf(offset) <= TIMING_WINDOW:
		has_pending_action = true
		pending_direction = direction
		_set_feedback("HIT · 已进入拍点窗口", GREEN)
	else:
		pending_miss = true
		combo = 0
		_set_feedback("MISS · 输入太早" if offset < 0.0 else "MISS · 输入太晚", RED)


func _advance_beat_clock(now: float) -> void:
	for _step in range(12):
		if not beat_pulsed and now >= beat_center_time:
			beat_pulsed = true
			pulse_flash = 1.0
			metronome.stream = click_stream
			metronome.play()
		if now >= beat_center_time + TIMING_WINDOW:
			_resolve_beat()
			if not is_running:
				return
			beat_index += 1
			beat_center_time += BEAT_PERIOD
			beat_pulsed = false
			beat_input_locked = false
			has_pending_action = false
			pending_direction = Vector2i.ZERO
			pending_miss = false
			continue
		break


func _resolve_beat() -> void:
	var summary := ""
	if has_pending_action:
		summary = _apply_player_action(pending_direction)
		combo += 1
		if enemy_hp <= 0:
			_finish_demo(true)
			return
	else:
		combo = 0
		summary = "MISS · 行动失败" if pending_miss else "WAIT · 本拍没有行动"

	var took_damage := _apply_enemy_turn()
	if took_damage:
		summary += " · BOSS 攻击 -1 HP"
		_set_feedback(summary, RED)
	else:
		_set_feedback(summary, GREEN if has_pending_action else MUTED)
	if player_hp <= 0:
		_finish_demo(false)


func _apply_player_action(direction: Vector2i) -> String:
	var target := player_cell + direction
	if not _inside_grid(target):
		return "HIT · 撞到边界"
	if target == enemy_cell:
		enemy_hp -= 1
		return "HIT · 攻击 BOSS -1 HP"
	player_cell = target
	return "HIT · 移动一格"


func _apply_enemy_turn() -> bool:
	if _manhattan(enemy_cell, player_cell) == 1:
		player_hp = maxi(0, player_hp - 1)
		player_hit_flash = 1.0
		return true

	var delta := player_cell - enemy_cell
	var step := Vector2i.ZERO
	if abs(delta.x) >= abs(delta.y) and delta.x != 0:
		step.x = int(sign(delta.x))
	elif delta.y != 0:
		step.y = int(sign(delta.y))
	var candidate := enemy_cell + step
	if candidate != player_cell and _inside_grid(candidate):
		enemy_cell = candidate
	return false


func _reset_demo() -> void:
	player_cell = PLAYER_START
	enemy_cell = ENEMY_START
	player_hp = PLAYER_MAX_HP
	enemy_hp = ENEMY_MAX_HP
	combo = 0
	beat_index = 0
	beat_center_time = _now_seconds() + 1.0
	beat_pulsed = false
	beat_input_locked = false
	has_pending_action = false
	pending_direction = Vector2i.ZERO
	pending_miss = false
	is_running = true
	pulse_flash = 0.0
	player_hit_flash = 0.0
	end_overlay.visible = false
	_set_feedback("准备：黄点进入绿色区域时按方向键", CYAN)
	queue_redraw()


func _finish_demo(player_won: bool) -> void:
	is_running = false
	metronome.stop()
	end_overlay.visible = true
	if player_won:
		end_title.text = "展示完成：击败 BOSS"
		end_title.add_theme_color_override("font_color", GREEN)
		end_body.text = "这只是核心玩法草模，不代表正式开发完成。\n按 R 或 Enter 重新演示"
	else:
		end_title.text = "展示结束：玩家倒下"
		end_title.add_theme_color_override("font_color", RED)
		end_body.text = "失拍会让 BOSS 继续行动。\n按 R 或 Enter 重新演示"


func _update_hud() -> void:
	hud_label.text = (
		"BPM　%d\n" % int(BPM)
		+ "当前拍　%d\n" % (beat_index + 1)
		+ "玩家 HP　%d / %d\n" % [player_hp, PLAYER_MAX_HP]
		+ "BOSS HP　%d / %d\n" % [enemy_hp, ENEMY_MAX_HP]
		+ "连续命中　%d" % combo
	)
	status_label.text = feedback_text
	status_label.add_theme_color_override("font_color", feedback_color)


func _set_feedback(message: String, color: Color) -> void:
	feedback_text = message
	feedback_color = color


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), BG)
	_draw_grid()
	_draw_side_panel()


func _draw_grid() -> void:
	var board_size := Vector2(GRID_SIZE) * CELL_SIZE
	draw_rect(Rect2(GRID_ORIGIN - Vector2(8.0, 8.0), board_size + Vector2(16.0, 16.0)), PANEL)
	for y in range(GRID_SIZE.y):
		for x in range(GRID_SIZE.x):
			var cell_rect := Rect2(GRID_ORIGIN + Vector2(x, y) * CELL_SIZE, Vector2.ONE * CELL_SIZE)
			draw_rect(cell_rect, GRID_A if (x + y) % 2 == 0 else GRID_B)
			draw_rect(cell_rect, Color(0.18, 0.29, 0.38, 0.7), false, 1.0)

	var player_center := _cell_center(player_cell)
	var player_color := Color.WHITE if player_hit_flash > 0.0 else BLUE
	draw_rect(Rect2(player_center - Vector2(18.0, 18.0), Vector2(36.0, 36.0)), player_color)
	draw_rect(Rect2(player_center - Vector2(7.0, 7.0), Vector2(14.0, 14.0)), BG)

	var enemy_center := _cell_center(enemy_cell)
	draw_rect(Rect2(enemy_center - Vector2(18.0, 18.0), Vector2(36.0, 36.0)), RED)
	draw_circle(enemy_center, 7.0, BG)
	var enemy_bar := Rect2(enemy_center + Vector2(-22.0, -29.0), Vector2(44.0, 5.0))
	draw_rect(enemy_bar, Color(0.15, 0.04, 0.07, 1.0))
	draw_rect(Rect2(enemy_bar.position, Vector2(enemy_bar.size.x * float(enemy_hp) / ENEMY_MAX_HP, 5.0)), RED)


func _draw_side_panel() -> void:
	var panel_rect := Rect2(535.0, 92.0, 380.0, 365.0)
	draw_rect(panel_rect, PANEL)
	draw_rect(panel_rect, Color(0.16, 0.28, 0.38, 1.0), false, 2.0)
	var pulse_center := Vector2(725.0, 128.0)
	draw_circle(pulse_center, 33.0 + pulse_flash * 12.0, Color(CYAN, 0.08 + pulse_flash * 0.14))
	draw_arc(pulse_center, 26.0 + pulse_flash * 8.0, 0.0, TAU, 40, CYAN, 4.0)
	draw_circle(pulse_center, 7.0 + pulse_flash * 5.0, CYAN)

	var bar := Rect2(575.0, 350.0, 300.0, 16.0)
	draw_rect(bar, Color(0.015, 0.025, 0.045, 1.0))
	var center_x := bar.get_center().x
	var window_pixels := TIMING_WINDOW / BEAT_PERIOD * bar.size.x
	draw_rect(Rect2(center_x - window_pixels, bar.position.y, window_pixels * 2.0, bar.size.y), Color(GREEN, 0.34))
	draw_line(Vector2(center_x, bar.position.y - 7.0), Vector2(center_x, bar.end.y + 7.0), CYAN, 2.0)
	var offset := _now_seconds() - beat_center_time
	var marker_ratio := clampf(offset / (BEAT_PERIOD * 0.5), -1.0, 1.0)
	draw_circle(Vector2(center_x + marker_ratio * bar.size.x * 0.5, bar.get_center().y), 7.0, AMBER)


func _cell_center(cell: Vector2i) -> Vector2:
	return GRID_ORIGIN + Vector2(cell) * CELL_SIZE + Vector2.ONE * CELL_SIZE * 0.5


func _inside_grid(cell: Vector2i) -> bool:
	return cell.x >= 0 and cell.y >= 0 and cell.x < GRID_SIZE.x and cell.y < GRID_SIZE.y


func _manhattan(first: Vector2i, second: Vector2i) -> int:
	return absi(first.x - second.x) + absi(first.y - second.y)


func _build_click_stream() -> AudioStreamWAV:
	const SAMPLE_RATE := 22050
	const SAMPLE_COUNT := 1100
	var bytes := PackedByteArray()
	bytes.resize(SAMPLE_COUNT * 2)
	for index in range(SAMPLE_COUNT):
		var time_seconds := float(index) / SAMPLE_RATE
		var wave := sin(TAU * 920.0 * time_seconds) * exp(-time_seconds * 60.0) * 0.32
		bytes.encode_s16(index * 2, int(wave * 32767.0))
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = SAMPLE_RATE
	stream.stereo = false
	stream.data = bytes
	return stream


func _now_seconds() -> float:
	return float(Time.get_ticks_usec()) / 1_000_000.0


func _run_headless_smoke() -> void:
	is_running = false
	var failures: Array[String] = []
	player_cell = Vector2i(1, 1)
	enemy_cell = Vector2i(5, 1)
	_apply_player_action(Vector2i.RIGHT)
	if player_cell != Vector2i(2, 1):
		failures.append("player movement")
	enemy_cell = Vector2i(3, 1)
	enemy_hp = 1
	_apply_player_action(Vector2i.RIGHT)
	if enemy_hp != 0 or player_cell != Vector2i(2, 1):
		failures.append("adjacent attack")
	enemy_hp = ENEMY_MAX_HP
	enemy_cell = player_cell + Vector2i.RIGHT
	player_hp = PLAYER_MAX_HP
	if not _apply_enemy_turn() or player_hp != PLAYER_MAX_HP - 1:
		failures.append("enemy turn")
	_reset_demo()
	is_running = false
	if player_cell != PLAYER_START or enemy_cell != ENEMY_START or player_hp != PLAYER_MAX_HP:
		failures.append("restart state")
	if failures.is_empty():
		print("SHOWCASE_SMOKE_OK | beat grid move attack enemy restart")
		get_tree().quit(0)
	else:
		for failure in failures:
			push_error("SHOWCASE_SMOKE_FAIL | " + failure)
		get_tree().quit(1)
