extends Control

# Tracks which notes are currently playing
# key = midi note number, value = AudioStreamPlayer
var active_notes := {}

# Labels to show what's happening on screen
var status_label : Label
var note_label   : Label

func _ready() -> void:
	# Tell Godot to start listening for MIDI devices
	OS.open_midi_inputs()

	# Print all connected MIDI devices to the console
	print("MIDI devices found: ", OS.get_connected_midi_inputs())

	_build_ui()
	
func _build_ui() -> void:
	var sw := get_viewport_rect().size.x

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
	status_label.add_theme_color_override("font_color", Color(0.6,0.6,0.6))
	add_child(status_label)

	note_label = Label.new()
	note_label.text = ""
	note_label.position = Vector2(0, 200)
	note_label.size = Vector2(sw, 80)
	note_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	note_label.add_theme_font_size_override("font_size", 64)
	note_label.add_theme_color_override("font_color", Color.WHITE)
	add_child(note_label)
