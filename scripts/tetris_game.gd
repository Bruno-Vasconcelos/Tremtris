extends Node2D

## Referências explícitas (evita depender só de `class_name` no escopo do parser).
const CAMPAIGN_SAVE_SCRIPT := preload("res://scripts/campaign_save.gd")
const CAMPAIGN_THEME_SCRIPT := preload("res://scripts/campaign_theme.gd")
const PASTA_TILES_SCRIPT := preload("res://scripts/pasta_tiles.gd")

const MAIN_MENU_SCENE := "res://scenes/main_menu.tscn"

const BOARD_WIDTH := 10
const BOARD_VISIBLE_HEIGHT := 20
const HIDDEN_ROWS := 2
const BOARD_HEIGHT := BOARD_VISIBLE_HEIGHT + HIDDEN_ROWS
const BOARD_BG_COLOR := Color8(10, 16, 24)
const CELL_SIZE := 28
const LAYOUT_GAP := 44
const SIDE_PANEL_WIDTH := 220
const TOP_PANEL_HEIGHT := 88

const FALL_INTERVAL := 0.65
const SOFT_DROP_INTERVAL := 0.05
const LOCK_DELAY := 0.45
const DAS_DELAY := 0.16
const ARR_INTERVAL := 0.045
const BACON_PIECE_CHANCE := 0.10
const SETTLE_MAX_SQUASH := 0.15
const SETTLE_MAX_GROW := 0.22
const ACTIVE_MASS_OVERDRAW := 0.32
const ACTIVE_EDGE_RADIUS := CELL_SIZE * 0.12
const ACTIVE_EDGE_WIDTH := CELL_SIZE * 0.22
const ACTIVE_TOP_RADIUS := CELL_SIZE * 0.18
const ACTIVE_TOP_WIDTH := CELL_SIZE * 0.30
const ACTIVE_EDGE_INSET := CELL_SIZE * 0.18
const ACTIVE_INNER_RADIUS := CELL_SIZE * 0.18

const CLEANER_COOLDOWN_SEC := 60.0
const CLEANER_LINE_REDUCTION_SEC := 5.0

const FREEZER_DURATION_SEC := 6.0
const FREEZER_COOLDOWN_SEC := 45.0
const FREEZER_SLOWDOWN := 4.0

const ORDER_MAX_HEIGHT_RATIO := 0.5
const ORDER_FIRST_HEIGHT_RATIO := 0.35
const ORDER_BOSS_LAST_HEIGHT_RATIO := 0.8
const ORDER_HEIGHT_VARIANCE := 2

const SCORE_BY_LINES := {
	1: 100,
	2: 300,
	3: 500,
	4: 800,
}

const WALL_KICKS_JLSTZ := {
	Vector2i(0, 1): [Vector2i(0, 0), Vector2i(-1, 0), Vector2i(-1, 1), Vector2i(0, -2), Vector2i(-1, -2)],
	Vector2i(1, 0): [Vector2i(0, 0), Vector2i(1, 0), Vector2i(1, -1), Vector2i(0, 2), Vector2i(1, 2)],
	Vector2i(1, 2): [Vector2i(0, 0), Vector2i(1, 0), Vector2i(1, -1), Vector2i(0, 2), Vector2i(1, 2)],
	Vector2i(2, 1): [Vector2i(0, 0), Vector2i(-1, 0), Vector2i(-1, 1), Vector2i(0, -2), Vector2i(-1, -2)],
	Vector2i(2, 3): [Vector2i(0, 0), Vector2i(1, 0), Vector2i(1, 1), Vector2i(0, -2), Vector2i(1, -2)],
	Vector2i(3, 2): [Vector2i(0, 0), Vector2i(-1, 0), Vector2i(-1, -1), Vector2i(0, 2), Vector2i(-1, 2)],
	Vector2i(3, 0): [Vector2i(0, 0), Vector2i(-1, 0), Vector2i(-1, -1), Vector2i(0, 2), Vector2i(-1, 2)],
	Vector2i(0, 3): [Vector2i(0, 0), Vector2i(1, 0), Vector2i(1, 1), Vector2i(0, -2), Vector2i(1, -2)],
}

const WALL_KICKS_I := {
	Vector2i(0, 1): [Vector2i(0, 0), Vector2i(-2, 0), Vector2i(1, 0), Vector2i(-2, -1), Vector2i(1, 2)],
	Vector2i(1, 0): [Vector2i(0, 0), Vector2i(2, 0), Vector2i(-1, 0), Vector2i(2, 1), Vector2i(-1, -2)],
	Vector2i(1, 2): [Vector2i(0, 0), Vector2i(-1, 0), Vector2i(2, 0), Vector2i(-1, 2), Vector2i(2, -1)],
	Vector2i(2, 1): [Vector2i(0, 0), Vector2i(1, 0), Vector2i(-2, 0), Vector2i(1, -2), Vector2i(-2, 1)],
	Vector2i(2, 3): [Vector2i(0, 0), Vector2i(2, 0), Vector2i(-1, 0), Vector2i(2, 1), Vector2i(-1, -2)],
	Vector2i(3, 2): [Vector2i(0, 0), Vector2i(-2, 0), Vector2i(1, 0), Vector2i(-2, -1), Vector2i(1, 2)],
	Vector2i(3, 0): [Vector2i(0, 0), Vector2i(1, 0), Vector2i(-2, 0), Vector2i(1, -2), Vector2i(-2, 1)],
	Vector2i(0, 3): [Vector2i(0, 0), Vector2i(-1, 0), Vector2i(2, 0), Vector2i(-1, 2), Vector2i(2, -1)],
}

var rng := RandomNumberGenerator.new()
var board_state: BoardState = BoardState.new(BOARD_WIDTH, BOARD_HEIGHT, HIDDEN_ROWS)
var bag: Array[String] = []
var next_queue: Array[String] = []

var current_piece_id := ""
var current_type := ""
var current_rotation := 0
var current_pivot := Vector2i.ZERO

var hold_piece_id := ""
var can_hold := true

var score := 0
var stage_score := 0
var lines_cleared := 0
var current_stage := 0
var game_over := false
var game_won := false
var paused := false

## Boss variant (linhas / pedidos) e mecânica "pedido".
var boss_lines_cleared_stage := 0
var boss_orders_cleared_stage := 0
var order_highlight_board_y := -1

var _music_player: AudioStreamPlayer
var _music_act_loaded := -1

var fall_timer := 0.0
var lock_timer := 0.0
var piece_visual_time := 0.0

var horizontal_dir := 0
var das_timer := 0.0
var arr_timer := 0.0

var board_cache_dirty := true
var locked_cells_cache: Dictionary = {}
var obstacle_cells_cache: Array[Vector2i] = []
var obstacle_durability_cache: Dictionary = {}

var cleaner_cooldown_remaining := 0.0

## Poder "Freezer": desacelera a gravidade por alguns segundos.
var freezer_time_remaining := 0.0
var freezer_cooldown_remaining := 0.0

## Mecanica "gordura subindo": linha-lixo periodica pela base.
var grease_timer := 0.0

## Efeito visual transitorio de "vapor" ao limpar linhas.
const CLEAR_EFFECT_DURATION := 0.45
var clear_effect_time := -1.0
var clear_effect_rows: Array[int] = []

# Game lifecycle
func _ready() -> void:
	texture_filter = TEXTURE_FILTER_NEAREST
	rng.randomize()
	_setup_music_player()
	_boot_from_session()


func _boot_from_session() -> void:
	match GameSession.start_mode:
		GameSession.StartMode.NEW_GAME:
			start_new_game()
		GameSession.StartMode.CONTINUE:
			start_campaign_from_save()
		GameSession.StartMode.STAGE_SELECT:
			_start_at_stage(GameSession.selected_stage_index)
	queue_redraw()


func _reset_round_state() -> void:
	board_state.reset()
	bag.clear()
	next_queue.clear()
	current_piece_id = ""
	current_type = ""
	hold_piece_id = ""
	can_hold = true
	game_over = false
	game_won = false
	paused = false
	fall_timer = 0.0
	lock_timer = 0.0
	piece_visual_time = 0.0
	horizontal_dir = 0
	das_timer = 0.0
	arr_timer = 0.0
	board_cache_dirty = true
	boss_lines_cleared_stage = 0
	boss_orders_cleared_stage = 0
	order_highlight_board_y = -1
	cleaner_cooldown_remaining = 0.0
	freezer_time_remaining = 0.0
	freezer_cooldown_remaining = 0.0
	grease_timer = 0.0
	clear_effect_time = -1.0
	clear_effect_rows.clear()


