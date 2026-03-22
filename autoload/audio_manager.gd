extends Node
## Procedural audio system — generates all sounds from sine waves at startup.
## v0.7.0: Added music crossfade, pitch jitter, hierarchical key lookup.
## API: AudioManager.play("click"), AudioManager.play_music("menu_theme")

const SAMPLE_RATE := 22050
const MIX_RATE := 22050

var _sounds: Dictionary = {}
var _pool: Array[AudioStreamPlayer] = []
var _ambient_player: AudioStreamPlayer = null
var _master_volume: float = 0.7
var _sfx_enabled: bool = true
var _ambient_enabled: bool = true

# Music crossfade
var _music_a: AudioStreamPlayer = null
var _music_b: AudioStreamPlayer = null
var _music_streams: Dictionary = {}
var _current_music_key: String = ""
var _music_volume: float = 0.15


func _ready() -> void:
	_generate_all_sounds()
	_generate_music()
	_create_pool(4)
	_create_ambient()
	_create_music_players()


func play(key: String) -> void:
	if not _sfx_enabled or _master_volume <= 0.0:
		return
	var resolved := _resolve_key(key)
	if resolved.is_empty():
		return
	var player := _get_free_player()
	if player:
		player.stream = _sounds[resolved]
		player.volume_db = linear_to_db(_master_volume)
		player.pitch_scale = randf_range(0.93, 1.07)
		player.play()


func _resolve_key(key: String) -> String:
	if key in _sounds:
		return key
	# Hierarchical fallback: "complete+day" → "complete"
	var parts: Array = Array(key.split("+"))
	while parts.size() > 1:
		parts.pop_back()
		var candidate: String = "+".join(PackedStringArray(parts))
		if candidate in _sounds:
			return candidate
	return ""


func play_music(key: String, fade_duration: float = 1.0) -> void:
	if key == _current_music_key:
		return
	if key not in _music_streams:
		return
	_current_music_key = key
	var target_db := linear_to_db(_master_volume * _music_volume)
	_music_b.stream = _music_streams[key]
	_music_b.volume_db = -80.0
	_music_b.play()
	var tw := create_tween()
	tw.set_parallel(true)
	if _music_a.playing:
		tw.tween_property(_music_a, "volume_db", -80.0, fade_duration)
	tw.tween_property(_music_b, "volume_db", target_db, fade_duration)
	tw.chain().tween_callback(func():
		_music_a.stop()
		var tmp := _music_a
		_music_a = _music_b
		_music_b = tmp
	)


func stop_music(fade_duration: float = 0.5) -> void:
	_current_music_key = ""
	if _music_a.playing:
		var tw := create_tween()
		tw.tween_property(_music_a, "volume_db", -80.0, fade_duration)
		tw.tween_callback(func(): _music_a.stop())


func set_master_volume(vol: float) -> void:
	_master_volume = clampf(vol, 0.0, 1.0)
	if _ambient_player:
		_ambient_player.volume_db = linear_to_db(_master_volume * 0.08)
	if _music_a and _music_a.playing:
		_music_a.volume_db = linear_to_db(_master_volume * _music_volume)


func get_master_volume() -> float:
	return _master_volume


func set_sfx_enabled(on: bool) -> void:
	_sfx_enabled = on


func get_sfx_enabled() -> bool:
	return _sfx_enabled


func set_ambient_enabled(on: bool) -> void:
	_ambient_enabled = on
	if _ambient_player:
		if on and not _ambient_player.playing:
			_ambient_player.play()
		elif not on and _ambient_player.playing:
			_ambient_player.stop()


# -- Pool management --

func _create_pool(size: int) -> void:
	for i in range(size):
		var p := AudioStreamPlayer.new()
		p.bus = "Master"
		add_child(p)
		_pool.append(p)


func _get_free_player() -> AudioStreamPlayer:
	for p in _pool:
		if not p.playing:
			return p
	# All busy — reuse the one closest to finishing
	var best: AudioStreamPlayer = _pool[0]
	var best_pos: float = 0.0
	for p in _pool:
		var pos: float = p.get_playback_position()
		var len: float = p.stream.get_length() if p.stream else 1.0
		var remaining := len - pos
		if remaining < (best.stream.get_length() if best.stream else 1.0) - best_pos:
			best = p
			best_pos = pos
	best.stop()
	return best


# -- Music players --

func _create_music_players() -> void:
	_music_a = AudioStreamPlayer.new()
	_music_a.bus = "Master"
	_music_a.volume_db = -80.0
	add_child(_music_a)
	_music_a.finished.connect(func():
		if _current_music_key in _music_streams:
			_music_a.play()
	)
	_music_b = AudioStreamPlayer.new()
	_music_b.bus = "Master"
	_music_b.volume_db = -80.0
	add_child(_music_b)


