extends RefCounted
class_name PieceLibrary

const PASTA_COLOR := Color8(241, 205, 101)
const BACON_COLOR := Color8(132, 78, 52)
const BACON_SUFFIX := ":bacon"

## Celula de "gordura" (mecanica de linha-lixo que sobe). Nao e um tetromino.
const GREASE_ID := ":grease"
const GREASE_COLOR := Color8(126, 100, 44)

const TYPES: Array[String] = [
	"I", "O", "T", "S", "Z", "J", "L", 
	 ]
 
## Por enquanto todas as pecas usam a textura/cor de macarrao.
const COLORS := {
	"I": PASTA_COLOR,
	"O": PASTA_COLOR,
	"T": PASTA_COLOR,
	"S": PASTA_COLOR,
	"Z": PASTA_COLOR,
	"J": PASTA_COLOR,
	"L": PASTA_COLOR,
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
}

static func get_cells(piece_type: String, rotation: int) -> Array[Vector2i]:
	var turns := posmod(rotation, 4)
	var rotation_cells: Array = ROTATIONS[piece_type][turns]
	var typed_cells: Array[Vector2i] = []
	for cell in rotation_cells:
		typed_cells.append(cell as Vector2i)
	return typed_cells

static func make_piece_id(piece_type: String, is_bacon: bool = false) -> String:
	if is_bacon:
		return piece_type + BACON_SUFFIX
	return piece_type

static func get_base_type(piece_id: String) -> String:
	if piece_id.contains(":"):
		return piece_id.get_slice(":", 0)
	return piece_id

static func is_bacon_piece(piece_id: String) -> bool:
	return piece_id.ends_with(BACON_SUFFIX)

static func get_color(piece_id: String) -> Color:
	if piece_id == GREASE_ID:
		return GREASE_COLOR
	if is_bacon_piece(piece_id):
		return BACON_COLOR

	var base_type := get_base_type(piece_id)
	return COLORS.get(base_type, PASTA_COLOR)
