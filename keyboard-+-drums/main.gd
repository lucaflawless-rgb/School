extends Control

@onready var midi_node := $midi

var key_areas  : Dictionary    = {}
var key_rects  : Dictionary    = {}
var note_names : Array[String] = ["C","C#","D","D#","E","F","F#","G","G#","A","A#","B"]
var info_label : Label
var held_note  : int   = -1

# Recording
var is_recording : bool  = false
var recorded     : Array = []
var rec_start    : float = 0.0
var note_starts  : Dictionary = {}

var key_to_note : Dictionary = {
	KEY_A: 60, KEY_W: 61, KEY_S: 62, KEY_E: 63,
	KEY_D: 64, KEY_F: 65, KEY_T: 66, KEY_G: 67,
	KEY_Y: 68, KEY_H: 69, KEY_U: 70, KEY_J: 71
}


func _ready() -> void:
	# Background
	var bg := ColorRect.new()
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.color = Color(0.1, 0.1, 0.13)
	add_child(bg)

	# Title
	var title := Label.new()
	title.text = "MIDI Piano"
	title.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	title.offset_top = 20
	title.offset_bottom = 55
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 28)
	title.add_theme_color_override("font_color", Color.WHITE)
	add_child(title)

	# Info label
	info_label = Label.new()
	info_label.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	info_label.offset_top = -36
	info_label.offset_bottom = -6
	info_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	info_label.add_theme_font_size_override("font_size", 14)
	info_label.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
	info_label.text = "R = Record  P = Play  S = Save  L = Load"
	add_child(info_label)

	_draw_keys()


func _draw_keys() -> void:
	var white_midis : Array[int] = [60, 62, 64, 65, 67, 69, 71]
	var black_midis : Array[int] = [61, 63, 66, 68, 70]
	var sx : float = (get_viewport_rect().size.x - 7 * 70.0) / 2.0
	var sy : float = 110.0
	var bx : Array[float] = [
		sx+0*70+46, sx+1*70+46, sx+3*70+46, sx+4*70+46, sx+5*70+46
	]

	for i : int in range(white_midis.size()):
		var note : int   = white_midis[i]
		var x    : float = sx + i * 70.0
		var cr   := ColorRect.new()
		cr.position = Vector2(x, sy)
		cr.size     = Vector2(66, 200)
		cr.color    = Color.WHITE
		add_child(cr)
		key_rects[note] = cr
		key_areas[note] = Rect2(x, sy, 66, 200)
		var lbl := Label.new()
		lbl.text = note_names[note % 12]
		lbl.position = Vector2(x + 22, sy + 170)
		lbl.add_theme_font_size_override("font_size", 14)
		lbl.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
		add_child(lbl)

	for i : int in range(black_midis.size()):
		var note : int = black_midis[i]
		var cr   := ColorRect.new()
		cr.position = Vector2(bx[i], sy)
		cr.size     = Vector2(40, 120)
		cr.color    = Color(0.1, 0.1, 0.1)
		add_child(cr)
		key_rects[note] = cr
		key_areas[note] = Rect2(bx[i], sy, 40, 120)


func _input(event: InputEvent) -> void:
	# Mouse clicks
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			var found : int = -1
			for note : int in [61,63,66,68,70]:
				if key_areas[note].has_point(event.position):
					found = note
					break
			if found == -1:
				for note : int in [60,62,64,65,67,69,71]:
					if key_areas[note].has_point(event.position):
						found = note
						break
			if found != -1:
				held_note = found
				_press_note(found)
		else:
			if held_note != -1:
				_release_note(held_note)
				held_note = -1

	# Keyboard
	if event is InputEventKey and not event.echo and event.pressed:
		match event.keycode:
			KEY_R: _toggle_record()
			KEY_P: _play_back()
			KEY_S: _save()
			KEY_L: _load()

	if event is InputEventKey and not event.echo:
		if event.keycode in key_to_note:
			var note : int = key_to_note[event.keycode]
			if event.pressed:
				_press_note(note)
			else:
				_release_note(note)


func _press_note(note: int) -> void:
	if note in key_rects:
		key_rects[note].color = Color(0.3, 0.6, 1.0)
	info_label.text = note_names[note % 12]
	midi_node._process_track_event_note_on(midi_node.channel_status[0], note, 100)
	if is_recording:
		note_starts[note] = Time.get_ticks_msec() - rec_start


func _release_note(note: int) -> void:
	if note in key_rects:
		var is_black : bool = [1,3,6,8,10].has(note % 12)
		key_rects[note].color = Color(0.1,0.1,0.1) if is_black else Color.WHITE
	info_label.text = "R = Record  P = Play  S = Save  L = Load"
	midi_node._process_track_event_note_off(midi_node.channel_status[0], note)
	if is_recording and note in note_starts:
		recorded.append({"note": note, "on": note_starts[note], "off": Time.get_ticks_msec() - rec_start})
		note_starts.erase(note)


func _toggle_record() -> void:
	is_recording = !is_recording
	if is_recording:
		recorded.clear()
		rec_start = Time.get_ticks_msec()
		info_label.text = "● Recording... press R to stop"
	else:
		info_label.text = "Recorded %d notes — P to play" % recorded.size()


func _play_back() -> void:
	if recorded.is_empty():
		info_label.text = "Nothing recorded yet"
		return
	info_label.text = "Playing back..."
	for entry in recorded:
		get_tree().create_timer(entry["on"]  / 1000.0).timeout.connect(func(): _press_note(entry["note"]))
		get_tree().create_timer(entry["off"] / 1000.0).timeout.connect(func(): _release_note(entry["note"]))


func _save() -> void:
	if recorded.is_empty():
		info_label.text = "Nothing to save"
		return
	var f := FileAccess.open("user://recording.json", FileAccess.WRITE)
	f.store_string(JSON.stringify(recorded))
	f.close()
	info_label.text = "Saved!"


func _load() -> void:
	if not FileAccess.file_exists("user://recording.json"):
		info_label.text = "No save file found"
		return
	var f := FileAccess.open("user://recording.json", FileAccess.READ)
	recorded = JSON.parse_string(f.get_as_text())
	f.close()
	info_label.text = "Loaded %d notes — P to play" % recorded.size()