func _setup_music_player() -> void:
	_music_player = AudioStreamPlayer.new()
	_music_player.name = "ActMusic"
	_music_player.bus = "Master"
	add_child(_music_player)


func start_campaign_from_save() -> void:
	score = 0
	stage_score = 0
	lines_cleared = 0
	var saved: int = clampi(CAMPAIGN_SAVE_SCRIPT.load_stage_index(), 0, StageLibrary.count() - 1)
	start_stage(saved)

func _process(delta: float) -> void:
	if not paused and not game_over and not game_won:
		if cleaner_cooldown_remaining > 0.0:
			cleaner_cooldown_remaining = maxf(0.0, cleaner_cooldown_remaining - delta)
		if freezer_time_remaining > 0.0:
			freezer_time_remaining = maxf(0.0, freezer_time_remaining - delta)
		if freezer_cooldown_remaining > 0.0:
			freezer_cooldown_remaining = maxf(0.0, freezer_cooldown_remaining - delta)

	if paused or game_over or game_won:
		queue_redraw()
		return

	piece_visual_time += delta
	if clear_effect_time >= 0.0:
		clear_effect_time += delta
		if clear_effect_time > CLEAR_EFFECT_DURATION:
			clear_effect_time = -1.0
	update_grease_rise(delta)
	if game_over:
		queue_redraw()
		return
	update_horizontal_movement(delta)

	var step_interval := get_effective_fall_interval()
	if Input.is_action_pressed("ui_down"):
		step_interval = SOFT_DROP_INTERVAL

	fall_timer += delta
	while fall_timer >= step_interval:
		fall_timer -= step_interval
		step_down_or_lock(step_interval)

	queue_redraw()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_M and (paused or game_over or game_won):
			_return_to_main_menu()
			return
		if event.keycode == KEY_ESCAPE and not game_over and not game_won:
			paused = not paused
			queue_redraw()
			return
		if event.keycode == KEY_R:
			start_new_game()
			return

	if game_over and not game_won:
		if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_T:
			retry_current_stage()
			return

	if paused:
		return

	if game_over or game_won:
		return

	if event.is_action_pressed("ui_up"):
		try_rotate(1)
	elif event.is_action_pressed("ui_accept"):
		hard_drop()
	elif event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_Z:
			try_rotate(-1)
		elif event.keycode == KEY_C:
			hold_current_piece()
		elif event.keycode == KEY_L:
			try_use_cleaner()
		elif event.keycode == KEY_F:
			try_use_freezer()

func try_use_cleaner() -> void:
	if not CAMPAIGN_SAVE_SCRIPT.is_cleaner_unlocked():
		return
	if cleaner_cooldown_remaining > 0.0:
		return
	if not board_state.damage_highest_durability_obstacle():
		return
	Sfx.play("cleaner")
	cleaner_cooldown_remaining = CLEANER_COOLDOWN_SEC
	board_cache_dirty = true
	queue_redraw()

func try_use_freezer() -> void:
	if not CAMPAIGN_SAVE_SCRIPT.is_cleaner_unlocked():
		return
	if freezer_cooldown_remaining > 0.0 or freezer_time_remaining > 0.0:
		return
	freezer_time_remaining = FREEZER_DURATION_SEC
	freezer_cooldown_remaining = FREEZER_COOLDOWN_SEC
	Sfx.play("freezer")
	queue_redraw()

func update_grease_rise(delta: float) -> void:
	var interval := StageLibrary.get_grease_interval(current_stage)
	if interval <= 0.0:
		return
	grease_timer += delta
	if grease_timer < interval:
		return
	grease_timer -= interval
	trigger_grease_rise()

func trigger_grease_rise() -> void:
	var gap_x := rng.randi_range(0, BOARD_WIDTH - 1)
	board_state.rise_grease_row(gap_x)
	board_cache_dirty = true
	Sfx.play("grease")

	# A peca atual pode ter passado a sobrepor celulas: sobe ate ficar valida.
	while not board_state.is_valid_piece_position(current_type, current_rotation, current_pivot):
		current_pivot += Vector2i.UP
		if current_pivot.y < 0:
			game_over = true
			Sfx.play("game_over")
			return

func start_new_game() -> void:
	score = 0
	stage_score = 0
	lines_cleared = 0
	CAMPAIGN_SAVE_SCRIPT.begin_new_campaign()
	start_stage(0)
	queue_redraw()


func _start_at_stage(stage_index: int) -> void:
	score = 0
	stage_score = 0
	lines_cleared = 0
	start_stage(clampi(stage_index, 0, StageLibrary.count() - 1))
	queue_redraw()


func _return_to_main_menu() -> void:
	get_tree().change_scene_to_file(MAIN_MENU_SCENE)


func retry_current_stage() -> void:
	var stage_idx := current_stage
	score = maxi(0, score - stage_score)
	start_stage(stage_idx)
	queue_redraw()

func start_stage(stage_index: int) -> void:
	_reset_round_state()
	current_stage = stage_index
	stage_score = 0

	board_state.apply_stage_obstacles(
		StageLibrary.get_obstacles(stage_index),
		StageLibrary.get_obstacle_durability(stage_index)
	)
	board_cache_dirty = true

	if StageLibrary.uses_order_line(stage_index):
		roll_order_highlight()

	_refresh_act_music()

	fill_next_queue()
	spawn_next_piece(true)


func _order_visible_y_from_bottom_ratio(ratio: float) -> int:
	var clamped_ratio: float = clampf(ratio, 0.0, 1.0)
	return (BOARD_VISIBLE_HEIGHT - 1) - int(round(clamped_ratio * float(BOARD_VISIBLE_HEIGHT - 1)))


func _is_boss_last_order() -> bool:
	if not StageLibrary.is_boss_variant_stage(current_stage):
		return false
	if StageLibrary.get_boss_mode(current_stage) != "orders":
		return false
	var target: int = StageLibrary.get_boss_orders_target(current_stage)
	return target - boss_orders_cleared_stage == 1


func roll_order_highlight() -> void:
	if _is_boss_last_order():
		order_highlight_board_y = HIDDEN_ROWS + _order_visible_y_from_bottom_ratio(ORDER_BOSS_LAST_HEIGHT_RATIO)
		return

	var min_visible_y: int = _order_visible_y_from_bottom_ratio(ORDER_MAX_HEIGHT_RATIO)
	var max_visible_y: int = BOARD_VISIBLE_HEIGHT - 1

	if order_highlight_board_y < 0:
		order_highlight_board_y = HIDDEN_ROWS + _order_visible_y_from_bottom_ratio(ORDER_FIRST_HEIGHT_RATIO)
		return

	var current_visible_y: int = order_highlight_board_y - HIDDEN_ROWS
	var delta: int = rng.randi_range(-ORDER_HEIGHT_VARIANCE, ORDER_HEIGHT_VARIANCE)
	var new_visible_y: int = clampi(current_visible_y + delta, min_visible_y, max_visible_y)
	order_highlight_board_y = HIDDEN_ROWS + new_visible_y


func _refresh_act_music() -> void:
	if _music_player == null:
		return
	var act: int = StageLibrary.get_act_index(current_stage)
	if act == _music_act_loaded:
		return
	_music_act_loaded = act
	var path: String = CAMPAIGN_THEME_SCRIPT.get_act_music_path(act)
	if not ResourceLoader.exists(path):
		_music_player.stop()
		return
	var stream: AudioStream = load(path) as AudioStream
	if stream == null:
		return
	_music_player.stream = stream
	_music_player.play()


func get_effective_fall_interval() -> float:
	var interval := FALL_INTERVAL * StageLibrary.get_gravity_mult(current_stage)
	if freezer_time_remaining > 0.0:
		interval *= FREEZER_SLOWDOWN
	return interval


func get_current_palette() -> Dictionary:
	return CAMPAIGN_THEME_SCRIPT.get_palette(StageLibrary.get_theme_id(current_stage))

# Piece flow
func fill_next_queue() -> void:
	while next_queue.size() < 5:
		if bag.is_empty():
			bag = PieceLibrary.TYPES.duplicate()
			bag.shuffle()
		var next_type: String = bag.pop_back()
		var piece_id: String = PieceLibrary.make_piece_id(next_type, rng.randf() < BACON_PIECE_CHANCE)
		next_queue.append(piece_id)

