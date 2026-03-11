extends Node2D

const BOARD_WIDTH := 10
const BOARD_VISIBLE_HEIGHT := 20
const HIDDEN_ROWS := 2
const BOARD_HEIGHT := BOARD_VISIBLE_HEIGHT + HIDDEN_ROWS

const CELL_SIZE := 28
const BOARD_ORIGIN := Vector2i(220, 50)
const SIDE_PANEL_X := BOARD_ORIGIN.x + BOARD_WIDTH * CELL_SIZE + 40

const FALL_INTERVAL := 0.65
const SOFT_DROP_INTERVAL := 0.05
const LOCK_DELAY := 0.45

const SCORE_BY_LINES := {
	1: 100,
	2: 300,
	3: 500,
	4: 800,
}

const WALL_KICKS: Array[Vector2i] = [
	Vector2i(0, 0),
	Vector2i(-1, 0),
	Vector2i(1, 0),
	Vector2i(-2, 0),
	Vector2i(2, 0),
	Vector2i(0, -1),
]

var rng := RandomNumberGenerator.new()

var board: Array = []
var bag: Array[String] = []
var next_queue: Array[String] = []

var current_type := ""
var current_rotation := 0
var current_pivot := Vector2i.ZERO

var hold_type := ""
var can_hold := true

var score := 0
var lines_cleared := 0
var game_over := false

var fall_timer := 0.0
var lock_timer := 0.0

func _ready() -> void:
	rng.randomize()
	start_new_game()

func _process(delta: float) -> void:
	if game_over:
		queue_redraw()
		return

	var step_interval := FALL_INTERVAL
	if Input.is_action_pressed("ui_down"):
		step_interval = SOFT_DROP_INTERVAL

	fall_timer += delta
	while fall_timer >= step_interval:
		fall_timer -= step_interval
		step_down_or_lock(step_interval)

	queue_redraw()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_R:
			start_new_game()
			return

	if game_over:
		return

	if event.is_action_pressed("ui_left"):
		try_move(Vector2i.LEFT)
	elif event.is_action_pressed("ui_right"):
		try_move(Vector2i.RIGHT)
	elif event.is_action_pressed("ui_up"):
		try_rotate(1)
	elif event.is_action_pressed("ui_accept"):
		hard_drop()
	elif event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_Z:
			try_rotate(-1)
		elif event.keycode == KEY_C:
			hold_current_piece()

func start_new_game() -> void:
	board.clear()
	for _y in range(BOARD_HEIGHT):
		var row: Array = []
		for _x in range(BOARD_WIDTH):
			row.append("")
		board.append(row)

	bag.clear()
	next_queue.clear()
	hold_type = ""
	can_hold = true

	score = 0
	lines_cleared = 0
	game_over = false
	fall_timer = 0.0
	lock_timer = 0.0

	fill_next_queue()
	spawn_next_piece(true)
	queue_redraw()

func fill_next_queue() -> void:
	while next_queue.size() < 5:
		if bag.is_empty():
			bag = PieceLibrary.TYPES.duplicate()
			bag.shuffle()
		next_queue.append(bag.pop_back())

func spawn_next_piece(allow_hold: bool) -> void:
	fill_next_queue()
	current_type = next_queue.pop_front()
	current_rotation = 0
	current_pivot = Vector2i(BOARD_WIDTH / 2, HIDDEN_ROWS)
	can_hold = allow_hold

	if not is_valid_position(current_type, current_rotation, current_pivot):
		game_over = true

func step_down_or_lock(elapsed: float) -> void:
	if try_move(Vector2i.DOWN):
		lock_timer = 0.0
		return

	lock_timer += elapsed
	if lock_timer >= LOCK_DELAY:
		lock_current_piece()
		lock_timer = 0.0

func try_move(delta: Vector2i) -> bool:
	var target_pivot := current_pivot + delta
	if is_valid_position(current_type, current_rotation, target_pivot):
		current_pivot = target_pivot
		return true
	return false

func try_rotate(direction: int) -> void:
	var target_rotation := posmod(current_rotation + direction, 4)
	for kick in WALL_KICKS:
		var target_pivot := current_pivot + kick
		if is_valid_position(current_type, target_rotation, target_pivot):
			current_rotation = target_rotation
			current_pivot = target_pivot
			return

func hard_drop() -> void:
	while try_move(Vector2i.DOWN):
		pass
	lock_current_piece()

