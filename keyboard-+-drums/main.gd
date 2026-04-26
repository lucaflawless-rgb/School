extends Control

var active_notes := {}
var status_label : Label
var note_label   : Label


func _ready() -> void:
	OS.open_midi_inputs()
	print("MIDI devices: ", OS.get_connected_midi_inputs())
	_build_ui()


func _build_ui() -> void:
	var sw := get_viewport_rect().size.x

	var bg := ColorRect.new()
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.color = Color(0.10, 0.10, 0.13)
	add_child(bg)

	var title := Label.new()
	title.text = "MIDI Piano"
	title.position = Vector2(0, 30)
	title.size = Vector2(sw, 40)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 32)
	title.add_theme_color_override("font_color", Color.WHITE)
	add_child(title)

	status_label = Label.new()
	status_label.text = "Waiting for MIDI..."
	status_label.position = Vector2(0, 80)
	status_label.size = Vector2(sw, 28)
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status_label.add_theme_font_size_override("font_size", 15)
	status_label.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
	add_child(status_label)

	note_label = Label.new()
	note_label.text = ""
	note_label.position = Vector2(0, 180)
	note_label.size = Vector2(sw, 100)
	note_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	note_label.add_theme_font_size_override("font_size", 80)
	note_label.add_theme_color_override("font_color", Color.WHITE)
	add_child(note_label)


func _input(event: InputEvent) -> void:
	if not event is InputEventMIDI:
		return

	if event.message == MIDI_MESSAGE_NOTE_ON and event.velocity > 0:
		play_midi_note(event.pitch, event.velocity)
	elif event.message == MIDI_MESSAGE_NOTE_OFF:
		stop_midi_note(event.pitch)
	elif event.message == MIDI_MESSAGE_NOTE_ON and event.velocity == 0:
		stop_midi_note(event.pitch)


func play_midi_note(pitch: int, velocity: int) -> void:
	if pitch in active_notes:
		return

	var stream := AudioStreamGenerator.new()
	stream.mix_rate      = 44100.0
	stream.buffer_length = 0.5

	var player := AudioStreamPlayer.new()
	player.stream    = stream
	player.volume_db = linear_to_db(velocity / 127.0)
	add_child(player)
	player.play()

	var pb    := player.get_stream_playback() as AudioStreamGeneratorPlayback
	var freq  := midi_to_freq(pitch)
	var count := pb.get_frames_available()
	for f in range(count):
		var t := float(f) / 44100.0
		var s := sin(t * freq * TAU) * 0.8
		pb.push_frame(Vector2(s, s))

	active_notes[pitch] = player

	var names := ["C","C#","D","D#","E","F","F#","G","G#","A","A#","B"]
	note_label.text   = names[pitch % 12]
	status_label.text = "Note %d  |  Vel %d  |  %.1f Hz" % [pitch, velocity, freq]


func stop_midi_note(pitch: int) -> void:
	if not pitch in active_notes:
		return

	var player : AudioStreamPlayer = active_notes[pitch]
	var tween := create_tween()
	tween.tween_property(player, "volume_db", -80.0, 0.15)
	tween.tween_callback(player.queue_free)
	active_notes.erase(pitch)

	if active_notes.is_empty():
		note_label.text   = ""
		status_label.text = "Waiting for MIDI..."


func midi_to_freq(pitch: int) -> float:
	return 440.0 * pow(2.0, (pitch - 69.0) / 12.0)


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		OS.close_midi_inputs()
