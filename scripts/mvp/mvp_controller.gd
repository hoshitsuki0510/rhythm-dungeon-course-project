class_name MvpController
extends Control

const BeatClockScript = preload("res://scripts/proto_001/beat_clock.gd")
const StateScript = preload("res://scripts/mvp/mvp_state.gd")
const RoomViewScript = preload("res://scripts/mvp/mvp_room_view.gd")
const RhythmHudScript = preload("res://scripts/mvp/mvp_rhythm_hud.gd")
const SettingsScript = preload("res://scripts/mvp/mvp_settings.gd")
const HEART_FULL = preload("res://assets/ui/heart_full.png")
const HEART_EMPTY = preload("res://assets/ui/heart_empty.png")
const CHARGE_ICON = preload("res://assets/ui/charge_one.png")
const SHIELD_ICON = preload("res://assets/ui/shield_ready.png")
const TEMPO_ICON = preload("res://assets/items/echo_tempo.png")
const GUARD_ICON = preload("res://assets/items/echo_guard.png")
const IMPACT_ICON = preload("res://assets/items/echo_impact.png")
const VIGOR_ICON = preload("res://assets/items/echo_vigor.png")
const PULSE_ICON = preload("res://assets/items/echo_pulse.png")
const END_CORE = preload("res://assets/objects/heart_core_v2.png")
const TRANSITION_ATRIUM_TO_VENTRICLE = preload("res://assets/transitions/trans_atrium_to_ventricle.png")
const TRANSITION_VENTRICLE_TO_ATRIUM = preload("res://assets/transitions/trans_ventricle_to_atrium.png")
const TRANSITION_ATRIUM_TO_VENTRICLE4 = preload("res://assets/transitions/trans_atrium_to_ventricle4.png")
const TRANSITION_ENDING_REVIVAL = preload("res://assets/transitions/trans_ending_revival.png")
const TITLE_BACKGROUND_PATH := "res://assets/generated/bhai/inbox/scenes/title_screen_background_raw.jpeg"
const PIXEL_FONT = preload("res://assets/fonts/FusionPixel_12px_Proportional_zh_hans.ttf")

const ACTION_PAUSE: StringName = &"pause_game"
const ACTION_CHARGE: StringName = &"charge_action"
const ACTION_INTERACT: StringName = &"interact_action"
const DEBUG_INFINITE_HEALTH_KEY := KEY_F6
const DEBUG_ROOM_JUMP_KEY := KEY_F7

const COLOR_TEXT := Color(0.90, 0.94, 0.89, 1.0)
const COLOR_MUTED := Color(0.57, 0.65, 0.59, 1.0)
const COLOR_READY := Color(0.27, 0.90, 0.76, 1.0)
const COLOR_HIT := Color(0.44, 1.0, 0.62, 1.0)
const COLOR_MISS := Color(1.0, 0.34, 0.34, 1.0)
const COLOR_WARNING := Color(1.0, 0.72, 0.25, 1.0)
const END_EMBLEM_SIZE := Vector2(64.0, 64.0)
const END_EMBLEM_VISUAL_CENTER_Y := 113.0

var beat_clock: BeatClock
var metronome: AudioStreamPlayer
var room_state: MvpRunState
var room_view: MvpRoomView
var rhythm_hud: MvpRhythmHud
var room_label: Label
var room_title_label: Label
var room_subtitle_label: Label
var bpm_label: Label
var beat_label: Label
var judge_label: Label
var hp_row: HBoxContainer
var boss_health_panel: Panel
var boss_health_label: Label
var boss_health_bar: ProgressBar
var boss_health_value_label: Label
var action_state_row: HBoxContainer
var buff_row: HBoxContainer
var stats_label: Label
var intent_label: Label
var status_label: Label
var controls_label: Label
var test_mode_label: Label
var transition_overlay: ColorRect
var transition_art: TextureRect
var transition_label: Label
var transition_streaks: Array[ColorRect] = []
var reward_overlay: ColorRect
var reward_title: Label
var reward_body: Label
var reward_tempo_button: Button
var reward_guard_button: Button
var reward_option_ids: Array[StringName] = []
var end_overlay: ColorRect
var end_panel: Panel
var end_title: Label
var end_emblem: TextureRect
var end_body: Label
var restart_button: Button
var pause_overlay: ColorRect
var pause_title: Label
var pause_body: Label
var pause_resume_button: Button
var pause_title_button: Button
var main_menu_overlay: ColorRect
var main_menu_start_button: Button
var main_menu_settings_button: Button
var main_menu_quit_button: Button
var settings_overlay: ColorRect
var settings_panel: Panel
var settings_volume_slider: HSlider
var settings_volume_value: Label
var settings_offset_slider: HSlider
var settings_offset_value: Label
var settings_binding_buttons: Dictionary = {}
var settings_back_button: Button
var settings_status_label: Label
var title_background: TextureRect
var gameplay_hud_layer: Control
var debug_room_overlay: ColorRect

var is_running := false
var input_locked := false
var resolving := false
var transition_locked := false
var pending_action: StringName = &"none"
var pending_direction := Vector2i.ZERO
var pending_miss_text := ""
var pending_shield_assist := false
var click_stream: AudioStreamWAV
var transition_tween: Tween
var end_tween: Tween
var pause_tween: Tween
var game_paused := false
var pause_started_time := 0.0
var configured_chart_offset_ms := 0.0
var game_settings
var rebinding_action: StringName = &""
var infinite_health_test_mode := false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build_interface()
	game_settings = SettingsScript.new()
	game_settings.load_and_apply()
	configure_timing(game_settings.chart_offset_ms)
	_update_settings_controls()
	room_state = StateScript.new()
	room_view.bind_state(room_state)
	rhythm_hud.bind_clock(beat_clock)
	beat_clock.beat_started.connect(_on_beat_started)
	beat_clock.beat_resolved.connect(_on_beat_resolved)
	beat_clock.beat_cue_requested.connect(_on_beat_cue_requested)
	restart_button.pressed.connect(restart_run)
	reward_tempo_button.pressed.connect(func() -> void: _choose_reward(1))
	reward_guard_button.pressed.connect(func() -> void: _choose_reward(2))
	click_stream = _build_click_stream()
	if DisplayServer.get_name().to_lower() == "headless":
		start_game()
	else:
		_show_main_menu()


func _unhandled_key_input(event: InputEvent) -> void:
	if not event is InputEventKey:
		return
	var key_event := event as InputEventKey
	if not key_event.pressed or key_event.echo:
		return
	var physical_code := key_event.physical_keycode
	var key_code := key_event.keycode
	if rebinding_action != &"":
		if key_code == KEY_ESCAPE or physical_code == KEY_ESCAPE:
			rebinding_action = &""
			settings_status_label.text = "已取消重新绑定"
		else:
			_capture_binding(key_event)
		get_viewport().set_input_as_handled()
		return
	if settings_overlay.visible:
		if key_code == KEY_ESCAPE or physical_code == KEY_ESCAPE:
			_close_settings()
			get_viewport().set_input_as_handled()
		return
	if OS.is_debug_build() and (physical_code == DEBUG_ROOM_JUMP_KEY or key_code == DEBUG_ROOM_JUMP_KEY):
		_toggle_debug_room_overlay()
		get_viewport().set_input_as_handled()
		return
	if debug_room_overlay != null and debug_room_overlay.visible:
		return
	if main_menu_overlay.visible:
		return
	if OS.is_debug_build() and (physical_code == DEBUG_INFINITE_HEALTH_KEY or key_code == DEBUG_INFINITE_HEALTH_KEY):
		_set_infinite_health_test_mode(not infinite_health_test_mode)
		get_viewport().set_input_as_handled()
		return
	if physical_code == KEY_R or key_code == KEY_R:
		restart_run()
		get_viewport().set_input_as_handled()
		return
	var pause_pressed := key_event.is_action_pressed(ACTION_PAUSE) or key_code == KEY_ESCAPE or physical_code == KEY_ESCAPE
	if pause_pressed:
		if game_paused:
			_set_game_paused(false)
			get_viewport().set_input_as_handled()
		elif _can_pause():
			_set_game_paused(true)
			get_viewport().set_input_as_handled()
		return
	if key_event.is_action_pressed(ACTION_INTERACT):
		if _can_interact_with_next_layer_portal():
			_interact_with_next_layer_portal()
		else:
			_set_status("靠近中央传送门后按 E", COLOR_MUTED)
		get_viewport().set_input_as_handled()
		return
	if reward_overlay.visible:
		if physical_code == KEY_1 or key_code == KEY_1:
			_choose_reward(1)
			get_viewport().set_input_as_handled()
		elif physical_code == KEY_2 or key_code == KEY_2:
			_choose_reward(2)
			get_viewport().set_input_as_handled()
		return
	if end_overlay.visible:
		if physical_code == KEY_ENTER or key_code == KEY_ENTER:
			restart_run()
			get_viewport().set_input_as_handled()
		return
	if not is_running or transition_locked:
		return
	var direction := Vector2i.ZERO
	if InputMap.event_is_action(key_event, &"move_up"):
		direction = Vector2i.UP
	elif InputMap.event_is_action(key_event, &"move_down"):
		direction = Vector2i.DOWN
	elif InputMap.event_is_action(key_event, &"move_left"):
		direction = Vector2i.LEFT
	elif InputMap.event_is_action(key_event, &"move_right"):
		direction = Vector2i.RIGHT
	if direction != Vector2i.ZERO:
		submit_direction_at(direction)
		get_viewport().set_input_as_handled()
	elif key_event.is_action_pressed(ACTION_CHARGE):
		submit_charge_at()
		get_viewport().set_input_as_handled()


