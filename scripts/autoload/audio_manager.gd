extends Node

const MIX_RATE := 22050
const SFX_POOL_SIZE := 8
const CROSSFADE_SEC := 0.85

const BGM_FILE_MAP := {
	"title_theme": "res://assets/audio/bgm/dark_fog.mp3",
	"day_theme": "res://assets/audio/bgm/study_and_relax.mp3",
	"afternoon_theme": "res://assets/audio/bgm/evening_melodrama.mp3",
	"forest_theme": "res://assets/audio/bgm/comfortable_mystery_2.mp3",
	"night_forest": "res://assets/audio/bgm/dark_fog.mp3",
	"corrupted_tension": "res://assets/audio/bgm/giant_wyrm.mp3",
	"boss_bgm": "res://assets/audio/bgm/tempting_secrets.mp3",
	"vhs_memory_bgm": "res://assets/audio/bgm/comfortable_mystery_2.mp3",
}

const MUSIC_CREDITS: Array[Dictionary] = [
	{
		"title": "Study and Relax",
		"artist": "Kevin MacLeod (incompetech.com)",
		"license": "CC-BY 4.0",
		"usage": "Quarto de Huwag & Agdangan (Manhã)"
	},
	{
		"title": "Evening Melodrama",
		"artist": "Kevin MacLeod (incompetech.com)",
		"license": "CC-BY 4.0",
		"usage": "Fim de Tarde em Agdangan"
	},
	{
		"title": "Dark Fog",
		"artist": "Kevin MacLeod (incompetech.com)",
		"license": "CC-BY 4.0",
		"usage": "Menu Inicial & Noite em Agdangan"
	},
	{
		"title": "Comfortable Mystery 2",
		"artist": "Kevin MacLeod (incompetech.com)",
		"license": "CC-BY 4.0",
		"usage": "Trilha da Floresta & Memória VHS"
	},
	{
		"title": "Giant Wyrm",
		"artist": "Kevin MacLeod (incompetech.com)",
		"license": "CC-BY 4.0",
		"usage": "Modo Corrompido (Psicológico)"
	},
	{
		"title": "Tempting Secrets",
		"artist": "Kevin MacLeod (incompetech.com)",
		"license": "CC-BY 4.0",
		"usage": "Guardiã da Lagoa & Confrontos"
	},
]

var master_volume: float = 1.0
var music_volume: float = 0.80
var sfx_volume: float = 0.90

var current_bgm_track: String = ""
var current_ambience_track: String = ""
var current_scene_id: String = ""
var boss_music_active: bool = false

var _bgm_player: AudioStreamPlayer
var _bgm_fade_player: AudioStreamPlayer
var _ambience_player: AudioStreamPlayer
var _amb_fade_player: AudioStreamPlayer
var _bgm_tween: Tween = null
var _amb_tween: Tween = null
var _lp_tween: Tween = null

var _sfx_pool: Array[AudioStreamPlayer] = []
var _sfx_index: int = 0
var _stream_cache: Dictionary = {}


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_setup_audio_buses()
	set_volumes(master_volume, music_volume, sfx_volume)

	_bgm_player = _create_bus_player("BGMPlayerA", "Music", -10.0)
	_bgm_fade_player = _create_bus_player("BGMPlayerB", "Music", -40.0)
	_ambience_player = _create_bus_player("AmbiencePlayerA", "Ambience", -13.0)
	_amb_fade_player = _create_bus_player("AmbiencePlayerB", "Ambience", -40.0)

	for i in range(SFX_POOL_SIZE):
		var p := _create_bus_player("SFXPlayer_%d" % i, "SFX", -7.5)
		_sfx_pool.append(p)

	_connect_game_state_signals.call_deferred()


func _setup_audio_buses() -> void:
	_ensure_filtered_bus("Music", 14000.0, 0.34, -1.5)
	_ensure_filtered_bus("Ambience", 1800.0, 0.30, -2.0)
	_ensure_filtered_bus("SFX", 3600.0, 0.32, -1.0)


func set_volumes(master: float, music: float, sfx: float) -> void:
	master_volume = clampf(master, 0.0, 1.0)
	music_volume = clampf(music, 0.0, 1.0)
	sfx_volume = clampf(sfx, 0.0, 1.0)
	_apply_bus_volume("Master", master_volume, 0.0)
	_apply_bus_volume("Music", music_volume, -1.5)
	_apply_bus_volume("Ambience", music_volume, -2.5)
	_apply_bus_volume("SFX", sfx_volume, -1.0)


func _apply_bus_volume(bus_name: String, norm_val: float, base_db: float) -> void:
	var idx := AudioServer.get_bus_index(bus_name)
	if idx == -1:
		return
	AudioServer.set_bus_mute(idx, norm_val <= 0.01)
	if norm_val > 0.01:
		AudioServer.set_bus_volume_db(idx, base_db + linear_to_db(norm_val))


func set_music_lowpass_cutoff(target_hz: float, duration_sec: float = 0.65) -> void:
	var idx := AudioServer.get_bus_index("Music")
	if idx == -1:
		return
	var lpf: AudioEffectLowPassFilter = null
	for i in range(AudioServer.get_bus_effect_count(idx)):
		var eff := AudioServer.get_bus_effect(idx, i)
		if eff is AudioEffectLowPassFilter:
			lpf = eff as AudioEffectLowPassFilter
			break
	if lpf == null:
		return
	if _lp_tween != null and _lp_tween.is_valid():
		_lp_tween.kill()
	if not is_inside_tree() or duration_sec <= 0.01:
		lpf.cutoff_hz = target_hz
		return
	_lp_tween = create_tween()
	_lp_tween.tween_property(lpf, "cutoff_hz", target_hz, duration_sec).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)


