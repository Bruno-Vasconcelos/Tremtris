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
var board_state: BoardState = BoardState.new(BOARD_WIDTH, BOARD_HEIGHT, HIDDEN_ROWS)
var bag: Array[String] = []
var next_queue: Array[String] = []

var current_type := ""
var current_rotation := 0
var current_pivot := Vector2i.ZERO

var hold_type := ""
var can_hold := true

var score := 0
var phase_score := 0
var lines_cleared := 0
var current_stage := 0
var game_over := false
var game_won := false

var fall_timer := 0.0
var lock_timer := 0.0

# Game lifecycle
func _ready() -> void:
	rng.randomize()
	start_new_game()

func _process(delta: float) -> void:
	if game_over or game_won:
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

	if game_over or game_won:
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
	board_state.reset()
	bag.clear()
	next_queue.clear()
	hold_type = ""
	can_hold = true

	score = 0
	phase_score = 0
	lines_cleared = 0
	current_stage = 0
	game_over = false
	game_won = false
	fall_timer = 0.0
	lock_timer = 0.0

	start_stage(current_stage)
	queue_redraw()

func start_stage(stage_index: int) -> void:
	board_state.reset()
	current_stage = stage_index
	phase_score = 0
	game_over = false
	game_won = false
	bag.clear()
	next_queue.clear()
	hold_type = ""
	can_hold = true
	fall_timer = 0.0
	lock_timer = 0.0

	board_state.apply_stage_obstacles(
		StageLibrary.get_obstacles(stage_index),
		StageLibrary.get_obstacle_durability(stage_index)
	)
	fill_next_queue()
	spawn_next_piece(true)

# Piece flow
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

	if not board_state.is_valid_piece_position(current_type, current_rotation, current_pivot):
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
	if board_state.is_valid_piece_position(current_type, current_rotation, target_pivot):
		current_pivot = target_pivot
		return true
	return false

func try_rotate(direction: int) -> void:
	var target_rotation := posmod(current_rotation + direction, 4)
	for kick in WALL_KICKS:
		var target_pivot := current_pivot + kick
		if board_state.is_valid_piece_position(current_type, target_rotation, target_pivot):
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
	if not board_state.is_valid_piece_position(current_type, current_rotation, current_pivot):
		game_over = true

func lock_current_piece() -> void:
	board_state.lock_piece(current_type, current_rotation, current_pivot)
	var stage_changed := clear_completed_lines()
	if stage_changed or game_won:
		return
	spawn_next_piece(true)

func clear_completed_lines() -> bool:
	var cleared_count := board_state.resolve_completed_lines()
	if cleared_count == 0:
		return false
	lines_cleared += cleared_count

	if can_award_stage_score():
		var earned_score: int = SCORE_BY_LINES.get(cleared_count, cleared_count * 100)
		score += earned_score
		phase_score += earned_score

	if is_obstacle_stage() and has_remaining_stage_obstacles():
		return false

	if phase_score >= get_stage_goal():
		return advance_stage()

	return false

func advance_stage() -> bool:
	if current_stage >= StageLibrary.count() - 1:
		game_won = true
		return true

	start_stage(current_stage + 1)
	return true

func get_stage_goal() -> int:
	return StageLibrary.get_goal(current_stage)

func is_obstacle_stage() -> bool:
	return StageLibrary.stage_uses_obstacles(current_stage)

func has_remaining_stage_obstacles() -> bool:
	return board_state.count_remaining_obstacles() > 0

func can_award_stage_score() -> bool:
	if not is_obstacle_stage():
		return true
	return not has_remaining_stage_obstacles()

func get_piece_cells(piece_type: String, rotation: int, pivot: Vector2i) -> Array[Vector2i]:
	return board_state.get_piece_cells(piece_type, rotation, pivot)

func get_ghost_pivot() -> Vector2i:
	var ghost := current_pivot
	while board_state.is_valid_piece_position(current_type, current_rotation, ghost + Vector2i.DOWN):
		ghost += Vector2i.DOWN
	return ghost

# Rendering
func _draw() -> void:
	draw_board_background()
	draw_locked_cells()
	draw_obstacle_cells()
	if not game_over and not game_won:
		draw_piece(get_piece_cells(current_type, current_rotation, get_ghost_pivot()), PieceLibrary.get_color(current_type).darkened(0.55), true)
		draw_piece(get_piece_cells(current_type, current_rotation, current_pivot), PieceLibrary.get_color(current_type), false)
	draw_grid_lines()
	draw_side_panel()
	if game_over:
		draw_game_over_overlay()
	elif game_won:
		draw_stage_clear_overlay()

func draw_board_background() -> void:
	var board_size := Vector2(BOARD_WIDTH * CELL_SIZE, BOARD_VISIBLE_HEIGHT * CELL_SIZE)
	draw_rect(Rect2(BOARD_ORIGIN, board_size), Color8(16, 22, 30), true)
	draw_rect(Rect2(BOARD_ORIGIN, board_size), Color8(70, 80, 95), false, 2.0)

func draw_locked_cells() -> void:
	for y in range(HIDDEN_ROWS, BOARD_HEIGHT):
		for x in range(BOARD_WIDTH):
			var cell_type: String = board_state.get_locked_cell_type(x, y)
			if cell_type == "":
				continue
			var draw_pos := board_to_screen(Vector2i(x, y))
			draw_block(draw_pos, PieceLibrary.get_color(cell_type), false)

