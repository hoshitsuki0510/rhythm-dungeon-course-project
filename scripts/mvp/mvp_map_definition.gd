extends Resource

const RIGHT_ATRIUM_MAP_ID: StringName = &"right_atrium_11x6"
const RIGHT_ATRIUM_GRID_SIZE := Vector2i(11, 6)
const RIGHT_ATRIUM_REFERENCE_SIZE := Vector2(960.0, 540.0)
const RIGHT_ATRIUM_GRID_ORIGIN := Vector2(153.0, 95.0)
const RIGHT_ATRIUM_TILE_SIZE := 60.0
const RIGHT_ATRIUM_EXIT_CENTER := Vector2(850.0, 270.0)
const RIGHT_ATRIUM_EXIT_SIZE := Vector2(34.0, 66.0)
const UPPER_LAYER_REFERENCE_SIZE := Vector2(960.0, 540.0)

@export var map_id: StringName = RIGHT_ATRIUM_MAP_ID
@export var grid_size := RIGHT_ATRIUM_GRID_SIZE
@export var art_reference_size := RIGHT_ATRIUM_REFERENCE_SIZE
@export var art_grid_origin := RIGHT_ATRIUM_GRID_ORIGIN
@export var art_tile_size := RIGHT_ATRIUM_TILE_SIZE
@export var exit_door_center := RIGHT_ATRIUM_EXIT_CENTER
@export var exit_door_size := RIGHT_ATRIUM_EXIT_SIZE


func configure_for_layer(layer_index: int) -> void:
	# The three generated upper-layer maps do not share the first-layer art
	# margins. Keep the gameplay grid authoritative per artwork so sprites and
	# doors land on real floor cells instead of the surrounding wall/corridor.
	match layer_index:
		2:
			map_id = &"right_ventricle_9x5"
			grid_size = Vector2i(9, 5)
			art_reference_size = UPPER_LAYER_REFERENCE_SIZE
			art_grid_origin = Vector2(235.0, 95.0)
			art_tile_size = 60.0
			exit_door_center = Vector2(785.0, 235.0)
			exit_door_size = Vector2(34.0, 66.0)
		3:
			map_id = &"left_atrium_10x5"
			grid_size = Vector2i(10, 5)
			art_reference_size = UPPER_LAYER_REFERENCE_SIZE
			art_grid_origin = Vector2(164.0, 95.0)
			art_tile_size = 60.0
			exit_door_center = Vector2(805.0, 255.0)
			exit_door_size = Vector2(34.0, 66.0)
		4:
			map_id = &"left_ventricle_9x5"
			grid_size = Vector2i(9, 5)
			art_reference_size = UPPER_LAYER_REFERENCE_SIZE
			art_grid_origin = Vector2(235.0, 95.0)
			art_tile_size = 60.0
			exit_door_center = Vector2(807.0, 215.0)
			exit_door_size = Vector2(34.0, 66.0)
		_:
			map_id = RIGHT_ATRIUM_MAP_ID
			grid_size = RIGHT_ATRIUM_GRID_SIZE
			art_reference_size = RIGHT_ATRIUM_REFERENCE_SIZE
			art_grid_origin = RIGHT_ATRIUM_GRID_ORIGIN
			art_tile_size = RIGHT_ATRIUM_TILE_SIZE
			exit_door_center = RIGHT_ATRIUM_EXIT_CENTER
			exit_door_size = RIGHT_ATRIUM_EXIT_SIZE


func is_inside(cell: Vector2i) -> bool:
	return cell.x >= 0 and cell.y >= 0 and cell.x < grid_size.x and cell.y < grid_size.y


func get_scene_rect(viewport_size: Vector2) -> Rect2:
	var actual_viewport := viewport_size
	if actual_viewport.x <= 0.0 or actual_viewport.y <= 0.0:
		actual_viewport = art_reference_size
	var scale_factor := minf(actual_viewport.x / art_reference_size.x, actual_viewport.y / art_reference_size.y)
	var scene_size := art_reference_size * scale_factor
	return Rect2((actual_viewport - scene_size) * 0.5, scene_size)


func get_grid_layout(viewport_size: Vector2) -> Dictionary:
	var scene_rect := get_scene_rect(viewport_size)
	var scene_scale := scene_rect.size.x / art_reference_size.x
	return {
		"origin": scene_rect.position + art_grid_origin * scene_scale,
		"cell_size": art_tile_size * scene_scale,
	}


func get_cell_center(cell: Vector2i, viewport_size: Vector2) -> Vector2:
	var layout := get_grid_layout(viewport_size)
	return layout.origin + Vector2(cell) * float(layout.cell_size) + Vector2.ONE * float(layout.cell_size) * 0.5


func get_board_center(viewport_size: Vector2) -> Vector2:
	var layout := get_grid_layout(viewport_size)
	return layout.origin + Vector2(grid_size) * float(layout.cell_size) * 0.5


func get_exit_center(viewport_size: Vector2) -> Vector2:
	var scene_rect := get_scene_rect(viewport_size)
	var scene_scale := scene_rect.size.x / art_reference_size.x
	return scene_rect.position + exit_door_center * scene_scale


func get_exit_size(viewport_size: Vector2) -> Vector2:
	var scene_rect := get_scene_rect(viewport_size)
	return exit_door_size * (scene_rect.size.x / art_reference_size.x)
