extends Node

# AudioManager - Sistema de Áudio Autoral de Huwag
# Síntese procedural nativa em GDScript (PCM 16-bit WAV, 22050 Hz)
# Zero dependências externas proprietárias, volume balanceado e transições suaves.

const MIX_RATE := 22050

var _bgm_player: AudioStreamPlayer
var _ambience_player: AudioStreamPlayer
var _sfx_players: Array[AudioStreamPlayer] = []
var _cache: Dictionary = {}

var master_volume: float = 1.0
var music_volume: float = 0.8
var sfx_volume: float = 0.9

var _current_bgm_track: String = ""
var _current_ambience_track: String = ""

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

	# Configura AudioStreamPlayers dedicados
	_bgm_player = AudioStreamPlayer.new()
	_bgm_player.name = "BGMPlayer"
	_bgm_player.bus = "Master"
	add_child(_bgm_player)

	_ambience_player = AudioStreamPlayer.new()
	_ambience_player.name = "AmbiencePlayer"
	_ambience_player.bus = "Master"
	add_child(_ambience_player)

	# Pool de players para SFX simultâneos
	for i in range(8):
		var p := AudioStreamPlayer.new()
		p.name = "SFXPlayer_%d" % i
		p.bus = "Master"
		add_child(p)
		_sfx_players.append(p)

	_update_volumes()

func set_volumes(master: float, music: float, sfx: float) -> void:
	master_volume = clampf(master, 0.0, 1.0)
	music_volume = clampf(music, 0.0, 1.0)
	sfx_volume = clampf(sfx, 0.0, 1.0)
	_update_volumes()

func _update_volumes() -> void:
	if _bgm_player:
		_bgm_player.volume_db = _linear_to_db(master_volume * music_volume)
	if _ambience_player:
		_ambience_player.volume_db = _linear_to_db(master_volume * music_volume * 0.75)

func _linear_to_db(linear: float) -> float:
	if linear <= 0.001:
		return -80.0
	return 20.0 * log(linear) / log(10.0)

# --- REPRODUÇÃO DE MÚSICA E AMBIÊNCIA ---

func play_bgm(track_name: String, fade_duration: float = 1.0) -> void:
	if _current_bgm_track == track_name and _bgm_player.playing:
		return
	_current_bgm_track = track_name

	if track_name == "" or track_name == "none":
		if _bgm_player.playing:
			var tw := create_tween()
			tw.tween_property(_bgm_player, "volume_db", -80.0, fade_duration)
			tw.tween_callback(_bgm_player.stop)
		return

	var stream := _get_stream(track_name)
	if stream == null:
		return

	if _bgm_player.playing and fade_duration > 0.1:
		var tw := create_tween()
		tw.tween_property(_bgm_player, "volume_db", -80.0, fade_duration * 0.5)
		tw.tween_callback(func():
			_bgm_player.stream = stream
			_bgm_player.play()
			var tw_in := create_tween()
			tw_in.tween_property(_bgm_player, "volume_db", _linear_to_db(master_volume * music_volume), fade_duration * 0.5)
		)
	else:
		_bgm_player.stream = stream
		_bgm_player.volume_db = _linear_to_db(master_volume * music_volume)
		_bgm_player.play()

func play_ambience(track_name: String, fade_duration: float = 1.5) -> void:
	if _current_ambience_track == track_name and _ambience_player.playing:
		return
	_current_ambience_track = track_name

	if track_name == "" or track_name == "none":
		if _ambience_player.playing:
			var tw := create_tween()
			tw.tween_property(_ambience_player, "volume_db", -80.0, fade_duration)
			tw.tween_callback(_ambience_player.stop)
		return

	var stream := _get_stream(track_name)
	if stream == null:
		return

	_ambience_player.stream = stream
	_ambience_player.volume_db = _linear_to_db(master_volume * music_volume * 0.75)
	_ambience_player.play()