func spawn_next_piece(allow_hold: bool) -> void:
	fill_next_queue()
	var next_piece_id: String = next_queue.pop_front()
	set_current_piece(next_piece_id)
	current_rotation = 0
	current_pivot = Vector2i(int(BOARD_WIDTH / 2), HIDDEN_ROWS)
	can_hold = allow_hold
	piece_visual_time = 0.0

	if not board_state.is_valid_piece_position(current_type, current_rotation, current_pivot):
		game_over = true
		Sfx.play("game_over")

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
	for kick in get_wall_kicks(current_type, current_rotation, target_rotation):
		var target_pivot := current_pivot + kick
		if board_state.is_valid_piece_position(current_type, target_rotation, target_pivot):
			current_rotation = target_rotation
			current_pivot = target_pivot
			Sfx.play("rotate", 0.05)
			return

func hard_drop() -> void:
	Sfx.play("hard_drop")
	while try_move(Vector2i.DOWN):
		pass
	lock_current_piece()

func hold_current_piece() -> void:
	if not can_hold:
		return

	can_hold = false
	if hold_piece_id == "":
		hold_piece_id = current_piece_id
		spawn_next_piece(false)
		return

	var swapped_piece_id: String = hold_piece_id
	hold_piece_id = current_piece_id
	set_current_piece(swapped_piece_id)
	current_rotation = 0
	current_pivot = Vector2i(int(BOARD_WIDTH / 2), HIDDEN_ROWS)
	if not board_state.is_valid_piece_position(current_type, current_rotation, current_pivot):
		game_over = true
		Sfx.play("game_over")

func lock_current_piece() -> void:
	if current_type == "":
		return

	board_state.lock_piece(current_type, current_piece_id, current_rotation, current_pivot)
	Sfx.play("lock", 0.06)
	board_cache_dirty = true
	var stage_changed := clear_completed_lines()
	if stage_changed or game_won:
		return
	spawn_next_piece(true)

func clear_completed_lines() -> bool:
	var result: Dictionary = board_state.resolve_completed_lines()
	var cleared_count: int = int(result.get("count", 0))
	if cleared_count == 0:
		return false
	board_cache_dirty = true

	var cleared_rows: Array = result.get("cleared_rows", []) as Array

	clear_effect_rows.clear()
	for row_y in cleared_rows:
		var visible_row: int = int(row_y) - HIDDEN_ROWS
		if visible_row >= 0 and visible_row < BOARD_VISIBLE_HEIGHT:
			clear_effect_rows.append(visible_row)
	if not clear_effect_rows.is_empty():
		clear_effect_time = 0.0

	lines_cleared += cleared_count

	if cleared_count > 0 and CAMPAIGN_SAVE_SCRIPT.is_cleaner_unlocked():
		cleaner_cooldown_remaining = maxf(
			0.0,
			cleaner_cooldown_remaining - CLEANER_LINE_REDUCTION_SEC * float(cleared_count)
		)

	var earned_score: int = SCORE_BY_LINES.get(cleared_count, cleared_count * 100)
	score += earned_score
	stage_score += earned_score

	if cleared_count >= 4:
		Sfx.play("tetris")
	else:
		Sfx.play("line", 0.06)

	if StageLibrary.uses_order_line(current_stage):
		var hit_order := false
		for y in cleared_rows:
			if int(y) == order_highlight_board_y:
				hit_order = true
				break
		if hit_order:
			Sfx.play("order_bell")
			if StageLibrary.is_boss_variant_stage(current_stage) and StageLibrary.get_boss_mode(current_stage) == "orders":
				boss_orders_cleared_stage += 1
			elif StageLibrary.get_mechanic_id(current_stage) == "orders":
				const ORDER_BONUS := 220
				score += ORDER_BONUS
				stage_score += ORDER_BONUS
			roll_order_highlight()

	if StageLibrary.is_boss_variant_stage(current_stage) and StageLibrary.get_boss_mode(current_stage) == "lines":
		boss_lines_cleared_stage += cleared_count
		Sfx.play("boss_hit")

	if not can_advance_stage():
		return false

	return advance_stage()

func advance_stage() -> bool:
	Sfx.play("stage_clear")
	if StageLibrary.is_boss_stage(current_stage) and current_stage == StageLibrary.get_first_boss_stage_index():
		CAMPAIGN_SAVE_SCRIPT.unlock_cleaner()

	if current_stage >= StageLibrary.count() - 1:
		game_won = true
		CAMPAIGN_SAVE_SCRIPT.save_stage_index(current_stage)
		CAMPAIGN_SAVE_SCRIPT.update_highest_unlocked(current_stage)
		return true

	var next_stage: int = current_stage + 1
	start_stage(next_stage)
	CAMPAIGN_SAVE_SCRIPT.save_stage_index(next_stage)
	CAMPAIGN_SAVE_SCRIPT.update_highest_unlocked(next_stage)
	return true

func get_stage_goal() -> int:
	return StageLibrary.get_goal(current_stage)

func is_obstacle_stage() -> bool:
	return StageLibrary.stage_uses_obstacles(current_stage)

func has_remaining_stage_obstacles() -> bool:
	return board_state.count_remaining_obstacles() > 0

func can_advance_stage() -> bool:
	if StageLibrary.is_boss_variant_stage(current_stage):
		var boss_mode: String = StageLibrary.get_boss_mode(current_stage)
		if boss_mode == "lines":
			return boss_lines_cleared_stage >= StageLibrary.get_boss_lines_target(current_stage)
		if boss_mode == "orders":
			return boss_orders_cleared_stage >= StageLibrary.get_boss_orders_target(current_stage)
		return false

	if stage_score < get_stage_goal():
		return false
	if not is_obstacle_stage():
		return true
	return not has_remaining_stage_obstacles()

func get_piece_cells(piece_type: String, rot_index: int, pivot: Vector2i) -> Array[Vector2i]:
	return board_state.get_piece_cells(piece_type, rot_index, pivot)

func set_current_piece(piece_id: String) -> void:
	current_piece_id = piece_id
	current_type = PieceLibrary.get_base_type(piece_id)

func get_ghost_pivot() -> Vector2i:
	var ghost := current_pivot
	while board_state.is_valid_piece_position(current_type, current_rotation, ghost + Vector2i.DOWN):
		ghost += Vector2i.DOWN
	return ghost

func update_horizontal_movement(delta: float) -> void:
	var want_left := Input.is_action_pressed("ui_left")
	var want_right := Input.is_action_pressed("ui_right")

	var wanted_dir := 0
	if want_left and not want_right:
		wanted_dir = -1
	elif want_right and not want_left:
		wanted_dir = 1

	if wanted_dir == 0:
		horizontal_dir = 0
		das_timer = 0.0
		arr_timer = 0.0
		return

	if wanted_dir != horizontal_dir:
		horizontal_dir = wanted_dir
		das_timer = 0.0
		arr_timer = 0.0
		if try_move(Vector2i(horizontal_dir, 0)):
			Sfx.play("move", 0.06)
		lock_timer = 0.0
		return

	das_timer += delta
	if das_timer < DAS_DELAY:
		return

	arr_timer += delta
	while arr_timer >= ARR_INTERVAL:
		arr_timer -= ARR_INTERVAL
		if not try_move(Vector2i(horizontal_dir, 0)):
			arr_timer = 0.0
			return
		Sfx.play("move", 0.06)
		lock_timer = 0.0

func get_wall_kicks(piece_type: String, from_rotation: int, to_rotation: int) -> Array[Vector2i]:
	if piece_type == "O":
		return [Vector2i.ZERO]

	var key := Vector2i(posmod(from_rotation, 4), posmod(to_rotation, 4))
	if piece_type == "I":
		if WALL_KICKS_I.has(key):
			return to_vector2i_array(WALL_KICKS_I[key])
		return [Vector2i.ZERO]

	if WALL_KICKS_JLSTZ.has(key):
		return to_vector2i_array(WALL_KICKS_JLSTZ[key])
	return [Vector2i.ZERO]

func to_vector2i_array(raw: Array) -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	result.resize(raw.size())
	for i in range(raw.size()):
		result[i] = raw[i] as Vector2i
	return result

# Rendering
func _draw() -> void:
	draw_scene_background()
	draw_boss_panel()
	draw_board_background()
	draw_grid_lines()
	ensure_board_draw_cache()
	draw_order_highlight()
	if not game_over and not game_won:
		draw_current_pasta_piece(get_ghost_pivot(), 0.34, 0.0, 0.0)
	draw_locked_cells()
	draw_obstacle_cells()
	draw_clear_effect()
	if not game_over and not game_won:
		var settle := get_settle_amount()
		draw_current_pasta_piece(current_pivot, 1.0, settle, settle)
	draw_side_panel()
	if paused:
		draw_pause_overlay()
	elif game_over:
		draw_game_over_overlay()
	elif game_won:
		draw_stage_clear_overlay()