func submit_direction_at(direction: Vector2i, sample_time: float = -1.0) -> bool:
	if not _can_submit() or direction == Vector2i.ZERO:
		return false
	var timing := beat_clock.get_input_timing(sample_time)
	if int(timing.target_beat) != beat_clock.beat_number:
		_show_non_consuming_off_beat_input(timing)
		return false
	input_locked = true
	var judgement: int = timing.judgement
	var offset_seconds: float = timing.offset
	var offset_ms := int(round(offset_seconds * 1000.0))
	var shield_assisted := _try_absorb_miss(judgement, offset_seconds)
	if judgement == beat_clock.TimingJudgement.HIT or shield_assisted:
		pending_action = &"direction"
		pending_direction = direction
		pending_shield_assist = shield_assisted
		if shield_assisted:
			judge_label.text = "SYNC  %+d ms" % offset_ms
			judge_label.add_theme_color_override("font_color", COLOR_READY)
			rhythm_hud.set_judgement(&"shield")
			room_view.show_rhythm_shield_assist()
			_set_status("节奏护盾吸附 · 行动被拉回拍点", COLOR_READY)
		else:
			judge_label.text = "GOOD  %+d ms" % offset_ms
			judge_label.add_theme_color_override("font_color", COLOR_HIT)
			rhythm_hud.set_judgement(&"hit")
			_set_status("行动已锁定 · 等待本拍结算", COLOR_HIT)
	else:
		pending_action = &"miss"
		pending_miss_text = "EARLY" if judgement == beat_clock.TimingJudgement.EARLY else "LATE"
		judge_label.text = "%s  %+d ms" % [pending_miss_text, offset_ms]
		judge_label.add_theme_color_override("font_color", COLOR_MISS)
		rhythm_hud.set_judgement(&"miss")
		_set_status("失拍 · 敌人仍会行动", COLOR_MISS)
	return true


func submit_charge_at(sample_time: float = -1.0) -> bool:
	if not _can_submit():
		return false
	var timing := beat_clock.get_input_timing(sample_time)
	if int(timing.target_beat) != beat_clock.beat_number:
		_show_non_consuming_off_beat_input(timing)
		return false
	input_locked = true
	var judgement: int = timing.judgement
	var offset_seconds: float = timing.offset
	var offset_ms := int(round(offset_seconds * 1000.0))
	var shield_assisted := _try_absorb_miss(judgement, offset_seconds)
	if judgement == beat_clock.TimingJudgement.HIT or shield_assisted:
		pending_action = &"charge"
		pending_shield_assist = shield_assisted
		if shield_assisted:
			judge_label.text = "SYNC  %+d ms" % offset_ms
			judge_label.add_theme_color_override("font_color", COLOR_READY)
			rhythm_hud.set_judgement(&"shield")
			room_view.show_rhythm_shield_assist()
			_set_status("节奏护盾吸附 · 蓄力被拉回拍点", COLOR_READY)
		else:
			judge_label.text = "CHARGE  %+d ms" % offset_ms
			judge_label.add_theme_color_override("font_color", COLOR_WARNING)
			rhythm_hud.set_judgement(&"hit")
			_set_status("蓄力已锁定 · 敌人仍会行动", COLOR_WARNING)
	else:
		pending_action = &"miss"
		pending_miss_text = "EARLY" if judgement == beat_clock.TimingJudgement.EARLY else "LATE"
		judge_label.text = "%s  %+d ms" % [pending_miss_text, offset_ms]
		judge_label.add_theme_color_override("font_color", COLOR_MISS)
		rhythm_hud.set_judgement(&"miss")
		_set_status("失拍 · 本拍没有行动", COLOR_MISS)
	return true


# Kept as a compatibility alias for the first MVP smoke tests. Left Shift is
# now the active charge input; a beat with no input remains the ordinary wait.
func submit_wait_at(sample_time: float = -1.0) -> bool:
	return submit_charge_at(sample_time)


func _try_absorb_miss(judgement: int, offset_seconds: float) -> bool:
	if judgement == beat_clock.TimingJudgement.HIT:
		return false
	if room_state == null or not room_state.rhythm_shield:
		return false
	if absf(offset_seconds) > StateScript.RHYTHM_SHIELD_WINDOW:
		return false
	return room_state.consume_rhythm_shield()


func _show_non_consuming_off_beat_input(timing: Dictionary) -> void:
	var target_beat := int(timing.get("target_beat", beat_clock.beat_number))
	var offset_ms := int(round(float(timing.get("offset", 0.0)) * 1000.0))
	if target_beat < beat_clock.beat_number:
		judge_label.text = "LATE  %+d ms" % offset_ms
		_set_status("迟到输入属于上一拍 · 未占用当前拍", COLOR_MISS)
	else:
		judge_label.text = "EARLY  %+d ms" % offset_ms
		_set_status("过早输入属于下一拍 · 未提前锁定", COLOR_MISS)
	judge_label.add_theme_color_override("font_color", COLOR_MISS)
	rhythm_hud.set_judgement(&"miss")


func start_game() -> void:
	main_menu_overlay.visible = false
	settings_overlay.visible = false
	if is_instance_valid(gameplay_hud_layer):
		gameplay_hud_layer.visible = true
	rebinding_action = &""
	restart_run()


func _show_main_menu() -> void:
	if get_tree().paused:
		get_tree().paused = false
	game_paused = false
	pause_started_time = 0.0
	metronome.stream_paused = false
	if is_instance_valid(pause_overlay):
		pause_overlay.visible = false
	is_running = false
	resolving = false
	transition_locked = false
	beat_clock.stop()
	metronome.stop()
	settings_overlay.visible = false
	main_menu_overlay.visible = true
	if is_instance_valid(gameplay_hud_layer):
		gameplay_hud_layer.visible = false
	main_menu_start_button.grab_focus()


func _open_settings() -> void:
	rebinding_action = &""
	settings_status_label.text = "点击键位按钮后，按下新的按键"
	_update_settings_controls()
	main_menu_overlay.visible = false
	settings_overlay.visible = true
	if is_instance_valid(gameplay_hud_layer):
		gameplay_hud_layer.visible = false
	settings_volume_slider.grab_focus()


func _close_settings() -> void:
	rebinding_action = &""
	configure_timing(game_settings.chart_offset_ms)
	var save_error: Error = game_settings.save()
	settings_overlay.visible = false
	main_menu_overlay.visible = true
	if is_instance_valid(gameplay_hud_layer):
		gameplay_hud_layer.visible = false
	if save_error != OK:
		push_error("Could not save MVP settings: %s" % error_string(save_error))
	main_menu_start_button.grab_focus()


func _quit_game() -> void:
	get_tree().quit()


func _on_master_volume_changed(value: float) -> void:
	game_settings.set_master_volume(value)
	settings_volume_value.text = "%d%%" % roundi(game_settings.master_volume_percent)


func _on_chart_offset_changed(value: float) -> void:
	game_settings.set_chart_offset(value)
	configure_timing(game_settings.chart_offset_ms)
	settings_offset_value.text = "%+d ms" % roundi(game_settings.chart_offset_ms)


func _begin_rebind(action: StringName) -> void:
	rebinding_action = action
	settings_status_label.text = "正在设置「%s」：请按新按键（Esc 取消）" % SettingsScript.ACTION_LABELS.get(action, String(action))
	var button: Button = settings_binding_buttons.get(action)
	if button != null:
		button.text = "等待输入…"


func _capture_binding(event: InputEventKey) -> void:
	var action := rebinding_action
	if not game_settings.set_binding(action, event):
		settings_status_label.text = "该按键无法使用，请重试"
		return
	rebinding_action = &""
	settings_status_label.text = "已更新「%s」" % SettingsScript.ACTION_LABELS.get(action, String(action))
	_update_binding_button(action)


func _update_settings_controls() -> void:
	if game_settings == null:
		return
	settings_volume_slider.set_value_no_signal(game_settings.master_volume_percent)
	settings_volume_value.text = "%d%%" % roundi(game_settings.master_volume_percent)
	settings_offset_slider.set_value_no_signal(game_settings.chart_offset_ms)
	settings_offset_value.text = "%+d ms" % roundi(game_settings.chart_offset_ms)
	for action in SettingsScript.ACTIONS:
		_update_binding_button(action)


func _update_binding_button(action: StringName) -> void:
	var button: Button = settings_binding_buttons.get(action)
	if button != null:
		button.text = game_settings.get_binding_text(action)


func restart_run() -> void:
	if room_state == null:
		return
	if get_tree().paused:
		get_tree().paused = false
	game_paused = false
	main_menu_overlay.visible = false
	settings_overlay.visible = false
	if is_instance_valid(gameplay_hud_layer):
		gameplay_hud_layer.visible = true
	rebinding_action = &""
	pause_started_time = 0.0
	metronome.stream_paused = false
	_cancel_overlay_tweens()
	room_state.reset_run()
	transition_locked = false
	is_running = true
	resolving = false
	_reset_pending_input()
	end_overlay.visible = false
	end_overlay.modulate.a = 1.0
	reward_overlay.visible = false
	pause_overlay.visible = false
	pause_overlay.modulate.a = 1.0
	transition_overlay.visible = false
	transition_overlay.color.a = 0.0
	_reset_transition_visuals()
	room_view.reset_feedback()
	rhythm_hud.reset_feedback()
	room_view.set_room()
	beat_clock.bpm = room_state.get_bpm()
	beat_clock.timing_window = 0.12
	beat_clock.chart_offset_seconds = configured_chart_offset_ms / 1000.0
	beat_clock.audio_lead_time = clampf(AudioServer.get_time_to_next_mix() + AudioServer.get_output_latency(), 0.0, 0.20)
	judge_label.text = "READY"
	judge_label.add_theme_color_override("font_color", COLOR_READY)
	_set_status("第 %d 层已接入 · 走向右侧出口" % room_state.layer_index, COLOR_READY)
	beat_clock.start()
	_refresh_ui()


func _on_beat_cue_requested(_beat_number: int) -> void:
	metronome.stream = click_stream
	metronome.play()