func play_sfx(sfx_name: String, volume_mult: float = 1.0, pitch_scale: float = 1.0) -> void:
	var stream := _get_stream(sfx_name)
	if stream == null:
		return

	# Busca um player livre no pool
	var player: AudioStreamPlayer = null
	for p in _sfx_players:
		if not p.playing:
			player = p
			break
	if player == null:
		player = _sfx_players[0]

	player.stream = stream
	player.pitch_scale = pitch_scale
	player.volume_db = _linear_to_db(master_volume * sfx_volume * volume_mult)
	player.play()

# --- SÍNTESE PROCEDURAL DE ÁUDIO (16-BIT PCM WAV) ---

func _get_stream(name: String) -> AudioStreamWAV:
	if _cache.has(name):
		return _cache[name] as AudioStreamWAV

	var stream: AudioStreamWAV = null
	match name:
		# Interface e Diálogo
		"ui_hover":
			stream = _synth_ui_hover()
		"ui_select":
			stream = _synth_ui_select()
		"ui_back":
			stream = _synth_ui_back()
		"ui_dialogue":
			stream = _synth_dialogue_blip()
		"save_chime":
			stream = _synth_save_chime()

		# Gameplay e Combate
		"step":
			stream = _synth_footstep()
		"swing_miss":
			stream = _synth_swing_miss()
		"melee_hit":
			stream = _synth_melee_hit()
		"water_cast":
			stream = _synth_water_cast()
		"player_hurt":
			stream = _synth_player_hurt()
		"extinguish":
			stream = _synth_extinguish()
		"santelmo_cry":
			stream = _synth_santelmo_cry()
		"vhs_glitch":
			stream = _synth_vhs_glitch()

		# Trilhas Sonoras e Ambiências em Loop
		"title_theme":
			stream = _synth_title_drone()
		"morning_ambience":
			stream = _synth_morning_ambience()
		"afternoon_ambience":
			stream = _synth_afternoon_ambience()
		"night_ambience":
			stream = _synth_night_ambience()
		"act3_ambience":
			stream = _synth_act3_ambience()
		"vhs_memory_bgm":
			stream = _synth_vhs_memory_bgm()
		"fire_hazard":
			stream = _synth_fire_hazard()

	if stream != null:
		_cache[name] = stream
	return stream

func _create_wav(samples: PackedByteArray, loop: bool = false, loop_begin: int = 0, loop_end: int = 0) -> AudioStreamWAV:
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = MIX_RATE
	wav.stereo = false
	wav.data = samples
	if loop:
		wav.loop_mode = AudioStreamWAV.LOOP_FORWARD
		wav.loop_begin = loop_begin
		wav.loop_end = loop_end if loop_end > 0 else (samples.size() / 2)
	return wav

func _write_s16(bytes: PackedByteArray, idx: int, value: float) -> void:
	var s := clampi(int(value * 32767.0), -32768, 32767)
	var u := s if s >= 0 else 65536 + s
	var b0 := u & 0xFF
	var b1 := (u >> 8) & 0xFF
	bytes[idx * 2] = b0
	bytes[idx * 2 + 1] = b1

# --- SINTETIZADORES ESPECÍFICOS ---

func _synth_ui_hover() -> AudioStreamWAV:
	var duration := 0.04
	var count := int(duration * float(MIX_RATE))
	var bytes := PackedByteArray()
	bytes.resize(count * 2)
	for i in range(count):
		var t := float(i) / float(count)
		var env := sin(t * PI)
		var freq := lerpf(480.0, 620.0, t)
		var sig := sin(float(i) * TAU * freq / float(MIX_RATE)) * env * 0.25
		_write_s16(bytes, i, sig)
	return _create_wav(bytes)

