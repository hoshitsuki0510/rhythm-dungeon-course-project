extends SceneTree

func _init() -> void:
	print("started")
	for class_name_text in ["FontFile", "Font", "Theme", "SystemFont"]:
		print("CLASS ", class_name_text)
		for p in ClassDB.class_get_property_list(class_name_text):
			var n := String(p.get("name", ""))
			if n.contains("fallback") or n.contains("font") or n.contains("oversample") or n.contains("hint"):
				print(p)
	var f: Font = load("res://assets/fonts/FusionPixel_12px_Proportional_zh_hans.ttf")
	print("font resource=", f, "has_char=", f.has_char(ord("律")), "has_minus=", f.has_char(ord("−")))
	print("font props hinting=", f.hinting, "allow_system_fallback=", f.allow_system_fallback, "fallbacks=", f.fallbacks)
	print("font name=", f.font_name, "style=", f.font_style, "weight=", f.font_weight, "stretch=", f.font_stretch)
	for p in f.get_property_list():
		var n := String(p.get("name", ""))
		if n.contains("antialias") or n.contains("subpixel") or n.contains("oversam") or n.contains("hint") or n.contains("fallback"):
			print("FONT_PROP ", n, "=", f.get(n))
	quit()
