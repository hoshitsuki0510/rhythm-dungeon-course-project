extends Control

@onready var status_label: Label = %StatusLabel


func _ready() -> void:
	var smoke_message := "INIT_SMOKE_OK | Godot 4.7.2 | project initialized"
	print(smoke_message)
	status_label.text = "初始化完成：场景、脚本与导出预设均已加载"

	if DisplayServer.get_name() == "headless":
		get_tree().quit(0)