func _ensure_filtered_bus(bus_name: String, cutoff_hz: float, resonance: float, volume_db: float) -> void:
	var idx := AudioServer.get_bus_index(bus_name)
	if idx == -1:
		AudioServer.add_bus()
		idx = AudioServer.get_bus_count() - 1
		AudioServer.set_bus_name(idx, bus_name)
		AudioServer.set_bus_send(idx, "Master")
	AudioServer.set_bus_volume_db(idx, volume_db)

	var has_lp := false
	for i in range(AudioServer.get_bus_effect_count(idx)):
		var eff := AudioServer.get_bus_effect(idx, i)
		if eff is AudioEffectLowPassFilter:
			var lpf := eff as AudioEffectLowPassFilter
			lpf.cutoff_hz = cutoff_hz
			lpf.resonance = resonance
			has_lp = true
			break
	if not has_lp:
		var lpf := AudioEffectLowPassFilter.new()
		lpf.cutoff_hz = cutoff_hz
		lpf.resonance = resonance
		AudioServer.add_bus_effect(idx, lpf)


func _create_bus_player(node_name: String, bus_name: String, vol_db: float) -> AudioStreamPlayer:
	var p := AudioStreamPlayer.new()
	p.name = node_name
	p.volume_db = vol_db
	p.bus = bus_name if AudioServer.get_bus_index(bus_name) != -1 else "Master"
	add_child(p)
	return p


func get_bus_lowpass_cutoff(bus_name: String) -> float:
	var idx := AudioServer.get_bus_index(bus_name)
	if idx == -1:
		return -1.0
	for i in range(AudioServer.get_bus_effect_count(idx)):
		var eff := AudioServer.get_bus_effect(idx, i)
		if eff is AudioEffectLowPassFilter:
			return (eff as AudioEffectLowPassFilter).cutoff_hz
	return -1.0


func get_current_bgm() -> String:
	return current_bgm_track


func get_current_ambience() -> String:
	return current_ambience_track


func _connect_game_state_signals() -> void:
	if not has_node("/root/GameState"):
		return
	var gs := get_node("/root/GameState")
	if gs.has_signal("day_period_changed") and not gs.is_connected("day_period_changed", _on_environment_state_changed):
		gs.connect("day_period_changed", _on_environment_state_changed)
	if gs.has_signal("higher_dose_changed") and not gs.is_connected("higher_dose_changed", _on_higher_dose_changed):
		gs.connect("higher_dose_changed", _on_higher_dose_changed)
	if gs.has_signal("perception_changed") and not gs.is_connected("perception_changed", _on_perception_changed):
		gs.connect("perception_changed", _on_perception_changed)


func _on_environment_state_changed(_period: String) -> void:
	if not current_scene_id.is_empty():
		sync_adaptive_soundtrack(current_scene_id, boss_music_active)


func _on_higher_dose_changed(_active: bool) -> void:
	if not current_scene_id.is_empty():
		sync_adaptive_soundtrack(current_scene_id, boss_music_active)


func _on_perception_changed(_mode: int) -> void:
	if not current_scene_id.is_empty():
		sync_adaptive_soundtrack(current_scene_id, boss_music_active)


func sync_adaptive_soundtrack(scene_id: String = "", is_boss_fight: bool = false) -> void:
	if not scene_id.is_empty():
		current_scene_id = scene_id
	boss_music_active = is_boss_fight

	var is_act3 := false
	var is_corrupted := false
	var period := "morning"
	var fire_active := false
	if has_node("/root/GameState"):
		var gs := get_node("/root/GameState")
		if gs.has_method("is_unfiltered_act3"):
			is_act3 = bool(gs.call("is_unfiltered_act3"))
		if gs.has_method("is_higher_dose"):
			is_corrupted = bool(gs.call("is_higher_dose"))
		elif gs.has_method("is_higher_dose_active"):
			is_corrupted = bool(gs.call("is_higher_dose_active"))
		if gs.has_method("get_day_period"):
			period = str(gs.call("get_day_period"))
		if gs.has_method("get_switch"):
			fire_active = bool(gs.call("get_switch", "015_Floresta_em_chamas")) and not bool(gs.call("get_switch", "019_Ato2_concluido"))

	var low_scene := current_scene_id.to_lower()
	var is_forest := ("forest" in low_scene or "floresta" in low_scene or "clearing" in low_scene or "trail" in low_scene)
	var is_title := ("title" in low_scene or "menu" in low_scene)
	var is_vhs := ("vhs" in low_scene)

	if is_title:
		set_music_lowpass_cutoff(13500.0, 0.5)
		play_bgm("title_theme", -9.0)
		play_ambience("night_ambience" if period == "night" else "morning_ambience", -16.5)
		return

	if is_vhs:
		set_music_lowpass_cutoff(1350.0, 0.4)
		play_bgm("vhs_memory_bgm", -9.5)
		play_ambience("corrupted_ambience", -15.5)
		return

	if is_act3:
		set_music_lowpass_cutoff(9500.0, 0.5)
		stop_bgm()
		play_ambience("act3_ambience", -13.5)
		return

	if is_boss_fight:
		set_music_lowpass_cutoff(12500.0, 0.4)
		play_bgm("boss_bgm", -8.0)
		play_ambience("corrupted_ambience", -14.0)
		return

	if is_corrupted:
		set_music_lowpass_cutoff(1250.0, 0.45)
		play_bgm("corrupted_tension", -8.0)
		play_ambience("corrupted_ambience", -12.5)
		return

	set_music_lowpass_cutoff(14000.0, 0.65)
	if is_forest:
		if fire_active:
			play_bgm("night_forest", -9.0)
			play_ambience("fire_hazard", -12.0)
		elif period == "night":
			play_bgm("night_forest", -9.5)
			play_ambience("night_ambience", -13.0)
		else:
			play_bgm("forest_theme", -9.5)
			play_ambience("forest_ambience", -14.0)
		return

	# Agdangan & Interiores (Manhã / Tarde / Noite)
	if period == "night":
		play_bgm("night_forest", -9.5)
		play_ambience("night_ambience", -13.5)
	elif period == "afternoon":
		play_bgm("afternoon_theme", -9.5)
		play_ambience("afternoon_ambience", -14.5)
	else:
		play_bgm("day_theme", -9.5)
		play_ambience("morning_ambience", -15.0)


