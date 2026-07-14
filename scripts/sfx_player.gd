extends Node

## Autoload "Sfx": efeitos sonoros de cozinha sintetizados por codigo.
## Os buffers sao gerados uma unica vez no boot (AudioStreamWAV) e reproduzidos
## por um pool de AudioStreamPlayer. Sem arquivos externos; se algo falhar na
## geracao, o jogo simplesmente fica em silencio (fallback seguro).

const MIX_RATE := 44100
const POOL_SIZE := 10
const MASTER_VOLUME_DB := -7.0

var _players: Array[AudioStreamPlayer] = []
var _next_player := 0
var _catalog: Dictionary = {}
var _rng := RandomNumberGenerator.new()
var _enabled := true


func _ready() -> void:
	_rng.randomize()
	_build_pool()
	_build_catalog()


func _build_pool() -> void:
	var bus := _resolve_bus()
	for pool_slot in range(POOL_SIZE):
		var player := AudioStreamPlayer.new()
		player.name = "SfxVoice%d" % pool_slot
		player.bus = bus
		player.volume_db = MASTER_VOLUME_DB
		add_child(player)
		_players.append(player)


func _resolve_bus() -> String:
	if AudioServer.get_bus_index("SFX") != -1:
		return "SFX"
	return "Master"


## Toca um som do catalogo. `pitch_variation` (0..1) aplica leve variacao
## aleatoria de tom para os sons repetitivos nao soarem mecanicos.
func play(sound_name: String, pitch_variation := 0.0) -> void:
	if not _enabled or _players.is_empty():
		return
	var stream: AudioStreamWAV = _catalog.get(sound_name, null)
	if stream == null:
		return
	var player := _players[_next_player]
	_next_player = (_next_player + 1) % _players.size()
	player.stream = stream
	if pitch_variation > 0.0:
		player.pitch_scale = 1.0 + (_rng.randf() * 2.0 - 1.0) * pitch_variation
	else:
		player.pitch_scale = 1.0
	player.play()


# --- Catalogo -------------------------------------------------------------

func _build_catalog() -> void:
	_catalog = {
		"move": _make_stream(_synth_move()),
		"rotate": _make_stream(_synth_rotate()),
		"soft_drop": _make_stream(_synth_soft_drop()),
		"hard_drop": _make_stream(_synth_hard_drop()),
		"lock": _make_stream(_synth_lock()),
		"line": _make_stream(_synth_chop()),
		"tetris": _make_stream(_synth_tetris()),
		"order_bell": _make_stream(_synth_bell()),
		"cleaner": _make_stream(_synth_cleaner()),
		"freezer": _make_stream(_synth_freezer()),
		"grease": _make_stream(_synth_grease()),
		"boss_hit": _make_stream(_synth_boss_hit()),
		"stage_clear": _make_stream(_synth_stage_clear()),
		"game_over": _make_stream(_synth_game_over()),
		"menu_move": _make_stream(_synth_menu_move()),
		"menu_confirm": _make_stream(_synth_menu_confirm()),
	}


# --- Sintese --------------------------------------------------------------

func _samples(seconds: float) -> PackedFloat32Array:
	var buf := PackedFloat32Array()
	buf.resize(int(seconds * MIX_RATE))
	return buf


func _add_tone(
	buf: PackedFloat32Array,
	freq: float,
	start: float,
	dur: float,
	amp: float,
	decay: float,
	wave := "sine"
) -> void:
	var start_i := int(start * MIX_RATE)
	var count := int(dur * MIX_RATE)
	for i in range(count):
		var idx := start_i + i
		if idx < 0 or idx >= buf.size():
			continue
		var t := float(i) / float(MIX_RATE)
		var env := exp(-decay * t)
		var phase := TAU * freq * t
		var s := 0.0
		match wave:
			"square":
				s = signf(sin(phase))
			"tri":
				s = asin(sin(phase)) * (2.0 / PI)
			"saw":
				s = 2.0 * fposmod(freq * t, 1.0) - 1.0
			_:
				s = sin(phase)
		buf[idx] += s * amp * env


func _add_noise(
	buf: PackedFloat32Array, start: float, dur: float, amp: float, decay: float
) -> void:
	var start_i := int(start * MIX_RATE)
	var count := int(dur * MIX_RATE)
	for i in range(count):
		var idx := start_i + i
		if idx < 0 or idx >= buf.size():
			continue
		var t := float(i) / float(MIX_RATE)
		buf[idx] += (_rng.randf() * 2.0 - 1.0) * amp * exp(-decay * t)


## Ruido "chiado" (high-pass + modulacao de amplitude) — remete a fritura/spray.
func _add_sizzle(
	buf: PackedFloat32Array, start: float, dur: float, amp: float, decay := 6.0
) -> void:
	var start_i := int(start * MIX_RATE)
	var count := int(dur * MIX_RATE)
	var last := 0.0
	for i in range(count):
		var idx := start_i + i
		if idx < 0 or idx >= buf.size():
			continue
		var t := float(i) / float(MIX_RATE)
		var env := exp(-decay * t)
		var n := _rng.randf() * 2.0 - 1.0
		var hp := n - last
		last = n
		var modulation := 0.6 + 0.4 * sin(TAU * 32.0 * t)
		buf[idx] += hp * amp * env * modulation


