extends RefCounted
class_name StageLibrary

const OBSTACLE_COLORS := {
	3: Color8(196, 92, 92),
	2: Color8(156, 124, 124),
	1: Color8(112, 120, 128),
}

## Cada fase: goal (pontos, ignorado em boss variant), obstáculos, ato, tema, mecânica, boss.
const STAGES := [
	# --- Ato 1: bistrô / obstáculos ---
	{
		"goal": 520,
		"obstacle_durability": 0,
		"obstacles": [],
		"act": 0,
		"theme": "bistro",
		"mechanic": "none",
		"kind": "normal",
		"boss_mode": "",
		"boss_lines_target": 0,
		"boss_orders_target": 0,
		"gravity_mult": 1.0,
		"boss_name": "",
	},
	{
		"goal": 680,
		"obstacle_durability": 0,
		"obstacles": [],
		"act": 0,
		"theme": "bistro",
		"mechanic": "none",
		"kind": "normal",
		"boss_mode": "",
		"boss_lines_target": 0,
		"boss_orders_target": 0,
		"gravity_mult": 1.0,
		"boss_name": "",
	},
	{
		"goal": 860,
		"obstacle_durability": 1,
		"obstacles": [
			Vector2i(4, 17), Vector2i(5, 17),
			Vector2i(4, 18), Vector2i(5, 18),
		],
		"act": 0,
		"theme": "bistro",
		"mechanic": "obstacles",
		"kind": "normal",
		"boss_mode": "",
		"boss_lines_target": 0,
		"boss_orders_target": 0,
		"gravity_mult": 1.0,
		"boss_name": "",
	},
	{
		"goal": 1040,
		"obstacle_durability": 2,
		"obstacles": [
			Vector2i(3, 16), Vector2i(6, 16),
			Vector2i(3, 17), Vector2i(6, 17),
			Vector2i(4, 18), Vector2i(5, 18),
		],
		"act": 0,
		"theme": "bistro",
		"mechanic": "obstacles",
		"kind": "normal",
		"boss_mode": "",
		"boss_lines_target": 0,
		"boss_orders_target": 0,
		"gravity_mult": 1.0,
		"boss_name": "",
	},
	{
		"goal": 0,
		"obstacle_durability": 0,
		"obstacles": [],
		"act": 0,
		"theme": "bistro",
		"mechanic": "none",
		"kind": "boss",
		"boss_mode": "lines",
		"boss_lines_target": 10,
		"boss_orders_target": 0,
		"gravity_mult": 1.0,
		"boss_name": "Bruto da Grelha",
	},
	# --- Ato 2: pedidos ---
	{
		"goal": 740,
		"obstacle_durability": 0,
		"obstacles": [],
		"act": 1,
		"theme": "gourmet",
		"mechanic": "orders",
		"kind": "normal",
		"boss_mode": "",
		"boss_lines_target": 0,
		"boss_orders_target": 0,
		"gravity_mult": 1.0,
		"boss_name": "",
	},
	{
		"goal": 920,
		"obstacle_durability": 0,
		"obstacles": [],
		"act": 1,
		"theme": "gourmet",
		"mechanic": "orders",
		"kind": "normal",
		"boss_mode": "",
		"boss_lines_target": 0,
		"boss_orders_target": 0,
		"gravity_mult": 1.0,
		"boss_name": "",
	},
	{
		"goal": 1120,
		"obstacle_durability": 1,
		"obstacles": [
			Vector2i(2, 17), Vector2i(7, 17),
		],
		"act": 1,
		"theme": "gourmet",
		"mechanic": "orders",
		"kind": "normal",
		"boss_mode": "",
		"boss_lines_target": 0,
		"boss_orders_target": 0,
		"gravity_mult": 1.0,
		"boss_name": "",
	},
	{
		"goal": 1320,
		"obstacle_durability": 2,
		"obstacles": [
			Vector2i(4, 15), Vector2i(5, 15),
			Vector2i(3, 16), Vector2i(6, 16),
			Vector2i(4, 18), Vector2i(5, 18),
		],
		"act": 1,
		"theme": "gourmet",
		"mechanic": "orders",
		"kind": "normal",
		"boss_mode": "",
		"boss_lines_target": 0,
		"boss_orders_target": 0,
		"gravity_mult": 1.0,
		"boss_name": "",
	},
	{
		"goal": 0,
		"obstacle_durability": 0,
		"obstacles": [],
		"act": 1,
		"theme": "gourmet",
		"mechanic": "orders",
		"kind": "boss",
		"boss_mode": "orders",
		"boss_lines_target": 0,
		"boss_orders_target": 5,
		"gravity_mult": 1.0,
		"boss_name": "Crítico de Salão",
	},
	# --- Ato 3: pressão ---
	{
		"goal": 820,
		"obstacle_durability": 1,
		"obstacles": [
			Vector2i(1, 18), Vector2i(8, 18),
			Vector2i(4, 17), Vector2i(5, 17),
		],
		"act": 2,
		"theme": "banquet",
		"mechanic": "pressure",
		"kind": "normal",
		"boss_mode": "",
		"boss_lines_target": 0,
		"boss_orders_target": 0,
		"gravity_mult": 0.88,
		"boss_name": "",
	},
	{
		"goal": 1020,
		"obstacle_durability": 2,
		"obstacles": [
			Vector2i(2, 16), Vector2i(7, 16),
			Vector2i(3, 17), Vector2i(6, 17),
			Vector2i(4, 18), Vector2i(5, 18),
		],
		"act": 2,
		"theme": "banquet",
		"mechanic": "pressure",
		"kind": "normal",
		"boss_mode": "",
		"boss_lines_target": 0,
		"boss_orders_target": 0,
		"gravity_mult": 0.78,
		"boss_name": "",
	},
	{
		"goal": 1220,
		"obstacle_durability": 2,
		"obstacles": [
			Vector2i(1, 15), Vector2i(8, 15),
			Vector2i(2, 17), Vector2i(7, 17),
			Vector2i(4, 18), Vector2i(5, 18),
		],
		"act": 2,
		"theme": "banquet",
		"mechanic": "pressure",
		"kind": "normal",
		"boss_mode": "",
		"boss_lines_target": 0,
		"boss_orders_target": 0,
		"gravity_mult": 0.68,
		"boss_name": "",
	},
	{
		"goal": 1420,
		"obstacle_durability": 2,
		"obstacles": [
			Vector2i(0, 16), Vector2i(9, 16),
			Vector2i(2, 17), Vector2i(7, 17),
			Vector2i(4, 16), Vector2i(5, 16),
			Vector2i(3, 18), Vector2i(6, 18),
		],
		"act": 2,
		"theme": "banquet",
		"mechanic": "pressure",
		"kind": "normal",
		"boss_mode": "",
		"boss_lines_target": 0,
		"boss_orders_target": 0,
		"gravity_mult": 0.58,
		"boss_name": "",
	},
	{
		"goal": 0,
		"obstacle_durability": 1,
		"obstacles": [
			Vector2i(4, 18), Vector2i(5, 18),
		],
		"act": 2,
		"theme": "banquet",
		"mechanic": "pressure",
		"kind": "boss",
		"boss_mode": "lines",
		"boss_lines_target": 16,
		"boss_orders_target": 0,
		"gravity_mult": 0.48,
		"boss_name": "Estrela Michelin",
	},
]


