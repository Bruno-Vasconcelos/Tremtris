extends RefCounted
class_name CampaignTheme

## Paletas por tema visual (fundo da cena, moldura, tabuleiro, acentos UI).


static func get_palette(theme_id: String) -> Dictionary:
	match theme_id:
		"gourmet":
			return {
				"scene_outer": Color8(14, 10, 22),
				"scene_inner": Color8(22, 16, 34),
				"scene_border": Color8(120, 90, 140),
				"board_frame": Color8(32, 22, 48),
				"board_frame_line": Color8(140, 110, 168),
				"board_fill": Color8(12, 10, 24),
				"board_line": Color8(72, 58, 96),
				"boss_panel_fill": Color8(26, 18, 40),
				"boss_panel_line": Color8(150, 118, 178),
				"accent": Color8(255, 196, 120),
				"accent_dim": Color8(200, 160, 210),
			}
		"banquet":
			return {
				"scene_outer": Color8(18, 8, 10),
				"scene_inner": Color8(34, 14, 18),
				"scene_border": Color8(160, 72, 72),
				"board_frame": Color8(48, 18, 22),
				"board_frame_line": Color8(190, 96, 88),
				"board_fill": Color8(16, 8, 10),
				"board_line": Color8(96, 44, 48),
				"boss_panel_fill": Color8(40, 14, 18),
				"boss_panel_line": Color8(200, 100, 92),
				"accent": Color8(255, 214, 120),
				"accent_dim": Color8(230, 170, 150),
			}
		_:
			return {
				"scene_outer": Color8(8, 12, 18),
				"scene_inner": Color8(12, 18, 28),
				"scene_border": Color8(46, 62, 82),
				"board_frame": Color8(18, 24, 34),
				"board_frame_line": Color8(88, 106, 126),
				"board_fill": Color8(10, 16, 24),
				"board_line": Color8(58, 76, 98),
				"boss_panel_fill": Color8(18, 24, 34),
				"boss_panel_line": Color8(88, 106, 126),
				"accent": Color8(255, 200, 120),
				"accent_dim": Color8(180, 205, 225),
			}


static func get_act_music_path(act_index: int) -> String:
	return "res://audio/act_%d.ogg" % act_index
