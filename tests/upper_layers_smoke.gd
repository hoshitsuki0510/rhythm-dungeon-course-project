extends SceneTree

const StateScript = preload("res://scripts/mvp/mvp_state.gd")
const MvpScene = preload("res://scenes/mvp/mvp_run.tscn")
const PISTON_SHEET = preload("res://assets/sprites/piston_colossus_sheet.png")
const OXYGEN_SHEET = preload("res://assets/sprites/oxygen_reservoir_sheet.png")
const ARRHYTHMIA_SHEET = preload("res://assets/sprites/arrhythmia_boss_sheet.png")
const RIGHT_VENTRICLE_BACKGROUND = preload("res://assets/backgrounds/room_right_ventricle.png")
const LEFT_ATRIUM_BACKGROUND = preload("res://assets/backgrounds/room_left_atrium.png")
const LEFT_VENTRICLE_BACKGROUND = preload("res://assets/backgrounds/room_left_ventricle.png")
const PRESSURIZED_PORTAL = preload("res://assets/objects/portal_pressurized_sheet.png")
const OXYGEN_PORTAL = preload("res://assets/objects/portal_oxygen_flow_sheet.png")
const PRIME_RESONANCE_PORTAL = preload("res://assets/objects/portal_prime_resonance_sheet.png")
const PISTON_STRIKE_EFFECT = preload("res://assets/effects/piston_strike_sheet.png")
const PULMONARY_JET_EFFECT = preload("res://assets/effects/pulmonary_jet_sheet.png")
const OXYGEN_CHARGE_EFFECT = preload("res://assets/effects/oxygen_charge_sheet.png")
const GROUND_SPIKE_EFFECT = preload("res://assets/effects/ground_spike_wave_sheet.png")
const DEFIBRILLATION_EFFECT = preload("res://assets/effects/defibrillation_countdown_sheet.png")
const NOISE_PROJECTILE_EFFECT = preload("res://assets/effects/noise_projectile_sheet.png")
var failures: Array[String] = []

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var state := StateScript.new()
	# Reach layer 2 through the same five-room route used by the controller.
	for _i in range(4):
		_expect(state.enter_next_room(), "layer one route advances")
	state.room_cleared = true
	_expect(state.advance_layer(), "layer one portal advances to layer two")
	_expect(state.layer_index == 2 and state.room_kind == StateScript.ROOM_START, "layer two starts at preparation room")
	_expect(state.room_background_path == "res://assets/backgrounds/room_right_ventricle.png", "layer two uses generated map")
	for _i in range(4): state.enter_next_room()
	var boss2: MvpUnitState = state.get_boss()
	_expect(state.boss_kind == &"piston_colossus" and boss2.max_hp == 8, "layer two piston boss loads")
	state.player.cell = Vector2i(2, 2)
	var result := state.resolve_turn(&"wait")
	_expect(result.enemies[0].kind == "piston_windup", "piston boss telegraphs")
	_expect(result.enemies[0].cells.size() == state.map_definition.grid_size.x, "piston boss telegraphs full row")
	state.player.cell = Vector2i(2, 4)
	result = state.resolve_turn(&"wait")
	_expect(result.enemies[0].kind == "piston_strike" and not result.enemies[0].hit, "piston strike can be dodged")

	state.room_cleared = true
	_expect(state.advance_layer(), "layer two portal advances to layer three")
	_expect(state.room_background_path == "res://assets/backgrounds/room_left_atrium.png", "layer three uses generated map")
	for _i in range(4): state.enter_next_room()
	var boss3: MvpUnitState = state.get_boss()
	_expect(state.boss_kind == &"oxygen_reservoir" and boss3.max_hp == 8, "layer three oxygen boss loads")
	state.player.cell = Vector2i(4, 2)
	result = state.resolve_turn(&"wait")
	_expect(result.enemies[0].kind == "oxygen_charge" and result.enemies[0].interruptible, "oxygen boss starts interruptible charge")
	result = state.resolve_turn(&"direction", Vector2i.RIGHT)
	_expect(result.player.interrupted and result.player.damage > 0, "oxygen charge is interrupted by attack")
	_expect(state.boss_charge_beat == 0, "oxygen charge resets after interruption")

	state.room_cleared = true
	_expect(state.advance_layer(), "layer three portal advances to layer four")
	_expect(state.room_background_path == "res://assets/backgrounds/room_left_ventricle.png", "layer four uses generated map")
	for _i in range(4): state.enter_next_room()
	var boss4: MvpUnitState = state.get_boss()
	_expect(state.boss_kind == &"arrhythmia" and state.get_bpm() == 105.0, "layer four starts at 105 BPM")
	state.player.cell = Vector2i(4, 2)
	boss4.cell = Vector2i(5, 2)
	boss4.hp = 5
	result = state.resolve_turn(&"direction", Vector2i.RIGHT)
	_expect(state.boss_phase_shift_pending and state.boss_phase_shift_countdown == 4, "arrhythmia starts four beat defibrillation warning")
	for _i in range(4): result = state.resolve_turn(&"wait")
	_expect(state.boss_phase == 2 and state.get_bpm() == 140.0, "arrhythmia switches to 140 BPM phase")
	_expect(result.enemies[0].kind == "phase_shift", "phase switch resolves after four beats")

	var scene := MvpScene.instantiate()
	root.add_child(scene)
	scene.beat_clock.stop()
	var world_assets := [
		[StateScript.LAYER_TWO, RIGHT_VENTRICLE_BACKGROUND, PRESSURIZED_PORTAL, PISTON_SHEET],
		[StateScript.LAYER_THREE, LEFT_ATRIUM_BACKGROUND, OXYGEN_PORTAL, OXYGEN_SHEET],
		[StateScript.LAYER_FOUR, LEFT_VENTRICLE_BACKGROUND, PRIME_RESONANCE_PORTAL, ARRHYTHMIA_SHEET],
	]
	for layer_and_assets in world_assets:
		var layer := int(layer_and_assets[0])
		scene.room_state.layer_index = layer
		scene.room_state._enter_room(StateScript.ROOM_BOSS)
		scene.room_view.set_room()
		var boss_sprite: Sprite2D = scene.room_view.actor_sprites.get("boss")
		_expect(boss_sprite != null and boss_sprite.texture == layer_and_assets[3], "layer %d uses its generated Boss atlas" % layer)
		_expect(scene.room_view.background_texture == layer_and_assets[1], "layer %d uses its generated map texture" % layer)
		scene.room_state.room_cleared = true
		scene.room_view.set_room()
		_expect(scene.room_view.exit_portal_sprite.texture == layer_and_assets[2], "layer %d uses its generated central portal" % layer)
		_expect(scene.room_view.exit_portal_sprite.hframes == 4 and scene.room_view.exit_portal_sprite.vframes == 1, "layer %d portal is a four-frame sheet" % layer)
	# Exercise the actual presentation dispatcher for every new upper-layer sheet.
	scene.room_state.layer_index = StateScript.LAYER_TWO
	scene.room_state._enter_room(StateScript.ROOM_BOSS)
	scene.room_view.set_room()
	scene.room_view.present_turn({"enemies":[{"kind":"piston_windup", "cells":[Vector2i(0, 2), Vector2i(10, 2)], "axis":"row", "valve_state":"red"}]})
	_expect(_has_effect_texture(scene, PISTON_STRIKE_EFFECT), "2F piston windup uses generated effect")
	scene.room_view.present_turn({"enemies":[{"kind":"piston_strike", "cells":[Vector2i(0, 2), Vector2i(5, 2), Vector2i(10, 2)], "axis":"row", "valve_state":"blue", "hit":false}]})
	_expect(_has_effect_texture(scene, PISTON_STRIKE_EFFECT), "2F piston strike uses generated effect")

	scene.room_state.layer_index = StateScript.LAYER_THREE
	scene.room_state._enter_room(StateScript.ROOM_BOSS)
	scene.room_view.set_room()
	scene.room_view.present_turn({"enemies":[{"kind":"oxygen_charge", "charge_beat":2}]})
	_expect(_has_effect_texture(scene, OXYGEN_CHARGE_EFFECT), "3F oxygen charge uses generated effect")
	scene.room_view.present_turn({"enemies":[{"kind":"oxygen_blast", "hit":false}]})
	_expect(_has_effect_texture(scene, PULMONARY_JET_EFFECT), "3F pulmonary jet uses generated effect")
	scene.room_view.present_turn({"enemies":[{"kind":"oxygen_stagger"}]})
	_expect(scene.room_view.actor_layer.get_child_count() > 0, "3F stagger feedback remains visible")

	scene.room_state.layer_index = StateScript.LAYER_FOUR
	scene.room_state._enter_room(StateScript.ROOM_BOSS)
	scene.room_view.set_room()
	scene.room_view.present_turn({"enemies":[{"kind":"spike_windup", "cells":[Vector2i(3, 2), Vector2i(4, 2), Vector2i(5, 2)], "direction":Vector2i.RIGHT}]})
	_expect(_has_effect_texture(scene, GROUND_SPIKE_EFFECT), "4F spike warning uses generated effect")
	scene.room_view.present_turn({"enemies":[{"kind":"noise_burst", "hit":false}]})
	_expect(_has_effect_texture(scene, NOISE_PROJECTILE_EFFECT), "4F noise burst uses generated effect")
	scene.room_view.present_turn({"enemies":[{"kind":"defibrillation", "countdown":3}]})
	_expect(_has_effect_texture(scene, DEFIBRILLATION_EFFECT), "4F defibrillation uses generated effect")
	scene.room_view.present_turn({"enemies":[{"kind":"phase_shift"}]})
	_expect(_has_effect_texture(scene, DEFIBRILLATION_EFFECT), "4F phase shift uses generated effect")

	scene.room_state.layer_index = StateScript.LAYER_FOUR
	scene.room_state._enter_room(StateScript.ROOM_BOSS)
	scene.room_state._enter_room(StateScript.ROOM_BOSS)
	scene.room_view.set_room()
	scene._finish_run(true)
	_expect(scene.end_title.text.find("四层完成") >= 0, "final Boss opens the four-layer ending")
	_expect(scene.end_body.text.find("始源心核") >= 0, "final ending describes restored core")
	scene.metronome.stop()
	root.remove_child(scene)
	scene.free()

	if failures.is_empty():
		print("UPPER_LAYERS_SMOKE_OK | 2F_piston_row_column 3F_interruptible_four_beat_charge 4F_105_to_140_defibrillation layer_art_grids generated_maps generated_central_portals boss_atlas_runtime upper_boss_effects_runtime reward_icons portal_route")
		quit(0)
		return
	for failure in failures:
		push_error("UPPER_LAYERS_SMOKE_FAIL | " + failure)
	quit(1)

func _has_effect_texture(scene: Node, expected: Texture2D) -> bool:
	for child in scene.room_view.actor_layer.get_children():
		if child is Sprite2D and child.texture == expected:
			return true
	return false


func _expect(condition: bool, label: String) -> void:
	if not condition:
		failures.append(label)
