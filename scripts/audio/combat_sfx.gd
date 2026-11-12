extends RefCounted
class_name CombatSfx

const MIX_RATE := 22050
static var _cache: Dictionary = {}

static func play(host: Node, sfx_name: String, volume_db: float = -6.0) -> void:
	if host == null or not host.is_inside_tree():
		return
	var stream := _get_or_build_stream(sfx_name)
	if stream == null:
		return
	var player := AudioStreamPlayer.new()
	player.stream = stream
	player.volume_db = volume_db
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
		"swing_miss":
			samples = _synth_swing_miss()
		"melee_hit":
			samples = _synth_melee_hit()
		"water_cast":
			samples = _synth_water_cast()
		"player_hurt":
			samples = _synth_player_hurt()
		_:
			samples = _synth_swing_miss()

	wav.data = samples
	_cache[sfx_name] = wav
	return wav

static func _synth_swing_miss() -> PackedByteArray:
	var duration := 0.11
	var count := int(duration * float(MIX_RATE))
	var bytes := PackedByteArray()
	bytes.resize(count * 2)
	var phase := 0.0
	var rng := RandomNumberGenerator.new()
	rng.seed = 104729
	var lp := 0.0
	for i in range(count):
		var t := float(i) / float(count)
		var env := sin(t * PI) * (1.0 - t * 0.4)
		var freq := lerpf(420.0, 150.0, t)
		phase += TAU * freq / float(MIX_RATE)
		var noise := rng.randf_range(-1.0, 1.0)
		lp = lerpf(lp, noise, 0.24)
		var sig := (sin(phase) * 0.35 + lp * 0.65) * env * 0.38
		_write_s16(bytes, i, sig)
	return bytes

static func _synth_melee_hit() -> PackedByteArray:
	var duration := 0.14
	var count := int(duration * float(MIX_RATE))
	var bytes := PackedByteArray()
	bytes.resize(count * 2)
	var phase := 0.0
	var rng := RandomNumberGenerator.new()
	rng.seed = 339817
	for i in range(count):
		var t := float(i) / float(count)
		var env := pow(1.0 - t, 2.2)
		var freq := lerpf(240.0, 62.0, pow(t, 0.55))
		phase += TAU * freq / float(MIX_RATE)
		var transient := rng.randf_range(-1.0, 1.0) * exp(-t * 28.0)
		var body := sin(phase) + 0.35 * sin(phase * 2.1)
		var sig := clampf((body * 0.72 + transient * 0.55) * env * 0.65, -0.95, 0.95)
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
		var bubble_mod := sin(t * TAU * 19.0) * 140.0
		var freq := lerpf(320.0, 540.0, t) + bubble_mod
		phase += TAU * freq / float(MIX_RATE)
		var noise := rng.randf_range(-1.0, 1.0)
		bp = lerpf(bp, noise, 0.35)
		var sig := (sin(phase) * 0.45 + bp * 0.45) * env * 0.48
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
		var sig := tanh(sin(phase) * 1.8) * env * 0.55
		_write_s16(bytes, i, sig)
	return bytes

static func _write_s16(bytes: PackedByteArray, idx: int, sample: float) -> void:
	var v := clampi(int(sample * 32767.0), -32768, 32767)
	if v < 0:
		v += 65536
	bytes[idx * 2] = v & 0xFF
	bytes[idx * 2 + 1] = (v >> 8) & 0xFF