func get_settle_amount() -> float:
	# Only "squashes" while it's touching the stack (lock timer running).
	if lock_timer <= 0.0:
		return 0.0
	var t := clampf(lock_timer / LOCK_DELAY, 0.0, 1.0)
	# Faster onset so it feels like it "melts" quickly.
	var s := t * t * (3.0 - 2.0 * t)
	return clampf(s * 1.25, 0.0, 1.0)

func ensure_board_draw_cache() -> void:
	if not board_cache_dirty:
		return

	locked_cells_cache.clear()
	obstacle_cells_cache.clear()
	obstacle_durability_cache.clear()

	for y in range(HIDDEN_ROWS, BOARD_HEIGHT):
		for x in range(BOARD_WIDTH):
			var piece_id: String = board_state.get_locked_cell_type(x, y)
			if piece_id != "":
				if not locked_cells_cache.has(piece_id):
					locked_cells_cache[piece_id] = []
				var grouped_cells: Array = locked_cells_cache[piece_id]
				grouped_cells.append(Vector2i(x, y))
				locked_cells_cache[piece_id] = grouped_cells

			var durability: int = board_state.get_obstacle_durability(x, y)
			if durability > 0:
				var cell := Vector2i(x, y)
				obstacle_cells_cache.append(cell)
				obstacle_durability_cache[cell] = durability

	board_cache_dirty = false

func draw_order_highlight() -> void:
	if order_highlight_board_y < 0:
		return
	if not StageLibrary.uses_order_line(current_stage):
		return
	var visible_y: int = order_highlight_board_y - HIDDEN_ROWS
	if visible_y < 0 or visible_y >= BOARD_VISIBLE_HEIGHT:
		return
	var pal: Dictionary = get_current_palette()
	var board_origin: Vector2i = get_board_origin()
	var top_left: Vector2 = Vector2(board_origin) + Vector2(0, visible_y * CELL_SIZE)
	var accent: Color = pal.get("accent", Color8(255, 200, 120)) as Color
	var fill := Color(accent.r, accent.g, accent.b, 0.24)
	draw_rect(Rect2(top_left, Vector2(BOARD_WIDTH * CELL_SIZE, CELL_SIZE)), fill, true)
	draw_rect(Rect2(top_left, Vector2(BOARD_WIDTH * CELL_SIZE, CELL_SIZE)), Color(accent.r, accent.g, accent.b, 0.55), false, 2.0)

func draw_scene_background() -> void:
	var pal: Dictionary = get_current_palette()
	var viewport_size: Vector2 = get_viewport_rect().size
	var outer: Color = pal.get("scene_outer", Color8(8, 12, 18)) as Color
	var inner: Color = pal.get("scene_inner", Color8(12, 18, 28)) as Color
	var border: Color = pal.get("scene_border", Color8(46, 62, 82)) as Color
	draw_rect(Rect2(Vector2.ZERO, viewport_size), outer, true)
	var inner_rect := Rect2(Vector2(28, 24), viewport_size - Vector2(56, 48))
	draw_rect(inner_rect, inner, true)
	draw_backsplash_tiles(inner_rect, border)
	draw_rect(inner_rect, border, false, 2.0)
	draw_steam_wisps(viewport_size)

func draw_backsplash_tiles(area: Rect2, line_color: Color) -> void:
	const TILE := 48.0
	var col := Color(line_color.r, line_color.g, line_color.b, 0.07)
	var x := area.position.x + TILE
	while x < area.position.x + area.size.x:
		draw_line(Vector2(x, area.position.y), Vector2(x, area.position.y + area.size.y), col, 1.0)
		x += TILE
	var y := area.position.y + TILE
	while y < area.position.y + area.size.y:
		draw_line(Vector2(area.position.x, y), Vector2(area.position.x + area.size.x, y), col, 1.0)
		y += TILE

func draw_steam_wisps(viewport_size: Vector2) -> void:
	var pal: Dictionary = get_current_palette()
	var accent: Color = pal.get("accent", Color8(255, 200, 120)) as Color
	for i in range(4):
		var phase := piece_visual_time * 0.6 + float(i) * 1.7
		var base_x := viewport_size.x * (0.1 + 0.22 * float(i))
		var rise := fposmod(phase, TAU) / TAU
		var alpha := (1.0 - rise) * 0.05
		if alpha <= 0.002:
			continue
		var pos := Vector2(base_x + sin(phase) * 16.0, viewport_size.y * (0.92 - 0.55 * rise))
		draw_circle(pos, 26.0 + rise * 32.0, Color(accent.r, accent.g, accent.b, alpha))

func draw_clear_effect() -> void:
	if clear_effect_time < 0.0 or clear_effect_rows.is_empty():
		return
	var t := clampf(clear_effect_time / CLEAR_EFFECT_DURATION, 0.0, 1.0)
	var board_origin: Vector2i = get_board_origin()
	var pal: Dictionary = get_current_palette()
	var accent: Color = pal.get("accent", Color8(255, 200, 120)) as Color
	var board_width_px: float = float(BOARD_WIDTH * CELL_SIZE)
	for visible_row in clear_effect_rows:
		var y_px: float = float(board_origin.y + visible_row * CELL_SIZE)
		draw_rect(Rect2(Vector2(float(board_origin.x), y_px), Vector2(board_width_px, float(CELL_SIZE))), Color(accent.r, accent.g, accent.b, (1.0 - t) * 0.45), true)
		for i in range(6):
			var cx: float = float(board_origin.x) + (float(i) + 0.5) / 6.0 * board_width_px
			var puff_y: float = y_px + float(CELL_SIZE) * 0.5 - t * float(CELL_SIZE) * 1.4
			draw_circle(Vector2(cx, puff_y), float(CELL_SIZE) * 0.32 * (0.6 + t), Color(1.0, 1.0, 1.0, (1.0 - t) * 0.28))