func _on_beat_started(_beat_number: int) -> void:
	if room_state == null:
		return
	room_view.beat_pulse()
	room_view.telegraph_enemies()
	rhythm_hud.notify_beat()
	beat_label.text = "BEAT  %02d" % beat_clock.beat_number
	if not input_locked and is_running:
		judge_label.text = "NOW"
		judge_label.add_theme_color_override("font_color", COLOR_WARNING)
	_refresh_ui()


func configure_timing(chart_offset_ms: float) -> void:
	configured_chart_offset_ms = clampf(chart_offset_ms, -200.0, 200.0)
	if is_instance_valid(beat_clock):
		beat_clock.chart_offset_seconds = configured_chart_offset_ms / 1000.0


func _on_beat_resolved(resolved_beat_number: int) -> void:
	if not is_running or resolving:
		return
	resolving = true
	var action_kind: StringName = &"wait"
	if pending_action == &"direction":
		action_kind = &"direction"
	elif pending_action == &"charge":
		action_kind = &"charge"
	elif pending_action == &"miss":
		action_kind = &"miss"
	var result := room_state.resolve_turn(action_kind, pending_direction)
	room_view.present_turn(result)
	_apply_turn_feedback(result)
	if result.player_defeated:
		_finish_run(false)
		return
	if result.room_cleared:
		_set_status("房间净化 · " + ("中央传送门已开启" if room_state.room_kind == StateScript.ROOM_BOSS else "右侧出口已开启"), COLOR_HIT)
		if room_state.room_kind == StateScript.ROOM_BOSS:
			beat_clock.bpm = room_state.get_bpm()
			rhythm_hud.set_phase_warning(false)
	if String(result.get("boss_kind", "")) == "arrhythmia":
		if String(result.get("enemies", []).front().get("kind", "")) == "defibrillation":
			rhythm_hud.set_phase_warning(true)
			_set_status("除颤预警 · 第 %d 拍 · 请保持走位" % int(result.get("enemies", []).front().get("countdown", 0)), COLOR_WARNING)
		elif String(result.get("enemies", []).front().get("kind", "")) == "phase_shift":
			rhythm_hud.set_phase_warning(false)
			beat_clock.set_bpm_preserving_phase(room_state.get_bpm())
			room_view.show_phase_shift()
			_set_status("律畸进入第二阶段 · 140 BPM", COLOR_WARNING)
	if room_state.room_kind != StateScript.ROOM_BOSS and room_state.can_leave_room() and room_state.is_at_exit():
		_schedule_next_room()
		return
	_reset_pending_input()
	resolving = false
	_refresh_ui()
	beat_label.text = "BEAT  %02d" % (resolved_beat_number + 1)
	judge_label.text = "READY"
	judge_label.add_theme_color_override("font_color", COLOR_READY)


func _apply_turn_feedback(result: Dictionary) -> void:
	var player_result: Dictionary = result.get("player", {})
	var player_kind := String(player_result.get("kind", "wait"))
	var status_text := ""
	var status_color := COLOR_TEXT
	if pending_action == &"miss":
		status_text = "%s · 行动失败" % pending_miss_text
		status_color = COLOR_MISS
	elif pending_action == &"charge":
		status_text = "蓄力就绪 · 下一次命中 +%d 伤害" % StateScript.CHARGE_BONUS_DAMAGE
		status_color = COLOR_WARNING
	elif pending_action == &"none":
		status_text = "本拍等待 · 连续同步中断"
		status_color = COLOR_MUTED
	else:
		match player_kind:
			"move":
				if bool(player_result.get("hazard", false)):
					status_text = "踩入血沉泥浆 · -%d HP" % int(player_result.get("damage", 0))
					status_color = COLOR_MISS
				else:
					status_text = "移动一格 · 节拍同步"
					status_color = COLOR_HIT
			"attack":
				var attack_from: Vector2i = player_result.get("from", room_state.player.cell)
				var attack_to: Vector2i = player_result.get("contact_cell", player_result.get("to", attack_from))
				var attack_distance := absi(attack_to.x - attack_from.x) + absi(attack_to.y - attack_from.y)
				if bool(player_result.get("charged_attack", false)):
					status_text = "蓄力斩击 · -%d HP" % int(player_result.get("damage", 0))
				elif bool(room_state.buffs.get("tempo", false)) and attack_distance > 1:
					status_text = "穿甲音波 · 两格命中 · -%d HP" % int(player_result.get("damage", 0))
				else:
					status_text = "斩击命中 · -%d HP" % int(player_result.get("damage", 0))
				if bool(player_result.get("interrupted", false)):
					status_text = "打断充能 · -%d HP" % int(player_result.get("damage", 0))
				status_color = COLOR_HIT
			"clash":
				status_text = "弹刀 · 双方攻击抵消"
				status_color = COLOR_WARNING
			"blocked":
				status_text = "边界或敌人阻挡"
				status_color = COLOR_WARNING
			_:
				status_text = "等待本拍"
	if pending_shield_assist:
		status_text = "护盾吸附 · " + status_text
		status_color = COLOR_READY
	if bool(result.get("shield_gained", false)):
		status_text += " · 节奏护盾就绪"
		status_color = COLOR_READY

	var enemy_results: Array = result.get("enemies", [])
	for enemy_result in enemy_results:
		var enemy_kind := String(enemy_result.get("kind", "none"))
		var planned_action := String(enemy_result.get("planned_action", enemy_result.get("intent", "")))
		if enemy_kind == "windup":
			if planned_action == "attack":
				status_text += " · 敌人举刀（下一拍攻击）"
				status_color = COLOR_WARNING
			else:
				status_text += " · 敌人蓄势（下一拍追击）"
				status_color = COLOR_WARNING
		elif enemy_kind == "attack":
			if bool(enemy_result.get("shielded", false)):
				status_text += " · 共鸣护盾挡下伤害"
				status_color = COLOR_READY
			else:
				status_text += " · 受到 -%d HP" % int(enemy_result.get("damage", 0))
				status_color = COLOR_MISS
		elif enemy_kind == "mud_windup":
			status_text += " · 泥浆喷吐者预警（下一拍发射）"
			status_color = COLOR_WARNING
		elif enemy_kind == "mud_fire":
			if bool(enemy_result.get("hit", false)):
				status_text += " · 泥浆弹命中 · -%d HP" % int(enemy_result.get("damage", 0))
				status_color = COLOR_MISS
			else:
				status_text += " · 泥浆弹沿十字方向发射"
				status_color = COLOR_WARNING
		elif enemy_kind == "hold":
			pass
		elif enemy_kind == "mud_summon":
			status_text += " · 泥鳃召唤血沉泥浆"
			status_color = COLOR_WARNING
		elif enemy_kind == "sweep_windup":
			status_text += " · 泥鳃横扫蓄力（外缘 3 格）"
			status_color = COLOR_WARNING
		elif enemy_kind == "piston_windup":
			status_text += " · 活塞巨像%s冲压预警" % ("红色行" if String(enemy_result.get("axis", "row")) == "row" else "蓝色列")
			status_color = COLOR_WARNING
		elif enemy_kind == "piston_strike":
			status_text += " · 行列冲压%s" % ("命中 · -%d HP" % int(enemy_result.get("damage", 0)) if bool(enemy_result.get("hit", false)) else "挥空")
			status_color = COLOR_MISS if bool(enemy_result.get("hit", false)) else COLOR_READY
		elif enemy_kind == "oxygen_charge":
			status_text += " · 血脉核心四拍充能（可打断）"
			status_color = COLOR_WARNING
		elif enemy_kind == "oxygen_blast":
			status_text += " · 充能喷流%s" % ("命中 · -%d HP" % int(enemy_result.get("damage", 0)) if bool(enemy_result.get("hit", false)) else "被躲开")
			status_color = COLOR_MISS if bool(enemy_result.get("hit", false)) else COLOR_READY
		elif enemy_kind == "spike_windup":
			status_text += " · 律畸地刺波预警"
			status_color = COLOR_WARNING
		elif enemy_kind == "noise_burst":
			status_text += " · 140 BPM 三向杂音弹%s" % ("命中 · -%d HP" % int(enemy_result.get("damage", 0)) if bool(enemy_result.get("hit", false)) else "挥空")
			status_color = COLOR_MISS if bool(enemy_result.get("hit", false)) else COLOR_READY
		elif enemy_kind == "defibrillation":
			status_text += " · 四拍除颤预警 · 第 %d 拍" % int(enemy_result.get("countdown", 0))
			status_color = COLOR_WARNING
		elif enemy_kind == "phase_shift":
			status_text += " · 阶段切换完成 · 140 BPM"
			status_color = COLOR_WARNING
		elif enemy_kind == "sweep":
			if bool(enemy_result.get("hit", false)):
				status_text += " · 横扫命中 · -%d HP" % int(enemy_result.get("damage", 0))
				status_color = COLOR_MISS
			else:
				status_text += " · 横扫挥空"
				status_color = COLOR_READY
		elif enemy_kind == "recovery":
			status_text += " · 泥鳃横扫后摇 · 安全输出拍"
			status_color = COLOR_READY
		elif enemy_kind == "move":
			status_text += " · 敌人逼近"
		elif enemy_kind == "mud_hit":
			status_text += " · 泥浆弹命中 · -%d HP" % int(enemy_result.get("damage", 0))
			status_color = COLOR_MISS
		elif enemy_kind == "parried":
			# The player result already owns the concise clash message.
			pass
		elif bool(enemy_result.get("cancelled", false)):
			if planned_action == "attack":
				status_text += " · 敌人挥空 · 你已移开"
				status_color = COLOR_READY
			else:
				status_text += " · 敌人追击受阻"
				status_color = COLOR_WARNING
	for environment_result in result.get("environment", []):
		if String(environment_result.get("kind", "")) == "mud_hit":
			status_text += " · 泥浆弹命中 · -%d HP" % int(environment_result.get("damage", 0))
			status_color = COLOR_MISS
	_set_status(status_text, status_color)