func _synth_ui_select() -> AudioStreamWAV:
	var duration := 0.12
	var count := int(duration * float(MIX_RATE))
	var bytes := PackedByteArray()
	bytes.resize(count * 2)
	for i in range(count):
		var t := float(i) / float(count)
		var env := pow(1.0 - t, 2.0)
		var freq := 880.0 if t < 0.3 else 1320.0
		var sig := (sin(float(i) * TAU * freq / float(MIX_RATE)) * 0.7 + sin(float(i) * TAU * freq * 1.5 / float(MIX_RATE)) * 0.3) * env * 0.4
		_write_s16(bytes, i, sig)
	return _create_wav(bytes)

func _synth_ui_back() -> AudioStreamWAV:
	var duration := 0.08
	var count := int(duration * float(MIX_RATE))
	var bytes := PackedByteArray()
	bytes.resize(count * 2)
	for i in range(count):
		var t := float(i) / float(count)
		var env := pow(1.0 - t, 1.8)
		var freq := lerpf(520.0, 310.0, t)
		var sig := sin(float(i) * TAU * freq / float(MIX_RATE)) * env * 0.3
		_write_s16(bytes, i, sig)
	return _create_wav(bytes)

func _synth_dialogue_blip() -> AudioStreamWAV:
	var duration := 0.035
	var count := int(duration * float(MIX_RATE))
	var bytes := PackedByteArray()
	bytes.resize(count * 2)
	for i in range(count):
		var t := float(i) / float(count)
		var env := sin(t * PI)
		var sig := sin(float(i) * TAU * 360.0 / float(MIX_RATE)) * env * 0.18
		_write_s16(bytes, i, sig)
	return _create_wav(bytes)

func _synth_save_chime() -> AudioStreamWAV:
	var duration := 0.6
	var count := int(duration * float(MIX_RATE))
	var bytes := PackedByteArray()
	bytes.resize(count * 2)
	for i in range(count):
		var t := float(i) / float(count)
		var env := pow(1.0 - t, 1.5)
		var s1 := sin(float(i) * TAU * 523.25 / float(MIX_RATE)) * 0.5
		var s2 := sin(float(i) * TAU * 659.25 / float(MIX_RATE)) * 0.3
		var s3 := sin(float(i) * TAU * 783.99 / float(MIX_RATE)) * 0.2
		var sig := (s1 + s2 + s3) * env * 0.4
		_write_s16(bytes, i, sig)
	return _create_wav(bytes)

func _synth_footstep() -> AudioStreamWAV:
	var duration := 0.07
	var count := int(duration * float(MIX_RATE))
	var bytes := PackedByteArray()
	bytes.resize(count * 2)
	var rng := RandomNumberGenerator.new()
	rng.seed = 4421
	var lp := 0.0
	for i in range(count):
		var t := float(i) / float(count)
		var env := sin(t * PI)
		var n := rng.randf_range(-1.0, 1.0)
		lp = lerpf(lp, n, 0.35)
		var sig := lp * env * 0.28
		_write_s16(bytes, i, sig)
	return _create_wav(bytes)

func _synth_swing_miss() -> AudioStreamWAV:
	var duration := 0.12
	var count := int(duration * float(MIX_RATE))
	var bytes := PackedByteArray()
	bytes.resize(count * 2)
	var rng := RandomNumberGenerator.new()
	rng.seed = 104729
	var lp := 0.0
	for i in range(count):
		var t := float(i) / float(count)
		var env := sin(t * PI)
		var freq := lerpf(380.0, 140.0, t)
		var n := rng.randf_range(-1.0, 1.0)
		lp = lerpf(lp, n, 0.25)
		var sig := (sin(float(i) * TAU * freq / float(MIX_RATE)) * 0.35 + lp * 0.65) * env * 0.45
		_write_s16(bytes, i, sig)
	return _create_wav(bytes)