func play_sfx(sfx_name: String, volume_db: float = -7.5, pitch_scale: float = 1.0) -> void:
	var stream := _get_or_build_stream("sfx:" + sfx_name)
	if stream == null or _sfx_pool.is_empty():
		return
	var p := _sfx_pool[_sfx_index]
	_sfx_index = (_sfx_index + 1) % _sfx_pool.size()
	p.stop()
	p.stream = stream
	p.volume_db = volume_db
	p.pitch_scale = clampf(pitch_scale, 0.55, 1.35)
	p.play()


func play_bgm(track_name: String, volume_db: float = -9.5) -> void:
	if track_name.is_empty() or track_name == "none":
		stop_bgm()
		return
	var stream := _get_or_build_stream("bgm:" + track_name)
	if stream == null:
		return
	if current_bgm_track == track_name and _bgm_player.playing and _bgm_player.stream == stream:
		_bgm_player.volume_db = volume_db
		return

	current_bgm_track = track_name
	_crossfade_pair(_bgm_player, _bgm_fade_player, stream, volume_db, true)
	var tmp := _bgm_player
	_bgm_player = _bgm_fade_player
	_bgm_fade_player = tmp


func stop_bgm() -> void:
	current_bgm_track = ""
	if _bgm_tween != null and _bgm_tween.is_valid():
		_bgm_tween.kill()
	_bgm_player.stop()
	_bgm_fade_player.stop()


func play_ambience(track_name: String, volume_db: float = -12.5) -> void:
	if track_name.is_empty() or track_name == "none":
		stop_ambience()
		return
	var stream := _get_or_build_stream("amb:" + track_name)
	if stream == null:
		return
	if current_ambience_track == track_name and _ambience_player.playing and _ambience_player.stream == stream:
		_ambience_player.volume_db = volume_db
		return

	current_ambience_track = track_name
	_crossfade_pair(_ambience_player, _amb_fade_player, stream, volume_db, false)
	var tmp := _ambience_player
	_ambience_player = _amb_fade_player
	_amb_fade_player = tmp


func stop_ambience() -> void:
	current_ambience_track = ""
	if _amb_tween != null and _amb_tween.is_valid():
		_amb_tween.kill()
	_ambience_player.stop()
	_amb_fade_player.stop()


func _crossfade_pair(outgoing: AudioStreamPlayer, incoming: AudioStreamPlayer, next_stream: AudioStream, target_db: float, is_bgm: bool) -> void:
	if is_bgm:
		if _bgm_tween != null and _bgm_tween.is_valid():
			_bgm_tween.kill()
	else:
		if _amb_tween != null and _amb_tween.is_valid():
			_amb_tween.kill()

	incoming.stop()
	incoming.stream = next_stream
	incoming.volume_db = -34.0 if outgoing.playing else target_db
	incoming.play()

	if not is_inside_tree():
		incoming.volume_db = target_db
		outgoing.stop()
		return

	var tw := create_tween().set_parallel(true)
	tw.tween_property(incoming, "volume_db", target_db, CROSSFADE_SEC).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	if outgoing.playing:
		tw.tween_property(outgoing, "volume_db", -38.0, CROSSFADE_SEC).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
		tw.chain().tween_callback(func() -> void:
			if is_instance_valid(outgoing):
				outgoing.stop()
		)
	if is_bgm:
		_bgm_tween = tw
	else:
		_amb_tween = tw


func _load_mp3_looped(res_path: String) -> AudioStreamMP3:
	var stream: AudioStreamMP3 = null
	if ResourceLoader.exists(res_path):
		var loaded := load(res_path)
		if loaded is AudioStreamMP3:
			stream = (loaded as AudioStreamMP3).duplicate() as AudioStreamMP3
	if stream == null:
		var abs_path := ProjectSettings.globalize_path(res_path)
		if FileAccess.file_exists(abs_path):
			stream = AudioStreamMP3.load_from_file(abs_path)
	if stream != null:
		stream.loop = true
	return stream