func hold_current_piece() -> void:
	if not can_hold:
		return

	can_hold = false
	if hold_type == "":
		hold_type = current_type
		spawn_next_piece(false)
		return

	var swapped := hold_type
	hold_type = current_type
	current_type = swapped
	current_rotation = 0
	current_pivot = Vector2i(BOARD_WIDTH / 2, HIDDEN_ROWS)
	if not is_valid_position(current_type, current_rotation, current_pivot):
		game_over = true

func lock_current_piece() -> void:
	for cell in get_piece_cells(current_type, current_rotation, current_pivot):
		if cell.y >= 0 and cell.y < BOARD_HEIGHT:
			board[cell.y][cell.x] = current_type

	clear_completed_lines()
	spawn_next_piece(true)

func clear_completed_lines() -> void:
	var kept_rows: Array = []
	var removed_count := 0

	for row in board:
		if row.all(func(cell: String): return cell != ""):
			removed_count += 1
		else:
			kept_rows.append(row)

	while kept_rows.size() < BOARD_HEIGHT:
		var new_row: Array = []
		for _x in range(BOARD_WIDTH):
			new_row.append("")
		kept_rows.push_front(new_row)

	board = kept_rows

	if removed_count > 0:
		lines_cleared += removed_count
		score += SCORE_BY_LINES.get(removed_count, removed_count * 100)

func is_valid_position(piece_type: String, rotation: int, pivot: Vector2i) -> bool:
	for cell in get_piece_cells(piece_type, rotation, pivot):
		if cell.x < 0 or cell.x >= BOARD_WIDTH:
			return false
		if cell.y >= BOARD_HEIGHT:
			return false
		if cell.y >= 0 and board[cell.y][cell.x] != "":
			return false
	return true

func get_piece_cells(piece_type: String, rotation: int, pivot: Vector2i) -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	for offset in PieceLibrary.get_cells(piece_type, rotation):
		cells.append(pivot + offset)
	return cells

func get_ghost_pivot() -> Vector2i:
	var ghost := current_pivot
	while is_valid_position(current_type, current_rotation, ghost + Vector2i.DOWN):
		ghost += Vector2i.DOWN
	return ghost

func _draw() -> void:
	draw_board_background()
	draw_locked_cells()
	if not game_over:
		draw_piece(get_piece_cells(current_type, current_rotation, get_ghost_pivot()), PieceLibrary.get_color(current_type).darkened(0.55), true)
		draw_piece(get_piece_cells(current_type, current_rotation, current_pivot), PieceLibrary.get_color(current_type), false)
	draw_grid_lines()
	draw_side_panel()
	if game_over:
		draw_game_over_overlay()

func draw_board_background() -> void:
	var board_size := Vector2(BOARD_WIDTH * CELL_SIZE, BOARD_VISIBLE_HEIGHT * CELL_SIZE)
	draw_rect(Rect2(BOARD_ORIGIN, board_size), Color8(16, 22, 30), true)
	draw_rect(Rect2(BOARD_ORIGIN, board_size), Color8(70, 80, 95), false, 2.0)

func draw_locked_cells() -> void:
	for y in range(HIDDEN_ROWS, BOARD_HEIGHT):
		for x in range(BOARD_WIDTH):
			var cell_type: String = board[y][x]
			if cell_type == "":
				continue
			var draw_pos := board_to_screen(Vector2i(x, y))
			draw_block(draw_pos, PieceLibrary.get_color(cell_type), false)

func draw_piece(cells: Array[Vector2i], color: Color, is_ghost: bool) -> void:
	for cell in cells:
		if cell.y < HIDDEN_ROWS:
			continue
		if cell.y >= BOARD_HEIGHT:
			continue
		var draw_pos := board_to_screen(cell)
		draw_block(draw_pos, color, is_ghost)

func draw_block(screen_pos: Vector2i, color: Color, is_ghost: bool) -> void:
	var rect := Rect2(Vector2(screen_pos), Vector2(CELL_SIZE, CELL_SIZE))
	if is_ghost:
		draw_rect(rect, color, false, 2.0)
		return

	draw_rect(rect.grow(-1), color, true)
	draw_rect(rect.grow(-1), color.lightened(0.25), false, 2.0)

