extends RefCounted
class_name CampaignSave

const SAVE_PATH := "user://chef_campaign_save.cfg"
const SECTION := "campaign"
const KEY_STAGE := "stage_index"
const KEY_HAS_PROGRESS := "has_progress"
const KEY_HIGHEST_UNLOCKED := "highest_unlocked_stage"
const KEY_CLEANER_UNLOCKED := "cleaner_unlocked"

## Desbloqueia todas as fases no seletor e o produto de limpeza (testes).
const TEST_UNLOCK_ALL_STAGES := true


static func _max_stage_index() -> int:
	return maxi(StageLibrary.count() - 1, 0)


static func _load_cfg() -> ConfigFile:
	var cfg := ConfigFile.new()
	if cfg.load(SAVE_PATH) != OK:
		return null
	return cfg


static func _write_cfg(cfg: ConfigFile) -> void:
	cfg.save(SAVE_PATH)


static func has_progress() -> bool:
	var cfg := _load_cfg()
	if cfg == null:
		return false
	if cfg.has_section_key(SECTION, KEY_HAS_PROGRESS):
		return bool(cfg.get_value(SECTION, KEY_HAS_PROGRESS, false))
	# Save legado: arquivo existe com stage_index.
	return cfg.has_section_key(SECTION, KEY_STAGE)


static func load_highest_unlocked_stage() -> int:
	var cfg := _load_cfg()
	if cfg == null:
		return 0
	if cfg.has_section_key(SECTION, KEY_HIGHEST_UNLOCKED):
		return clampi(int(cfg.get_value(SECTION, KEY_HIGHEST_UNLOCKED, 0)), 0, _max_stage_index())
	# Save legado: desbloqueia até a fase salva.
	return clampi(int(cfg.get_value(SECTION, KEY_STAGE, 0)), 0, _max_stage_index())


static func is_stage_unlocked(stage_index: int) -> bool:
	if TEST_UNLOCK_ALL_STAGES:
		return true
	return stage_index <= load_highest_unlocked_stage()


static func is_cleaner_unlocked() -> bool:
	if TEST_UNLOCK_ALL_STAGES:
		return true
	var cfg := _load_cfg()
	if cfg == null:
		return false
	return bool(cfg.get_value(SECTION, KEY_CLEANER_UNLOCKED, false))


static func unlock_cleaner() -> void:
	var cfg := _load_cfg()
	if cfg == null:
		cfg = ConfigFile.new()
	cfg.set_value(SECTION, KEY_CLEANER_UNLOCKED, true)
	cfg.set_value(SECTION, KEY_HAS_PROGRESS, true)
	_write_cfg(cfg)


static func save_stage_index(stage_index: int) -> void:
	var cfg := _load_cfg()
	if cfg == null:
		cfg = ConfigFile.new()
	var clamped := clampi(stage_index, 0, _max_stage_index())
	var highest := clampi(int(cfg.get_value(SECTION, KEY_HIGHEST_UNLOCKED, 0)), 0, _max_stage_index())
	cfg.set_value(SECTION, KEY_STAGE, clamped)
	cfg.set_value(SECTION, KEY_HAS_PROGRESS, true)
	cfg.set_value(SECTION, KEY_HIGHEST_UNLOCKED, highest)
	_write_cfg(cfg)


static func load_stage_index() -> int:
	var cfg := _load_cfg()
	if cfg == null:
		return 0
	return clampi(int(cfg.get_value(SECTION, KEY_STAGE, 0)), 0, _max_stage_index())


static func update_highest_unlocked(stage_index: int) -> void:
	var cfg := _load_cfg()
	if cfg == null:
		cfg = ConfigFile.new()
	var clamped := clampi(stage_index, 0, _max_stage_index())
	var current := clampi(int(cfg.get_value(SECTION, KEY_HIGHEST_UNLOCKED, 0)), 0, _max_stage_index())
	cfg.set_value(SECTION, KEY_HIGHEST_UNLOCKED, maxi(current, clamped))
	cfg.set_value(SECTION, KEY_HAS_PROGRESS, true)
	_write_cfg(cfg)


static func begin_new_campaign() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value(SECTION, KEY_STAGE, 0)
	cfg.set_value(SECTION, KEY_HAS_PROGRESS, true)
	cfg.set_value(SECTION, KEY_HIGHEST_UNLOCKED, 0)
	cfg.set_value(SECTION, KEY_CLEANER_UNLOCKED, false)
	_write_cfg(cfg)


static func clear_save() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value(SECTION, KEY_STAGE, 0)
	cfg.set_value(SECTION, KEY_HAS_PROGRESS, false)
	cfg.set_value(SECTION, KEY_HIGHEST_UNLOCKED, 0)
	cfg.set_value(SECTION, KEY_CLEANER_UNLOCKED, false)
	_write_cfg(cfg)