func draw_boss_panel() -> void:
	var font := ThemeDB.fallback_font
	var panel: Rect2 = get_boss_panel_rect()
	var pal: Dictionary = get_current_palette()
	var panel_fill: Color = pal.get("boss_panel_fill", Color8(18, 24, 34)) as Color
	var panel_line: Color = pal.get("boss_panel_line", Color8(88, 106, 126)) as Color
	var title_color := Color8(242, 236, 226)
	var subtitle_color := Color8(196, 212, 224)
	var accent: Color = pal.get("accent", Color8(255, 200, 120)) as Color

	draw_rect(panel, panel_fill, true)
	draw_rect(panel, panel_line, false, 2.0)

	if StageLibrary.is_boss_variant_stage(current_stage):
		var mode: String = StageLibrary.get_boss_mode(current_stage)
		var display_name: String = StageLibrary.get_boss_display_name(current_stage)
		if display_name == "":
			display_name = "Chefao"
		draw_string(font, Vector2(panel.position.x + 22, panel.position.y + 28), display_name, HORIZONTAL_ALIGNMENT_LEFT, -1, 24, title_color)
		if mode == "lines":
			var tgt: int = maxi(StageLibrary.get_boss_lines_target(current_stage), 1)
			var prog: float = clampf(float(boss_lines_cleared_stage) / float(tgt), 0.0, 1.0)
			draw_string(font, Vector2(panel.position.x + 22, panel.position.y + 52), "Linhas limpas: %d / %d" % [boss_lines_cleared_stage, tgt], HORIZONTAL_ALIGNMENT_LEFT, -1, 18, subtitle_color)
			var bar_rect := Rect2(panel.position + Vector2(22, 58), Vector2(panel.size.x - 44, 16))
			draw_rect(bar_rect, Color8(44, 54, 68), true)
			if prog > 0.0:
				draw_rect(Rect2(bar_rect.position, Vector2(bar_rect.size.x * prog, bar_rect.size.y)), Color8(232, 92, 110), true)
			draw_rect(bar_rect, Color8(126, 142, 160), false, 2.0)
			var lines_hint := "Limpe linhas suficientes para vencer o confronto."
			if StageLibrary.get_grease_interval(current_stage) > 0.0:
				lines_hint = "A gordura sobe! Use o freezer (F) e limpe a brecha."
			draw_string(font, Vector2(panel.position.x + 22, panel.position.y + 82), lines_hint, HORIZONTAL_ALIGNMENT_LEFT, -1, 14, accent)
		elif mode == "orders":
			var otgt: int = maxi(StageLibrary.get_boss_orders_target(current_stage), 1)
			var oprog: float = clampf(float(boss_orders_cleared_stage) / float(otgt), 0.0, 1.0)
			draw_string(font, Vector2(panel.position.x + 22, panel.position.y + 52), "Pedidos completos: %d / %d" % [boss_orders_cleared_stage, otgt], HORIZONTAL_ALIGNMENT_LEFT, -1, 18, subtitle_color)
			var obar := Rect2(panel.position + Vector2(22, 58), Vector2(panel.size.x - 44, 16))
			draw_rect(obar, Color8(44, 54, 68), true)
			if oprog > 0.0:
				draw_rect(Rect2(obar.position, Vector2(obar.size.x * oprog, obar.size.y)), Color8(120, 200, 140), true)
			draw_rect(obar, Color8(126, 142, 160), false, 2.0)
			var orders_hint := "Limpe a fileira DOURADA inteira como parte de uma linha."
			if StageLibrary.hides_next(current_stage):
				orders_hint = "Sem previa: a PROXIMA peca fica oculta. Sirva os pedidos!"
			draw_string(font, Vector2(panel.position.x + 22, panel.position.y + 82), orders_hint, HORIZONTAL_ALIGNMENT_LEFT, -1, 14, accent)
		return

	var stage_title := StageLibrary.get_stage_label(current_stage)
	draw_string(font, Vector2(panel.position.x + 22, panel.position.y + 28), stage_title, HORIZONTAL_ALIGNMENT_LEFT, -1, 22, title_color)
	var goal: int = max(get_stage_goal(), 1)
	var damage: int = clampi(stage_score, 0, goal)
	var remaining: int = max(goal - damage, 0)
	var progress: float = float(damage) / float(goal)
	var shielded: bool = is_obstacle_stage() and has_remaining_stage_obstacles()

	draw_string(font, Vector2(panel.position.x + 22, panel.position.y + 52), "Pontos da fase: %d / %d" % [damage, goal], HORIZONTAL_ALIGNMENT_LEFT, -1, 18, subtitle_color)
	if shielded:
		draw_string(font, Vector2(panel.position.x + 470, panel.position.y + 52), "ESCUDO ATIVO", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, accent)

	var bar_rect := Rect2(panel.position + Vector2(22, 58), Vector2(panel.size.x - 44, 16))
	draw_rect(bar_rect, Color8(44, 54, 68), true)
	if progress > 0.0:
		draw_rect(Rect2(bar_rect.position, Vector2(bar_rect.size.x * progress, bar_rect.size.y)), Color8(232, 92, 110), true)
	draw_rect(bar_rect, Color8(126, 142, 160), false, 2.0)

	if StageLibrary.get_grease_interval(current_stage) > 0.0:
		draw_string(font, Vector2(panel.position.x + 22, panel.position.y + 82), "Gordura sobe pela base — limpe a brecha e use o freezer (F).", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, accent)
	elif StageLibrary.get_mechanic_id(current_stage) == "orders":
		draw_string(font, Vector2(panel.position.x + 22, panel.position.y + 82), "Dica: limpe a fileira dourada para bonus de pontos.", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, accent)
	elif StageLibrary.get_mechanic_id(current_stage) == "pressure":
		draw_string(font, Vector2(panel.position.x + 22, panel.position.y + 82), "Gravidade aumentada neste ato — pense rapido.", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, accent)

func draw_board_background() -> void:
	var pal: Dictionary = get_current_palette()
	var board_origin: Vector2i = get_board_origin()
	var board_origin_vec: Vector2 = Vector2(board_origin.x, board_origin.y)
	var board_size: Vector2 = Vector2(get_board_pixel_size())
	var frame: Color = pal.get("board_frame", Color8(18, 24, 34)) as Color
	var frame_line: Color = pal.get("board_frame_line", Color8(88, 106, 126)) as Color
	var fill: Color = pal.get("board_fill", BOARD_BG_COLOR) as Color
	var inner_line: Color = pal.get("board_line", Color8(58, 76, 98)) as Color
	draw_rect(Rect2(board_origin_vec - Vector2(14, 14), board_size + Vector2(28, 28)), frame, true)
	draw_rect(Rect2(board_origin_vec - Vector2(14, 14), board_size + Vector2(28, 28)), frame_line, false, 2.0)
	draw_rect(Rect2(board_origin_vec, board_size), fill, true)
	draw_rect(Rect2(board_origin_vec, board_size), inner_line, false, 2.0)

func draw_locked_cells() -> void:
	if locked_cells_cache.is_empty():
		return

	## Agrupa por familia visual para o macarrao se encaixar entre pecas vizinhas.
	var family_cells: Dictionary = {}
	for piece_id in locked_cells_cache.keys():
		var family: String = PASTA_TILES_SCRIPT.visual_family(str(piece_id))
		if not family_cells.has(family):
			var empty_bucket: Array[Vector2i] = []
			family_cells[family] = empty_bucket
		var bucket: Array[Vector2i] = family_cells[family]
		for cell in locked_cells_cache[piece_id]:
			bucket.append(cell as Vector2i)
		family_cells[family] = bucket

	var active_family := ""
	var active_cells: Array[Vector2i] = []
	if not game_over and not game_won and current_piece_id != "":
		active_family = PASTA_TILES_SCRIPT.visual_family(current_piece_id)
		active_cells = get_piece_cells(current_type, current_rotation, current_pivot)

	for family in family_cells.keys():
		var cells: Array[Vector2i] = family_cells[family]
		var connect: Dictionary = PASTA_TILES_SCRIPT.build_lookup(cells)
		if family == active_family:
			for cell in active_cells:
				connect[cell] = true
		draw_pasta_piece(cells, PASTA_TILES_SCRIPT.modulate_for_family(str(family)), 0.0, 0.0, connect)

func draw_current_pasta_piece(pivot: Vector2i, alpha: float, settle: float, squash: float) -> void:
	var family: String = PASTA_TILES_SCRIPT.visual_family(current_piece_id)
	var cells: Array[Vector2i] = get_piece_cells(current_type, current_rotation, pivot)
	var connect: Dictionary = PASTA_TILES_SCRIPT.build_lookup(cells)
	## Ghost fica sozinho; peca ativa se encaixa com o macarrao ja no tabuleiro.
	if alpha >= 0.9:
		for piece_id in locked_cells_cache.keys():
			if PASTA_TILES_SCRIPT.visual_family(str(piece_id)) != family:
				continue
			for cell in locked_cells_cache[piece_id]:
				connect[cell] = true
	draw_pasta_piece(cells, PASTA_TILES_SCRIPT.modulate_for_family(family, alpha), settle, squash, connect)

func draw_pasta_piece(
	cells: Array[Vector2i],
	modulate: Color = Color.WHITE,
	settle: float = 0.0,
	squash: float = 0.0,
	connect_lookup: Dictionary = {}
) -> void:
	var visible_cells: Array[Vector2i] = []
	for cell in cells:
		if cell.y < HIDDEN_ROWS or cell.y >= BOARD_HEIGHT:
			continue
		visible_cells.append(cell)
	if visible_cells.is_empty():
		return

	var lookup: Dictionary = connect_lookup
	if lookup.is_empty():
		lookup = PASTA_TILES_SCRIPT.build_lookup(visible_cells)

	var atlas: Texture2D = PASTA_TILES_SCRIPT.get_atlas()
	if atlas == null:
		draw_soft_piece(visible_cells, PieceLibrary.PASTA_COLOR, settle, squash)
		return

	var grow_amount := settle * SETTLE_MAX_GROW
	var squash_amount := squash * SETTLE_MAX_SQUASH
	## Overdraw leve evita fissuras entre tiles ao escalar 16 -> CELL_SIZE.
	var overdraw := 0.75 + grow_amount

	for cell in visible_cells:
		var mask: int = PASTA_TILES_SCRIPT.neighbor_mask(cell, lookup)
		var src := PASTA_TILES_SCRIPT.region_for_mask(mask)
		var base := Rect2(Vector2(board_to_screen(cell)), Vector2(CELL_SIZE, CELL_SIZE))
		var rect := base.grow(overdraw)
		if squash_amount > 0.0:
			var target_h := rect.size.y * (1.0 - squash_amount)
			var target_w := rect.size.x * (1.0 + squash_amount * 1.15)
			rect.position.x -= (target_w - rect.size.x) * 0.5
			rect.position.y += (rect.size.y - target_h) * 0.5
			rect.size = Vector2(target_w, target_h)
		draw_texture_rect_region(atlas, rect, src, modulate)