func _get_or_build_stream(key: String) -> AudioStream:
	if _stream_cache.has(key):
		return _stream_cache[key] as AudioStream

	if key.begins_with("bgm:"):
		var track_id := key.trim_prefix("bgm:")
		if BGM_FILE_MAP.has(track_id):
			var mp3 := _load_mp3_looped(str(BGM_FILE_MAP[track_id]))
			if mp3 != null:
				_stream_cache[key] = mp3
				return mp3

	var stream: AudioStream = null
	match key:
		# === UI & Gameplay SFX (timbres quentes e graves, zero agudos estridentes) ===
		"sfx:ui_hover", "sfx:ui_move":
			stream = _synth_tone(0.045, 220.0, 260.0, 0.22, false, 0.0)
		"sfx:ui_select", "sfx:save_chime":
			stream = _synth_ui_select()
		"sfx:ui_back":
			stream = _synth_tone(0.09, 240.0, 165.0, 0.26, false, 0.04)
		"sfx:ui_dialogue":
			stream = _synth_tone(0.032, 196.0, 220.0, 0.16, false, 0.02)
		"sfx:eye_open":
			stream = _synth_tone(0.18, 92.0, 148.0, 0.20, false, 0.45)
		"sfx:heartbeat_muffled":
			stream = _synth_tone(0.24, 62.0, 40.0, 0.28, false, 0.05)
		"sfx:footstep":
			stream = _synth_footstep()
		"sfx:vhs_glitch":
			stream = _synth_vhs_glitch()
		"sfx:water_splash":
			stream = _synth_water_splash()
		"sfx:water_cast":
			stream = _synth_water_splash()
		"sfx:fire_douse":
			stream = _synth_fire_douse()
		"sfx:santelmo_cry":
			stream = _synth_santelmo_cry()
		"sfx:santelmo_defeat":
			stream = _synth_santelmo_defeat()
		"sfx:boss_telegraph":
			stream = _synth_boss_telegraph()
		"sfx:boss_roar":
			stream = _synth_boss_roar()
		"sfx:act3_shatter":
			stream = _synth_act3_shatter()
		"sfx:melee_hit":
			stream = _synth_melee_hit()
		"sfx:swing_miss":
			stream = _synth_swing_whoosh()
		"sfx:player_hurt":
			stream = _synth_player_hurt()

		# === Fallback Procedural BGM ===
		"bgm:title_theme":
			stream = _synth_title_bgm()
		"bgm:day_theme":
			stream = _synth_day_bgm()
		"bgm:afternoon_theme":
			stream = _synth_day_bgm()
		"bgm:forest_theme":
			stream = _synth_forest_bgm()
		"bgm:night_forest":
			stream = _synth_night_forest_bgm()
		"bgm:corrupted_tension":
			stream = _synth_corrupted_tension_bgm()
		"bgm:boss_bgm":
			stream = _synth_boss_bgm()
		"bgm:vhs_memory_bgm":
			stream = _synth_vhs_memory_bgm()

		# === Ambiências Filtradas (sem apitos de 2.4–4.8 kHz) ===
		"amb:morning_ambience":
			stream = _synth_morning_ambience()
		"amb:afternoon_ambience":
			stream = _synth_afternoon_ambience()
		"amb:night_ambience":
			stream = _synth_night_ambience()
		"amb:forest_ambience":
			stream = _synth_forest_ambience()
		"amb:corrupted_ambience":
			stream = _synth_corrupted_ambience()
		"amb:fire_hazard":
			stream = _synth_fire_hazard_ambience()
		"amb:act3_ambience":
			stream = _synth_act3_ambience()

	if stream != null:
		_stream_cache[key] = stream
	return stream


func _make_wav(samples: PackedFloat32Array, loop: bool = false) -> AudioStreamWAV:
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = MIX_RATE
	wav.stereo = false
	if loop:
		wav.loop_mode = AudioStreamWAV.LOOP_FORWARD
		wav.loop_begin = 0
		wav.loop_end = samples.size()

	var bytes := PackedByteArray()
	bytes.resize(samples.size() * 2)
	for i in range(samples.size()):
		var s := clampf(samples[i], -0.95, 0.95)
		var pcm := int(round(s * 32767.0))
		bytes[i * 2] = pcm & 0xFF
		bytes[i * 2 + 1] = (pcm >> 8) & 0xFF
	wav.data = bytes
	return wav


func _synth_tone(duration: float, f_start: float, f_end: float, amp: float, loop: bool, noise_mix: float) -> AudioStreamWAV:
	var count := maxi(1, int(duration * MIX_RATE))
	var arr := PackedFloat32Array()
	arr.resize(count)
	var phase := 0.0
	var lp := 0.0
	var rng := RandomNumberGenerator.new()
	rng.seed = int(f_start * 100.0 + f_end * 10.0)
	for i in range(count):
		var t := float(i) / float(count)
		var env := sin(t * PI) if not loop else 1.0
		if not loop and t < 0.08:
			env = t / 0.08
		elif not loop:
			env = pow(1.0 - t, 1.45)
		var freq := lerpf(minf(f_start, 520.0), minf(f_end, 520.0), t)
		phase += TAU * freq / float(MIX_RATE)
		var sig := sin(phase) * (1.0 - noise_mix) + rng.randf_range(-1.0, 1.0) * noise_mix
		lp += 0.18 * (sig - lp)
		arr[i] = lp * amp * env
	return _make_wav(arr, loop)


func _synth_ui_select() -> AudioStreamWAV:
	var count := int(0.11 * MIX_RATE)
	var arr := PackedFloat32Array()
	arr.resize(count)
	var phase := 0.0
	var lp := 0.0
	for i in range(count):
		var t := float(i) / float(count)
		var freq := 220.0 if t < 0.48 else 293.66 # A3 -> D4 (quente e suave)
		var env := pow(1.0 - t, 1.25)
		phase += TAU * freq / float(MIX_RATE)
		var raw := sin(phase) * 0.75 + sin(phase * 0.5) * 0.25
		lp += 0.22 * (raw - lp)
		arr[i] = lp * 0.24 * env
	return _make_wav(arr, false)


func _synth_footstep() -> AudioStreamWAV:
	var count := int(0.065 * MIX_RATE)
	var arr := PackedFloat32Array()
	arr.resize(count)
	var rng := RandomNumberGenerator.new()
	rng.seed = 904
	var lp := 0.0
	var phase := 0.0
	for i in range(count):
		var t := float(i) / float(count)
		var env := pow(1.0 - t, 2.2)
		phase += TAU * lerpf(115.0, 58.0, t) / float(MIX_RATE)
		var n := rng.randf_range(-1.0, 1.0)
		lp += 0.10 * (n - lp)
		arr[i] = (sin(phase) * 0.45 + lp * 0.55) * 0.22 * env
	return _make_wav(arr, false)


