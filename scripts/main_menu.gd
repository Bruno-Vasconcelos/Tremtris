extends Control

const GAME_SCENE := "res://scenes/main.tscn"
const STAGE_SELECT_SCENE := "res://scenes/stage_select.tscn"

@onready var _continue_button: Button = %ContinueButton
@onready var _progress_label: Label = %ProgressLabel


func _ready() -> void:
	_apply_theme()
	_refresh_progress_ui()
	_continue_button.pressed.connect(_on_continue_pressed)


func _apply_theme() -> void:
	var pal: Dictionary = CampaignTheme.get_palette("bistro")
	var outer: Color = pal.get("scene_outer", Color8(8, 12, 18))
	var accent: Color = pal.get("accent", Color8(255, 200, 120))
	var label_color: Color = pal.get("accent_dim", Color8(180, 205, 225))

	var panel := %PanelContainer as PanelContainer
	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = pal.get("scene_inner", Color8(12, 18, 28))
	panel_style.border_color = pal.get("scene_border", Color8(46, 62, 82))
	panel_style.set_border_width_all(2)
	panel_style.set_corner_radius_all(8)
	panel_style.content_margin_left = 48
	panel_style.content_margin_right = 48
	panel_style.content_margin_top = 40
	panel_style.content_margin_bottom = 40
	panel.add_theme_stylebox_override("panel", panel_style)

	var title := %TitleLabel as Label
	title.add_theme_color_override("font_color", Color8(242, 236, 226))
	_progress_label.add_theme_color_override("font_color", label_color)

	for button in [%NewGameButton, _continue_button, %StageSelectButton, %QuitButton]:
		_style_menu_button(button as Button, accent, outer)


func _style_menu_button(button: Button, accent: Color, outer: Color) -> void:
	var normal := StyleBoxFlat.new()
	normal.bg_color = Color8(18, 24, 34)
	normal.border_color = Color8(88, 106, 126)
	normal.set_border_width_all(2)
	normal.set_corner_radius_all(6)
	normal.content_margin_top = 12
	normal.content_margin_bottom = 12

	var hover := normal.duplicate() as StyleBoxFlat
	hover.border_color = accent
	hover.bg_color = Color8(24, 32, 44)

	var disabled := normal.duplicate() as StyleBoxFlat
	disabled.bg_color = Color8(14, 18, 24)
	disabled.border_color = Color8(44, 54, 68)

	button.add_theme_stylebox_override("normal", normal)
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_stylebox_override("pressed", hover)
	button.add_theme_stylebox_override("disabled", disabled)
	button.add_theme_color_override("font_color", Color8(242, 236, 226))
	button.add_theme_color_override("font_disabled_color", Color8(90, 100, 112))
	button.add_theme_font_size_override("font_size", 22)


func _refresh_progress_ui() -> void:
	if CampaignSave.has_progress():
		var stage_idx: int = CampaignSave.load_stage_index()
		_progress_label.text = "Ultima fase: %s" % StageLibrary.get_stage_label(stage_idx)
		_continue_button.disabled = false
		_continue_button.text = "Carregar ultima fase"
	else:
		_progress_label.text = "Nenhum progresso salvo"
		_continue_button.disabled = true
		_continue_button.text = "Carregar ultima fase (sem save)"


func _on_new_game_pressed() -> void:
	GameSession.set_new_game()
	get_tree().change_scene_to_file(GAME_SCENE)


func _on_continue_pressed() -> void:
	if not CampaignSave.has_progress():
		return
	GameSession.set_continue()
	get_tree().change_scene_to_file(GAME_SCENE)


func _on_stage_select_pressed() -> void:
	get_tree().change_scene_to_file(STAGE_SELECT_SCENE)


func _on_quit_pressed() -> void:
	get_tree().quit()
