extends Node

enum StartMode {
	NEW_GAME,
	CONTINUE,
	STAGE_SELECT,
}

var start_mode: StartMode = StartMode.NEW_GAME
var selected_stage_index: int = 0


func set_new_game() -> void:
	start_mode = StartMode.NEW_GAME
	selected_stage_index = 0


func set_continue() -> void:
	start_mode = StartMode.CONTINUE
	selected_stage_index = 0


func set_stage_select(stage_index: int) -> void:
	start_mode = StartMode.STAGE_SELECT
	selected_stage_index = stage_index
