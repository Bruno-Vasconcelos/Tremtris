extends RefCounted
class_name CampaignSave

const SAVE_PATH := "user://chef_campaign_save.cfg"
const SECTION := "campaign"
const KEY_STAGE := "stage_index"


static func _max_stage_index() -> int:
	return maxi(StageLibrary.count() - 1, 0)


static func save_stage_index(stage_index: int) -> void:
	var cfg := ConfigFile.new()
	cfg.set_value(SECTION, KEY_STAGE, clampi(stage_index, 0, _max_stage_index()))
	cfg.save(SAVE_PATH)


static func load_stage_index() -> int:
	var cfg := ConfigFile.new()
	if cfg.load(SAVE_PATH) != OK:
		return 0
	return clampi(int(cfg.get_value(SECTION, KEY_STAGE, 0)), 0, _max_stage_index())


static func clear_save() -> void:
	save_stage_index(0)