func draw_grid_lines() -> void:
	for x in range(BOARD_WIDTH + 1):
		var start := BOARD_ORIGIN + Vector2i(x * CELL_SIZE, 0)
		var finish := start + Vector2i(0, BOARD_VISIBLE_HEIGHT * CELL_SIZE)
		draw_line(Vector2(start), Vector2(finish), Color8(45, 55, 70), 1.0)

	for y in range(BOARD_VISIBLE_HEIGHT + 1):
		var start := BOARD_ORIGIN + Vector2i(0, y * CELL_SIZE)
		var finish := start + Vector2i(BOARD_WIDTH * CELL_SIZE, 0)
		draw_line(Vector2(start), Vector2(finish), Color8(45, 55, 70), 1.0)

func draw_side_panel() -> void:
	var font := ThemeDB.fallback_font
	var title_color := Color8(230, 235, 245)
	var value_color := Color8(180, 205, 225)

	draw_string(font, Vector2(SIDE_PANEL_X, 90), "TETRIS", HORIZONTAL_ALIGNMENT_LEFT, -1, 32, title_color)
	draw_string(font, Vector2(SIDE_PANEL_X, 130), "Linhas: %d" % lines_cleared, HORIZONTAL_ALIGNMENT_LEFT, -1, 20, value_color)
	draw_string(font, Vector2(SIDE_PANEL_X, 155), "Pontos: %d" % score, HORIZONTAL_ALIGNMENT_LEFT, -1, 20, value_color)

	draw_string(font, Vector2(SIDE_PANEL_X, 210), "Grip (Hold)", HORIZONTAL_ALIGNMENT_LEFT, -1, 20, title_color)
	draw_preview_box(Vector2i(SIDE_PANEL_X, 220), hold_type)

	draw_string(font, Vector2(SIDE_PANEL_X, 340), "Proximas", HORIZONTAL_ALIGNMENT_LEFT, -1, 20, title_color)
	for i in range(min(3, next_queue.size())):
		draw_preview_box(Vector2i(SIDE_PANEL_X, 350 + i * 90), next_queue[i])

	draw_string(font, Vector2(SIDE_PANEL_X, 640), "Controles", HORIZONTAL_ALIGNMENT_LEFT, -1, 18, title_color)
	draw_string(font, Vector2(SIDE_PANEL_X, 665), "Setas: mover/rotacionar", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, value_color)
	draw_string(font, Vector2(SIDE_PANEL_X, 685), "Z: rotacao anti-horaria", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, value_color)
	draw_string(font, Vector2(SIDE_PANEL_X, 705), "Espaco/Enter: hard drop", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, value_color)
	draw_string(font, Vector2(SIDE_PANEL_X, 725), "C: grip (hold)", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, value_color)
	draw_string(font, Vector2(SIDE_PANEL_X, 745), "R: reiniciar", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, value_color)

func draw_preview_box(origin: Vector2i, piece_type: String) -> void:
	var size := Vector2i(120, 80)
	draw_rect(Rect2(origin, size), Color8(22, 28, 38), true)
	draw_rect(Rect2(origin, size), Color8(65, 75, 90), false, 1.5)

	if piece_type == "":
		return

	var base := Vector2(origin + Vector2i(42, 34))
	for cell in PieceLibrary.get_cells(piece_type, 0):
		var pos := base + Vector2(cell) * 16.0
		draw_rect(Rect2(pos, Vector2(14, 14)), PieceLibrary.get_color(piece_type), true)
		draw_rect(Rect2(pos, Vector2(14, 14)), PieceLibrary.get_color(piece_type).lightened(0.2), false, 1.0)

func draw_game_over_overlay() -> void:
	var overlay := Rect2(BOARD_ORIGIN, Vector2(BOARD_WIDTH * CELL_SIZE, BOARD_VISIBLE_HEIGHT * CELL_SIZE))
	draw_rect(overlay, Color(0, 0, 0, 0.6), true)
	var font := ThemeDB.fallback_font
	draw_string(font, Vector2(BOARD_ORIGIN.x + 35, BOARD_ORIGIN.y + 250), "GAME OVER", HORIZONTAL_ALIGNMENT_LEFT, -1, 36, Color8(255, 220, 220))
	draw_string(font, Vector2(BOARD_ORIGIN.x + 32, BOARD_ORIGIN.y + 285), "Pressione R para reiniciar", HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color8(230, 230, 230))

func board_to_screen(cell: Vector2i) -> Vector2i:
	var visible_y := cell.y - HIDDEN_ROWS
	return BOARD_ORIGIN + Vector2i(cell.x * CELL_SIZE, visible_y * CELL_SIZE)