func draw_obstacle_cells() -> void:
	if obstacle_cells_cache.is_empty():
		return

	var font := ThemeDB.fallback_font
	for cell in obstacle_cells_cache:
		var durability: int = obstacle_durability_cache.get(cell, 0)
		if durability <= 0:
			continue
		var draw_pos := board_to_screen(cell)
		draw_obstacle_block(draw_pos, durability, font)

func draw_soft_piece(cells: Array[Vector2i], color: Color, settle: float = 0.0, squash: float = 0.0) -> void:
	var visible_cells: Array[Vector2i] = []
	var cell_lookup: Dictionary = {}

	for cell in cells:
		if cell.y < HIDDEN_ROWS:
			continue
		if cell.y >= BOARD_HEIGHT:
			continue
		visible_cells.append(cell)
		cell_lookup[cell] = true

	if visible_cells.is_empty():
		return

	var fill := color if color.a >= 1.0 else Color(color.r, color.g, color.b, 0.68)
	draw_soft_piece_body(visible_cells, fill, settle, squash)
	draw_soft_piece_edges(cell_lookup, fill, settle)
	draw_soft_piece_inner_corner_fills(cell_lookup, fill)

func draw_soft_piece_body(visible_cells: Array[Vector2i], color: Color, settle: float, squash: float) -> void:
	var grow_amount := settle * SETTLE_MAX_GROW
	var squash_amount := squash * SETTLE_MAX_SQUASH
	for cell in visible_cells:
		var base := Rect2(Vector2(board_to_screen(cell)), Vector2(CELL_SIZE, CELL_SIZE))
		var rect := base.grow(ACTIVE_MASS_OVERDRAW + grow_amount)

		# "Settle squash": a little flatter (y) and wider (x) as it locks.
		if squash_amount > 0.0:
			var target_h := rect.size.y * (1.0 - squash_amount)
			var target_w := rect.size.x * (1.0 + squash_amount * 1.15)
			rect.position.x -= (target_w - rect.size.x) * 0.5
			rect.position.y += (rect.size.y - target_h) * 0.5
			rect.size = Vector2(target_w, target_h)

		# Base fill
		draw_rect(rect, color, true)

		# "Massa" shading: subtle bottom dark + top highlight.
		var top := color.lightened(0.14)
		var bottom := color.darkened(0.10)
		draw_rect(Rect2(rect.position, Vector2(rect.size.x, rect.size.y * 0.42)), top, true)
		draw_rect(Rect2(rect.position + Vector2(0.0, rect.size.y * 0.72), Vector2(rect.size.x, rect.size.y * 0.28)), bottom, true)

		# Wet shine streak (slightly animated, tiny).
		var wobble := sin(piece_visual_time * 5.0 + float(cell.x) * 0.9 + float(cell.y) * 0.6) * (1.6 + settle * 0.8)
		var shine := Color(1, 1, 1, 0.12 + settle * 0.10)
		var shine_y := rect.position.y + rect.size.y * 0.22 + wobble
		draw_rect(Rect2(Vector2(rect.position.x + rect.size.x * 0.18, shine_y), Vector2(rect.size.x * 0.64, max(1.0, rect.size.y * 0.08))), shine, true)

func draw_soft_piece_edges(cell_lookup: Dictionary, color: Color, extra_size: float) -> void:
	var bounds := get_soft_piece_bounds(cell_lookup)
	var radius := ACTIVE_EDGE_RADIUS + extra_size * 0.35
	var edge_width := ACTIVE_EDGE_WIDTH + extra_size * 0.55
	var top_radius := ACTIVE_TOP_RADIUS + extra_size * 0.42
	var top_width := ACTIVE_TOP_WIDTH + extra_size * 0.65

	draw_soft_piece_horizontal_runs(cell_lookup, bounds, Vector2i.UP, color, top_width, top_radius, CELL_SIZE * 0.08)
	draw_soft_piece_horizontal_runs(cell_lookup, bounds, Vector2i.DOWN, color, edge_width, radius, CELL_SIZE * 0.92)
	draw_soft_piece_vertical_runs(cell_lookup, bounds, Vector2i.LEFT, color, edge_width, radius, CELL_SIZE * 0.08)
	draw_soft_piece_vertical_runs(cell_lookup, bounds, Vector2i.RIGHT, color, edge_width, radius, CELL_SIZE * 0.92)

func draw_soft_piece_inner_corner_fills(cell_lookup: Dictionary, color: Color) -> void:
	var bounds := get_soft_piece_bounds(cell_lookup)
	for y in range(bounds.position.y, bounds.position.y + bounds.size.y):
		for x in range(bounds.position.x, bounds.position.x + bounds.size.x):
			var empty_cell := Vector2i(x, y)
			if cell_lookup.has(empty_cell):
				continue

			var screen_pos := Vector2(board_to_screen(empty_cell))
			if cell_lookup.has(empty_cell + Vector2i.LEFT) and cell_lookup.has(empty_cell + Vector2i.UP):
				draw_circle(screen_pos, ACTIVE_INNER_RADIUS, color)
			if cell_lookup.has(empty_cell + Vector2i.RIGHT) and cell_lookup.has(empty_cell + Vector2i.UP):
				draw_circle(screen_pos + Vector2(CELL_SIZE, 0.0), ACTIVE_INNER_RADIUS, color)
			if cell_lookup.has(empty_cell + Vector2i.LEFT) and cell_lookup.has(empty_cell + Vector2i.DOWN):
				draw_circle(screen_pos + Vector2(0.0, CELL_SIZE), ACTIVE_INNER_RADIUS, color)
			if cell_lookup.has(empty_cell + Vector2i.RIGHT) and cell_lookup.has(empty_cell + Vector2i.DOWN):
				draw_circle(screen_pos + Vector2(CELL_SIZE, CELL_SIZE), ACTIVE_INNER_RADIUS, color)

func draw_soft_piece_horizontal_runs(cell_lookup: Dictionary, bounds: Rect2i, direction: Vector2i, color: Color, width: float, radius: float, y_factor: float) -> void:
	for y in range(bounds.position.y, bounds.position.y + bounds.size.y):
		var x := bounds.position.x
		while x < bounds.position.x + bounds.size.x:
			var cell := Vector2i(x, y)
			var is_edge := cell_lookup.has(cell) and not cell_lookup.has(cell + direction)
			if not is_edge:
				x += 1
				continue

			var run_start := x
			x += 1
			while x < bounds.position.x + bounds.size.x:
				var next_cell := Vector2i(x, y)
				if not cell_lookup.has(next_cell) or cell_lookup.has(next_cell + direction):
					break
				x += 1
			var run_end := x - 1

			var start_pos := Vector2(board_to_screen(Vector2i(run_start, y))) + Vector2(ACTIVE_EDGE_INSET, y_factor)
			var end_pos := Vector2(board_to_screen(Vector2i(run_end, y))) + Vector2(CELL_SIZE - ACTIVE_EDGE_INSET, y_factor)
			draw_soft_piece_edge_segment(start_pos, end_pos, color, width, radius)

func draw_soft_piece_vertical_runs(cell_lookup: Dictionary, bounds: Rect2i, direction: Vector2i, color: Color, width: float, radius: float, x_factor: float) -> void:
	for x in range(bounds.position.x, bounds.position.x + bounds.size.x):
		var y := bounds.position.y
		while y < bounds.position.y + bounds.size.y:
			var cell := Vector2i(x, y)
			var is_edge := cell_lookup.has(cell) and not cell_lookup.has(cell + direction)
			if not is_edge:
				y += 1
				continue

			var run_start := y
			y += 1
			while y < bounds.position.y + bounds.size.y:
				var next_cell := Vector2i(x, y)
				if not cell_lookup.has(next_cell) or cell_lookup.has(next_cell + direction):
					break
				y += 1
			var run_end := y - 1

			var start_pos := Vector2(board_to_screen(Vector2i(x, run_start))) + Vector2(x_factor, ACTIVE_EDGE_INSET)
			var end_pos := Vector2(board_to_screen(Vector2i(x, run_end))) + Vector2(x_factor, CELL_SIZE - ACTIVE_EDGE_INSET)
			draw_soft_piece_edge_segment(start_pos, end_pos, color, width, radius)

func draw_soft_piece_edge_segment(start_pos: Vector2, end_pos: Vector2, color: Color, width: float, radius: float) -> void:
	draw_line(start_pos, end_pos, color, width, true)
	draw_circle(start_pos, radius, color)
	draw_circle(end_pos, radius, color)