func _synth_melee_hit() -> AudioStreamWAV:
	var duration := 0.16
	var count := int(duration * float(MIX_RATE))
	var bytes := PackedByteArray()
	bytes.resize(count * 2)
	var rng := RandomNumberGenerator.new()
	rng.seed = 339817
	for i in range(count):
		var t := float(i) / float(count)
		var env := pow(1.0 - t, 2.2)
		var freq := lerpf(240.0, 60.0, pow(t, 0.5))
		var transient := rng.randf_range(-1.0, 1.0) * exp(-t * 30.0)
		var body := sin(float(i) * TAU * freq / float(MIX_RATE))
		var sig := clampf((body * 0.7 + transient * 0.5) * env * 0.7, -0.95, 0.95)
		_write_s16(bytes, i, sig)
	return _create_wav(bytes)

func _synth_water_cast() -> AudioStreamWAV:
	var duration := 0.28
	var count := int(duration * float(MIX_RATE))
	var bytes := PackedByteArray()
	bytes.resize(count * 2)
	var rng := RandomNumberGenerator.new()
	rng.seed = 819203
	for i in range(count):
		var t := float(i) / float(count)
		var env := sin(t * PI)
		var bubble := sin(t * TAU * 18.0) * 120.0
		var freq := lerpf(280.0, 520.0, t) + bubble
		var sig := (sin(float(i) * TAU * freq / float(MIX_RATE)) * 0.6 + rng.randf_range(-0.4, 0.4)) * env * 0.5
		_write_s16(bytes, i, sig)
	return _create_wav(bytes)

func _synth_player_hurt() -> AudioStreamWAV:
	var duration := 0.22
	var count := int(duration * float(MIX_RATE))
	var bytes := PackedByteArray()
	bytes.resize(count * 2)
	var rng := RandomNumberGenerator.new()
	rng.seed = 771239
	for i in range(count):
		var t := float(i) / float(count)
		var env := pow(1.0 - t, 1.8)
		var freq := lerpf(180.0, 80.0, t)
		var noise := rng.randf_range(-1.0, 1.0) * 0.35
		var sig := (sin(float(i) * TAU * freq / float(MIX_RATE)) * 0.65 + noise) * env * 0.6
		_write_s16(bytes, i, sig)
	return _create_wav(bytes)

func _synth_extinguish() -> AudioStreamWAV:
	var duration := 0.4
	var count := int(duration * float(MIX_RATE))
	var bytes := PackedByteArray()
	bytes.resize(count * 2)
	var rng := RandomNumberGenerator.new()
	rng.seed = 551921
	var lp := 0.0
	for i in range(count):
		var t := float(i) / float(count)
		var env := exp(-t * 4.5)
		var n := rng.randf_range(-1.0, 1.0)
		lp = lerpf(lp, n, 0.45)
		var hiss := lp * (0.8 + 0.2 * sin(t * TAU * 24.0))
		var sig := hiss * env * 0.6
		_write_s16(bytes, i, sig)
	return _create_wav(bytes)

func _synth_santelmo_cry() -> AudioStreamWAV:
	var duration := 0.35
	var count := int(duration * float(MIX_RATE))
	var bytes := PackedByteArray()
	bytes.resize(count * 2)
	var rng := RandomNumberGenerator.new()
	rng.seed = 99881
	for i in range(count):
		var t := float(i) / float(count)
		var env := sin(t * PI)
		var warble := sin(t * TAU * 14.0) * 160.0
		var freq := lerpf(680.0, 920.0, t) + warble
		var n := rng.randf_range(-0.3, 0.3)
		var sig := (sin(float(i) * TAU * freq / float(MIX_RATE)) * 0.7 + n) * env * 0.5
		_write_s16(bytes, i, sig)
	return _create_wav(bytes)

func _synth_vhs_glitch() -> AudioStreamWAV:
	var duration := 0.18
	var count := int(duration * float(MIX_RATE))
	var bytes := PackedByteArray()
	bytes.resize(count * 2)
	var rng := RandomNumberGenerator.new()
	rng.seed = 12093
	for i in range(count):
		var t := float(i) / float(count)
		var env := sin(t * PI)
		var noise := rng.randf_range(-1.0, 1.0)
		var buzz := sin(float(i) * TAU * 60.0 / float(MIX_RATE)) # 60Hz hum elétrico
		var sig := (noise * 0.7 + buzz * 0.3) * env * 0.4
		_write_s16(bytes, i, sig)
	return _create_wav(bytes)