func _synth_vhs_glitch() -> AudioStreamWAV:
	var count := int(0.24 * MIX_RATE)
	var arr := PackedFloat32Array()
	arr.resize(count)
	var rng := RandomNumberGenerator.new()
	rng.seed = 404
	var lp := 0.0
	for i in range(count):
		var t := float(i) / float(count)
		var env := (1.0 - t * 0.72)
		var n := rng.randf_range(-1.0, 1.0)
		lp = lerpf(lp, n, 0.08)
		var hum := sin(float(i) * TAU * 60.0 / float(MIX_RATE)) * 0.48 + sin(float(i) * TAU * 120.0 / float(MIX_RATE)) * 0.22
		arr[i] = (lp * 0.42 + hum) * 0.26 * env
	return _make_wav(arr, false)


func _synth_water_splash() -> AudioStreamWAV:
	var count := int(0.32 * MIX_RATE)
	var arr := PackedFloat32Array()
	arr.resize(count)
	var rng := RandomNumberGenerator.new()
	rng.seed = 777
	var lp := 0.0
	var phase := 0.0
	for i in range(count):
		var t := float(i) / float(count)
		var env := sin(minf(1.0, t * 4.5) * PI * 0.5) * pow(1.0 - t, 1.2)
		var n := rng.randf_range(-1.0, 1.0)
		lp = lerpf(lp, n, 0.09 + 0.08 * (1.0 - t))
		var freq := lerpf(240.0, 145.0, t)
		phase += TAU * freq / float(MIX_RATE)
		arr[i] = (lp * 0.65 + sin(phase) * 0.35) * 0.30 * env
	return _make_wav(arr, false)


func _synth_fire_douse() -> AudioStreamWAV:
	var count := int(0.45 * MIX_RATE)
	var arr := PackedFloat32Array()
	arr.resize(count)
	var rng := RandomNumberGenerator.new()
	rng.seed = 515
	var lp := 0.0
	for i in range(count):
		var t := float(i) / float(count)
		var env := pow(1.0 - t, 1.25)
		var n := rng.randf_range(-1.0, 1.0)
		lp = lerpf(lp, n, 0.11)
		var sub := sin(float(i) * TAU * lerpf(160.0, 72.0, t) / float(MIX_RATE)) * 0.32
		arr[i] = (lp * 0.68 + sub) * 0.30 * env
	return _make_wav(arr, false)


func _synth_santelmo_cry() -> AudioStreamWAV:
	# Gemido cavo e grave (sem apito agudo)
	var count := int(0.34 * MIX_RATE)
	var arr := PackedFloat32Array()
	arr.resize(count)
	var phase := 0.0
	var lp := 0.0
	for i in range(count):
		var t := float(i) / float(count)
		var env := sin(t * PI) * (1.0 - t * 0.35)
		var vib := sin(t * TAU * 7.0) * 12.0
		var freq := lerpf(240.0, 155.0, t) + vib
		phase += TAU * freq / float(MIX_RATE)
		var raw := sin(phase) * 0.68 + sin(phase * 0.5) * 0.32
		lp += 0.16 * (raw - lp)
		arr[i] = lp * 0.25 * env
	return _make_wav(arr, false)


func _synth_santelmo_defeat() -> AudioStreamWAV:
	var count := int(0.50 * MIX_RATE)
	var arr := PackedFloat32Array()
	arr.resize(count)
	var phase := 0.0
	var rng := RandomNumberGenerator.new()
	rng.seed = 909
	var lp := 0.0
	for i in range(count):
		var t := float(i) / float(count)
		var env := pow(1.0 - t, 1.35)
		var freq := lerpf(220.0, 68.0, t)
		phase += TAU * freq / float(MIX_RATE)
		var raw := sin(phase) * 0.65 + rng.randf_range(-0.35, 0.35) * 0.35
		lp += 0.14 * (raw - lp)
		arr[i] = lp * 0.30 * env
	return _make_wav(arr, false)


func _synth_boss_telegraph() -> AudioStreamWAV:
	# Pulso sub-grave de aviso antes de investida/onda do Boss
	var count := int(0.42 * MIX_RATE)
	var arr := PackedFloat32Array()
	arr.resize(count)
	var phase := 0.0
	var lp := 0.0
	for i in range(count):
		var t := float(i) / float(count)
		var env := sin(t * PI)
		var freq := lerpf(78.0, 142.0, t)
		phase += TAU * freq / float(MIX_RATE)
		var raw := sin(phase) * 0.70 + sin(phase * 1.5) * 0.30
		lp += 0.15 * (raw - lp)
		arr[i] = lp * 0.34 * env
	return _make_wav(arr, false)


func _synth_boss_roar() -> AudioStreamWAV:
	var count := int(0.68 * MIX_RATE)
	var arr := PackedFloat32Array()
	arr.resize(count)
	var rng := RandomNumberGenerator.new()
	rng.seed = 612
	var phase := 0.0
	var lp := 0.0
	for i in range(count):
		var t := float(i) / float(count)
		var env := sin(minf(1.0, t * 4.0) * PI * 0.5) * pow(1.0 - t, 1.15)
		var freq := lerpf(118.0, 52.0, t) + sin(t * TAU * 6.0) * 6.0
		phase += TAU * freq / float(MIX_RATE)
		var raw := sin(phase) * 0.62 + sin(phase * 0.5) * 0.25 + rng.randf_range(-1.0, 1.0) * 0.22
		lp += 0.10 * (raw - lp)
		arr[i] = lp * 0.38 * env
	return _make_wav(arr, false)