# -- Ambient --

func _create_ambient() -> void:
	_ambient_player = AudioStreamPlayer.new()
	_ambient_player.bus = "Master"
	_ambient_player.volume_db = linear_to_db(_master_volume * 0.08)
	add_child(_ambient_player)
	var stream := _gen_ambient_drone(4.0)
	_ambient_player.stream = stream
	if _ambient_enabled:
		_ambient_player.play()
	_ambient_player.finished.connect(func():
		if _ambient_enabled:
			_ambient_player.play()
	)


# -- Sound generation --

func _generate_all_sounds() -> void:
	_sounds["click"] = _gen_click()
	_sounds["click+soft"] = _gen_click_soft()
	_sounds["complete"] = _gen_complete()
	_sounds["level_up"] = _gen_level_up()
	_sounds["achievement"] = _gen_achievement()
	_sounds["jump"] = _gen_jump()
	_sounds["land"] = _gen_land()
	_sounds["land+heavy"] = _gen_land_heavy()
	_sounds["popup_open"] = _gen_popup_open()
	_sounds["popup_close"] = _gen_popup_close()
	_sounds["xp_gain"] = _gen_xp_gain()


func _generate_music() -> void:
	_music_streams["menu_theme"] = _gen_music_calm(8.0)
	_music_streams["climb_theme"] = _gen_music_hopeful(8.0)
	_music_streams["night_theme"] = _gen_music_night(8.0)


func _make_stream(samples: PackedByteArray, duration: float) -> AudioStreamWAV:
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = MIX_RATE
	stream.stereo = false
	stream.data = samples
	return stream


func _sine_samples(freq: float, duration: float, volume: float = 0.8,
		decay: float = 0.0) -> PackedByteArray:
	var count := int(duration * SAMPLE_RATE)
	var buf := PackedByteArray()
	buf.resize(count * 2)
	for i in range(count):
		var t := float(i) / SAMPLE_RATE
		var env := volume
		if decay > 0.0:
			env *= exp(-t * decay)
		var val := sin(t * freq * TAU) * env
		var sample := int(clampf(val, -1.0, 1.0) * 32767.0)
		buf[i * 2] = sample & 0xFF
		buf[i * 2 + 1] = (sample >> 8) & 0xFF
	return buf


func _noise_samples(duration: float, volume: float = 0.5,
		decay: float = 0.0) -> PackedByteArray:
	var count := int(duration * SAMPLE_RATE)
	var buf := PackedByteArray()
	buf.resize(count * 2)
	var rng := RandomNumberGenerator.new()
	rng.seed = 12345
	for i in range(count):
		var t := float(i) / SAMPLE_RATE
		var env := volume
		if decay > 0.0:
			env *= exp(-t * decay)
		var val := rng.randf_range(-1.0, 1.0) * env
		var sample := int(clampf(val, -1.0, 1.0) * 32767.0)
		buf[i * 2] = sample & 0xFF
		buf[i * 2 + 1] = (sample >> 8) & 0xFF
	return buf


func _mix_buffers(a: PackedByteArray, b: PackedByteArray) -> PackedByteArray:
	var sz := maxi(a.size(), b.size())
	var out := PackedByteArray()
	out.resize(sz)
	for i in range(0, sz, 2):
		var sa: int = 0
		var sb: int = 0
		if i + 1 < a.size():
			sa = (a[i] | (a[i + 1] << 8))
			if sa > 32767:
				sa -= 65536
		if i + 1 < b.size():
			sb = (b[i] | (b[i + 1] << 8))
			if sb > 32767:
				sb -= 65536
		var mixed := clampi(sa + sb, -32768, 32767)
		out[i] = mixed & 0xFF
		out[i + 1] = (mixed >> 8) & 0xFF
	return out


# -- Individual sounds --

func _gen_click() -> AudioStreamWAV:
	return _make_stream(_sine_samples(800.0, 0.05, 0.6, 40.0), 0.05)


func _gen_click_soft() -> AudioStreamWAV:
	return _make_stream(_sine_samples(600.0, 0.04, 0.35, 50.0), 0.04)


func _gen_complete() -> AudioStreamWAV:
	# Ascending C-E-G chord
	var c := _sine_samples(261.6, 0.4, 0.4, 4.0)
	var e := _sine_samples(329.6, 0.35, 0.35, 4.5)
	var g := _sine_samples(392.0, 0.3, 0.3, 5.0)
	var mixed := _mix_buffers(c, _mix_buffers(e, g))
	return _make_stream(mixed, 0.4)