# --- SINTETIZADORES DE AMBIÊNCIA E TRILHAS EM LOOP ---

func _synth_title_drone() -> AudioStreamWAV:
	# Drone atmosférico analógico de 6.0 segundos em loop perfeito
	var duration := 6.0
	var count := int(duration * float(MIX_RATE))
	var bytes := PackedByteArray()
	bytes.resize(count * 2)
	for i in range(count):
		var t := float(i) / float(count)
		var base1 := sin(float(i) * TAU * 55.0 / float(MIX_RATE)) # A1
		var base2 := sin(float(i) * TAU * 110.0 / float(MIX_RATE)) * 0.4 # A2
		var fifth := sin(float(i) * TAU * 82.4 / float(MIX_RATE)) * 0.35 # E2
		var beat := sin(t * TAU * 1.5) * 0.15
		var tape_hiss := sin(float(i) * 123.45) * 0.04
		var sig := (base1 + base2 + fifth + beat + tape_hiss) * 0.38
		_write_s16(bytes, i, sig)
	return _create_wav(bytes, true, 0, count)

func _synth_morning_ambience() -> AudioStreamWAV:
	# Brisa tropical matinal e leveza
	var duration := 5.0
	var count := int(duration * float(MIX_RATE))
	var bytes := PackedByteArray()
	bytes.resize(count * 2)
	var rng := RandomNumberGenerator.new()
	rng.seed = 2049
	var lp := 0.0
	for i in range(count):
		var t := float(i) / float(count)
		var wind_mod := 0.5 + 0.5 * sin(t * TAU * 0.8)
		var n := rng.randf_range(-1.0, 1.0)
		lp = lerpf(lp, n, 0.08)
		# Suave canto de pássaro periódico
		var bird := 0.0
		if fmod(t * 5.0, 1.8) < 0.12:
			var bt := fmod(t * 5.0, 1.8) / 0.12
			bird = sin(bt * TAU * lerpf(2400.0, 2900.0, bt)) * sin(bt * PI) * 0.18
		var sig := (lp * 0.6 * wind_mod + bird) * 0.3
		_write_s16(bytes, i, sig)
	return _create_wav(bytes, true, 0, count)

func _synth_afternoon_ambience() -> AudioStreamWAV:
	# Calor opressivo de fim de tarde, insetos/cigarras
	var duration := 4.5
	var count := int(duration * float(MIX_RATE))
	var bytes := PackedByteArray()
	bytes.resize(count * 2)
	for i in range(count):
		var t := float(i) / float(count)
		var cicada := sin(float(i) * TAU * 4200.0 / float(MIX_RATE)) * sin(t * TAU * 6.0) * 0.12
		var drone := sin(float(i) * TAU * 73.4 / float(MIX_RATE)) * 0.2
		var heat_pulse := sin(t * TAU * 0.5) * 0.08
		var sig := (cicada + drone + heat_pulse) * 0.35
		_write_s16(bytes, i, sig)
	return _create_wav(bytes, true, 0, count)

func _synth_night_ambience() -> AudioStreamWAV:
	# Noite de Agdangan: grilos, brisa noturna e tensão psicológica sutil
	var duration := 5.0
	var count := int(duration * float(MIX_RATE))
	var bytes := PackedByteArray()
	bytes.resize(count * 2)
	for i in range(count):
		var t := float(i) / float(count)
		var crickets := sin(float(i) * TAU * 4800.0 / float(MIX_RATE)) * (1.0 if fmod(t * 4.0, 1.0) < 0.4 else 0.0) * 0.08
		var wind := sin(float(i) * TAU * 65.0 / float(MIX_RATE)) * (0.6 + 0.4 * sin(t * TAU * 0.4)) * 0.22
		var tension := sin(float(i) * TAU * 98.0 / float(MIX_RATE)) * 0.1
		var sig := (crickets + wind + tension) * 0.35
		_write_s16(bytes, i, sig)
	return _create_wav(bytes, true, 0, count)

