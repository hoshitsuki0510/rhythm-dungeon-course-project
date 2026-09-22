extends SceneTree

const PixelFont = preload("res://assets/fonts/FusionPixel_12px_Proportional_zh_hans.ttf")
const SOURCE_ROOTS := ["res://scripts", "res://scenes", "res://project.godot"]
const EXTRA_SYMBOLS := "±·。《》：，（）！？，、　"

var failures: Array[String] = []
var required_codepoints: Dictionary = {}


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	_collect_required_codepoints()
	_validate_font_resource()
	_validate_required_codepoints()
	if failures.is_empty():
		print("FONT_SMOKE_OK | Fusion Pixel 12px proportional zh_hans | %d codepoints" % required_codepoints.size())
		quit(0)
		return
	for failure in failures:
		push_error("FONT_SMOKE_FAIL | " + failure)
	quit(1)


func _collect_required_codepoints() -> void:
	# Scan the source rather than maintaining a second hand-written character
	# list. This keeps the check useful when a future UI string is added.
	for root_path in SOURCE_ROOTS:
		if root_path == "res://project.godot":
			_collect_from_file(root_path)
		else:
			_collect_from_directory(root_path)
	for codepoint in range(32, 127):
		required_codepoints[codepoint] = true
	for i in range(EXTRA_SYMBOLS.length()):
		required_codepoints[EXTRA_SYMBOLS.unicode_at(i)] = true


func _collect_from_directory(directory_path: String) -> void:
	var directory := DirAccess.open(directory_path)
	if directory == null:
		failures.append("cannot open %s" % directory_path)
		return
	directory.list_dir_begin()
	while true:
		var entry := directory.get_next()
		if entry.is_empty():
			break
		if entry == "." or entry == "..":
			continue
		var entry_path := directory_path.path_join(entry)
		if directory.current_is_dir():
			_collect_from_directory(entry_path)
		elif entry.ends_with(".gd") or entry.ends_with(".tscn"):
			_collect_from_file(entry_path)
	directory.list_dir_end()


func _collect_from_file(file_path: String) -> void:
	var source := FileAccess.get_file_as_string(file_path)
	for i in range(source.length()):
		var codepoint := source.unicode_at(i)
		# Check every non-ASCII codepoint used by the project, not only the
		# current Chinese block and hand-maintained punctuation list. This catches
		# arrows, dashes, ellipses, mathematical signs, and future UI symbols.
		if codepoint > 126 and codepoint != 0x09 and codepoint != 0x0A and codepoint != 0x0D:
			required_codepoints[codepoint] = true


func _validate_font_resource() -> void:
	if PixelFont == null:
		failures.append("font resource failed to load")
		return
	if not PixelFont is FontFile:
		failures.append("loaded resource is not a FontFile")
		return
	var font_file := PixelFont as FontFile
	if font_file.allow_system_fallback:
		failures.append("system fallback is enabled; it can introduce non-pixel glyphs")
	if font_file.antialiasing != 0:
		failures.append("antialiasing is %d, expected 0" % font_file.antialiasing)
	# Godot's pixel-font importer should leave these at zero. Non-zero values
	# can introduce inconsistent glyph positioning at the 12–16 px HUD sizes.
	if font_file.hinting != 0:
		failures.append("hinting is %d, expected 0" % font_file.hinting)
	if font_file.subpixel_positioning != 0:
		failures.append("subpixel positioning is %d, expected 0" % font_file.subpixel_positioning)


func _validate_required_codepoints() -> void:
	var missing: Array[String] = []
	for codepoint in required_codepoints:
		if codepoint == 9 or codepoint == 10 or codepoint == 13:
			continue
		if not PixelFont.has_char(int(codepoint)):
			missing.append("U+%04X %s" % [int(codepoint), String.chr(int(codepoint))])
	if not missing.is_empty():
		missing.sort()
		failures.append("missing %d project glyphs: %s" % [missing.size(), ", ".join(missing)])