func _gen_level_up() -> AudioStreamWAV:
	# Arpeggio C-E-G-C5 staggered
	var dur := 0.8
	var count := int(dur * SAMPLE_RATE)
	var buf := PackedByteArray()
	buf.resize(count * 2)
	var notes := [261.6, 329.6, 392.0, 523.2]
	var onsets := [0.0, 0.15, 0.3, 0.45]
	for i in range(count):
		var t := float(i) / SAMPLE_RATE
		var val := 0.0
		for n in range(4):
			var nt: float = t - onsets[n]
			if nt >= 0.0:
				val += sin(nt * notes[n] * TAU) * 0.35 * exp(-nt * 4.0)
		var sample := int(clampf(val, -1.0, 1.0) * 32767.0)
		buf[i * 2] = sample & 0xFF
		buf[i * 2 + 1] = (sample >> 8) & 0xFF
	return _make_stream(buf, dur)


func _gen_achievement() -> AudioStreamWAV:
	# Sparkle shimmer — high sweep with tremolo
	var dur := 0.5
	var count := int(dur * SAMPLE_RATE)
	var buf := PackedByteArray()
	buf.resize(count * 2)
	for i in range(count):
		var t := float(i) / SAMPLE_RATE
		var freq := lerpf(2000.0, 4000.0, t / dur)
		var tremolo := 0.5 + 0.5 * sin(t * 30.0 * TAU)
		var val := sin(t * freq * TAU) * 0.4 * tremolo * exp(-t * 3.0)
		var sample := int(clampf(val, -1.0, 1.0) * 32767.0)
		buf[i * 2] = sample & 0xFF
		buf[i * 2 + 1] = (sample >> 8) & 0xFF
	return _make_stream(buf, dur)


func _gen_jump() -> AudioStreamWAV:
	# Rising pitch noise burst
	var dur := 0.15
	var count := int(dur * SAMPLE_RATE)
	var buf := PackedByteArray()
	buf.resize(count * 2)
	var rng := RandomNumberGenerator.new()
	rng.seed = 999
	for i in range(count):
		var t := float(i) / SAMPLE_RATE
		var noise := rng.randf_range(-1.0, 1.0)
		var freq := lerpf(300.0, 800.0, t / dur)
		var tone := sin(t * freq * TAU) * 0.3
		var val := (noise * 0.2 + tone) * exp(-t * 8.0)
		var sample := int(clampf(val, -1.0, 1.0) * 32767.0)
		buf[i * 2] = sample & 0xFF
		buf[i * 2 + 1] = (sample >> 8) & 0xFF
	return _make_stream(buf, dur)


func _gen_land() -> AudioStreamWAV:
	# Low thud
	return _make_stream(_sine_samples(100.0, 0.1, 0.7, 25.0), 0.1)


func _gen_land_heavy() -> AudioStreamWAV:
	# Deeper thud with noise
	var thud := _sine_samples(65.0, 0.15, 0.8, 20.0)
	var noise := _noise_samples(0.15, 0.2, 30.0)
	return _make_stream(_mix_buffers(thud, noise), 0.15)


func _gen_popup_open() -> AudioStreamWAV:
	# Soft rising whoosh
	var dur := 0.2
	var count := int(dur * SAMPLE_RATE)
	var buf := PackedByteArray()
	buf.resize(count * 2)
	var rng := RandomNumberGenerator.new()
	rng.seed = 555
	for i in range(count):
		var t := float(i) / SAMPLE_RATE
		var freq := lerpf(200.0, 600.0, t / dur)
		var noise := rng.randf_range(-1.0, 1.0) * 0.15
		var tone := sin(t * freq * TAU) * 0.25
		var env := sin(t / dur * PI)  # bell curve envelope
		var val := (tone + noise) * env
		var sample := int(clampf(val, -1.0, 1.0) * 32767.0)
		buf[i * 2] = sample & 0xFF
		buf[i * 2 + 1] = (sample >> 8) & 0xFF
	return _make_stream(buf, dur)


func _gen_popup_close() -> AudioStreamWAV:
	# Soft falling whoosh
	var dur := 0.15
	var count := int(dur * SAMPLE_RATE)
	var buf := PackedByteArray()
	buf.resize(count * 2)
	var rng := RandomNumberGenerator.new()
	rng.seed = 777
	for i in range(count):
		var t := float(i) / SAMPLE_RATE
		var freq := lerpf(600.0, 200.0, t / dur)
		var noise := rng.randf_range(-1.0, 1.0) * 0.15
		var tone := sin(t * freq * TAU) * 0.25
		var env := exp(-t * 6.0)
		var val := (tone + noise) * env
		var sample := int(clampf(val, -1.0, 1.0) * 32767.0)
		buf[i * 2] = sample & 0xFF
		buf[i * 2 + 1] = (sample >> 8) & 0xFF
	return _make_stream(buf, dur)