func _schedule_next_room() -> void:
	if transition_locked:
		return
	transition_locked = true
	is_running = false
	beat_clock.stop()
	room_view.play_exit_transition()
	var transition_text: String
	if room_state.room_kind == StateScript.ROOM_BOSS:
		transition_text = "心核复苏" if room_state.layer_index >= StateScript.TOTAL_LAYERS else "前往第 %d 层" % (room_state.layer_index + 1)
	else:
		transition_text = "深入第 %d 层" % room_state.layer_index
	_prepare_transition_overlay(transition_text, _get_layer_transition_texture())
	if transition_tween != null and transition_tween.is_valid():
		transition_tween.kill()
	transition_tween = create_tween()
	transition_tween.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	transition_tween.tween_interval(0.06)
	if transition_art.visible:
		transition_tween.parallel().tween_property(transition_art, "modulate:a", 0.96, 0.42).set_delay(0.04)
	transition_tween.parallel().tween_property(transition_label, "modulate:a", 1.0, 0.24).set_delay(0.22)
	transition_tween.tween_interval(0.12)
	transition_tween.tween_callback(_advance_room)


func _advance_room() -> void:
	if transition_tween != null and transition_tween.is_valid():
		transition_tween.kill()
	transition_tween = null
	if room_state.room_kind == StateScript.ROOM_BOSS:
		# The portal is the exit from the Boss room itself. Advance directly to
		# the next layer's start room; only the fourth Boss reaches the ending.
		if room_state.advance_layer():
			room_view.set_room()
			beat_clock.bpm = room_state.get_bpm()
			transition_overlay.color.a = 0.0
			transition_overlay.visible = false
			_reset_transition_visuals()
			transition_locked = false
			resolving = false
			_reset_pending_input()
			is_running = true
			room_view.show_room_arrival()
			beat_clock.start()
			_set_status("抵达第 %d 层 · 新节律已同步" % room_state.layer_index, COLOR_READY)
			_refresh_ui()
			return
		transition_overlay.visible = false
		_reset_transition_visuals()
		_refresh_ui()
		_finish_run(true)
		return
	room_state.enter_next_room()
	room_view.set_room()
	beat_clock.bpm = room_state.get_bpm()
	transition_overlay.color.a = 0.0
	transition_overlay.visible = false
	_reset_transition_visuals()
	transition_locked = false
	resolving = false
	_reset_pending_input()
	if room_state.room_kind == StateScript.ROOM_REWARD:
		is_running = false
		beat_clock.stop()
		reward_overlay.visible = true
		_refresh_reward_choices()
		_set_status("选择一项增益", COLOR_WARNING)
	else:
		is_running = true
		room_view.show_room_arrival()
		beat_clock.start()
		_set_status("新的房间已同步 · 走向右侧出口", COLOR_READY)
	_refresh_ui()


func _refresh_reward_choices() -> void:
	if room_state == null:
		return
	reward_option_ids = room_state.get_reward_options()
	reward_title.text = "%dF · 回响祭坛" % room_state.layer_index
	reward_body.text = "选择一项增益"
	var definitions: Array[Dictionary] = []
	for echo_id in reward_option_ids:
		definitions.append(room_state.get_echo_definition(echo_id))
	while definitions.size() < 2:
		definitions.append({"label":"暂无增益", "detail":""})
	_set_reward_button_content(reward_tempo_button, definitions[0], reward_option_ids[0] if reward_option_ids.size() > 0 else &"")
	_set_reward_button_content(reward_guard_button, definitions[1], reward_option_ids[1] if reward_option_ids.size() > 1 else &"")
	reward_tempo_button.disabled = reward_option_ids.size() < 1
	reward_guard_button.disabled = reward_option_ids.size() < 2


func _set_reward_button_content(button: Button, definition: Dictionary, echo_id: StringName) -> void:
	button.tooltip_text = "%s：%s" % [definition.get("label", ""), definition.get("detail", "")]
	var content := button.get_node_or_null("Content") as VBoxContainer
	if content == null:
		return
	var icon := content.get_node_or_null("Icon") as TextureRect
	var title := content.get_node_or_null("Title") as Label
	var detail := content.get_node_or_null("Detail") as Label
	var shortcut := content.get_node_or_null("Shortcut") as Label
	if icon != null:
		icon.texture = _reward_icon_for(echo_id)
		icon.visible = echo_id != &"" and icon.texture != null
	if title != null:
		title.text = String(definition.get("label", ""))
	if detail != null:
		detail.text = String(definition.get("detail", ""))
	if shortcut != null:
		shortcut.text = "%d" % (1 if button == reward_tempo_button else 2)


func _reward_icon_for(echo_id: StringName) -> Texture2D:
	match echo_id:
		&"tempo": return TEMPO_ICON
		&"guard": return GUARD_ICON
		&"impact": return IMPACT_ICON
		&"vigor": return VIGOR_ICON
		&"pulse": return PULSE_ICON
		_: return null


func _choose_reward(choice: int) -> void:
	if not reward_overlay.visible or transition_locked:
		return
	var result := room_state.choose_reward(choice)
	if not bool(result.get("accepted", false)):
		return
	reward_overlay.visible = false
	transition_locked = true
	_prepare_transition_overlay("%s · 共鸣" % String(result.get("label", "回响")))
	if transition_tween != null and transition_tween.is_valid():
		transition_tween.kill()
	transition_tween = create_tween()
	transition_tween.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	transition_tween.parallel().tween_property(transition_label, "modulate:a", 1.0, 0.20).set_delay(0.10)
	transition_tween.tween_interval(0.18)
	transition_tween.tween_callback(_advance_room)


func _finish_run(won: bool) -> void:
	is_running = false
	resolving = false
	transition_locked = false
	beat_clock.stop()
	metronome.stop()
	_layout_end_emblem()
	end_overlay.visible = true
	end_overlay.modulate.a = 0.0
	var final_echo := "无回响"
	if bool(room_state.buffs.get("tempo", false)):
		final_echo = "穿甲音波"
	elif bool(room_state.buffs.get("guard", false)):
		final_echo = "共鸣护盾"
	if won and room_state.room_kind == StateScript.ROOM_BOSS and room_state.layer_index < StateScript.TOTAL_LAYERS:
		end_title.text = "第一层已完成"
		end_title.add_theme_color_override("font_color", COLOR_HIT)
		end_body.text = "右心房·暗河导流腔已净化。\n中央传送门已开启，可由此进入第二层右心室。"
		end_emblem.modulate = Color(0.52, 1.0, 0.72, 1.0)
		end_panel.add_theme_stylebox_override("panel", _make_panel_style(Color(0.035, 0.10, 0.075, 0.98), Color(0.34, 0.88, 0.60, 1.0)))
		restart_button.text = "重新挑战第一层"
	elif won:
		var echo_line := "旅途的余响已归于心核。" if final_echo == "无回响" else "%s已融入新的共鸣。" % final_echo
		end_title.text = "心核复苏 · 四层完成"
		end_title.add_theme_color_override("font_color", COLOR_HIT)
		end_body.text = "始源心核重新恢复四层节律。\n%s" % echo_line
		end_emblem.modulate = Color(0.52, 1.0, 0.72, 1.0)
		end_panel.add_theme_stylebox_override("panel", _make_panel_style(Color(0.035, 0.10, 0.075, 0.98), Color(0.34, 0.88, 0.60, 1.0)))
		restart_button.text = "再次踏入遗迹"
	else:
		end_title.text = "心核沉寂"
		end_title.add_theme_color_override("font_color", COLOR_MISS)
		end_body.text = "倒在%s。\n心核仍在等待下一次共鸣。" % room_state.get_chamber_display_name()
		end_emblem.modulate = Color(0.86, 0.30, 0.28, 0.78)
		end_panel.add_theme_stylebox_override("panel", _make_panel_style(Color(0.11, 0.045, 0.04, 0.98), Color(0.74, 0.26, 0.24, 1.0)))
		restart_button.text = "重新挑战"
	room_state.finish_run()
	beat_clock.bpm = room_state.get_bpm()
	rhythm_hud.set_phase_warning(false)
	if end_tween != null and end_tween.is_valid():
		end_tween.kill()
	end_tween = create_tween()
	end_tween.tween_interval(0.34 if not won else 0.18)
	end_tween.tween_property(end_overlay, "modulate:a", 1.0, 0.24)
	_refresh_ui()


func _cancel_overlay_tweens() -> void:
	if transition_tween != null and transition_tween.is_valid():
		transition_tween.kill()
	if end_tween != null and end_tween.is_valid():
		end_tween.kill()
	if pause_tween != null and pause_tween.is_valid():
		pause_tween.kill()
	transition_tween = null
	end_tween = null
	pause_tween = null


func _reset_pending_input() -> void:
	input_locked = false
	pending_action = &"none"
	pending_direction = Vector2i.ZERO
	pending_miss_text = ""
	pending_shield_assist = false


func _can_submit() -> bool:
	return is_running and not game_paused and not input_locked and not resolving and not transition_locked and not reward_overlay.visible and not end_overlay.visible


func _set_infinite_health_test_mode(enabled: bool) -> void:
	infinite_health_test_mode = enabled
	if room_state != null:
		room_state.set_infinite_health_test_mode(enabled)
	if test_mode_label != null:
		test_mode_label.visible = enabled
	if enabled:
		_set_status("测试模式：无限生命已开启（F6 关闭）", COLOR_WARNING)
	else:
		_set_status("测试模式：无限生命已关闭", COLOR_MUTED)
	_refresh_ui()


func _can_pause() -> bool:
	return is_running and not transition_locked and not reward_overlay.visible and not end_overlay.visible


func _can_interact_with_next_layer_portal() -> bool:
	return is_running and not transition_locked and not reward_overlay.visible and not end_overlay.visible and room_state.is_near_next_layer_portal()


