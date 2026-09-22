extends Control

const RoomStateScript = preload("res://scripts/proto_001/room_state.gd")

const COLOR_TEXT := Color(0.88, 0.91, 0.88, 1.0)
const COLOR_MUTED := Color(0.57, 0.62, 0.58, 1.0)
const COLOR_READY := Color(0.22, 0.82, 0.74, 1.0)
const COLOR_HIT := Color(0.35, 0.91, 0.55, 1.0)
const COLOR_MISS := Color(0.94, 0.34, 0.30, 1.0)
const COLOR_WARNING := Color(1.0, 0.72, 0.24, 1.0)

@onready var beat_clock = %BeatClock
@onready var metronome: AudioStreamPlayer = %Metronome
@onready var room_view = %RoomView
@onready var rhythm_hud = %RhythmHud
@onready var bpm_label: Label = %BpmLabel
@onready var beat_label: Label = %BeatLabel
@onready var judge_label: Label = %JudgeLabel
@onready var stats_label: Label = %StatsLabel
@onready var intent_label: Label = %IntentLabel
@onready var status_label: Label = %StatusLabel
@onready var end_overlay: ColorRect = %EndOverlay
@onready var end_title: Label = %EndTitle
@onready var end_body: Label = %EndBody
@onready var restart_button: Button = %RestartButton

var room_state = RoomStateScript.new()
var is_running := false
var input_locked := false
var pending_action: StringName = &"none"
var pending_direction := Vector2i.ZERO
var pending_miss_text := ""
var combo := 0
var successful_actions := 0
var misses := 0
var click_stream: AudioStreamWAV


func _ready() -> void:
	room_view.bind_room(room_state)
	rhythm_hud.bind_clock(beat_clock)
	beat_clock.beat_started.connect(_on_beat_started)
	beat_clock.beat_resolved.connect(_on_beat_resolved)
	restart_button.pressed.connect(restart_room)
	click_stream = _build_click_stream()
	restart_room()


func _unhandled_key_input(event: InputEvent) -> void:
	if not event is InputEventKey:
		return
	var key_event := event as InputEventKey
	if not key_event.pressed or key_event.echo:
		return

	var physical_code := key_event.physical_keycode
	if physical_code == KEY_R or key_event.keycode == KEY_R:
		restart_room()
		get_viewport().set_input_as_handled()
		return
	if not is_running:
		if physical_code == KEY_ENTER or key_event.keycode == KEY_ENTER:
			restart_room()
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

	submit_direction_at(direction)
	get_viewport().set_input_as_handled()


func submit_direction_at(direction: Vector2i, sample_time: float = -1.0) -> bool:
	if not is_running or input_locked or direction == Vector2i.ZERO:
		return false

	input_locked = true
	var judgement: int = beat_clock.judge_time(sample_time)
	var offset_ms := int(round(beat_clock.get_timing_offset(sample_time) * 1000.0))
	if judgement == beat_clock.TimingJudgement.HIT:
		pending_action = &"direction"
		pending_direction = direction
		judge_label.text = "GOOD  %+d ms" % offset_ms
		judge_label.add_theme_color_override("font_color", COLOR_HIT)
		rhythm_hud.set_judgement(&"hit")
		_set_status("行动已锁定，等待本拍结算", COLOR_HIT)
	else:
		pending_action = &"miss"
		pending_miss_text = "EARLY" if judgement == beat_clock.TimingJudgement.EARLY else "LATE"
		judge_label.text = "%s  %+d ms" % [pending_miss_text, offset_ms]
		judge_label.add_theme_color_override("font_color", COLOR_MISS)
		rhythm_hud.set_judgement(&"miss")
		_set_status("失拍：本拍行动失败", COLOR_MISS)
	return true


func restart_room() -> void:
	room_state.reset()
	combo = 0
	successful_actions = 0
	misses = 0
	is_running = true
	_reset_pending_input()
	end_overlay.visible = false
	room_view.reset_feedback()
	rhythm_hud.reset_feedback()
	judge_label.text = "READY"
	judge_label.add_theme_color_override("font_color", COLOR_READY)
	_set_status("心核脉冲正在建立", COLOR_READY)
	beat_clock.start()
	_refresh_ui()


func _on_beat_started(_beat_number: int) -> void:
	rhythm_hud.notify_beat()
	metronome.stream = click_stream
	metronome.play()
	beat_label.text = "BEAT  %02d" % beat_clock.beat_number
	if not input_locked:
		judge_label.text = "NOW"
		judge_label.add_theme_color_override("font_color", COLOR_WARNING)


