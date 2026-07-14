extends RefCounted
class_name CampaignTheme

## Paletas por tema visual (fundo da cena, moldura, tabuleiro, acentos UI).


static func get_palette(theme_id: String) -> Dictionary:
	match theme_id:
		"gourmet":
			# Ato 2 — salao gourmet: verde-esmeralda elegante com dourado.
			return {
				"scene_outer": Color8(12, 22, 20),
				"scene_inner": Color8(16, 30, 27),
				"scene_border": Color8(78, 146, 120),
				"board_frame": Color8(20, 38, 33),
				"board_frame_line": Color8(96, 166, 138),
				"board_fill": Color8(9, 17, 15),
				"board_line": Color8(48, 86, 74),
				"boss_panel_fill": Color8(18, 34, 29),
				"boss_panel_line": Color8(104, 172, 144),
				"accent": Color8(242, 208, 122),
				"accent_dim": Color8(176, 214, 192),
			}
		"banquet":
			# Ato 3 — banquete final: bordo profundo com brasa e dourado.
			return {
				"scene_outer": Color8(24, 10, 12),
				"scene_inner": Color8(36, 15, 18),
				"scene_border": Color8(176, 82, 72),
				"board_frame": Color8(48, 18, 22),
				"board_frame_line": Color8(200, 102, 88),
				"board_fill": Color8(18, 8, 10),
				"board_line": Color8(98, 46, 48),
				"boss_panel_fill": Color8(42, 16, 20),
				"boss_panel_line": Color8(208, 106, 92),
				"accent": Color8(255, 200, 108),
				"accent_dim": Color8(236, 176, 156),
			}
		_:
			# Ato 1 — bistro da esquina: madeira quente, creme e ambar.
			return {
				"scene_outer": Color8(24, 18, 13),
				"scene_inner": Color8(35, 27, 20),
				"scene_border": Color8(126, 90, 56),
				"board_frame": Color8(41, 31, 22),
				"board_frame_line": Color8(154, 112, 70),
				"board_fill": Color8(18, 14, 11),
				"board_line": Color8(72, 55, 40),
				"boss_panel_fill": Color8(38, 28, 20),
				"boss_panel_line": Color8(150, 110, 70),
				"accent": Color8(255, 190, 96),
				"accent_dim": Color8(216, 182, 150),
			}


static func get_act_music_path(act_index: int) -> String:
	return "res://audio/act_%d.ogg" % act_index