func _make_stream(buf: PackedFloat32Array) -> AudioStreamWAV:
	var bytes := PackedByteArray()
	bytes.resize(buf.size() * 2)
	for i in range(buf.size()):
		var v := clampf(buf[i], -1.0, 1.0)
		bytes.encode_s16(i * 2, int(v * 32767.0))
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = MIX_RATE
	stream.stereo = false
	stream.data = bytes
	return stream


# --- Definicao de cada som ------------------------------------------------

func _synth_move() -> PackedFloat32Array:
	var buf := _samples(0.05)
	_add_tone(buf, 220.0, 0.0, 0.05, 0.22, 42.0, "square")
	return buf


func _synth_rotate() -> PackedFloat32Array:
	var buf := _samples(0.10)
	_add_tone(buf, 330.0, 0.0, 0.05, 0.20, 30.0, "tri")
	_add_tone(buf, 495.0, 0.03, 0.06, 0.16, 28.0, "tri")
	return buf


func _synth_soft_drop() -> PackedFloat32Array:
	var buf := _samples(0.06)
	_add_tone(buf, 150.0, 0.0, 0.06, 0.20, 45.0, "sine")
	return buf


func _synth_hard_drop() -> PackedFloat32Array:
	var buf := _samples(0.20)
	_add_tone(buf, 108.0, 0.0, 0.20, 0.45, 20.0, "sine")
	_add_noise(buf, 0.0, 0.06, 0.26, 42.0)
	return buf


func _synth_lock() -> PackedFloat32Array:
	var buf := _samples(0.16)
	_add_tone(buf, 130.0, 0.0, 0.08, 0.26, 32.0, "sine")
	_add_sizzle(buf, 0.0, 0.16, 0.16, 9.0)
	return buf


func _synth_chop() -> PackedFloat32Array:
	var buf := _samples(0.12)
	_add_noise(buf, 0.0, 0.05, 0.28, 55.0)
	_add_tone(buf, 400.0, 0.0, 0.05, 0.18, 45.0, "tri")
	return buf


func _synth_tetris() -> PackedFloat32Array:
	var buf := _samples(0.55)
	_add_sizzle(buf, 0.0, 0.45, 0.28, 5.0)
	_add_tone(buf, 523.25, 0.0, 0.15, 0.18, 8.0, "tri")
	_add_tone(buf, 659.25, 0.08, 0.18, 0.18, 8.0, "tri")
	_add_tone(buf, 783.99, 0.16, 0.28, 0.20, 6.0, "tri")
	return buf


func _synth_bell() -> PackedFloat32Array:
	var buf := _samples(0.70)
	_add_tone(buf, 880.0, 0.0, 0.70, 0.28, 5.0, "sine")
	_add_tone(buf, 1760.0, 0.0, 0.50, 0.11, 7.0, "sine")
	_add_tone(buf, 2637.0, 0.0, 0.30, 0.05, 10.0, "sine")
	return buf


func _synth_cleaner() -> PackedFloat32Array:
	var buf := _samples(0.35)
	_add_sizzle(buf, 0.0, 0.35, 0.26, 4.0)
	return buf


func _synth_freezer() -> PackedFloat32Array:
	# Brilho gelido descendo: tons agudos com decaimento em glissando.
	var buf := _samples(0.5)
	_add_tone(buf, 1568.0, 0.0, 0.30, 0.16, 6.0, "sine")
	_add_tone(buf, 1244.0, 0.08, 0.30, 0.15, 6.0, "sine")
	_add_tone(buf, 988.0, 0.16, 0.34, 0.15, 5.0, "sine")
	_add_tone(buf, 784.0, 0.24, 0.40, 0.16, 4.0, "sine")
	return buf


func _synth_grease() -> PackedFloat32Array:
	# Borbulhar grave e untuoso quando a gordura sobe.
	var buf := _samples(0.4)
	_add_tone(buf, 96.0, 0.0, 0.4, 0.30, 8.0, "sine")
	_add_sizzle(buf, 0.05, 0.30, 0.16, 7.0)
	return buf


func _synth_boss_hit() -> PackedFloat32Array:
	var buf := _samples(0.30)
	_add_tone(buf, 90.0, 0.0, 0.30, 0.42, 12.0, "square")
	_add_noise(buf, 0.0, 0.10, 0.26, 30.0)
	return buf


func _synth_stage_clear() -> PackedFloat32Array:
	var buf := _samples(0.95)
	var notes := [523.25, 659.25, 783.99, 1046.5]
	for i in range(notes.size()):
		_add_tone(buf, float(notes[i]), float(i) * 0.12, 0.5, 0.24, 4.0, "tri")
	return buf


func _synth_game_over() -> PackedFloat32Array:
	var buf := _samples(0.95)
	var notes := [392.0, 329.63, 261.63, 196.0]
	for i in range(notes.size()):
		_add_tone(buf, float(notes[i]), float(i) * 0.16, 0.5, 0.26, 3.5, "tri")
	return buf


func _synth_menu_move() -> PackedFloat32Array:
	var buf := _samples(0.05)
	_add_tone(buf, 440.0, 0.0, 0.05, 0.18, 40.0, "sine")
	return buf


func _synth_menu_confirm() -> PackedFloat32Array:
	var buf := _samples(0.22)
	_add_tone(buf, 523.25, 0.0, 0.10, 0.22, 12.0, "tri")
	_add_tone(buf, 783.99, 0.08, 0.14, 0.22, 10.0, "tri")
	return buf