func _interact_with_next_layer_portal() -> void:
	var target_layer := room_state.layer_index + 1
	_set_status("中央传送门已响应 · 正在前往第 %d 层" % target_layer, COLOR_HIT)
	_schedule_next_room()


func _return_to_title_from_pause() -> void:
	_show_main_menu()


func _set_game_paused(paused: bool) -> void:
	if game_paused == paused:
		return
	if paused:
		game_paused = true
		pause_started_time = beat_clock.now_seconds()
		metronome.stream_paused = true
		pause_overlay.visible = true
		pause_overlay.modulate.a = 0.0
		get_tree().paused = true
		if pause_tween != null and pause_tween.is_valid():
			pause_tween.kill()
		pause_tween = create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
		pause_tween.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		pause_tween.tween_property(pause_overlay, "modulate:a", 1.0, 0.16)
		return
	var paused_duration := maxf(0.0, beat_clock.now_seconds() - pause_started_time)
	if beat_clock.is_running:
		beat_clock.beat_center_time += paused_duration
	get_tree().paused = false
	game_paused = false
	pause_started_time = 0.0
	metronome.stream_paused = false
	if pause_tween != null and pause_tween.is_valid():
		pause_tween.kill()
	pause_tween = null
	pause_overlay.visible = false
	pause_overlay.modulate.a = 1.0
	judge_label.text = "READY"
	judge_label.add_theme_color_override("font_color", COLOR_READY)


func _get_layer_transition_texture() -> Texture2D:
	if room_state == null or room_state.room_kind != StateScript.ROOM_BOSS:
		return null
	match room_state.layer_index:
		StateScript.LAYER_ONE:
			return TRANSITION_ATRIUM_TO_VENTRICLE
		StateScript.LAYER_TWO:
			return TRANSITION_VENTRICLE_TO_ATRIUM
		StateScript.LAYER_THREE:
			return TRANSITION_ATRIUM_TO_VENTRICLE4
		StateScript.LAYER_FOUR:
			return TRANSITION_ENDING_REVIVAL
		_:
			return null


func _prepare_transition_overlay(message: String, transition_texture: Texture2D = null) -> void:
	transition_overlay.visible = true
	transition_overlay.color.a = 0.0
	transition_art.texture = transition_texture
	transition_art.visible = transition_texture != null
	transition_art.modulate = Color(1.0, 1.0, 1.0, 0.0)
	transition_label.text = message
	transition_label.modulate.a = 0.0
	_reset_transition_visuals()


func _reset_transition_visuals() -> void:
	var starting_positions := [Vector2(-300.0, 162.0), Vector2(-360.0, 268.0), Vector2(-240.0, 366.0)]
	for index in range(transition_streaks.size()):
		transition_streaks[index].position = starting_positions[index]
		transition_streaks[index].visible = false
		transition_streaks[index].modulate.a = 0.0


func _refresh_ui() -> void:
	if room_state == null:
		return
	room_label.text = room_state.get_room_label()
	room_title_label.text = room_state.room_title
	room_subtitle_label.text = room_state.room_subtitle
	bpm_label.text = "%d BPM  ·  判定 ±120 ms" % int(room_state.get_bpm())
	beat_label.text = "BEAT  %02d" % beat_clock.beat_number
	stats_label.text = "敌方  %d   连续  %02d\n有效  %03d   失拍  %03d" % [
		_count_living_enemies(), room_state.combo, room_state.successful_actions, room_state.misses,
	]
	_update_hp_icons()
	_update_boss_health_bar()
	_update_action_state_icons()
	_update_buff_icons()
	rhythm_hud.set_action_states(room_state.charged, room_state.rhythm_shield, StateScript.RHYTHM_SHIELD_WINDOW)
	beat_clock.resolution_window = StateScript.RHYTHM_SHIELD_WINDOW if room_state.rhythm_shield else beat_clock.timing_window
	var primary := room_state.get_primary_enemy()
	if primary == null and room_state.room_kind == StateScript.ROOM_BOSS and room_state.room_cleared:
		intent_label.text = "传送门状态   已开启 · 靠近中央按 E"
		intent_label.add_theme_color_override("font_color", COLOR_HIT)
	elif primary == null:
		intent_label.text = "出口状态   已开启"
		intent_label.add_theme_color_override("font_color", COLOR_HIT)
	elif primary.role == &"slug" and primary.enemy_plan == &"mud":
		intent_label.text = "敌人意图   泥浆喷吐 · 下一拍发射"
		intent_label.add_theme_color_override("font_color", COLOR_WARNING)
	elif primary.role == &"slug":
		intent_label.text = "敌人意图   定点待机 · 四拍循环"
		intent_label.add_theme_color_override("font_color", COLOR_WARNING)
	elif primary.role == &"enemy" and primary.enemy_plan == &"attack":
		intent_label.text = "敌人意图   举刀 · 下一拍攻击"
		intent_label.add_theme_color_override("font_color", COLOR_MISS)
	elif primary.role == &"enemy" and primary.enemy_plan == &"move":
		intent_label.text = "敌人意图   蓄势 · 下一拍追击"
		intent_label.add_theme_color_override("font_color", COLOR_WARNING)
	elif primary.role == &"enemy" and room_state.enemy_intent(primary) == &"attack":
		intent_label.text = "敌人意图   接触 · 下一拍举刀"
		intent_label.add_theme_color_override("font_color", COLOR_WARNING)
	elif room_state.room_kind == StateScript.ROOM_BOSS:
		var boss_intent: StringName = room_state.enemy_intent(primary)
		var boss_intent_text: String = {
			"mud": "泥浆召唤",
			"sweep": "横扫蓄力 · 外缘 3 格",
			"recovery": "横扫后摇 · 安全输出",
		}.get(String(boss_intent), "四拍循环")
		intent_label.text = "Boss 意图   %s" % boss_intent_text
		intent_label.add_theme_color_override("font_color", COLOR_WARNING)
	elif room_state.enemy_intent(primary) == &"attack":
		intent_label.text = "敌人意图   攻击"
		intent_label.add_theme_color_override("font_color", COLOR_MISS)
	else:
		intent_label.text = "敌人意图   追击"
		intent_label.add_theme_color_override("font_color", COLOR_WARNING)
	room_view.queue_redraw()


func _count_living_enemies() -> int:
	var count := 0
	for enemy in room_state.enemies:
		if enemy.is_alive():
			count += 1
	return count


func _update_hp_icons() -> void:
	if hp_row == null or room_state == null or room_state.player == null:
		return
	# The Vigor echo raises max_hp during a run, so the HUD must create a new
	# heart slot instead of keeping the initial five-slot layout.
	while hp_row.get_child_count() < room_state.player.max_hp:
		var icon := TextureRect.new()
		icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		icon.custom_minimum_size = Vector2(30, 30)
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		hp_row.add_child(icon)
	while hp_row.get_child_count() > room_state.player.max_hp:
		var extra := hp_row.get_child(hp_row.get_child_count() - 1)
		hp_row.remove_child(extra)
		extra.queue_free()
	for index in range(hp_row.get_child_count()):
		var icon := hp_row.get_child(index) as TextureRect
		icon.texture = HEART_FULL if index < room_state.player.hp else HEART_EMPTY


func _boss_health_hint() -> String:
	match room_state.layer_index:
		2: return "红/蓝瓣膜 · 行列冲压"
		3: return "四拍充能 · 可打断"
		4: return "%d BPM · %s" % [int(room_state.get_bpm()), "除颤预警" if room_state.boss_phase_shift_pending else "双阶段"]
		_: return "3×3 占格 · 横扫 3 格"


func _update_boss_health_bar() -> void:
	if boss_health_panel == null:
		return
	var boss := room_state.get_boss()
	boss_health_panel.visible = room_state.room_kind == StateScript.ROOM_BOSS and boss != null and is_running
	if not boss_health_panel.visible:
		return
	boss_health_label.text = room_state.get_boss_display_name()
	boss_health_bar.max_value = float(boss.max_hp)
	boss_health_bar.value = float(maxi(boss.hp, 0))
	boss_health_value_label.text = "%d / %d" % [maxi(boss.hp, 0), boss.max_hp]


func _update_action_state_icons() -> void:
	for child in action_state_row.get_children():
		action_state_row.remove_child(child)
		child.queue_free()
	_add_state_icon(CHARGE_ICON, "蓄力就绪", room_state.charged)
	_add_state_icon(SHIELD_ICON, "节奏护盾就绪", room_state.rhythm_shield)


func _add_state_icon(texture: Texture2D, tooltip: String, active: bool) -> void:
	if not active:
		return
	var icon := TextureRect.new()
	icon.texture = texture
	icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	icon.custom_minimum_size = Vector2(28, 28)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.tooltip_text = tooltip
	action_state_row.add_child(icon)


func _update_buff_icons() -> void:
	for child in buff_row.get_children():
		buff_row.remove_child(child)
		child.queue_free()
	if bool(room_state.buffs.get("tempo", false)):
		_add_buff_icon(TEMPO_ICON, "穿甲音波：普通攻击延伸至前方两格")
	if bool(room_state.buffs.get("guard", false)):
		_add_buff_icon(GUARD_ICON, "共鸣护盾：3 次连续有效行动获得节奏护盾")
	for echo_id in [&"impact", &"vigor", &"pulse"]:
		if bool(room_state.buffs.get(echo_id, false)):
			_add_buff_icon(_reward_icon_for(echo_id), room_state.get_echo_definition(echo_id).detail)


func _add_buff_icon(texture: Texture2D, tooltip: String) -> void:
	var icon := TextureRect.new()
	icon.texture = texture
	icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	icon.custom_minimum_size = Vector2(28, 28)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.tooltip_text = tooltip
	buff_row.add_child(icon)


func _add_buff_label(text: String) -> void:
	var label := _make_label(text, Vector2.ZERO, Vector2(0, 26), 10, Color(0.76, 0.90, 0.82, 0.72))
	label.custom_minimum_size = Vector2(52, 26)
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.tooltip_text = text
	buff_row.add_child(label)