func _synth_act3_shatter() -> AudioStreamWAV:
	var count := int(0.55 * MIX_RATE)
	var arr := PackedFloat32Array()
	arr.resize(count)
	var rng := RandomNumberGenerator.new()
	rng.seed = 303
	var lp := 0.0
	for i in range(count):
		var t := float(i) / float(count)
		var env := pow(1.0 - t, 1.5)
		var ring := sin(float(i) * TAU * 220.0 / float(MIX_RATE)) * 0.42 + sin(float(i) * TAU * 110.0 / float(MIX_RATE)) * 0.38
		var n := rng.randf_range(-1.0, 1.0) * pow(1.0 - t, 2.5) * 0.35
		lp += 0.14 * ((ring + n) - lp)
		arr[i] = lp * 0.32 * env
	return _make_wav(arr, false)


func _synth_melee_hit() -> AudioStreamWAV:
	var count := int(0.14 * MIX_RATE)
	var arr := PackedFloat32Array()
	arr.resize(count)
	var rng := RandomNumberGenerator.new()
	rng.seed = 4111
	var phase := 0.0
	var lp := 0.0
	for i in range(count):
		var t := float(i) / float(count)
		var env := pow(1.0 - t, 1.9)
		phase += TAU * lerpf(155.0, 52.0, t) / float(MIX_RATE)
		var n := rng.randf_range(-1.0, 1.0)
		lp += 0.16 * (n - lp)
		arr[i] = (sin(phase) * 0.72 + lp * 0.28) * 0.36 * env
	return _make_wav(arr, false)


func _synth_swing_whoosh() -> AudioStreamWAV:
	var count := int(0.13 * MIX_RATE)
	var arr := PackedFloat32Array()
	arr.resize(count)
	var rng := RandomNumberGenerator.new()
	rng.seed = 1337
	var lp := 0.0
	var phase := 0.0
	for i in range(count):
		var t := float(i) / float(count)
		var env := sin(t * PI) * (1.0 - 0.3 * t)
		phase += TAU * lerpf(210.0, 92.0, t) / float(MIX_RATE)
		lp += 0.12 * (rng.randf_range(-1.0, 1.0) - lp)
		arr[i] = (lp * 0.58 + sin(phase) * 0.42) * 0.26 * env
	return _make_wav(arr, false)


func _synth_player_hurt() -> AudioStreamWAV:
	var count := int(0.20 * MIX_RATE)
	var arr := PackedFloat32Array()
	arr.resize(count)
	var phase := 0.0
	var lp := 0.0
	for i in range(count):
		var t := float(i) / float(count)
		var env := pow(1.0 - t, 1.45)
		phase += TAU * lerpf(165.0, 68.0, t) / float(MIX_RATE)
		var raw := sin(phase) * 0.75 + sin(phase * 0.5) * 0.25
		lp += 0.18 * (raw - lp)
		arr[i] = lp * 0.34 * env
	return _make_wav(arr, false)


# ==============================================================================
# TRILHAS SONORAS PROCEDURAIS ADAPTATIVAS (GRAVES, QUENTES E COM LOW-PASS)
# ==============================================================================

func _synth_title_bgm() -> AudioStreamWAV:
	# Pad melancólico de fita VHS em Ré menor (D2-A2-F3)
	var duration := 8.0
	var count := int(duration * MIX_RATE)
	var arr := PackedFloat32Array()
	arr.resize(count)
	var rng := RandomNumberGenerator.new()
	rng.seed = 1997
	var lp := 0.0
	for i in range(count):
		var t := float(i) / float(MIX_RATE)
		var wow := sin(t * TAU * 0.25) * 0.0025
		var f1 := 73.42 * (1.0 + wow)  # D2
		var f2 := 110.00 * (1.0 - wow) # A2
		var f3 := 174.61 * (1.0 + wow) # F3
		var pad := (
			sin(t * TAU * f1) * 0.46
			+ sin(t * TAU * f2) * 0.34
			+ sin(t * TAU * f3) * 0.20 * (0.65 + 0.35 * sin(t * TAU * 0.125))
		)
		var tape := rng.randf_range(-1.0, 1.0) * 0.025
		lp += 0.08 * ((pad + tape) - lp)
		arr[i] = lp * 0.26
	return _make_wav(arr, true)


func _synth_day_bgm() -> AudioStreamWAV:
	# Melodia ambiental calma, melancólica e acolhedora para Agdangan (Dm7 -> Bbmaj7 -> Gm7 -> A7sus4)
	var duration := 12.0
	var count := int(duration * MIX_RATE)
	var arr := PackedFloat32Array()
	arr.resize(count)
	var chords := [
		[73.42, 110.00, 146.83, 174.61], # Dm
		[58.27, 116.54, 146.83, 174.61], # Bbmaj7
		[98.00, 116.54, 146.83, 196.00], # Gm
		[55.00, 110.00, 146.83, 164.81], # Asus4/E
	]
	var notes := [220.00, 196.00, 174.61, 146.83, 164.81, 174.61, 146.83, 130.81]
	var lp := 0.0
	for i in range(count):
		var t := float(i) / float(MIX_RATE)
		var bar := int(floor(t / 3.0)) % chords.size()
		var chord: Array = chords[bar]
		var bar_t := fmod(t, 3.0) / 3.0
		var swell := sin(bar_t * PI)
		var pad := (
			sin(t * TAU * float(chord[0])) * 0.42
			+ sin(t * TAU * float(chord[1])) * 0.28
			+ sin(t * TAU * float(chord[2])) * 0.18 * swell
			+ sin(t * TAU * float(chord[3])) * 0.12 * swell
		)
		var note_idx := int(floor(t / 1.5)) % notes.size()
		var note_t := fmod(t, 1.5) / 1.5
		var note_env := sin(minf(1.0, note_t * 5.0) * PI * 0.5) * pow(1.0 - note_t, 1.6)
		var warm_pluck := sin(t * TAU * float(notes[note_idx])) * 0.18 * note_env
		lp += 0.09 * ((pad + warm_pluck) - lp)
		arr[i] = lp * 0.24
	return _make_wav(arr, true)