func _gen_xp_gain() -> AudioStreamWAV:
	# High ding with slight detune
	var a := _sine_samples(1200.0, 0.15, 0.5, 15.0)
	var b := _sine_samples(1205.0, 0.15, 0.3, 15.0)  # slight detune for shimmer
	return _make_stream(_mix_buffers(a, b), 0.15)


func _gen_ambient_drone(duration: float) -> AudioStreamWAV:
	var count := int(duration * SAMPLE_RATE)
	var buf := PackedByteArray()
	buf.resize(count * 2)
	for i in range(count):
		var t := float(i) / SAMPLE_RATE
		var val := sin(t * 90.0 * TAU) * 0.3
		val += sin(t * 45.0 * TAU) * 0.2  # sub-octave
		val *= 0.5  # keep quiet
		# Fade in/out at edges
		var fade_in := minf(t / 0.5, 1.0)
		var fade_out := minf((duration - t) / 0.5, 1.0)
		val *= fade_in * fade_out
		var sample := int(clampf(val, -1.0, 1.0) * 32767.0)
		buf[i * 2] = sample & 0xFF
		buf[i * 2 + 1] = (sample >> 8) & 0xFF
	var stream := _make_stream(buf, duration)
	stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	stream.loop_end = count
	return stream


# -- Music generation --

func _gen_music_calm(duration: float) -> AudioStreamWAV:
	# Gentle pad — C major chord with slow modulation
	var count := int(duration * SAMPLE_RATE)
	var buf := PackedByteArray()
	buf.resize(count * 2)
	for i in range(count):
		var t := float(i) / SAMPLE_RATE
		var mod := 1.0 + sin(t * 0.3 * TAU) * 0.02
		var val := sin(t * 261.6 * mod * TAU) * 0.12
		val += sin(t * 329.6 * mod * TAU) * 0.08
		val += sin(t * 392.0 * mod * TAU) * 0.06
		val += sin(t * 130.8 * TAU) * 0.1  # bass
		var fade_in := minf(t / 1.0, 1.0)
		var fade_out := minf((duration - t) / 1.0, 1.0)
		val *= fade_in * fade_out
		var sample := int(clampf(val, -1.0, 1.0) * 32767.0)
		buf[i * 2] = sample & 0xFF
		buf[i * 2 + 1] = (sample >> 8) & 0xFF
	var stream := _make_stream(buf, duration)
	stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	stream.loop_end = count
	return stream


func _gen_music_hopeful(duration: float) -> AudioStreamWAV:
	# Brighter pad — G major with gentle arpeggio feel
	var count := int(duration * SAMPLE_RATE)
	var buf := PackedByteArray()
	buf.resize(count * 2)
	for i in range(count):
		var t := float(i) / SAMPLE_RATE
		var mod := 1.0 + sin(t * 0.5 * TAU) * 0.015
		var val := sin(t * 196.0 * mod * TAU) * 0.1  # G3
		val += sin(t * 246.9 * mod * TAU) * 0.07  # B3
		val += sin(t * 293.7 * mod * TAU) * 0.06  # D4
		val += sin(t * 392.0 * mod * TAU) * 0.04  # G4
		val += sin(t * 98.0 * TAU) * 0.12  # bass G2
		# Gentle pulse
		val *= 0.85 + sin(t * 1.5 * TAU) * 0.15
		var fade_in := minf(t / 1.0, 1.0)
		var fade_out := minf((duration - t) / 1.0, 1.0)
		val *= fade_in * fade_out
		var sample := int(clampf(val, -1.0, 1.0) * 32767.0)
		buf[i * 2] = sample & 0xFF
		buf[i * 2 + 1] = (sample >> 8) & 0xFF
	var stream := _make_stream(buf, duration)
	stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	stream.loop_end = count
	return stream


func _gen_music_night(duration: float) -> AudioStreamWAV:
	# Dark ambient — Am7 with slow drift
	var count := int(duration * SAMPLE_RATE)
	var buf := PackedByteArray()
	buf.resize(count * 2)
	for i in range(count):
		var t := float(i) / SAMPLE_RATE
		var drift := sin(t * 0.2 * TAU) * 0.03
		var val := sin(t * 220.0 * (1.0 + drift) * TAU) * 0.08  # A3
		val += sin(t * 261.6 * TAU) * 0.05  # C4
		val += sin(t * 329.6 * (1.0 - drift) * TAU) * 0.04  # E4
		val += sin(t * 110.0 * TAU) * 0.1  # bass A2
		var fade_in := minf(t / 1.5, 1.0)
		var fade_out := minf((duration - t) / 1.5, 1.0)
		val *= fade_in * fade_out
		var sample := int(clampf(val, -1.0, 1.0) * 32767.0)
		buf[i * 2] = sample & 0xFF
		buf[i * 2 + 1] = (sample >> 8) & 0xFF
	var stream := _make_stream(buf, duration)
	stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	stream.loop_end = count
	return stream