func _set_status(message: String, color: Color) -> void:
	status_label.text = message
	status_label.add_theme_color_override("font_color", color)


func _toggle_debug_room_overlay() -> void:
	if debug_room_overlay == null:
		return
	debug_room_overlay.visible = not debug_room_overlay.visible
	if debug_room_overlay.visible:
		if is_instance_valid(gameplay_hud_layer):
			gameplay_hud_layer.visible = false
		debug_room_overlay.get_node("Panel/Close").grab_focus()
	else:
		if is_instance_valid(gameplay_hud_layer) and not main_menu_overlay.visible:
			gameplay_hud_layer.visible = true


func _jump_debug_room(layer: int, room_kind: int) -> void:
	if not OS.is_debug_build() or room_state == null:
		return
	if get_tree().paused:
		get_tree().paused = false
	game_paused = false
	room_state.reset_run()
	room_state.layer_index = layer
	room_state._enter_room(room_kind)
	room_state.run_finished = false
	_cancel_overlay_tweens()
	transition_locked = false
	resolving = false
	is_running = room_kind != StateScript.ROOM_REWARD
	reward_overlay.visible = false
	end_overlay.visible = false
	pause_overlay.visible = false
	room_view.reset_feedback()
	rhythm_hud.reset_feedback()
	room_view.set_room()
	beat_clock.stop()
	beat_clock.bpm = room_state.get_bpm()
	beat_clock.timing_window = 0.12
	_reset_pending_input()
	if room_kind == StateScript.ROOM_REWARD:
		_refresh_reward_choices()
		reward_overlay.visible = true
	else:
		room_view.show_room_arrival()
		beat_clock.start()
	_refresh_ui()
	debug_room_overlay.visible = false
	if is_instance_valid(gameplay_hud_layer):
		gameplay_hud_layer.visible = true
	_set_status("测试跳转：第 %d 层 · %s" % [layer, room_state.room_title], COLOR_WARNING)


func _build_debug_room_overlay() -> void:
	debug_room_overlay = ColorRect.new()
	debug_room_overlay.name = "DebugRoomOverlay"
	debug_room_overlay.color = Color(0.005, 0.012, 0.010, 0.88)
	debug_room_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	debug_room_overlay.z_index = 100
	debug_room_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	debug_room_overlay.visible = false
	debug_room_overlay.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(debug_room_overlay)
	var panel := Panel.new()
	panel.name = "Panel"
	panel.position = Vector2(160, 72)
	panel.size = Vector2(640, 396)
	panel.add_theme_stylebox_override("panel", _make_panel_style(Color(0.035, 0.085, 0.068, 0.98), Color(0.28, 0.82, 0.59, 1.0)))
	debug_room_overlay.add_child(panel)
	var title := _make_label("测试跳转 · 选择楼层和房间", Vector2(30, 22), Vector2(580, 36), 25, COLOR_HIT)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	panel.add_child(title)
	var hint := _make_label("仅 Debug 可用 · F7 打开/关闭 · 跳转会重置当前房间状态", Vector2(30, 60), Vector2(580, 24), 12, COLOR_MUTED)
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	panel.add_child(hint)
	var layers := ["1F 右心房", "2F 右心室", "3F 左心房", "4F 左心室"]
	for index in range(layers.size()):
		var button := _make_menu_button(layers[index], 14)
		button.position = Vector2(36 + index * 146, 98)
		button.size = Vector2(136, 38)
		button.pressed.connect(_select_debug_layer.bind(index + 1))
		panel.add_child(button)
	var rooms := [["起始房", StateScript.ROOM_START], ["普通房", StateScript.ROOM_NORMAL], ["奖励房", StateScript.ROOM_REWARD], ["困难房", StateScript.ROOM_HARD], ["Boss 房", StateScript.ROOM_BOSS]]
	for index in range(rooms.size()):
		var button := _make_menu_button(String(rooms[index][0]), 14)
		button.position = Vector2(36 + (index % 3) * 190, 166 + (index / 3) * 54)
		button.size = Vector2(172, 42)
		button.pressed.connect(_select_debug_room.bind(int(rooms[index][1])))
		panel.add_child(button)
	var close := _make_menu_button("关闭（F7）", 14)
	close.name = "Close"
	close.position = Vector2(220, 322)
	close.size = Vector2(200, 42)
	close.pressed.connect(_toggle_debug_room_overlay)
	panel.add_child(close)
	# The selected layer is kept as a simple debug-only field; normal gameplay
	# never exposes this panel or these buttons.
	debug_room_overlay.set_meta("selected_layer", 1)


func _select_debug_layer(layer: int) -> void:
	if debug_room_overlay != null:
		debug_room_overlay.set_meta("selected_layer", layer)
	_set_status("已选择第 %d 层，请选择房间" % layer, COLOR_WARNING)


func _select_debug_room(room_kind: int) -> void:
	var layer := int(debug_room_overlay.get_meta("selected_layer", 1))
	_jump_debug_room(layer, room_kind)


func _build_interface() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var game_theme := Theme.new()
	game_theme.default_font = PIXEL_FONT
	game_theme.default_font_size = 15
	game_theme.set_color("font_color", "Label", COLOR_TEXT)
	game_theme.set_color("font_hover_color", "Button", Color.WHITE)
	game_theme.set_font_size("font_size", "Button", 15)
	set_theme(game_theme)

	var background := ColorRect.new()
	background.color = Color(0.018, 0.028, 0.026, 1.0)
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(background)
	move_child(background, 0)

	room_view = RoomViewScript.new()
	room_view.process_mode = Node.PROCESS_MODE_PAUSABLE
	room_view.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(room_view)

	beat_clock = BeatClockScript.new()
	beat_clock.name = "BeatClock"
	beat_clock.process_mode = Node.PROCESS_MODE_PAUSABLE
	add_child(beat_clock)
	metronome = AudioStreamPlayer.new()
	metronome.name = "Metronome"
	metronome.volume_db = -11.0
	metronome.process_mode = Node.PROCESS_MODE_PAUSABLE
	add_child(metronome)

	gameplay_hud_layer = Control.new()
	var hud_layer := gameplay_hud_layer
	hud_layer.name = "FormalHud"
	hud_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	hud_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud_layer.z_index = 20
	add_child(hud_layer)

	hp_row = HBoxContainer.new()
	hp_row.name = "HeartHealth"
	hp_row.position = Vector2(18, 16)
	hp_row.size = Vector2(170, 32)
	hp_row.add_theme_constant_override("separation", 3)
	hud_layer.add_child(hp_row)
	for _index in range(StateScript.PLAYER_MAX_HP):
		var icon := TextureRect.new()
		icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		icon.custom_minimum_size = Vector2(30, 30)
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		hp_row.add_child(icon)

	boss_health_panel = Panel.new()
	boss_health_panel.name = "BossHealth"
	boss_health_panel.anchor_left = 0.5
	boss_health_panel.anchor_right = 0.5
	boss_health_panel.offset_left = -210.0
	boss_health_panel.offset_top = 10.0
	boss_health_panel.offset_right = 210.0
	boss_health_panel.offset_bottom = 68.0
	boss_health_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	boss_health_panel.visible = false
	boss_health_panel.add_theme_stylebox_override("panel", _make_panel_style(Color(0.035, 0.045, 0.055, 0.94), Color(0.82, 0.25, 0.57, 1.0)))
	hud_layer.add_child(boss_health_panel)
	boss_health_label = _make_label("静脉吸附者·泥鳃", Vector2(14, 4), Vector2(392, 22), 13, COLOR_TEXT)
	boss_health_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	boss_health_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	boss_health_panel.add_child(boss_health_label)
	boss_health_bar = ProgressBar.new()
	boss_health_bar.name = "HealthBar"
	boss_health_bar.position = Vector2(20, 31)
	boss_health_bar.size = Vector2(380, 16)
	boss_health_bar.min_value = 0.0
	boss_health_bar.max_value = 6.0
	boss_health_bar.value = 6.0
	boss_health_bar.step = 0.0
	boss_health_bar.show_percentage = false
	boss_health_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	boss_health_bar.add_theme_stylebox_override("background", _make_panel_style(Color(0.06, 0.075, 0.08, 1.0), Color(0.24, 0.31, 0.32, 1.0)))
	boss_health_bar.add_theme_stylebox_override("fill", _make_panel_style(Color(0.76, 0.18, 0.42, 1.0), Color(1.0, 0.38, 0.68, 1.0)))
	boss_health_panel.add_child(boss_health_bar)
	boss_health_value_label = _make_label("6 / 6", Vector2(20, 28), Vector2(380, 22), 11, Color.WHITE)
	boss_health_value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	boss_health_value_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	boss_health_value_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	boss_health_panel.add_child(boss_health_value_label)

	action_state_row = HBoxContainer.new()
	action_state_row.name = "ActionStates"
	action_state_row.position = Vector2(18, 51)
	action_state_row.size = Vector2(90, 28)
	action_state_row.add_theme_constant_override("separation", 5)
	hud_layer.add_child(action_state_row)
	buff_row = HBoxContainer.new()
	buff_row.name = "RunEchoes"
	buff_row.position = Vector2(112, 51)
	buff_row.size = Vector2(90, 28)
	buff_row.add_theme_constant_override("separation", 5)
	hud_layer.add_child(buff_row)
	controls_label = _make_label("WASD / 方向键移动 · Shift 蓄力 · Space / Esc 暂停 · E 传送", Vector2(18, 86), Vector2(430, 24), 12, Color(0.72, 0.82, 0.78, 0.56))
	controls_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud_layer.add_child(controls_label)
	test_mode_label = _make_label("测试模式：无限生命 · F6 关闭", Vector2(18, 110), Vector2(360, 22), 12, COLOR_WARNING)
	test_mode_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	test_mode_label.visible = false
	hud_layer.add_child(test_mode_label)

	rhythm_hud = RhythmHudScript.new()
	rhythm_hud.name = "FallingBeatTrack"
	rhythm_hud.process_mode = Node.PROCESS_MODE_PAUSABLE
	rhythm_hud.anchor_left = 0.5
	rhythm_hud.anchor_top = 1.0
	rhythm_hud.anchor_right = 0.5
	rhythm_hud.anchor_bottom = 1.0
	rhythm_hud.offset_left = -96.0
	rhythm_hud.offset_top = -154.0
	rhythm_hud.offset_right = 96.0
	rhythm_hud.offset_bottom = -8.0
	hud_layer.add_child(rhythm_hud)
	judge_label = _make_label("READY", Vector2.ZERO, Vector2(192, 20), 14, COLOR_READY)
	judge_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	judge_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rhythm_hud.add_child(judge_label)

	# Keep diagnostic text sources for logic and automated regression without
	# rendering prototype chrome around the formal game view.
	var diagnostics := Control.new()
	diagnostics.name = "HiddenDiagnostics"
	diagnostics.visible = false
	add_child(diagnostics)
	room_label = _make_label("01 / 05", Vector2.ZERO, Vector2(1, 1), 12, COLOR_READY)
	room_title_label = _make_label("心核前厅", Vector2.ZERO, Vector2(1, 1), 12, COLOR_TEXT)
	room_subtitle_label = _make_label("起始房", Vector2.ZERO, Vector2(1, 1), 12, COLOR_MUTED)
	bpm_label = _make_label("90 BPM · ±120 ms", Vector2.ZERO, Vector2(1, 1), 12, COLOR_READY)
	beat_label = _make_label("BEAT  01", Vector2.ZERO, Vector2(1, 1), 12, COLOR_MUTED)
	stats_label = _make_label("", Vector2.ZERO, Vector2(1, 1), 12, COLOR_TEXT)
	intent_label = _make_label("", Vector2.ZERO, Vector2(1, 1), 12, COLOR_WARNING)
	status_label = _make_label("心核脉冲正在建立", Vector2.ZERO, Vector2(1, 1), 12, COLOR_READY)
	for diagnostic_label in [room_label, room_title_label, room_subtitle_label, bpm_label, beat_label, stats_label, intent_label, status_label]:
		diagnostics.add_child(diagnostic_label)

	transition_overlay = ColorRect.new()
	transition_overlay.color = Color(0.0, 0.0, 0.0, 0.0)
	transition_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	transition_overlay.z_index = 30
	transition_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(transition_overlay)
	transition_art = TextureRect.new()
	transition_art.name = "TransitionArt"
	transition_art.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	transition_art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	transition_art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	transition_art.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	transition_art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	transition_art.visible = false
	transition_overlay.add_child(transition_art)
	transition_streaks.clear()
	transition_label = _make_label("深入遗迹", Vector2(260, 235), Vector2(440, 50), 25, COLOR_READY)
	transition_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	transition_overlay.add_child(transition_label)
	_reset_transition_visuals()

	_build_reward_overlay()
	_build_end_overlay()
	_build_pause_overlay()
	_build_main_menu_overlay()
	_build_settings_overlay()
	if OS.is_debug_build():
		_build_debug_room_overlay()


