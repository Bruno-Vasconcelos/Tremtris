extends Control

const MAIN_MENU_SCENE := "res://scenes/main_menu.tscn"
const GAME_SCENE := "res://scenes/main.tscn"

const ACT_NAMES := ["Ato 1 — Bistrô", "Ato 2 — Salão gourmet", "Ato 3 — Banquete final"]
const STAGES_PER_ACT := 5

@onready var _stage_list: VBoxContainer = %StageList


func _ready() -> void:
	_apply_theme()
	_refresh_test_mode_label()
	_build_stage_list()
	%BackButton.pressed.connect(_on_back_pressed)


func _refresh_test_mode_label() -> void:
	var subtitle := %SubtitleLabel as Label
	if CampaignSave.TEST_UNLOCK_ALL_STAGES:
		subtitle.text = "Modo teste: todas as fases desbloqueadas."
	else:
		subtitle.text = "Fases bloqueadas aparecem acinzentadas."


func _apply_theme() -> void:
	var pal: Dictionary = CampaignTheme.get_palette("bistro")
	var panel := %PanelContainer as PanelContainer
	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = pal.get("scene_inner", Color8(12, 18, 28))
	panel_style.border_color = pal.get("scene_border", Color8(46, 62, 82))
	panel_style.set_border_width_all(2)
	panel_style.set_corner_radius_all(8)
	panel_style.content_margin_left = 32
	panel_style.content_margin_right = 32
	panel_style.content_margin_top = 28
	panel_style.content_margin_bottom = 28
	panel.add_theme_stylebox_override("panel", panel_style)

	(%TitleLabel as Label).add_theme_color_override("font_color", Color8(242, 236, 226))
	(%SubtitleLabel as Label).add_theme_color_override("font_color", Color8(180, 205, 225))
	_style_menu_button(%BackButton, pal.get("accent", Color8(255, 200, 120)))


func _style_menu_button(button: Button, accent: Color) -> void:
	var normal := StyleBoxFlat.new()
	normal.bg_color = Color8(18, 24, 34)
	normal.border_color = Color8(88, 106, 126)
	normal.set_border_width_all(2)
	normal.set_corner_radius_all(6)
	normal.content_margin_top = 10
	normal.content_margin_bottom = 10

	var hover := normal.duplicate() as StyleBoxFlat
	hover.border_color = accent
	hover.bg_color = Color8(24, 32, 44)

	button.add_theme_stylebox_override("normal", normal)
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_stylebox_override("pressed", hover)
	button.add_theme_color_override("font_color", Color8(242, 236, 226))
	button.add_theme_font_size_override("font_size", 20)


func _build_stage_list() -> void:
	for child in _stage_list.get_children():
		child.queue_free()

	var accent: Color = CampaignTheme.get_palette("bistro").get("accent", Color8(255, 200, 120))

	for act in range(ACT_NAMES.size()):
		var act_label := Label.new()
		act_label.text = ACT_NAMES[act]
		act_label.add_theme_color_override("font_color", Color8(196, 212, 224))
		act_label.add_theme_font_size_override("font_size", 18)
		_stage_list.add_child(act_label)

		var row := GridContainer.new()
		row.columns = STAGES_PER_ACT
		row.add_theme_constant_override("h_separation", 12)
		row.add_theme_constant_override("v_separation", 12)
		_stage_list.add_child(row)

		for slot in range(STAGES_PER_ACT):
			var stage_index: int = act * STAGES_PER_ACT + slot
			if stage_index >= StageLibrary.count():
				break
			row.add_child(_make_stage_button(stage_index, accent))

		var spacer := Control.new()
		spacer.custom_minimum_size = Vector2(0, 8)
		_stage_list.add_child(spacer)


func _make_stage_button(stage_index: int, accent: Color) -> Button:
	var unlocked := CampaignSave.is_stage_unlocked(stage_index)
	var button := Button.new()
	button.custom_minimum_size = Vector2(140, 52)
	button.disabled = not unlocked

	var label := "Fase %d" % (stage_index + 1)
	if StageLibrary.is_boss_stage(stage_index):
		var boss_name: String = StageLibrary.get_boss_display_name(stage_index)
		if boss_name != "":
			label += "\nBOSS: %s" % boss_name
		else:
			label += "\nBOSS"
	button.text = label
	button.add_theme_font_size_override("font_size", 14)

	var normal := StyleBoxFlat.new()
	normal.bg_color = Color8(18, 24, 34) if unlocked else Color8(14, 18, 24)
	normal.border_color = Color8(88, 106, 126) if unlocked else Color8(44, 54, 68)
	normal.set_border_width_all(2)
	normal.set_corner_radius_all(6)
	normal.content_margin_top = 6
	normal.content_margin_bottom = 6

	var hover := normal.duplicate() as StyleBoxFlat
	hover.border_color = accent
	hover.bg_color = Color8(24, 32, 44)

	button.add_theme_stylebox_override("normal", normal)
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_stylebox_override("pressed", hover)
	button.add_theme_stylebox_override("disabled", normal)
	button.add_theme_color_override("font_color", Color8(242, 236, 226))
	button.add_theme_color_override("font_disabled_color", Color8(90, 100, 112))
	button.modulate.a = 1.0 if unlocked else 0.45

	if unlocked:
		button.pressed.connect(_on_stage_pressed.bind(stage_index))

	return button


func _on_stage_pressed(stage_index: int) -> void:
	if not CampaignSave.is_stage_unlocked(stage_index):
		return
	GameSession.set_stage_select(stage_index)
	get_tree().change_scene_to_file(GAME_SCENE)


func _on_back_pressed() -> void:
	get_tree().change_scene_to_file(MAIN_MENU_SCENE)