func _synth_act3_ambience() -> AudioStreamWAV:
	# Ato 3: Zumbido elétrico desolador, eco de fita VHS gasta e silêncio perturbador
	var duration := 5.5
	var count := int(duration * float(MIX_RATE))
	var bytes := PackedByteArray()
	bytes.resize(count * 2)
	var rng := RandomNumberGenerator.new()
	rng.seed = 6612
	for i in range(count):
		var t := float(i) / float(count)
		var hum := sin(float(i) * TAU * 60.0 / float(MIX_RATE)) * 0.28 # 60Hz hum
		var low_drone := sin(float(i) * TAU * 41.2 / float(MIX_RATE)) * 0.25 # E1 ultra-baixo
		var hiss := rng.randf_range(-0.1, 0.1) * (0.8 + 0.2 * sin(t * TAU * 3.0))
		var dissonant := sin(float(i) * TAU * 63.8 / float(MIX_RATE)) * 0.15 # Dissonância sutil batendo com 60Hz
		var sig := (hum + low_drone + hiss + dissonant) * 0.4
		_write_s16(bytes, i, sig)
	return _create_wav(bytes, true, 0, count)

func _synth_vhs_memory_bgm() -> AudioStreamWAV:
	# Melodia de caixinha de música fragmentada em 8-bit com wow/flutter de fita VHS
	var duration := 6.0
	var count := int(duration * float(MIX_RATE))
	var bytes := PackedByteArray()
	bytes.resize(count * 2)

	# Notas: D4 (293.66), F4 (349.23), A4 (440.0), C5 (523.25), Bb4 (466.16), A4 (440.0)
	var notes := [293.66, 349.23, 440.0, 523.25, 466.16, 440.0]
	var note_dur := duration / float(notes.size())

	for i in range(count):
		var t := float(i) / float(count)
		var note_idx := clampi(int(t * float(notes.size())), 0, notes.size() - 1)
		var note_t := fmod(float(i) / float(MIX_RATE), note_dur) / note_dur
		var env := exp(-note_t * 3.8)

		var wow := sin(t * TAU * 1.2) * 2.5 # Wow & flutter analógico
		var base_freq: float = notes[note_idx] + wow
		var chime := sin(float(i) * TAU * base_freq / float(MIX_RATE)) * 0.6
		var chime_oct := sin(float(i) * TAU * base_freq * 2.0 / float(MIX_RATE)) * 0.25

		var low_pad := sin(float(i) * TAU * 73.41 / float(MIX_RATE)) * 0.15
		var tape_flutter := sin(float(i) * 55.0) * 0.03

		var sig := ((chime + chime_oct) * env * 0.45 + low_pad + tape_flutter) * 0.5
		_write_s16(bytes, i, sig)
	return _create_wav(bytes, true, 0, count)

func _synth_fire_hazard() -> AudioStreamWAV:
	# Fogo rugindo e crepitação contínua
	var duration := 4.0
	var count := int(duration * float(MIX_RATE))
	var bytes := PackedByteArray()
	bytes.resize(count * 2)
	var rng := RandomNumberGenerator.new()
	rng.seed = 91823
	var lp := 0.0
	for i in range(count):
		var t := float(i) / float(count)
		var n := rng.randf_range(-1.0, 1.0)
		lp = lerpf(lp, n, 0.15)
		var roar := lp * (0.8 + 0.2 * sin(t * TAU * 1.5))
		var pop := 0.0
		if rng.randf() < 0.003:
			pop = rng.randf_range(0.5, 1.0)
		var sig := (roar * 0.5 + pop * 0.5) * 0.45
		_write_s16(bytes, i, sig)
	return _create_wav(bytes, true, 0, count)