func _synth_forest_bgm() -> AudioStreamWAV:
	# Drone profundo de madeira e brisa suave na mata (D2 / A2 / C3)
	var duration := 10.0
	var count := int(duration * MIX_RATE)
	var arr := PackedFloat32Array()
	arr.resize(count)
	var lp := 0.0
	for i in range(count):
		var t := float(i) / float(MIX_RATE)
		var lfo := 0.55 + 0.45 * sin(t * TAU * 0.10)
		var bass := sin(t * TAU * 73.42) * 0.48 + sin(t * TAU * 110.00) * 0.30 + sin(t * TAU * 130.81) * 0.22 * lfo
		lp += 0.07 * (bass - lp)
		arr[i] = lp * 0.23
	return _make_wav(arr, true)


func _synth_night_forest_bgm() -> AudioStreamWAV:
	# Ambiência sombria e imersiva com pulso grave (E1 41.2 Hz + E2 82.4 Hz + B2 123.5 Hz)
	var duration := 8.0
	var count := int(duration * MIX_RATE)
	var arr := PackedFloat32Array()
	arr.resize(count)
	var lp := 0.0
	for i in range(count):
		var t := float(i) / float(MIX_RATE)
		var pulse := pow(0.5 + 0.5 * sin(t * TAU * 0.25), 2.0)
		var sub := sin(t * TAU * 41.20) * 0.50 * (0.65 + 0.35 * pulse)
		var mid := sin(t * TAU * 82.41) * 0.32 + sin(t * TAU * 123.47) * 0.18 * pulse
		lp += 0.06 * ((sub + mid) - lp)
		arr[i] = lp * 0.25
	return _make_wav(arr, true)


func _synth_corrupted_tension_bgm() -> AudioStreamWAV:
	# Tensão psicológica com sub-bass heartbeat e modulação lenta (zero apito agudo)
	var duration := 8.0
	var count := int(duration * MIX_RATE)
	var arr := PackedFloat32Array()
	arr.resize(count)
	var lp := 0.0
	for i in range(count):
		var t := float(i) / float(MIX_RATE)
		var beat_cycle := fmod(t, 1.6)
		var hb := 0.0
		if beat_cycle < 0.18:
			hb = sin((beat_cycle / 0.18) * PI) * sin(t * TAU * 48.0) * 0.58
		elif beat_cycle >= 0.26 and beat_cycle < 0.42:
			hb = sin(((beat_cycle - 0.26) / 0.16) * PI) * sin(t * TAU * 38.0) * 0.42
		var detune := sin(t * TAU * 0.125) * 0.8
		var drone := (
			sin(t * TAU * 55.0) * 0.36
			+ sin(t * TAU * (82.41 + detune)) * 0.26
			+ sin(t * TAU * (116.54 - detune)) * 0.18
		)
		lp += 0.07 * ((hb + drone) - lp)
		arr[i] = lp * 0.27
	return _make_wav(arr, true)


func _synth_boss_bgm() -> AudioStreamWAV:
	# Boss Fight da Lagoa Azul: pulso grave tribal + swell dramático em Ré menor (< 320 Hz)
	var duration := 8.0
	var count := int(duration * MIX_RATE)
	var arr := PackedFloat32Array()
	arr.resize(count)
	var bass_roots := [73.42, 65.41, 58.27, 55.00] # D2 -> C2 -> Bb1 -> A1
	var lp := 0.0
	for i in range(count):
		var t := float(i) / float(MIX_RATE)
		var bar := int(floor(t / 2.0)) % bass_roots.size()
		var root := float(bass_roots[bar])
		var step_t := fmod(t, 0.5) / 0.5
		var pulse_env := pow(1.0 - step_t, 1.8)
		var drum_sub := sin(t * TAU * lerpf(root * 1.2, root * 0.75, step_t)) * 0.48 * pulse_env
		var cello := (
			sin(t * TAU * root) * 0.34
			+ sin(t * TAU * (root * 1.5)) * 0.24
			+ sin(t * TAU * (root * 2.0)) * 0.14 * (0.5 + 0.5 * sin(t * TAU * 0.5))
		)
		lp += 0.09 * ((drum_sub + cello) - lp)
		arr[i] = lp * 0.30
	return _make_wav(arr, true)


func _synth_vhs_memory_bgm() -> AudioStreamWAV:
	var duration := 6.0
	var count := int(duration * MIX_RATE)
	var arr := PackedFloat32Array()
	arr.resize(count)
	var rng := RandomNumberGenerator.new()
	rng.seed = 1994
	var lp := 0.0
	for i in range(count):
		var t := float(i) / float(MIX_RATE)
		var drift := sin(t * TAU * 0.33) * 1.2
		var drone := sin(t * TAU * (65.41 + drift)) * 0.46 + sin(t * TAU * (98.0 - drift * 0.5)) * 0.28
		var hiss := rng.randf_range(-1.0, 1.0) * 0.03
		lp = lerpf(lp, drone + hiss, 0.07)
		arr[i] = lp * 0.24
	return _make_wav(arr, true)


# ==============================================================================
# AMBIÊNCIAS NATURAIS E PSICOLÓGICAS COM FILTRO PASSA-BAIXA (SEM APITOS AGUDOS)
# ==============================================================================