func _on_beat_resolved(resolved_beat_number: int) -> void:
	if not is_running:
		return

	var action_kind: StringName = &"wait"
	if pending_action == &"direction":
		action_kind = &"direction"
	var result := room_state.resolve_turn(action_kind, pending_direction)
	_apply_turn_feedback(result)
	if result.room_cleared:
		_finish_room(true)
		return
	if result.player_defeated:
		_finish_room(false)
		return

	_reset_pending_input()
	_refresh_ui()
	beat_label.text = "BEAT  %02d" % (resolved_beat_number + 1)
	judge_label.text = "READY"
	judge_label.add_theme_color_override("font_color", COLOR_READY)


func _apply_turn_feedback(result: Dictionary) -> void:
	var player_result: Dictionary = result.player
	var enemy_result: Dictionary = result.enemy
	var player_text := ""
	var status_color := COLOR_TEXT

	if pending_action == &"miss":
		combo = 0
		misses += 1
		player_text = "%s：行动失败" % pending_miss_text
		status_color = COLOR_MISS
	elif pending_action == &"none":
		combo = 0
		player_text = "WAIT：本拍未行动"
		status_color = COLOR_MUTED
	else:
		match String(player_result.kind):
			"move":
				combo += 1
				successful_actions += 1
				player_text = "移动一格"
				room_view.show_action()
			"attack":
				combo += 1
				successful_actions += 1
				player_text = "攻击命中  -%d HP" % int(player_result.damage)
				room_view.show_enemy_hit()
			"blocked":
				combo = 0
				player_text = "边界阻挡"
				status_color = COLOR_WARNING

	if String(enemy_result.kind) == "attack":
		player_text += "  ·  敌人攻击  -%d HP" % int(enemy_result.damage)
		status_color = COLOR_MISS
		room_view.show_player_hit()
	elif String(enemy_result.kind) == "move":
		player_text += "  ·  敌人逼近"

	_set_status(player_text, status_color)


func _finish_room(player_won: bool) -> void:
	is_running = false
	beat_clock.stop()
	metronome.stop()
	end_overlay.visible = true
	if player_won:
		end_title.text = "房间净化"
		end_title.add_theme_color_override("font_color", COLOR_HIT)
		end_body.text = "基础敌人已被击败\n回合 %d  ·  有效行动 %d  ·  失拍 %d" % [
			room_state.turn_number,
			successful_actions,
			misses,
		]
	else:
		end_title.text = "探索中止"
		end_title.add_theme_color_override("font_color", COLOR_MISS)
		end_body.text = "心核同步已经断开\n回合 %d  ·  有效行动 %d  ·  失拍 %d" % [
			room_state.turn_number,
			successful_actions,
			misses,
		]
	_refresh_ui()


func _reset_pending_input() -> void:
	input_locked = false
	pending_action = &"none"
	pending_direction = Vector2i.ZERO
	pending_miss_text = ""


func _refresh_ui() -> void:
	bpm_label.text = "%d BPM  ·  ±%d ms" % [
		int(beat_clock.bpm),
		int(round(beat_clock.timing_window * 1000.0)),
	]
	beat_label.text = "BEAT  %02d" % beat_clock.beat_number
	stats_label.text = (
		"探索者     %d / %d HP\n" % [room_state.player.hp, room_state.player.max_hp]
		+ "守卫怪物   %d / %d HP\n" % [room_state.enemy.hp, room_state.enemy.max_hp]
		+ "连续同步   %d" % combo
	)
	if not room_state.enemy.is_alive():
		intent_label.text = "威胁清除"
		intent_label.add_theme_color_override("font_color", COLOR_HIT)
	elif room_state.is_enemy_threatening_player():
		intent_label.text = "敌人意图  攻击"
		intent_label.add_theme_color_override("font_color", COLOR_MISS)
	else:
		intent_label.text = "敌人意图  追击"
		intent_label.add_theme_color_override("font_color", COLOR_WARNING)
	room_view.queue_redraw()


func _set_status(message: String, color: Color) -> void:
	status_label.text = message
	status_label.add_theme_color_override("font_color", color)


func _build_click_stream() -> AudioStreamWAV:
	const SAMPLE_RATE := 22050
	const SAMPLE_COUNT := 1050
	var bytes := PackedByteArray()
	bytes.resize(SAMPLE_COUNT * 2)
	for index in range(SAMPLE_COUNT):
		var time_seconds := float(index) / SAMPLE_RATE
		var wave := sin(TAU * 880.0 * time_seconds) * exp(-time_seconds * 58.0) * 0.28
		bytes.encode_s16(index * 2, int(wave * 32767.0))
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = SAMPLE_RATE
	stream.stereo = false
	stream.data = bytes
	return stream
