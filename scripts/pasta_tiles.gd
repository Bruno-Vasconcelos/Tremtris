extends RefCounted
class_name PastaTiles

## Atlas 4x4 de tiles 16x16. Indice = mascara de vizinhos (N=1, E=2, S=4, W=8).

const ATLAS_PATH := "res://assets/pasta/pasta_atlas.png"
const TILE_PX := 16

static var _atlas: Texture2D


static func get_atlas() -> Texture2D:
	if _atlas != null:
		return _atlas

	var loaded := load(ATLAS_PATH)
	if loaded is Texture2D:
		_atlas = loaded as Texture2D
		return _atlas

	var img := Image.new()
	if img.load(ATLAS_PATH) == OK:
		_atlas = ImageTexture.create_from_image(img)
	return _atlas


static func region_for_mask(mask: int) -> Rect2:
	var m := mask & 15
	return Rect2(float((m % 4) * TILE_PX), float(int(m / 4) * TILE_PX), float(TILE_PX), float(TILE_PX))


static func neighbor_mask(cell: Vector2i, lookup: Dictionary) -> int:
	var m := 0
	if lookup.has(cell + Vector2i(0, -1)):
		m |= 1
	if lookup.has(cell + Vector2i(1, 0)):
		m |= 2
	if lookup.has(cell + Vector2i(0, 1)):
		m |= 4
	if lookup.has(cell + Vector2i(-1, 0)):
		m |= 8
	return m


static func build_lookup(cells: Array[Vector2i]) -> Dictionary:
	var lookup: Dictionary = {}
	for cell in cells:
		lookup[cell] = true
	return lookup


## Familia visual: pasta se encaixa entre si; bacon e gordura ficam separados.
static func visual_family(piece_id: String) -> String:
	if piece_id == PieceLibrary.GREASE_ID:
		return "grease"
	if PieceLibrary.is_bacon_piece(piece_id):
		return "bacon"
	return "pasta"


static func modulate_for_family(family: String, alpha: float = 1.0) -> Color:
	match family:
		"bacon":
			return Color(0.72, 0.42, 0.30, alpha)
		"grease":
			return Color(0.78, 0.68, 0.36, alpha)
		_:
			return Color(1.0, 1.0, 1.0, alpha)