func _synth_morning_ambience() -> AudioStreamWAV:
	# Brisa costeira matinal suave + harmônicos quentes graves (146–220 Hz)
	var duration := 6.0
	var count := int(duration * MIX_RATE)
	var arr := PackedFloat32Array()
	arr.resize(count)
	var rng := RandomNumberGenerator.new()
	rng.seed = 101
	var lp := 0.0
	for i in range(count):
		var t := float(i) / float(MIX_RATE)
		var n := rng.randf_range(-1.0, 1.0)
		lp = lerpf(lp, n, 0.035)
		var breeze := lp * (0.45 + 0.25 * sin(t * TAU * 0.166))
		var warm_pad := sin(t * TAU * 146.83) * 0.16 + sin(t * TAU * 220.0) * 0.10 * (0.5 + 0.5 * sin(t * TAU * 0.333))
		arr[i] = (breeze + warm_pad) * 0.20
	return _make_wav(arr, true)


func _synth_afternoon_ambience() -> AudioStreamWAV:
	# Brisa morna de fim de tarde + ressonância âmbar grave (98–196 Hz, zero cigarra 4200 Hz)
	var duration := 6.0
	var count := int(duration * MIX_RATE)
	var arr := PackedFloat32Array()
	arr.resize(count)
	var rng := RandomNumberGenerator.new()
	rng.seed = 202
	var lp := 0.0
	for i in range(count):
		var t := float(i) / float(MIX_RATE)
		var n := rng.randf_range(-1.0, 1.0)
		lp = lerpf(lp, n, 0.04)
		var warm_drone := sin(t * TAU * 98.0) * 0.30 + sin(t * TAU * 146.83) * 0.18 + sin(t * TAU * 196.0) * 0.10
		arr[i] = (lp * 0.38 + warm_drone) * 0.20
	return _make_wav(arr, true)


func _synth_night_ambience() -> AudioStreamWAV:
	# Vento noturno profundo nas copas + pulso grave (55–110 Hz, zero grilo 4800 Hz)
	var duration := 6.0
	var count := int(duration * MIX_RATE)
	var arr := PackedFloat32Array()
	arr.resize(count)
	var rng := RandomNumberGenerator.new()
	rng.seed = 260
	var lp := 0.0
	for i in range(count):
		var t := float(i) / float(MIX_RATE)
		var n := rng.randf_range(-1.0, 1.0)
		lp = lerpf(lp, n, 0.028)
		var sub := sin(t * TAU * 55.0) * 0.38 + sin(t * TAU * 82.41) * 0.24 * (0.6 + 0.4 * sin(t * TAU * 0.166))
		arr[i] = (lp * 0.42 + sub) * 0.22
	return _make_wav(arr, true)


func _synth_forest_ambience() -> AudioStreamWAV:
	# Riacho filtrado em passa-baixa + farfalhar suave de folhas graves
	var duration := 6.0
	var count := int(duration * MIX_RATE)
	var arr := PackedFloat32Array()
	arr.resize(count)
	var rng := RandomNumberGenerator.new()
	rng.seed = 312
	var lp := 0.0
	for i in range(count):
		var t := float(i) / float(MIX_RATE)
		var n := rng.randf_range(-1.0, 1.0)
		lp = lerpf(lp, n, 0.042 + 0.015 * sin(t * TAU * 0.333))
		var creek_body := sin(t * TAU * 110.0) * 0.20 + sin(t * TAU * 164.81) * 0.12
		arr[i] = (lp * 0.55 + creek_body) * 0.20
	return _make_wav(arr, true)


func _synth_corrupted_ambience() -> AudioStreamWAV:
	# Pulsação sub-grave abafada e respiração sombria filtrada
	var duration := 6.0
	var count := int(duration * MIX_RATE)
	var arr := PackedFloat32Array()
	arr.resize(count)
	var rng := RandomNumberGenerator.new()
	rng.seed = 666
	var lp := 0.0
	for i in range(count):
		var t := float(i) / float(MIX_RATE)
		var n := rng.randf_range(-1.0, 1.0)
		lp = lerpf(lp, n, 0.025)
		var throb := 0.55 + 0.45 * sin(t * TAU * 0.333)
		var sub := sin(t * TAU * 46.25) * 0.48 * throb + sin(t * TAU * 69.30) * 0.26
		arr[i] = (lp * 0.32 + sub) * 0.23
	return _make_wav(arr, true)


func _synth_fire_hazard_ambience() -> AudioStreamWAV:
	var duration := 4.0
	var count := int(duration * MIX_RATE)
	var arr := PackedFloat32Array()
	arr.resize(count)
	var rng := RandomNumberGenerator.new()
	rng.seed = 808
	var lp := 0.0
	for i in range(count):
		var t := float(i) / float(MIX_RATE)
		var n := rng.randf_range(-1.0, 1.0)
		lp = lerpf(lp, n, 0.055)
		var rumble := sin(t * TAU * 55.0) * 0.42 + sin(t * TAU * 82.41) * 0.24
		arr[i] = (lp * 0.48 + rumble) * 0.24
	return _make_wav(arr, true)


func _synth_act3_ambience() -> AudioStreamWAV:
	# Ar-condicionado clínico suave e grave de delegacia/hospital (60 Hz + 120 Hz filtrados)
	var duration := 6.0
	var count := int(duration * MIX_RATE)
	var arr := PackedFloat32Array()
	arr.resize(count)
	var rng := RandomNumberGenerator.new()
	rng.seed = 333
	var lp := 0.0
	for i in range(count):
		var t := float(i) / float(MIX_RATE)
		var hum := sin(t * TAU * 60.0) * 0.34 + sin(t * TAU * 120.0) * 0.16
		var air := rng.randf_range(-1.0, 1.0)
		lp = lerpf(lp, air, 0.022)
		arr[i] = (hum + lp * 0.28) * 0.16
	return _make_wav(arr, true)
