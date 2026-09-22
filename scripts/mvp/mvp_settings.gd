extends RefCounted

const SETTINGS_PATH := "user://mvp_settings.cfg"
const SETTINGS_VERSION := 1
const ACTIONS: Array[StringName] = [
	&"move_up",
	&"move_down",
	&"move_left",
	&"move_right",
	&"charge_action",
	&"pause_game",
	&"interact_action",
]
const ACTION_LABELS := {
	&"move_up": "向上移动",
	&"move_down": "向下移动",
	&"move_left": "向左移动",
	&"move_right": "向右移动",
	&"charge_action": "按拍蓄力",
	&"pause_game": "暂停/继续",
	&"interact_action": "交互/传送",
}

var settings_path := SETTINGS_PATH
var master_volume_percent := 80.0
var chart_offset_ms := 0.0


func _init(path: String = SETTINGS_PATH) -> void:
	settings_path = path


func load_and_apply() -> void:
	var config := ConfigFile.new()
	var loaded := config.load(settings_path) == OK
	if loaded:
		master_volume_percent = clampf(float(config.get_value("audio", "master_volume_percent", master_volume_percent)), 0.0, 100.0)
		chart_offset_ms = clampf(float(config.get_value("timing", "chart_offset_ms", chart_offset_ms)), -200.0, 200.0)
	for action in ACTIONS:
		_ensure_action(action)
		InputMap.action_erase_events(action)
		var restored := false
		if loaded and config.has_section_key("controls", String(action)):
			var encoded_events: Variant = config.get_value("controls", String(action), [])
			if encoded_events is Array:
				for encoded in encoded_events:
					if encoded is Dictionary:
						var event := _decode_key_event(encoded)
						if event != null:
							InputMap.action_add_event(action, event)
							restored = true
		if not restored:
			for event in _default_events(action):
				InputMap.action_add_event(action, event)
	apply_volume()


func save() -> Error:
	var config := ConfigFile.new()
	config.set_value("meta", "version", SETTINGS_VERSION)
	config.set_value("audio", "master_volume_percent", master_volume_percent)
	config.set_value("timing", "chart_offset_ms", chart_offset_ms)
	for action in ACTIONS:
		var encoded_events: Array[Dictionary] = []
		for event in InputMap.action_get_events(action):
			if event is InputEventKey:
				encoded_events.append(_encode_key_event(event as InputEventKey))
		config.set_value("controls", String(action), encoded_events)
	return config.save(settings_path)


func set_master_volume(value: float) -> void:
	master_volume_percent = clampf(value, 0.0, 100.0)
	apply_volume()


func apply_volume() -> void:
	var bus_index := AudioServer.get_bus_index("Master")
	if bus_index < 0:
		return
	var linear_volume := master_volume_percent / 100.0
	AudioServer.set_bus_mute(bus_index, linear_volume <= 0.001)
	AudioServer.set_bus_volume_db(bus_index, linear_to_db(maxf(linear_volume, 0.001)))


func set_chart_offset(value_ms: float) -> void:
	chart_offset_ms = clampf(value_ms, -200.0, 200.0)


func set_binding(action: StringName, source_event: InputEventKey) -> bool:
	if not ACTIONS.has(action):
		return false
	var event := InputEventKey.new()
	event.keycode = source_event.keycode
	event.physical_keycode = source_event.physical_keycode
	event.location = source_event.location
	if event.keycode == 0 and event.physical_keycode == 0:
		return false
	_ensure_action(action)
	InputMap.action_erase_events(action)
	InputMap.action_add_event(action, event)
	return true


func get_binding_text(action: StringName) -> String:
	for raw_event in InputMap.action_get_events(action):
		if not raw_event is InputEventKey:
			continue
		var event := raw_event as InputEventKey
		var code := event.physical_keycode if event.physical_keycode != 0 else event.keycode
		var text := OS.get_keycode_string(code)
		if code == KEY_SHIFT and event.location == KeyLocation.KEY_LOCATION_LEFT:
			return "左 Shift"
		return text if not text.is_empty() else event.as_text()
	return "未设置"


func _ensure_action(action: StringName) -> void:
	if not InputMap.has_action(action):
		InputMap.add_action(action)


func _default_events(action: StringName) -> Array[InputEventKey]:
	match action:
		&"move_up":
			return [_make_physical_key(KEY_W), _make_key(KEY_UP)]
		&"move_down":
			return [_make_physical_key(KEY_S), _make_key(KEY_DOWN)]
		&"move_left":
			return [_make_physical_key(KEY_A), _make_key(KEY_LEFT)]
		&"move_right":
			return [_make_physical_key(KEY_D), _make_key(KEY_RIGHT)]
		&"charge_action":
			return [_make_key(KEY_SHIFT, KeyLocation.KEY_LOCATION_LEFT)]
		&"pause_game":
			return [_make_key(KEY_SPACE), _make_key(KEY_ESCAPE)]
		&"interact_action":
			return [_make_key(KEY_E)]
		_:
			return []


func _make_key(code: Key, location: KeyLocation = KeyLocation.KEY_LOCATION_UNSPECIFIED) -> InputEventKey:
	var event := InputEventKey.new()
	event.keycode = code
	event.location = location
	return event


func _make_physical_key(code: Key) -> InputEventKey:
	var event := InputEventKey.new()
	event.physical_keycode = code
	return event


func _encode_key_event(event: InputEventKey) -> Dictionary:
	return {
		"keycode": int(event.keycode),
		"physical_keycode": int(event.physical_keycode),
		"location": int(event.location),
	}


func _decode_key_event(encoded: Dictionary) -> InputEventKey:
	var event := InputEventKey.new()
	event.keycode = int(encoded.get("keycode", 0)) as Key
	event.physical_keycode = int(encoded.get("physical_keycode", 0)) as Key
	event.location = int(encoded.get("location", 0)) as KeyLocation
	if event.keycode == 0 and event.physical_keycode == 0:
		return null
	return event