static func count() -> int:
	return STAGES.size()


static func _row(stage_index: int) -> Dictionary:
	return STAGES[clampi(stage_index, 0, STAGES.size() - 1)]


static func get_goal(stage_index: int) -> int:
	return int(_row(stage_index).get("goal", 0))


static func get_obstacles(stage_index: int) -> Array[Vector2i]:
	var raw: Array = _row(stage_index).get("obstacles", []) as Array
	var typed_cells: Array[Vector2i] = []
	for obstacle_cell in raw:
		typed_cells.append(obstacle_cell as Vector2i)
	return typed_cells


static func stage_uses_obstacles(stage_index: int) -> bool:
	return not get_obstacles(stage_index).is_empty()


static func get_obstacle_durability(stage_index: int) -> int:
	return int(_row(stage_index).get("obstacle_durability", 0))


static func get_obstacle_color(durability: int) -> Color:
	var color: Color = OBSTACLE_COLORS.get(durability, OBSTACLE_COLORS[1])
	return color


static func get_act_index(stage_index: int) -> int:
	return int(_row(stage_index).get("act", 0))


static func get_theme_id(stage_index: int) -> String:
	return str(_row(stage_index).get("theme", "bistro"))


static func get_mechanic_id(stage_index: int) -> String:
	return str(_row(stage_index).get("mechanic", "none"))


static func get_kind(stage_index: int) -> String:
	return str(_row(stage_index).get("kind", "normal"))


static func is_boss_stage(stage_index: int) -> bool:
	return get_kind(stage_index) == "boss"


static func get_boss_mode(stage_index: int) -> String:
	return str(_row(stage_index).get("boss_mode", ""))


static func is_boss_variant_stage(stage_index: int) -> bool:
	return is_boss_stage(stage_index) and get_boss_mode(stage_index) != ""


static func get_boss_lines_target(stage_index: int) -> int:
	return int(_row(stage_index).get("boss_lines_target", 0))


static func get_boss_orders_target(stage_index: int) -> int:
	return int(_row(stage_index).get("boss_orders_target", 0))


static func get_gravity_mult(stage_index: int) -> float:
	return float(_row(stage_index).get("gravity_mult", 1.0))


static func get_boss_display_name(stage_index: int) -> String:
	return str(_row(stage_index).get("boss_name", ""))


static func uses_order_line(stage_index: int) -> bool:
	return get_mechanic_id(stage_index) == "orders" or get_boss_mode(stage_index) == "orders"


static func get_stage_label(stage_index: int) -> String:
	return "Fase %d / %d" % [stage_index + 1, STAGES.size()]
