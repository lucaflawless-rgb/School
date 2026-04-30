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

var recording := false
var rec_start := 0.0
var takes := []

func _ready():
	for drum in NOTES:
		get_node(drum).pressed.connect(_hit.bind(drum))
	$BtnRec.pressed.connect(_rec)
	$BtnStop.pressed.connect(_stop)
	$BtnPlay.pressed.connect(_play)
	$BtnClear.pressed.connect(_clear)
	$BtnStop.disabled = true
	$BtnPlay.disabled = true
	$BtnClear.disabled = true

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

	if recording:
		takes.append({"drum": drum, "ms": Time.get_ticks_msec() - rec_start})

func _rec():
	takes.clear()
	recording = true
	rec_start = Time.get_ticks_msec()
	$BtnRec.disabled = true
	$BtnStop.disabled = false
	$BtnPlay.disabled = true
	$BtnClear.disabled = true
	$Status.text = "recording..."

func _stop():
	recording = false
	$BtnRec.disabled = false
	$BtnStop.disabled = true
	$BtnClear.disabled = false
	if takes.size() > 0:
		$BtnPlay.disabled = false
		$Status.text = "%d hits recorded — press PLAY" % takes.size()
	else:
		$Status.text = "nothing recorded"

func _play():
	$BtnPlay.disabled = true
	$BtnRec.disabled = true
	$Status.text = "playing back..."
	for hit in takes:
		var drum: String = hit["drum"]
		get_tree().create_timer(hit["ms"] / 1000.0).timeout.connect(func():
			_hit(drum)
		)

	var dur = takes[-1]["ms"] / 1000.0
	get_tree().create_timer(dur + 0.3).timeout.connect(func():
		$BtnPlay.disabled = false
		$BtnRec.disabled = false
		$Status.text = "done — press PLAY again or REC for new take"
	)

func _clear():
	takes.clear()
	$BtnPlay.disabled = true
	$BtnClear.disabled = true
	$Status.text = "press REC and start playing"
	