func get_soft_piece_bounds(cell_lookup: Dictionary) -> Rect2i:
	var min_x := BOARD_WIDTH
	var min_y := BOARD_HEIGHT
	var max_x := -1
	var max_y := -1
	for cell in cell_lookup.keys():
		var grid_cell: Vector2i = cell
		min_x = mini(min_x, grid_cell.x)
		min_y = mini(min_y, grid_cell.y)
		max_x = maxi(max_x, grid_cell.x)
		max_y = maxi(max_y, grid_cell.y)
	return Rect2i(Vector2i(min_x, min_y), Vector2i(max_x - min_x + 1, max_y - min_y + 1))

func draw_block(screen_pos: Vector2i, color: Color, is_ghost: bool) -> void:
	var rect := Rect2(Vector2(screen_pos), Vector2(CELL_SIZE, CELL_SIZE))
	if is_ghost:
		draw_rect(rect, color, false, 2.0)
		return

	var fill := color
	if color.a < 1.0:
		fill = Color(color.r, color.g, color.b, 0.58)
	draw_rect(rect.grow(-1), fill, true)
	draw_rect(rect.grow(-1), color.lightened(0.18), false, 2.0)
	draw_line(rect.position + Vector2(4, 6), rect.position + Vector2(CELL_SIZE - 5, 6), color.lightened(0.30), 1.5)

func draw_grid_lines() -> void:
	var pal: Dictionary = get_current_palette()
	var grid_col: Color = pal.get("board_line", Color8(58, 76, 98)) as Color
	grid_col = Color(grid_col.r, grid_col.g, grid_col.b, 0.65)
	var board_origin: Vector2i = get_board_origin()
	for x in range(BOARD_WIDTH + 1):
		var start := board_origin + Vector2i(x * CELL_SIZE, 0)
		var finish := start + Vector2i(0, BOARD_VISIBLE_HEIGHT * CELL_SIZE)
		draw_line(Vector2(start), Vector2(finish), grid_col, 1.0)

	for y in range(BOARD_VISIBLE_HEIGHT + 1):
		var start := board_origin + Vector2i(0, y * CELL_SIZE)
		var finish := start + Vector2i(BOARD_WIDTH * CELL_SIZE, 0)
		draw_line(Vector2(start), Vector2(finish), grid_col, 1.0)

func draw_side_panel() -> void:
	var font := ThemeDB.fallback_font
	var title_color := Color8(242, 236, 226)
	var value_color := Color8(180, 205, 225)
	var label_color := Color8(126, 142, 160)
	var side_panel_x: int = get_side_panel_x()
	var board_origin: Vector2i = get_board_origin()
	var top_y := int(board_origin.y)

	var act_n: int = StageLibrary.get_act_index(current_stage) + 1
	draw_string(font, Vector2(side_panel_x, top_y + 10), "CHEFTRIS", HORIZONTAL_ALIGNMENT_LEFT, -1, 28, title_color)
	draw_string(font, Vector2(side_panel_x, top_y + 38), StageLibrary.get_stage_label(current_stage), HORIZONTAL_ALIGNMENT_LEFT, -1, 16, label_color)
	draw_string(font, Vector2(side_panel_x, top_y + 58), "Ato %d de 3" % act_n, HORIZONTAL_ALIGNMENT_LEFT, -1, 16, label_color)
	draw_string(font, Vector2(side_panel_x, top_y + 86), "Pontuacao %d" % score, HORIZONTAL_ALIGNMENT_LEFT, -1, 20, value_color)
	draw_string(font, Vector2(side_panel_x, top_y + 112), "Linhas %d" % lines_cleared, HORIZONTAL_ALIGNMENT_LEFT, -1, 18, label_color)

	draw_string(font, Vector2(side_panel_x, top_y + 142), "HOLD", HORIZONTAL_ALIGNMENT_LEFT, -1, 18, title_color)
	draw_preview_box(Vector2i(side_panel_x, top_y + 152), hold_piece_id, Vector2i(152, 92))

	draw_string(font, Vector2(side_panel_x, top_y + 280), "PROXIMA", HORIZONTAL_ALIGNMENT_LEFT, -1, 18, title_color)
	if StageLibrary.hides_next(current_stage):
		draw_hidden_preview_box(Vector2i(side_panel_x, top_y + 290), Vector2i(152, 92), font)
	elif not next_queue.is_empty():
		draw_preview_box(Vector2i(side_panel_x, top_y + 290), next_queue[0], Vector2i(152, 92))

	if CAMPAIGN_SAVE_SCRIPT.is_cleaner_unlocked():
		var cleaner_status := "PRONTO (L)"
		if cleaner_cooldown_remaining > 0.0:
			cleaner_status = "%ds (L)" % int(ceil(cleaner_cooldown_remaining))
		draw_tool_box(Vector2(side_panel_x, top_y + 392), Vector2(82, 52), "LIMPEZA", cleaner_status, font)

		var freezer_status := "PRONTO (F)"
		if freezer_time_remaining > 0.0:
			freezer_status = "ATIVO %ds" % int(ceil(freezer_time_remaining))
		elif freezer_cooldown_remaining > 0.0:
			freezer_status = "%ds (F)" % int(ceil(freezer_cooldown_remaining))
		draw_tool_box(Vector2(side_panel_x + 88, top_y + 392), Vector2(82, 52), "FREEZER", freezer_status, font)

	draw_rect(Rect2(Vector2(side_panel_x, top_y + 452), Vector2(170, 110)), Color8(18, 24, 34), true)
	draw_rect(Rect2(Vector2(side_panel_x, top_y + 452), Vector2(170, 110)), Color8(88, 106, 126), false, 2.0)
	draw_string(font, Vector2(side_panel_x + 16, top_y + 480), "ESC", HORIZONTAL_ALIGNMENT_LEFT, -1, 26, title_color)
	draw_string(font, Vector2(side_panel_x + 16, top_y + 508), "Pausa e ajuda", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, value_color)
	draw_string(font, Vector2(side_panel_x + 16, top_y + 528), "R nova campanha", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, label_color)
	draw_string(font, Vector2(side_panel_x + 16, top_y + 546), "T tenta de novo", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, label_color)
	draw_string(font, Vector2(side_panel_x + 16, top_y + 564), "M menu principal", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, label_color)

func draw_preview_box(origin: Vector2i, piece_id: String, size := Vector2i(120, 80)) -> void:
	draw_rect(Rect2(origin, size), Color8(22, 28, 38), true)
	draw_rect(Rect2(origin, size), Color8(88, 106, 126), false, 1.5)

	if piece_id == "":
		return

	var piece_type := PieceLibrary.get_base_type(piece_id)
	var family: String = PASTA_TILES_SCRIPT.visual_family(piece_id)
	var modulate: Color = PASTA_TILES_SCRIPT.modulate_for_family(family)
	var cells: Array[Vector2i] = PieceLibrary.get_cells(piece_type, 0)
	var lookup: Dictionary = PASTA_TILES_SCRIPT.build_lookup(cells)
	var atlas: Texture2D = PASTA_TILES_SCRIPT.get_atlas()
	var base := Vector2(origin) + Vector2(size.x * 0.34, size.y * 0.42)
	var preview_cell := 16.0
	for cell in cells:
		var pos := base + Vector2(cell) * preview_cell
		var rect := Rect2(pos, Vector2(preview_cell, preview_cell)).grow(0.5)
		if atlas != null:
			var mask: int = PASTA_TILES_SCRIPT.neighbor_mask(cell, lookup)
			draw_texture_rect_region(atlas, rect, PASTA_TILES_SCRIPT.region_for_mask(mask), modulate)
		else:
			draw_rect(rect, PieceLibrary.get_color(piece_id), true)

func draw_hidden_preview_box(origin: Vector2i, size: Vector2i, font: Font) -> void:
	draw_rect(Rect2(origin, size), Color8(22, 28, 38), true)
	draw_rect(Rect2(origin, size), Color8(88, 106, 126), false, 1.5)
	draw_string(font, Vector2(origin) + Vector2(size.x * 0.42, size.y * 0.62), "?", HORIZONTAL_ALIGNMENT_LEFT, -1, 40, Color8(150, 118, 96))

func draw_tool_box(origin: Vector2, box_size: Vector2, label: String, status: String, font: Font) -> void:
	draw_rect(Rect2(origin, box_size), Color8(35, 27, 20), true)
	draw_rect(Rect2(origin, box_size), Color8(110, 82, 52), false, 2.0)
	draw_string(font, origin + Vector2(10, 20), label, HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color8(242, 236, 226))
	draw_string(font, origin + Vector2(10, 40), status, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color8(200, 214, 224))

