extends Control

@onready var midi_node := $midi

var key_areas : Dictionary = {}
var key_rects : Dictionary = {}
var note_names := ["C","C#","D","D#","E","F","F#","G","G#","A","A#","B"]
var info_label : Label
var status_bar : ColorRect
var held_note  : int = -1
var is_recording := false
var recorded     : Array = []
var rec_start    : float = 0.0
var note_starts  : Dictionary = {}
var key_to_note  := {KEY_A:60,KEY_W:61,KEY_S:62,KEY_E:63,KEY_D:64,KEY_F:65,KEY_T:66,KEY_G:67,KEY_Y:68,KEY_H:69,KEY_U:70,KEY_J:71}
var WHITE := [60,62,64,65,67,69,71]
var BLACK := [61,63,66,68,70]


func _ready() -> void:
	_cr(Color(0.08,0.08,0.10), Vector2.ZERO, get_viewport_rect().size)
	status_bar = _cr(Color(0.13,0.13,0.17), Vector2(0, get_viewport_rect().size.y - 48), Vector2(get_viewport_rect().size.x, 48))
	var hdr := _cr(Color(0.13,0.13,0.17), Vector2.ZERO, Vector2(get_viewport_rect().size.x, 52))
	_lbl("MIDI Piano", Vector2(0,10), 24, Color.WHITE, true)
	info_label = _lbl("M=Rec  N=Play  B=Save  V=Load", Vector2(0, get_viewport_rect().size.y-38), 13, Color(0.7,0.7,0.7), true)
	_draw_keys()


func _cr(col: Color, pos: Vector2, sz: Vector2) -> ColorRect:
	var c := ColorRect.new(); c.color = col; c.position = pos; c.size = sz; add_child(c); return c


func _lbl(txt: String, pos: Vector2, size: int, col: Color, wide: bool) -> Label:
	var l := Label.new(); l.text = txt; l.position = pos
	l.size = Vector2(get_viewport_rect().size.x, 36) if wide else Vector2(200, 36)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER if wide else HORIZONTAL_ALIGNMENT_LEFT
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", col); add_child(l); return l


func _draw_keys() -> void:
	var sx : float = (get_viewport_rect().size.x - 7*70.0) / 2.0
	var sy : float = 62.0
	var bx : Array[float] = [sx+46, sx+116, sx+256, sx+326, sx+396]
	for i in range(WHITE.size()):
		var x : float = sx + i * 70.0
		_cr(Color(0,0,0,0.3), Vector2(x+2, sy+2), Vector2(66,200))
		var cr := _cr(Color(0.97,0.97,0.95), Vector2(x, sy), Vector2(66,200))
		key_rects[WHITE[i]] = cr; key_areas[WHITE[i]] = Rect2(x, sy, 66, 200)
		_lbl(note_names[WHITE[i]%12], Vector2(x+20, sy+168), 13, Color(0.6,0.6,0.6), false)
	for i in range(BLACK.size()):
		_cr(Color(0,0,0,0.4), Vector2(bx[i]+2, sy+2), Vector2(40,120))
		var cr := _cr(Color(0.12,0.12,0.12), Vector2(bx[i], sy), Vector2(40,120))
		key_rects[BLACK[i]] = cr; key_areas[BLACK[i]] = Rect2(bx[i], sy, 40, 120)


func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			var found := -1
			for n in BLACK:
				if key_areas[n].has_point(event.position): found = n; break
			if found == -1:
				for n in WHITE:
					if key_areas[n].has_point(event.position): found = n; break
			if found != -1: held_note = found; _press(found)
		else:
			if held_note != -1: _release(held_note); held_note = -1
	if event is InputEventKey and not event.echo:
		if event.pressed:
			match event.keycode:
				KEY_M: _toggle_rec()
				KEY_N: _playback()
				KEY_B: _save()
				KEY_V: _load()
		if event.keycode in key_to_note:
			if event.pressed: _press(key_to_note[event.keycode])
			else: _release(key_to_note[event.keycode])


func _press(note: int) -> void:
	if note in key_rects: key_rects[note].color = Color(0.3,0.6,1.0)
	info_label.text = note_names[note % 12]
	midi_node._process_track_event_note_on(midi_node.channel_status[0], note, 100)
	if is_recording: note_starts[note] = Time.get_ticks_msec() - rec_start


func _release(note: int) -> void:
	if note in key_rects:
		key_rects[note].color = Color(0.12,0.12,0.12) if [1,3,6,8,10].has(note%12) else Color(0.97,0.97,0.95)
	info_label.text = "M=Rec  N=Play  B=Save  V=Load"
	midi_node._process_track_event_note_off(midi_node.channel_status[0], note)
	if is_recording and note in note_starts:
		recorded.append({"note":note,"on":note_starts[note],"off":Time.get_ticks_msec()-rec_start})
		note_starts.erase(note)


func _toggle_rec() -> void:
	is_recording = !is_recording
	if is_recording:
		recorded.clear(); rec_start = Time.get_ticks_msec()
		info_label.text = "● Recording...  M to stop"
		info_label.add_theme_color_override("font_color", Color(1.0,0.4,0.4))
		status_bar.color = Color(0.25,0.08,0.08)
	else:
		info_label.text = "Recorded %d notes" % recorded.size()
		info_label.add_theme_color_override("font_color", Color(0.7,0.7,0.7))
		status_bar.color = Color(0.13,0.13,0.17)


func _playback() -> void:
	if recorded.is_empty(): info_label.text = "Nothing recorded"; return
	info_label.text = "▶ Playing..."; info_label.add_theme_color_override("font_color", Color(0.4,0.9,0.5))
	status_bar.color = Color(0.08,0.20,0.10)
	for e in recorded:
		get_tree().create_timer(e["on"]/1000.0).timeout.connect(func(): _press(e["note"]))
		get_tree().create_timer(e["off"]/1000.0).timeout.connect(func(): _release(e["note"]))
	get_tree().create_timer(recorded[-1]["off"]/1000.0+0.3).timeout.connect(func():
		status_bar.color=Color(0.13,0.13,0.17); info_label.add_theme_color_override("font_color",Color(0.7,0.7,0.7)))


func _save() -> void:
	if recorded.is_empty(): info_label.text = "Nothing to save"; return
	var f := FileAccess.open("user://recording.json", FileAccess.WRITE)
	f.store_string(JSON.stringify(recorded)); f.close(); info_label.text = "✓ Saved!"


func _load() -> void:
	if not FileAccess.file_exists("user://recording.json"): info_label.text = "No save file found"; return
	var f := FileAccess.open("user://recording.json", FileAccess.READ)
	recorded = JSON.parse_string(f.get_as_text()); f.close()
	info_label.text = "✓ Loaded %d notes" % recorded.size()