func _build_reward_overlay() -> void:
	reward_overlay = ColorRect.new()
	reward_overlay.color = Color(0.012, 0.025, 0.021, 0.92)
	reward_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	reward_overlay.z_index = 40
	reward_overlay.visible = false
	add_child(reward_overlay)
	var panel := Panel.new()
	panel.position = Vector2(184, 126)
	panel.size = Vector2(592, 286)
	panel.add_theme_stylebox_override("panel", _make_panel_style(Color(0.055, 0.105, 0.083, 0.98), Color(0.30, 0.73, 0.52, 1.0)))
	reward_overlay.add_child(panel)
	reward_title = _make_label("右心房回响祭坛", Vector2(35, 22), Vector2(522, 38), 29, COLOR_READY)
	reward_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	panel.add_child(reward_title)
	reward_body = _make_label("选择一项增益", Vector2(35, 66), Vector2(522, 25), 15, COLOR_MUTED)
	reward_body.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	panel.add_child(reward_body)
	reward_tempo_button = _make_reward_button("穿甲音波", "普通攻击延伸至前方两格", "1", TEMPO_ICON)
	reward_tempo_button.position = Vector2(36, 116)
	reward_tempo_button.size = Vector2(250, 112)
	panel.add_child(reward_tempo_button)
	reward_guard_button = _make_reward_button("共鸣护盾", "3 次连续有效行动获得护盾", "2", GUARD_ICON)
	reward_guard_button.position = Vector2(306, 116)
	reward_guard_button.size = Vector2(250, 112)
	panel.add_child(reward_guard_button)


func _build_end_overlay() -> void:
	end_overlay = ColorRect.new()
	end_overlay.color = Color(0.012, 0.018, 0.015, 0.90)
	end_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	end_overlay.z_index = 50
	end_overlay.visible = false
	add_child(end_overlay)
	end_panel = Panel.new()
	end_panel.position = Vector2(220, 98)
	end_panel.size = Vector2(520, 344)
	end_panel.add_theme_stylebox_override("panel", _make_panel_style(Color(0.05, 0.085, 0.07, 0.98), Color(0.25, 0.56, 0.42, 1.0)))
	end_overlay.add_child(end_panel)
	end_title = _make_label("心核复苏", Vector2(30, 24), Vector2(460, 48), 33, COLOR_HIT)
	end_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	end_panel.add_child(end_title)
	end_emblem = TextureRect.new()
	end_emblem.name = "EndingCore"
	end_emblem.texture = END_CORE
	end_emblem.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	end_emblem.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	end_emblem.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	end_emblem.mouse_filter = Control.MOUSE_FILTER_IGNORE
	end_panel.add_child(end_emblem)
	_layout_end_emblem()
	end_body = _make_label("心核的脉动重新穿过枯萎森林。", Vector2(35, 154), Vector2(450, 70), 16, COLOR_TEXT)
	end_body.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	end_body.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	end_body.add_theme_constant_override("line_spacing", 5)
	end_panel.add_child(end_body)
	restart_button = Button.new()
	restart_button.text = "再次踏入遗迹"
	restart_button.position = Vector2(155, 252)
	restart_button.size = Vector2(210, 46)
	restart_button.add_theme_stylebox_override("normal", _make_panel_style(Color(0.13, 0.45, 0.34, 1.0), Color(0.35, 0.9, 0.65, 1.0)))
	restart_button.add_theme_stylebox_override("hover", _make_panel_style(Color(0.18, 0.60, 0.43, 1.0), Color(0.52, 1.0, 0.75, 1.0)))
	end_panel.add_child(restart_button)


func _layout_end_emblem() -> void:
	if not is_instance_valid(end_emblem) or not is_instance_valid(end_panel):
		return
	# Center the actual visible mass, not only the TextureRect. The generated
	# heart is top-heavy, so a geometrically centered 64x64 control still looks
	# too high between the title and result copy.
	end_emblem.size = END_EMBLEM_SIZE
	var target_center := Vector2(end_panel.size.x * 0.5, END_EMBLEM_VISUAL_CENTER_Y)
	var texture_size := Vector2(END_CORE.get_width(), END_CORE.get_height())
	var render_scale := minf(end_emblem.size.x / texture_size.x, end_emblem.size.y / texture_size.y)
	var visual_offset := room_view.get_texture_visual_centroid_offset(END_CORE)
	end_emblem.position = target_center - end_emblem.size * 0.5
	if visual_offset != Vector2.INF:
		end_emblem.position -= visual_offset * render_scale


func _build_pause_overlay() -> void:
	pause_overlay = ColorRect.new()
	pause_overlay.name = "PauseOverlay"
	pause_overlay.color = Color(0.008, 0.018, 0.016, 0.76)
	pause_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	pause_overlay.z_index = 60
	pause_overlay.visible = false
	pause_overlay.process_mode = Node.PROCESS_MODE_ALWAYS
	pause_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(pause_overlay)
	var panel := Panel.new()
	panel.position = Vector2(270, 132)
	panel.size = Vector2(420, 276)
	panel.add_theme_stylebox_override("panel", _make_panel_style(Color(0.045, 0.095, 0.075, 0.98), Color(0.32, 0.80, 0.58, 1.0)))
	pause_overlay.add_child(panel)
	pause_title = _make_label("节拍暂停", Vector2(30, 24), Vector2(360, 42), 29, COLOR_READY)
	pause_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	panel.add_child(pause_title)
	pause_body = _make_label("心核脉冲暂时静止\n\n空格 / Esc　继续游戏\n左 Shift　按拍蓄力", Vector2(35, 72), Vector2(350, 72), 15, COLOR_TEXT)
	pause_body.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	pause_body.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	pause_body.add_theme_constant_override("line_spacing", 3)
	panel.add_child(pause_body)
	pause_resume_button = _make_menu_button("继续游戏", 16)
	pause_resume_button.position = Vector2(58, 174)
	pause_resume_button.size = Vector2(142, 44)
	pause_resume_button.pressed.connect(func() -> void: _set_game_paused(false))
	panel.add_child(pause_resume_button)
	pause_title_button = _make_menu_button("返回标题", 16)
	pause_title_button.position = Vector2(220, 174)
	pause_title_button.size = Vector2(142, 44)
	pause_title_button.pressed.connect(_return_to_title_from_pause)
	panel.add_child(pause_title_button)


