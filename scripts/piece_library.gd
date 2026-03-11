extends RefCounted
class_name PieceLibrary

const TYPES: Array[String] = [
	"Six", "Seven"
	#"I", "O", "T", "S", "Z", "J", "L", 
	#"Big", "Small",
	 ]
 
const COLORS := {
	"I": Color8(0, 240, 240),
	"O": Color8(240, 240, 0),
	"T": Color8(160, 0, 240),
	"S": Color8(0, 240, 0),
	"Z": Color8(240, 0, 0),
	 "J": Color8(0, 80, 240),
	"L": Color8(240, 160, 0),
	"Big": Color8(20, 170, 0),
	"Small": Color8(20, 170, 0),
	"Six": Color8(0, 0, 150),
	"Seven": Color8(150,0,0),
}

const ROTATIONS := {
	"I": [
		[Vector2i(-1, 0), Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, 0)],
		[Vector2i(1, -1), Vector2i(1, 0), Vector2i(1, 1), Vector2i(1, 2)],
		[Vector2i(-1, 1), Vector2i(0, 1), Vector2i(1, 1), Vector2i(2, 1)],
		[Vector2i(0, -1), Vector2i(0, 0), Vector2i(0, 1), Vector2i(0, 2)],
	],
	"O": [
		[Vector2i(0, 0), Vector2i(1, 0), Vector2i(0, 1), Vector2i(1, 1)],
		[Vector2i(0, 0), Vector2i(1, 0), Vector2i(0, 1), Vector2i(1, 1)],
		[Vector2i(0, 0), Vector2i(1, 0), Vector2i(0, 1), Vector2i(1, 1)],
		[Vector2i(0, 0), Vector2i(1, 0), Vector2i(0, 1), Vector2i(1, 1)],
	],
	"T": [
		[Vector2i(-1, 0), Vector2i(0, 0), Vector2i(1, 0), Vector2i(0, 1)],
		[Vector2i(0, -1), Vector2i(0, 0), Vector2i(1, 0), Vector2i(0, 1)],
		[Vector2i(-1, 0), Vector2i(0, 0), Vector2i(1, 0), Vector2i(0, -1)],
		[Vector2i(0, -1), Vector2i(-1, 0), Vector2i(0, 0), Vector2i(0, 1)],
	],
	"S": [
		[Vector2i(0, 0), Vector2i(1, 0), Vector2i(-1, 1), Vector2i(0, 1)],
		[Vector2i(0, -1), Vector2i(0, 0), Vector2i(1, 0), Vector2i(1, 1)],
		[Vector2i(0, 0), Vector2i(1, 0), Vector2i(-1, 1), Vector2i(0, 1)],
		[Vector2i(0, -1), Vector2i(0, 0), Vector2i(1, 0), Vector2i(1, 1)],
	],
	"Z": [
		[Vector2i(-1, 0), Vector2i(0, 0), Vector2i(0, 1), Vector2i(1, 1)],
		[Vector2i(1, -1), Vector2i(0, 0), Vector2i(1, 0), Vector2i(0, 1)],
		[Vector2i(-1, 0), Vector2i(0, 0), Vector2i(0, 1), Vector2i(1, 1)],
		[Vector2i(1, -1), Vector2i(0, 0), Vector2i(1, 0), Vector2i(0, 1)],
	],
	"J": [
		[Vector2i(-1, 0), Vector2i(0, 0), Vector2i(1, 0), Vector2i(-1, 1)],
		[Vector2i(0, -1), Vector2i(0, 0), Vector2i(0, 1), Vector2i(1, 1)],
		[Vector2i(-1, 0), Vector2i(0, 0), Vector2i(1, 0), Vector2i(1, -1)],
		[Vector2i(-1, -1), Vector2i(0, -1), Vector2i(0, 0), Vector2i(0, 1)],
	],
	"L": [
		[Vector2i(-1, 0), Vector2i(0, 0), Vector2i(1, 0), Vector2i(1, 1)],
		[Vector2i(0, -1), Vector2i(0, 0), Vector2i(0, 1), Vector2i(1, -1)],
		[Vector2i(-1, 0), Vector2i(0, 0), Vector2i(1, 0), Vector2i(-1, -1)],
		[Vector2i(-1, 1), Vector2i(0, -1), Vector2i(0, 0), Vector2i(0, 1)],
	],
	"Big": [
		[Vector2i(0, 0), Vector2i(1, 0),Vector2i(2, 0),
		Vector2i(0, 1), Vector2i(1, 1),  Vector2i(2, 1),
		Vector2i(0, 2), Vector2i(1, 2),  Vector2i(2, 2)],
		[Vector2i(0, 0), Vector2i(1, 0),Vector2i(2, 0),
		Vector2i(0, 1), Vector2i(1, 1),  Vector2i(2, 1),
		Vector2i(0, 2), Vector2i(1, 2),  Vector2i(2, 2)],
		[Vector2i(0, 0), Vector2i(1, 0),Vector2i(2, 0),
		Vector2i(0, 1), Vector2i(1, 1),  Vector2i(2, 1),
		Vector2i(0, 2), Vector2i(1, 2),  Vector2i(2, 2)],
		[Vector2i(0, 0), Vector2i(1, 0),Vector2i(2, 0),
		Vector2i(0, 1), Vector2i(1, 1),  Vector2i(2, 1),
		Vector2i(0, 2), Vector2i(1, 2),  Vector2i(2, 2)],
	],
	"Small": [
		[Vector2i(0, 0)],
		[Vector2i(0, 0)],
		[Vector2i(0, 0)],
		[Vector2i(0, 0)],
	],
	"Six": [
		[
			Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, 0),
			Vector2i(0, 1),
			Vector2i(0, 2), Vector2i(1, 2), Vector2i(2, 2),
			Vector2i(0, 3), 				Vector2i(2, 3),
			Vector2i(0, 4), Vector2i(1, 4), Vector2i(2, 4),
		],
		[
			Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, 0), Vector2i(3, 0), Vector2i(4, 0),
			Vector2i(0, 1), Vector2i(2, 1), Vector2i(4, 1),
			Vector2i(0, 2), Vector2i(1, 2), Vector2i(2, 2), Vector2i(4, 2),
		],
		[
			Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, 0),
			Vector2i(0, 1), Vector2i(2, 1),
			Vector2i(0, 2), Vector2i(1, 2), Vector2i(2, 2),
			Vector2i(2, 3),
			Vector2i(0, 4), Vector2i(1, 4), Vector2i(2, 4),
		],
		[
			Vector2i(0, 0), Vector2i(2, 0), Vector2i(3, 0), Vector2i(4, 0),
			Vector2i(0, 1), Vector2i(2, 1), Vector2i(4, 1),
			Vector2i(0, 2), Vector2i(1, 2), Vector2i(2, 2), Vector2i(3, 2), Vector2i(4, 2),
		],
	],
	"Seven": [
		[
			Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, 0),
											Vector2i(2, 1),
											Vector2i(2, 2),
											Vector2i(2, 3),
											Vector2i(2, 4),
		],
		[
			Vector2i(0, 0), Vector2i(0, 1), Vector2i(0, 2),
			Vector2i(0, 3), Vector2i(1, 3), Vector2i(2, 3), Vector2i(3, 3),
		],
		[
			Vector2i(0, 0),
			Vector2i(0, 1),
			Vector2i(0, 2),
			Vector2i(0, 3),
			Vector2i(0, 4), Vector2i(1, 4), Vector2i(2, 4),
		],
		[
			Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, 0), Vector2i(3, 0),
			Vector2i(3, 1),
			Vector2i(3, 2),
			Vector2i(3, 3),
		],
	]
}

static func get_cells(piece_type: String, rotation: int) -> Array[Vector2i]:
	var turns := posmod(rotation, 4)
	var rotation_cells: Array = ROTATIONS[piece_type][turns]
	var typed_cells: Array[Vector2i] = []
	for cell in rotation_cells:
		typed_cells.append(cell as Vector2i)
	return typed_cells

static func get_color(piece_type: String) -> Color:
	return COLORS[piece_type]
