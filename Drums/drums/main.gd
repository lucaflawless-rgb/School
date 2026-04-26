extends Node2D

const CH = 9

const NOTES = {
	"Crash": 49, "HiHat": 42, "Ride": 51,
	"Tom1": 48,  "Tom2": 45,
	"Snare": 38, "Kick": 36
}

const KEYS = {
	KEY_Q:"Crash", KEY_W:"HiHat", KEY_E:"Ride",
	KEY_R:"Tom1",  KEY_T:"Tom2",
	KEY_A:"Snare", KEY_S:"Kick"
}

func _ready():
	for drum in NOTES:
		get_node(drum).pressed.connect(_hit.bind(drum))

func _input(e):
	if e is InputEventKey and e.pressed and not e.echo:
		if e.keycode in KEYS: _hit(KEYS[e.keycode])

func _hit(drum: String):
	var note = NOTES[drum]

	var on = InputEventMIDI.new()
	on.channel = CH
	on.message = MIDI_MESSAGE_NOTE_ON
	on.pitch = note
	on.velocity = 110
	$MidiPlayer.receive_raw_midi_message(on)

	get_tree().create_timer(0.15).timeout.connect(func():
		var off = InputEventMIDI.new()
		off.channel = CH
		off.message = MIDI_MESSAGE_NOTE_OFF
		off.pitch = note
		off.velocity = 0
		$MidiPlayer.receive_raw_midi_message(off)
	)

	get_node(drum).modulate = Color(2, 2, 0.5)
	get_tree().create_timer(0.1).timeout.connect(func():
		get_node(drum).modulate = Color(1, 1, 1)
	)
	