func _build_main_menu_overlay() -> void:
	main_menu_overlay = ColorRect.new()
	main_menu_overlay.name = "MainMenuOverlay"
	main_menu_overlay.color = Color(0.008, 0.018, 0.016, 0.24)
	main_menu_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	main_menu_overlay.z_index = 70
	main_menu_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(main_menu_overlay)
	var title_texture := _load_title_background()
	if title_texture != null:
		title_background = TextureRect.new()
		title_background.texture = title_texture
		title_background.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		title_background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		title_background.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		title_background.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		title_background.modulate = Color(0.72, 0.92, 0.84, 0.70)
		title_background.mouse_filter = Control.MOUSE_FILTER_IGNORE
		main_menu_overlay.add_child(title_background)
		main_menu_overlay.move_child(title_background, 0)
	var panel := Panel.new()
	panel.name = "MainMenuPanel"
	panel.position = Vector2(260, 102)
	panel.size = Vector2(440, 336)
	panel.add_theme_stylebox_override("panel", _make_panel_style(Color(0.035, 0.085, 0.068, 0.42), Color(0.28, 0.82, 0.59, 0.78)))
	main_menu_overlay.add_child(panel)
	var title := _make_label("律动遗迹", Vector2(35, 42), Vector2(370, 54), 38, COLOR_HIT)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	panel.add_child(title)
	main_menu_start_button = _make_menu_button("开始游戏", 18)
	main_menu_start_button.position = Vector2(95, 132)
	main_menu_start_button.size = Vector2(250, 48)
	main_menu_start_button.pressed.connect(start_game)
	panel.add_child(main_menu_start_button)
	main_menu_settings_button = _make_menu_button("设置", 16)
	main_menu_settings_button.position = Vector2(95, 192)
	main_menu_settings_button.size = Vector2(250, 44)
	main_menu_settings_button.pressed.connect(_open_settings)
	panel.add_child(main_menu_settings_button)
	main_menu_quit_button = _make_menu_button("退出游戏", 16)
	main_menu_quit_button.position = Vector2(95, 248)
	main_menu_quit_button.size = Vector2(250, 44)
	main_menu_quit_button.pressed.connect(_quit_game)
	panel.add_child(main_menu_quit_button)


func _build_settings_overlay() -> void:
	settings_overlay = ColorRect.new()
	settings_overlay.name = "SettingsOverlay"
	settings_overlay.color = Color(0.008, 0.018, 0.016, 0.80)
	settings_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	settings_overlay.z_index = 75
	settings_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	settings_overlay.visible = false
	add_child(settings_overlay)
	settings_panel = Panel.new()
	settings_panel.position = Vector2(180, 26)
	settings_panel.size = Vector2(600, 494)
	settings_panel.add_theme_stylebox_override("panel", _make_panel_style(Color(0.035, 0.085, 0.068, 0.99), Color(0.28, 0.82, 0.59, 1.0)))
	settings_overlay.add_child(settings_panel)
	var title := _make_label("设置", Vector2(36, 24), Vector2(528, 42), 30, COLOR_HIT)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	settings_panel.add_child(title)
	var audio_label := _make_label("音量", Vector2(42, 82), Vector2(120, 28), 16, COLOR_TEXT)
	settings_panel.add_child(audio_label)
	settings_volume_slider = HSlider.new()
	settings_volume_slider.position = Vector2(150, 80)
	settings_volume_slider.size = Vector2(300, 30)
	settings_volume_slider.min_value = 0.0
	settings_volume_slider.max_value = 100.0
	settings_volume_slider.step = 1.0
	settings_volume_slider.value_changed.connect(_on_master_volume_changed)
	settings_panel.add_child(settings_volume_slider)
	settings_volume_value = _make_label("80%", Vector2(465, 82), Vector2(90, 28), 15, COLOR_READY)
	settings_volume_value.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	settings_panel.add_child(settings_volume_value)
	var offset_label := _make_label("谱面延时", Vector2(42, 126), Vector2(120, 28), 16, COLOR_TEXT)
	settings_panel.add_child(offset_label)
	settings_offset_slider = HSlider.new()
	settings_offset_slider.position = Vector2(150, 124)
	settings_offset_slider.size = Vector2(300, 30)
	settings_offset_slider.min_value = -200.0
	settings_offset_slider.max_value = 200.0
	settings_offset_slider.step = 5.0
	settings_offset_slider.value_changed.connect(_on_chart_offset_changed)
	settings_panel.add_child(settings_offset_slider)
	settings_offset_value = _make_label("+0 ms", Vector2(465, 126), Vector2(90, 28), 15, COLOR_READY)
	settings_offset_value.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	settings_panel.add_child(settings_offset_value)
	var offset_hint := _make_label("EARLY 调低 · LATE 调高", Vector2(150, 148), Vector2(300, 18), 11, COLOR_MUTED)
	offset_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	settings_panel.add_child(offset_hint)
	var separator := HSeparator.new()
	separator.position = Vector2(40, 168)
	separator.size = Vector2(520, 2)
	settings_panel.add_child(separator)
	var keys_label := _make_label("键位", Vector2(42, 184), Vector2(120, 28), 16, COLOR_TEXT)
	settings_panel.add_child(keys_label)
	var y := 212.0
	for action in SettingsScript.ACTIONS:
		var label := _make_label(SettingsScript.ACTION_LABELS.get(action, String(action)), Vector2(48, y), Vector2(230, 26), 14, COLOR_MUTED)
		settings_panel.add_child(label)
		var button := _make_menu_button("未设置", 13)
		button.position = Vector2(330, y - 4.0)
		button.size = Vector2(180, 32)
		button.pressed.connect(_begin_rebind.bind(action))
		settings_binding_buttons[action] = button
		settings_panel.add_child(button)
		y += 32.0
	settings_status_label = _make_label("点击键位按钮后，按下新的按键", Vector2(42, 448), Vector2(360, 24), 12, COLOR_MUTED)
	settings_panel.add_child(settings_status_label)
	settings_back_button = _make_menu_button("返回", 14)
	settings_back_button.position = Vector2(428, 442)
	settings_back_button.size = Vector2(110, 34)
	settings_back_button.pressed.connect(_close_settings)
	settings_panel.add_child(settings_back_button)


func _load_title_background() -> Texture2D:
	# The downloaded placeholder is PNG bytes with the queue's .jpeg name. Use
	# Image decoding so a mismatched suffix cannot break startup; if decoding
	# fails, the normal procedural background behind the menu remains visible.
	if not FileAccess.file_exists(TITLE_BACKGROUND_PATH):
		return null
	var bytes := FileAccess.get_file_as_bytes(TITLE_BACKGROUND_PATH)
	var image := Image.new()
	var error := image.load_png_from_buffer(bytes) if bytes.size() >= 8 and bytes[0] == 0x89 and bytes[1] == 0x50 else image.load_jpg_from_buffer(bytes)
	if error != OK:
		return null
	return ImageTexture.create_from_image(image)


func _make_menu_button(text: String, font_size: int) -> Button:
	var button := Button.new()
	button.text = text
	button.focus_mode = Control.FOCUS_ALL
	button.add_theme_font_size_override("font_size", font_size)
	button.add_theme_stylebox_override("normal", _make_panel_style(Color(0.08, 0.20, 0.15, 1.0), Color(0.22, 0.58, 0.42, 1.0)))
	button.add_theme_stylebox_override("hover", _make_panel_style(Color(0.14, 0.36, 0.26, 1.0), Color(0.43, 0.92, 0.64, 1.0)))
	button.add_theme_stylebox_override("pressed", _make_panel_style(Color(0.05, 0.12, 0.09, 1.0), Color(0.31, 0.75, 0.52, 1.0)))
	return button


func _make_reward_button(title: String, detail: String, shortcut: String, icon: Texture2D) -> Button:
	var button := Button.new()
	button.text = ""
	button.tooltip_text = "%s：%s（按 %s）" % [title, detail, shortcut]
	button.focus_mode = Control.FOCUS_ALL
	button.add_theme_stylebox_override("normal", _make_panel_style(Color(0.08, 0.18, 0.14, 1.0), Color(0.22, 0.52, 0.39, 1.0)))
	button.add_theme_stylebox_override("hover", _make_panel_style(Color(0.13, 0.31, 0.23, 1.0), Color(0.43, 0.9, 0.62, 1.0)))
	button.add_theme_stylebox_override("pressed", _make_panel_style(Color(0.06, 0.12, 0.095, 1.0), Color(0.31, 0.75, 0.52, 1.0)))

	var content := VBoxContainer.new()
	content.name = "Content"
	content.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	content.offset_left = 10.0
	content.offset_top = 7.0
	content.offset_right = -10.0
	content.offset_bottom = -6.0
	content.alignment = BoxContainer.ALIGNMENT_CENTER
	content.add_theme_constant_override("separation", 1)
	content.mouse_filter = Control.MOUSE_FILTER_IGNORE
	button.add_child(content)

	var icon_rect := TextureRect.new()
	icon_rect.name = "Icon"
	icon_rect.texture = icon
	icon_rect.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	icon_rect.custom_minimum_size = Vector2(0, 30)
	icon_rect.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	icon_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content.add_child(icon_rect)

	var title_label := _make_label(title, Vector2.ZERO, Vector2.ZERO, 15, COLOR_TEXT)
	title_label.name = "Title"
	title_label.custom_minimum_size = Vector2(0, 20)
	title_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	title_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content.add_child(title_label)

	var detail_label := _make_label(detail, Vector2.ZERO, Vector2.ZERO, 13, COLOR_MUTED)
	detail_label.name = "Detail"
	detail_label.custom_minimum_size = Vector2(0, 20)
	detail_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	detail_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	detail_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	detail_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content.add_child(detail_label)

	var shortcut_label := _make_label(shortcut, Vector2.ZERO, Vector2.ZERO, 15, COLOR_READY)
	shortcut_label.name = "Shortcut"
	shortcut_label.custom_minimum_size = Vector2(0, 18)
	shortcut_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	shortcut_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	shortcut_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	shortcut_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content.add_child(shortcut_label)
	return button


func _make_label(text: String, label_position: Vector2, label_size: Vector2, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = text
	label.position = label_position
	label.size = label_size
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	return label


func _make_panel_style(background: Color, border: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = background
	style.border_color = border
	style.set_border_width_all(1)
	style.set_corner_radius_all(5)
	return style


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
