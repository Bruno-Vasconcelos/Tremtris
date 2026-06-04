extends RefCounted
class_name BoardState

var width: int
var height: int
var hidden_rows: int

var locked_cells: Array = []
var obstacle_cells: Array = []

func _init(board_width: int, board_height: int, hidden_row_count: int) -> void:
	width = board_width
	height = board_height
	hidden_rows = hidden_row_count
	reset()

func reset() -> void:
	locked_cells.clear()
	obstacle_cells.clear()

	for _y in range(height):
		var locked_row: Array[String] = []
		var obstacle_row: Array[int] = []
		for _x in range(width):
			locked_row.append("")
			obstacle_row.append(0)
		locked_cells.append(locked_row)
		obstacle_cells.append(obstacle_row)

func apply_stage_obstacles(cells: Array[Vector2i], durability: int) -> void:
	for cell in cells:
		var board_y: int = cell.y + hidden_rows
		if cell.x < 0 or cell.x >= width:
			continue
		if board_y < 0 or board_y >= height:
			continue
		obstacle_cells[board_y][cell.x] = durability

func lock_piece(piece_type: String, piece_id: String, rotation: int, pivot: Vector2i) -> void:
	for cell in get_piece_cells(piece_type, rotation, pivot):
		if cell.y >= 0 and cell.y < height:
			locked_cells[cell.y][cell.x] = piece_id

func resolve_completed_lines() -> Dictionary:
	var full_rows: Array[int] = []
	for y in range(height):
		var row_is_full := true
		for x in range(width):
			if locked_cells[y][x] == "" and obstacle_cells[y][x] == 0:
				row_is_full = false
				break
		if row_is_full:
			full_rows.append(y)

	if full_rows.is_empty():
		return {"count": 0, "cleared_rows": []}

	var cleared_snapshot: Array[int] = full_rows.duplicate()

	var rows_to_remove: Array[int] = []
	for y in full_rows:
		var has_obstacle := false
		for x in range(width):
			if obstacle_cells[y][x] > 0:
				has_obstacle = true
				obstacle_cells[y][x] -= 1
			locked_cells[y][x] = ""
		if not has_obstacle:
			rows_to_remove.append(y)

	if not rows_to_remove.is_empty():
		collapse_rows(rows_to_remove)

	return {"count": full_rows.size(), "cleared_rows": cleared_snapshot}

func collapse_rows(rows_to_remove: Array[int]) -> void:
	var remaining_locked: Array = []
	var remaining_obstacles: Array = []

	for y in range(height):
		if rows_to_remove.has(y):
			continue
		remaining_locked.append(locked_cells[y].duplicate())
		remaining_obstacles.append(obstacle_cells[y].duplicate())

	while remaining_locked.size() < height:
		var locked_row: Array[String] = []
		var obstacle_row: Array[int] = []
		for _x in range(width):
			locked_row.append("")
			obstacle_row.append(0)
		remaining_locked.push_front(locked_row)
		remaining_obstacles.push_front(obstacle_row)

	locked_cells = remaining_locked
	obstacle_cells = remaining_obstacles

func is_valid_piece_position(piece_type: String, rotation: int, pivot: Vector2i) -> bool:
	for cell in get_piece_cells(piece_type, rotation, pivot):
		if cell.x < 0 or cell.x >= width:
			return false
		if cell.y >= height:
			return false
		if cell.y >= 0 and is_occupied(cell):
			return false
	return true

func get_piece_cells(piece_type: String, rotation: int, pivot: Vector2i) -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	for offset in PieceLibrary.get_cells(piece_type, rotation):
		cells.append(pivot + offset)
	return cells

func get_locked_cell_type(x: int, y: int) -> String:
	var cell_type: String = locked_cells[y][x]
	return cell_type

func get_obstacle_durability(x: int, y: int) -> int:
	var durability: int = obstacle_cells[y][x]
	return durability

func count_remaining_obstacles() -> int:
	var remaining := 0
	for y in range(height):
		for x in range(width):
			if obstacle_cells[y][x] > 0:
				remaining += 1
	return remaining


func damage_highest_durability_obstacle() -> bool:
	var best_y := -1
	var best_x := width
	var best_durability := 0

	for y in range(height):
		for x in range(width):
			var durability: int = obstacle_cells[y][x]
			if durability <= 0:
				continue
			var take := false
			if durability > best_durability:
				take = true
			elif durability == best_durability:
				if y > best_y:
					take = true
				elif y == best_y and x < best_x:
					take = true
			if take:
				best_durability = durability
				best_y = y
				best_x = x

	if best_durability <= 0:
		return false

	obstacle_cells[best_y][best_x] -= 1
	return true


func is_occupied(cell: Vector2i) -> bool:
	return locked_cells[cell.y][cell.x] != "" or obstacle_cells[cell.y][cell.x] > 0