func draw_obstacle_cells() -> void:
	var font := ThemeDB.fallback_font
	for y in range(HIDDEN_ROWS, BOARD_HEIGHT):
		for x in range(BOARD_WIDTH):
			var durability: int = board_state.get_obstacle_durability(x, y)
			if durability <= 0:
				continue
			var draw_pos := board_to_screen(Vector2i(x, y))
			draw_obstacle_block(draw_pos, durability, font)

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
	var remaining_obstacles := board_state.count_remaining_obstacles()
	var phase_label := "Meta: %d / %d" % [phase_score, get_stage_goal()]
	if is_obstacle_stage() and remaining_obstacles > 0:
		phase_label = "Blocos: %d restantes" % remaining_obstacles

	draw_string(font, Vector2(SIDE_PANEL_X, 90), "TETRIS", HORIZONTAL_ALIGNMENT_LEFT, -1, 32, title_color)
	draw_string(font, Vector2(SIDE_PANEL_X, 118), "Fase %d / %d" % [current_stage + 1, StageLibrary.count()], HORIZONTAL_ALIGNMENT_LEFT, -1, 18, title_color)
	draw_string(font, Vector2(SIDE_PANEL_X, 130), "Linhas: %d" % lines_cleared, HORIZONTAL_ALIGNMENT_LEFT, -1, 20, value_color)
	draw_string(font, Vector2(SIDE_PANEL_X, 155), "Pontos: %d" % score, HORIZONTAL_ALIGNMENT_LEFT, -1, 20, value_color)
	draw_string(font, Vector2(SIDE_PANEL_X, 180), phase_label, HORIZONTAL_ALIGNMENT_LEFT, -1, 20, value_color)
	if is_obstacle_stage():
		draw_string(font, Vector2(SIDE_PANEL_X, 205), "Pontuacao libera apos limpar os blocos", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, value_color)

	draw_string(font, Vector2(SIDE_PANEL_X, 235), "Grip (Hold)", HORIZONTAL_ALIGNMENT_LEFT, -1, 20, title_color)
	draw_preview_box(Vector2i(SIDE_PANEL_X, 245), hold_type)

	draw_string(font, Vector2(SIDE_PANEL_X, 365), "Proximas", HORIZONTAL_ALIGNMENT_LEFT, -1, 20, title_color)
	for i in range(min(3, next_queue.size())):
		draw_preview_box(Vector2i(SIDE_PANEL_X, 375 + i * 90), next_queue[i])

	draw_string(font, Vector2(SIDE_PANEL_X, 640), "Controles", HORIZONTAL_ALIGNMENT_LEFT, -1, 18, title_color)
	draw_string(font, Vector2(SIDE_PANEL_X, 665), "Setas: mover/rotacionar", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, value_color)
	draw_string(font, Vector2(SIDE_PANEL_X, 685), "Z: rotacao anti-horaria", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, value_color)
	draw_string(font, Vector2(SIDE_PANEL_X, 705), "Espaco/Enter: hard drop", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, value_color)
	draw_string(font, Vector2(SIDE_PANEL_X, 725), "C: grip (hold)", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, value_color)
	draw_string(font, Vector2(SIDE_PANEL_X, 745), "Blocos de fase: 3 impactos", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, value_color)
	draw_string(font, Vector2(SIDE_PANEL_X, 765), "R: reiniciar", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, value_color)

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

func draw_stage_clear_overlay() -> void:
	var overlay := Rect2(BOARD_ORIGIN, Vector2(BOARD_WIDTH * CELL_SIZE, BOARD_VISIBLE_HEIGHT * CELL_SIZE))
	draw_rect(overlay, Color(0, 0, 0, 0.55), true)
	var font := ThemeDB.fallback_font
	draw_string(font, Vector2(BOARD_ORIGIN.x + 58, BOARD_ORIGIN.y + 240), "VOCE VENCEU", HORIZONTAL_ALIGNMENT_LEFT, -1, 32, Color8(220, 245, 220))
	draw_string(font, Vector2(BOARD_ORIGIN.x + 42, BOARD_ORIGIN.y + 275), "Fases concluidas: %d" % StageLibrary.count(), HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color8(230, 230, 230))
	draw_string(font, Vector2(BOARD_ORIGIN.x + 26, BOARD_ORIGIN.y + 302), "Pressione R para recomecar", HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color8(230, 230, 230))

func draw_obstacle_block(screen_pos: Vector2i, durability: int, font: Font) -> void:
	var color: Color = StageLibrary.get_obstacle_color(durability)
	var rect := Rect2(Vector2(screen_pos), Vector2(CELL_SIZE, CELL_SIZE))
	draw_rect(rect.grow(-1), color, true)
	draw_rect(rect.grow(-1), color.lightened(0.15), false, 2.0)
	draw_string(font, Vector2(screen_pos.x + 9, screen_pos.y + 20), str(durability), HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color8(245, 245, 245))

func board_to_screen(cell: Vector2i) -> Vector2i:
	var visible_y := cell.y - HIDDEN_ROWS
	return BOARD_ORIGIN + Vector2i(cell.x * CELL_SIZE, visible_y * CELL_SIZE)
