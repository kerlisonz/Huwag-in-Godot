extends RefCounted
class_name CombatSfx

const MIX_RATE := 22050
static var _cache: Dictionary = {}


static func play(host: Node, sfx_name: String, volume_db: float = -2.0, pitch_min: float = 0.94, pitch_max: float = 1.05) -> void:
	if host == null or not host.is_inside_tree():
		return
	var stream := _get_or_build_stream(sfx_name)
	if stream == null:
		return
	var player := AudioStreamPlayer.new()
	player.stream = stream
	player.volume_db = volume_db
	player.pitch_scale = randf_range(pitch_min, pitch_max)
	player.bus = "SFX" if AudioServer.get_bus_index("SFX") != -1 else "Master"
	host.get_tree().root.add_child(player)
	player.finished.connect(player.queue_free)
	player.play()


static func _get_or_build_stream(sfx_name: String) -> AudioStreamWAV:
	if _cache.has(sfx_name):
		return _cache[sfx_name] as AudioStreamWAV

	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = MIX_RATE
	wav.stereo = false

	var samples := PackedByteArray()
	match sfx_name:
		"swing_miss", "axe_swing_1":
			samples = _synth_axe_swing(0.18, 280.0, 92.0, 2100.0, 440.0, 1480.0, 104729, 0.86)
		"axe_swing_2":
			samples = _synth_axe_swing(0.17, 330.0, 112.0, 2500.0, 520.0, 1740.0, 208411, 0.90)
		"axe_swing_3":
			samples = _synth_axe_swing(0.24, 235.0, 62.0, 1850.0, 290.0, 1220.0, 319907, 0.95)
		"melee_hit":
			samples = _synth_melee_hit(false)
		"melee_hit_heavy":
			samples = _synth_melee_hit(true)
		"water_cast":
			samples = _synth_water_cast()
		"player_hurt":
			samples = _synth_player_hurt()
		_:
			samples = _synth_axe_swing(0.18, 280.0, 92.0, 2100.0, 440.0, 1480.0, 104729, 0.86)

	wav.data = samples
	_cache[sfx_name] = wav
	return wav


static func _synth_axe_swing(
	duration: float,
	body_f0: float,
	body_f1: float,
	air_f0: float,
	air_f1: float,
	steel_freq: float,
	seed_val: int,
	gain: float
) -> PackedByteArray:
	## Síntese procedural de golpe de machado:
	## 1) Corte de ar (bandpass sweep de ruído branco cortando de alta para média frequência)
	## 2) Peso do cabo/lâmina (varredura grave-média de corpo)
	## 3) Brilho metálico curto de aço no ápice do arco
	var count := int(duration * float(MIX_RATE))
	var bytes := PackedByteArray()
	bytes.resize(count * 2)
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_val

	var body_phase := 0.0
	var steel_phase1 := 0.0
	var steel_phase2 := 0.0
	var lp_hi := 0.0
	var lp_lo := 0.0

	for i in range(count):
		var t := float(i) / float(count)
		# Envelope rápido com pico de aceleração aos ~28% do arco (ataque cortante do machado)
		var attack := clampf(t / 0.22, 0.0, 1.0)
		var release := pow(1.0 - maxf(0.0, (t - 0.22) / 0.78), 1.45)
		var whoosh_env := pow(attack, 0.75) * release

		# Corte de ar em faixa (diferença de dois filtros 1-polo gera bandpass dinâmico)
		var noise := rng.randf_range(-1.0, 1.0)
		var fc_hi := lerpf(air_f0, air_f1, pow(t, 0.65))
		var fc_lo := fc_hi * 0.34
		var a_hi := clampf(TAU * fc_hi / (TAU * fc_hi + float(MIX_RATE)), 0.02, 0.85)
		var a_lo := clampf(TAU * fc_lo / (TAU * fc_lo + float(MIX_RATE)), 0.01, 0.70)
		lp_hi += a_hi * (noise - lp_hi)
		lp_lo += a_lo * (noise - lp_lo)
		var air_cut := (lp_hi - lp_lo) * 2.25

		# Corpo pesado da lâmina girando
		var body_freq := lerpf(body_f0, body_f1, pow(t, 0.58))
		body_phase += TAU * body_freq / float(MIX_RATE)
		var body_wave := (sin(body_phase) * 0.72 + sin(body_phase * 2.0) * 0.28) * pow(1.0 - t, 0.9)

		# Cintilação metálica curta no pico do golpe
		var steel_t := absf(t - 0.24)
		var steel_env := exp(-steel_t * 36.0)
		steel_phase1 += TAU * steel_freq / float(MIX_RATE)
		steel_phase2 += TAU * (steel_freq * 1.53) / float(MIX_RATE)
		var steel_wave := (sin(steel_phase1) * 0.6 + sin(steel_phase2) * 0.4) * steel_env * 0.28

		var raw := (air_cut * 0.68 + body_wave * 0.48 + steel_wave) * whoosh_env * gain
		var sig := clampf(tanh(raw * 1.35), -0.96, 0.96)
		_write_s16(bytes, i, sig)
	return bytes


