extends RefCounted
class_name StageLibrary

const OBSTACLE_COLORS := {
	3: Color8(196, 92, 92),
	2: Color8(156, 124, 124),
	1: Color8(112, 120, 128),
}

const STAGES := [
	{
		"goal": 600,
		"obstacle_durability": 0,
		"obstacles": [],
	},
	{
		"goal": 900,
		"obstacle_durability": 0,
		"obstacles": [],
	},
	{
		"goal": 1300,
		"obstacle_durability": 1,
		"obstacles": [
			Vector2i(4, 17), Vector2i(5, 17),
			Vector2i(4, 18), Vector2i(5, 18),
		],
	},
	{
		"goal": 1700,
		"obstacle_durability": 2,
		"obstacles": [
			Vector2i(3, 16), Vector2i(6, 16),
			Vector2i(3, 17), Vector2i(6, 17),
			Vector2i(4, 18), Vector2i(5, 18),
		],
	},
	{
		"goal": 2200,
		"obstacle_durability": 3,
		"obstacles": [
			Vector2i(3, 15), Vector2i(6, 15),
			Vector2i(3, 16), Vector2i(6, 16),
			Vector2i(4, 17), Vector2i(5, 17),
			Vector2i(4, 18), Vector2i(5, 18),
		],
	},
]

static func count() -> int:
	return STAGES.size()

static func get_goal(stage_index: int) -> int:
	var goal: int = STAGES[stage_index]["goal"]
	return goal

static func get_obstacles(stage_index: int) -> Array[Vector2i]:
	var typed_cells: Array[Vector2i] = []
	for obstacle_cell in STAGES[stage_index]["obstacles"]:
		typed_cells.append(obstacle_cell as Vector2i)
	return typed_cells

static func stage_uses_obstacles(stage_index: int) -> bool:
	return not get_obstacles(stage_index).is_empty()

static func get_obstacle_durability(stage_index: int) -> int:
	var durability: int = STAGES[stage_index]["obstacle_durability"]
	return durability

static func get_obstacle_color(durability: int) -> Color:
	var color: Color = OBSTACLE_COLORS.get(durability, OBSTACLE_COLORS[1])
	return color
