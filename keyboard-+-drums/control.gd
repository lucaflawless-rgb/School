extends Control

@onready var midi_player := $MidiPlayer

var note_label  : Label
var info_label  : Label
var note_names  := ["C","C#","D","D#","E","F","F#","G","G#","A","A#","B"]


func _ready() -> void:
	# Dark background
	var bg := ColorRect.new()
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.color = Color(0.1, 0.1, 0.13)
	add_child(bg)

	# Title
	var title := Label.new()
	title.text = "MIDI Piano"
	title.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	title.offset_top = 30
	title.offset_bottom = 70
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 32)
	title.add_theme_color_override("font_color", Color.WHITE)
	add_child(title)

	# Big note name
	note_label = Label.new()
	note_label.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	note_label.offset_left = -200
	note_label.offset_right = 200
	note_label.offset_top = -60
	note_label.offset_bottom = 60
	note_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	note_label.add_theme_font_size_override("font_size", 90)
	note_label.add_theme_color_override("font_color", Color(0.3, 0.7, 1.0))
	add_child(note_label)

	# Info line at bottom
	info_label = Label.new()
	info_label.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	info_label.offset_top = -40
	info_label.offset_bottom = -10
	info_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	info_label.add_theme_font_size_override("font_size", 14)
	info_label.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
	add_child(info_label)

	# Play the midi file using the sf2 soundfont
	if midi_player.stream != null:
		info_label.text = "Playing..."
		midi_player.play()
	else:
		info_label.text = "Assign a .mid file to MidiPlayer > Stream in the Inspector"


func _input(event: InputEvent) -> void:
	if not event is InputEventMIDI:
		return

	if event.message == MIDI_MESSAGE_NOTE_ON and event.velocity > 0:
		note_label.text = note_names[event.pitch % 12]
		info_label.text = "Note %d  |  %s  |  Velocity %d" % [event.pitch, note_names[event.pitch % 12], event.velocity]

	elif event.message == MIDI_MESSAGE_NOTE_OFF or (event.message == MIDI_MESSAGE_NOTE_ON and event.velocity == 0):
		note_label.text = ""
		info_label.text = "Playing..."
