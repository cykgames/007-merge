extends Node
## 自動加載單例 Sfx —— 運行時合成音效，項目裏不需要任何音頻檔案。

const RATE := 22050

var _players: Array[AudioStreamPlayer] = []
var _next := 0
var _cache: Dictionary = {}

var muted := false


func _ready() -> void:
	for i in 12:
		var p := AudioStreamPlayer.new()
		add_child(p)
		_players.append(p)


# ---------------------------------------------------------------- 對外介面

func play_drop() -> void:
	_play(_tone(190.0, 0.14, 26.0, 0.15, 0.30), -15.0)


func play_merge(tier: int) -> void:
	# 越大的水果音調越低沉、越有分量
	var f := 700.0 * pow(0.90, maxi(tier, 0))
	_play(_tone(f, 0.30, 9.0, 0.45), -9.0)


func play_combo(n: int) -> void:
	_play(_tone(minf(660.0 * pow(1.14, n), 2200.0), 0.16, 14.0, 0.6), -11.0)


func play_pop() -> void:
	_play(_sweep(900.0, 200.0, 0.18, 0.35), -11.0)


func play_unlock() -> void:
	_play(_sweep(420.0, 1250.0, 0.42, 0.0), -8.0)


func play_game_over() -> void:
	_play(_sweep(520.0, 90.0, 0.9, 0.0), -7.0)


# ---------------------------------------------------------------- 內部

func _play(stream: AudioStream, volume_db: float) -> void:
	if muted:
		return
	var p := _players[_next]
	_next = (_next + 1) % _players.size()
	p.stream = stream
	p.volume_db = volume_db
	p.pitch_scale = randf_range(0.97, 1.03)
	p.play()


func _wav(data: PackedByteArray) -> AudioStreamWAV:
	var w := AudioStreamWAV.new()
	w.format = AudioStreamWAV.FORMAT_16_BITS
	w.mix_rate = RATE
	w.stereo = false
	w.data = data
	return w


## 帶諧波和衰減包絡的單音
func _tone(freq: float, dur: float, decay: float, harmonic: float, noise: float = 0.0) -> AudioStreamWAV:
	var key := "t%.1f_%.2f_%.1f_%.2f_%.2f" % [freq, dur, decay, harmonic, noise]
	if _cache.has(key):
		return _cache[key]

	var n := int(RATE * dur)
	var data := PackedByteArray()
	data.resize(n * 2)
	for i in n:
		var t := float(i) / RATE
		var env := exp(-decay * t) * clampf(t / 0.004, 0.0, 1.0)
		var s := sin(TAU * freq * t) + harmonic * sin(TAU * freq * 2.0 * t)
		if noise > 0.0:
			s += noise * (randf() * 2.0 - 1.0)
		data.encode_s16(i * 2, int(clampf(s * env * 0.30, -1.0, 1.0) * 32767.0))

	var w := _wav(data)
	_cache[key] = w
	return w


## 頻率從 f0 滑到 f1
func _sweep(f0: float, f1: float, dur: float, noise: float = 0.0) -> AudioStreamWAV:
	var key := "s%.1f_%.1f_%.2f_%.2f" % [f0, f1, dur, noise]
	if _cache.has(key):
		return _cache[key]

	var n := int(RATE * dur)
	var data := PackedByteArray()
	data.resize(n * 2)
	var phase := 0.0
	for i in n:
		var t := float(i) / RATE
		var u := t / dur
		var f: float = lerpf(f0, f1, u * u if f1 > f0 else u)
		phase += TAU * f / RATE
		var env := clampf(t / 0.006, 0.0, 1.0) * pow(1.0 - u, 1.6)
		var s := sin(phase) + 0.25 * sin(phase * 2.0)
		if noise > 0.0:
			s += noise * (randf() * 2.0 - 1.0)
		data.encode_s16(i * 2, int(clampf(s * env * 0.30, -1.0, 1.0) * 32767.0))

	var w := _wav(data)
	_cache[key] = w
	return w