static func _synth_melee_hit(heavy: bool) -> PackedByteArray:
	## Impacto pesado da lâmina do machado: estalo inicial + soco grave + mordida metálica
	var duration := 0.22 if heavy else 0.16
	var count := int(duration * float(MIX_RATE))
	var bytes := PackedByteArray()
	bytes.resize(count * 2)
	var rng := RandomNumberGenerator.new()
	rng.seed = 448913 if heavy else 339817

	var body_phase := 0.0
	var bite_phase := 0.0
	var ring_phase := 0.0
	var lp := 0.0

	for i in range(count):
		var t := float(i) / float(count)
		var env := pow(1.0 - t, 1.75 if heavy else 2.0)

		var f0 := 185.0 if heavy else 210.0
		var f1 := 38.0 if heavy else 50.0
		body_phase += TAU * lerpf(f0, f1, pow(t, 0.48)) / float(MIX_RATE)
		var thump := (sin(body_phase) * 0.80 + sin(body_phase * 1.5) * 0.25) * env

		# Estalo seco do impacto (transiente rápido)
		var crack_env := exp(-t * (22.0 if heavy else 30.0))
		var noise := rng.randf_range(-1.0, 1.0)
		lp += 0.36 * (noise - lp)
		var crack := lp * crack_env * 1.15

		# Mordida metálica da lâmina
		bite_phase += TAU * lerpf(980.0, 340.0, pow(t, 0.6)) / float(MIX_RATE)
		ring_phase += TAU * (1360.0 if heavy else 1540.0) / float(MIX_RATE)
		var blade := sin(bite_phase) * exp(-t * 16.0) * 0.34 + sin(ring_phase) * exp(-t * (11.0 if heavy else 20.0)) * (0.28 if heavy else 0.16)

		var raw := (thump * 0.85 + crack * 0.72 + blade) * (0.96 if heavy else 0.88)
		var sig := clampf(tanh(raw * 1.45), -0.96, 0.96)
		_write_s16(bytes, i, sig)
	return bytes


static func _synth_water_cast() -> PackedByteArray:
	var duration := 0.22
	var count := int(duration * float(MIX_RATE))
	var bytes := PackedByteArray()
	bytes.resize(count * 2)
	var phase := 0.0
	var rng := RandomNumberGenerator.new()
	rng.seed = 819203
	var bp := 0.0
	for i in range(count):
		var t := float(i) / float(count)
		var env := sin(t * PI)
		var bubble_mod := sin(t * TAU * 8.0) * 28.0
		var freq := lerpf(175.0, 240.0, t) + bubble_mod
		phase += TAU * freq / float(MIX_RATE)
		var noise := rng.randf_range(-1.0, 1.0)
		bp = lerpf(bp, noise, 0.14)
		var sig := (sin(phase) * 0.45 + bp * 0.45) * env * 0.50
		_write_s16(bytes, i, sig)
	return bytes


static func _synth_player_hurt() -> PackedByteArray:
	var duration := 0.17
	var count := int(duration * float(MIX_RATE))
	var bytes := PackedByteArray()
	bytes.resize(count * 2)
	var phase := 0.0
	for i in range(count):
		var t := float(i) / float(count)
		var env := pow(1.0 - t, 1.8)
		var freq := lerpf(165.0, 58.0, t)
		phase += TAU * freq / float(MIX_RATE)
		var sig := tanh(sin(phase) * 1.8) * env * 0.62
		_write_s16(bytes, i, sig)
	return bytes


static func _write_s16(bytes: PackedByteArray, idx: int, sample: float) -> void:
	var v := clampi(int(sample * 32767.0), -32768, 32767)
	if v < 0:
		v += 65536
	bytes[idx * 2] = v & 0xFF
	bytes[idx * 2 + 1] = (v >> 8) & 0xFF