func draw_pause_overlay() -> void:
	var font := ThemeDB.fallback_font
	var viewport_size: Vector2 = get_viewport_rect().size
	draw_rect(Rect2(Vector2.ZERO, viewport_size), Color(0, 0, 0, 0.58), true)
	var panel_size: Vector2 = Vector2(724, 540)
	var panel: Rect2 = Rect2((viewport_size - panel_size) * 0.5, panel_size)
	draw_rect(panel, Color8(15, 22, 32), true)
	draw_rect(panel, Color8(104, 120, 142), false, 2.0)

	draw_string(font, panel.position + Vector2(28, 42), "PAUSADO", HORIZONTAL_ALIGNMENT_LEFT, -1, 34, Color8(244, 238, 230))
	draw_string(font, panel.position + Vector2(28, 74), "Comandos e como cada bloco funciona", HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color8(180, 205, 225))

	draw_string(font, panel.position + Vector2(28, 124), "Comandos", HORIZONTAL_ALIGNMENT_LEFT, -1, 22, Color8(244, 238, 230))
	draw_string(font, panel.position + Vector2(28, 154), "Setas: mover e girar", HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color8(180, 205, 225))
	draw_string(font, panel.position + Vector2(28, 182), "Z: rotacao anti-horaria", HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color8(180, 205, 225))
	draw_string(font, panel.position + Vector2(28, 210), "Espaco ou Enter: hard drop", HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color8(180, 205, 225))
	draw_string(font, panel.position + Vector2(28, 238), "C: hold", HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color8(180, 205, 225))
	if CAMPAIGN_SAVE_SCRIPT.is_cleaner_unlocked():
		draw_string(font, panel.position + Vector2(28, 266), "L: produto de limpeza", HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color8(180, 205, 225))
		draw_string(font, panel.position + Vector2(28, 294), "F: freezer (desacelera a gravidade)", HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color8(180, 205, 225))
		draw_string(font, panel.position + Vector2(28, 322), "Esc: voltar ao jogo", HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color8(180, 205, 225))
	else:
		draw_string(font, panel.position + Vector2(28, 266), "Esc: voltar ao jogo", HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color8(180, 205, 225))

	draw_string(font, panel.position + Vector2(390, 124), "Campanha", HORIZONTAL_ALIGNMENT_LEFT, -1, 22, Color8(244, 238, 230))
	draw_string(font, panel.position + Vector2(390, 154), "15 fases em 3 atos; chefes nas fases 5, 10 e 15", HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color8(180, 205, 225))
	draw_string(font, panel.position + Vector2(390, 182), "Fase normal: barra de pontos + escudo com obstaculos", HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color8(180, 205, 225))
	draw_string(font, panel.position + Vector2(390, 210), "Pedidos: fileira dourada da bonus (ato 2)", HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color8(180, 205, 225))
	draw_string(font, panel.position + Vector2(390, 238), "Chefao: regra especial no painel superior", HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color8(180, 205, 225))
	if CAMPAIGN_SAVE_SCRIPT.is_cleaner_unlocked():
		draw_string(font, panel.position + Vector2(390, 266), "L atinge obstaculo mais resistente", HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color8(180, 205, 225))
		draw_string(font, panel.position + Vector2(390, 294), "Recarga 60s; linhas limpas -5s", HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color8(180, 205, 225))

	draw_string(font, panel.position + Vector2(28, 318), "Progresso", HORIZONTAL_ALIGNMENT_LEFT, -1, 22, Color8(244, 238, 230))
	draw_string(font, panel.position + Vector2(28, 348), "Salva ao passar de fase. Menu no inicio do jogo.", HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color8(180, 205, 225))
	draw_string(font, panel.position + Vector2(28, 376), "T em game over: tenta a mesma fase de novo", HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color8(180, 205, 225))
	draw_string(font, panel.position + Vector2(28, 404), "M: voltar ao menu principal", HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color8(180, 205, 225))
	draw_string(font, panel.position + Vector2(28, 432), "R: nova campanha (do inicio)", HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color8(180, 205, 225))

	draw_string(font, panel.position + Vector2(28, 486), "Esc para fechar", HORIZONTAL_ALIGNMENT_LEFT, -1, 20, Color8(244, 238, 230))

func draw_game_over_overlay() -> void:
	var board_origin: Vector2i = get_board_origin()
	var board_origin_vec: Vector2 = Vector2(board_origin.x, board_origin.y)
	var overlay: Rect2 = Rect2(board_origin_vec, Vector2(get_board_pixel_size()))
	draw_rect(overlay, Color(0, 0, 0, 0.6), true)
	var font := ThemeDB.fallback_font
	draw_string(font, board_origin_vec + Vector2(35, 250), "GAME OVER", HORIZONTAL_ALIGNMENT_LEFT, -1, 36, Color8(255, 220, 220))
	draw_string(font, board_origin_vec + Vector2(32, 285), "T: tentar esta fase de novo", HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color8(230, 230, 230))
	draw_string(font, board_origin_vec + Vector2(32, 308), "R: nova campanha (do inicio)", HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color8(230, 230, 230))
	draw_string(font, board_origin_vec + Vector2(32, 331), "M: menu principal", HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color8(230, 230, 230))

func draw_stage_clear_overlay() -> void:
	var board_origin: Vector2i = get_board_origin()
	var board_origin_vec: Vector2 = Vector2(board_origin.x, board_origin.y)
	var overlay: Rect2 = Rect2(board_origin_vec, Vector2(get_board_pixel_size()))
	draw_rect(overlay, Color(0, 0, 0, 0.55), true)
	var font := ThemeDB.fallback_font
	draw_string(font, board_origin_vec + Vector2(10, 220), "CAMPANHA", HORIZONTAL_ALIGNMENT_LEFT, -1, 22, Color8(220, 245, 220))
	draw_string(font, board_origin_vec + Vector2(10, 246), "CONCLUIDA", HORIZONTAL_ALIGNMENT_LEFT, -1, 22, Color8(220, 245, 220))
	draw_string(font, board_origin_vec + Vector2(10, 276), "Tres chefes vencidos.", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color8(230, 230, 230))
	draw_string(font, board_origin_vec + Vector2(10, 300), "R: nova campanha", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color8(230, 230, 230))
	draw_string(font, board_origin_vec + Vector2(10, 324), "M: menu principal", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color8(230, 230, 230))

func draw_obstacle_block(screen_pos: Vector2i, durability: int, font: Font) -> void:
	var color: Color = StageLibrary.get_obstacle_color(durability)
	var rect := Rect2(Vector2(screen_pos), Vector2(CELL_SIZE, CELL_SIZE))
	draw_rect(rect.grow(-1), color, true)
	draw_rect(rect.grow(-1), color.lightened(0.15), false, 2.0)
	draw_string(font, Vector2(screen_pos.x + 9, screen_pos.y + 20), str(durability), HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color8(245, 245, 245))

func board_to_screen(cell: Vector2i) -> Vector2i:
	var visible_y := cell.y - HIDDEN_ROWS
	return get_board_origin() + Vector2i(cell.x * CELL_SIZE, visible_y * CELL_SIZE)

func get_board_pixel_size() -> Vector2i:
	return Vector2i(BOARD_WIDTH * CELL_SIZE, BOARD_VISIBLE_HEIGHT * CELL_SIZE)

func get_content_width() -> int:
	return get_board_pixel_size().x + LAYOUT_GAP + SIDE_PANEL_WIDTH

func get_board_origin() -> Vector2i:
	var viewport_size: Vector2 = get_viewport_rect().size
	var board_size: Vector2i = get_board_pixel_size()
	var content_width: int = get_content_width()
	var start_x: int = int((viewport_size.x - content_width) * 0.5)
	var start_y: int = int(max(140.0, (viewport_size.y - float(board_size.y)) * 0.5))
	return Vector2i(start_x, start_y)

func get_side_panel_x() -> int:
	return get_board_origin().x + get_board_pixel_size().x + LAYOUT_GAP

func get_boss_panel_rect() -> Rect2:
	var board_origin: Vector2i = get_board_origin()
	var panel_width: float = float(get_content_width())
	var panel_y: float = float(max(28, board_origin.y - TOP_PANEL_HEIGHT - 24))
	return Rect2(Vector2(board_origin.x, panel_y), Vector2(panel_width, TOP_PANEL_HEIGHT))
