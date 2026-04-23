extends Node2D

var height = 648
var width = 1152

var score = 0
var index_position = 0
var started = false
var responding = false

var notes = [52,53,54,55,56,57,58,59,60,61,62,63,64,65,66,67]
var white_keys = [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]
var black_keys = [0, 0, 0, 0, 0, 0]
var white_notes = [52,53,55,57,59,60,62,64,65,67]
var black_notes = [54,56,58,61,63,66]

var pattern = []
var pattern_length = []
var response = []





# Setup Functions

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	randomize()
	set_instrument(0,2)

# function to reset starts for when running the quiz
func start():
	started = true
	pattern = []
	index_position = 0
	response = []
	score = 0
	$Score.text = str('Score: ', score)
	playing()
	
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass

#function to setup instrument
func set_instrument(channel, instrument):
	var midi_event = InputEventMIDI.new()
	midi_event.channel = 0
	midi_event.message = MIDI_MESSAGE_PROGRAM_CHANGE
	midi_event.instrument = instrument
	$MidiPlayer.receive_raw_midi_message(midi_event)
	
func _draw() -> void:
	draw_rect(Rect2(0,0,width,height), Color.SKY_BLUE)
	
	var key_width = float(width) / 10
	var piano_height = float(height) / 2
	
	draw_rect(Rect2(0, piano_height, width, piano_height), Color.WHITE)
	
	# white keys
	for key in range(10):
		var x = key_width * key
		draw_line(Vector2(x, piano_height), Vector2(x, height), Color.BLACK)

		if white_keys[key] == 1:
			draw_rect(Rect2(x, piano_height, key_width, piano_height), Color.DIM_GRAY)
		elif white_keys[key] == 2:
			draw_rect(Rect2(x, piano_height, key_width, piano_height), Color.WEB_PURPLE)
			
	# black keys
	if black_keys[0] == 1:
		draw_rect(Rect2(1.75 * key_width, piano_height, key_width * 0.5, piano_height * 0.5), Color.DIM_GRAY)
	elif black_keys[0] == 2:
		draw_rect(Rect2(1.75 * key_width, piano_height, key_width * 0.5, piano_height * 0.5), Color.WEB_PURPLE)
	else:
		draw_rect(Rect2(1.75 * key_width, piano_height, key_width * 0.5, piano_height * 0.5), Color.BLACK)
	if black_keys[1] == 1:
		draw_rect(Rect2(2.75 * key_width, piano_height, key_width * 0.5, piano_height * 0.5), Color.DIM_GRAY)
	elif black_keys[1] == 2:
		draw_rect(Rect2(2.75 * key_width, piano_height, key_width * 0.5, piano_height * 0.5), Color.WEB_PURPLE)
	else:
		draw_rect(Rect2(2.75 * key_width, piano_height, key_width * 0.5, piano_height * 0.5), Color.BLACK)
	if black_keys[2] == 1:
		draw_rect(Rect2(3.75 * key_width, piano_height, key_width * 0.5, piano_height * 0.5), Color.DIM_GRAY)
	elif black_keys[2] == 2:
		draw_rect(Rect2(3.75 * key_width, piano_height, key_width * 0.5, piano_height * 0.5), Color.WEB_PURPLE)
	else:
		draw_rect(Rect2(3.75 * key_width, piano_height, key_width * 0.5, piano_height * 0.5), Color.BLACK)
	if black_keys[3] == 1:
		draw_rect(Rect2(5.75 * key_width, piano_height, key_width * 0.5, piano_height * 0.5), Color.DIM_GRAY)
	elif black_keys[3] == 2:
		draw_rect(Rect2(5.75 * key_width, piano_height, key_width * 0.5, piano_height * 0.5), Color.WEB_PURPLE)
	else:
		draw_rect(Rect2(5.75 * key_width, piano_height, key_width * 0.5, piano_height * 0.5), Color.BLACK)
	if black_keys[4] == 1:
		draw_rect(Rect2(6.75 * key_width, piano_height, key_width * 0.5, piano_height * 0.5), Color.DIM_GRAY)
	elif black_keys[4] == 2:
		draw_rect(Rect2(6.75 * key_width, piano_height, key_width * 0.5, piano_height * 0.5), Color.WEB_PURPLE)
	else:
		draw_rect(Rect2(6.75 * key_width, piano_height, key_width * 0.5, piano_height * 0.5), Color.BLACK)
	if black_keys[5] == 1:
		draw_rect(Rect2(8.75 * key_width, piano_height, key_width * 0.5, piano_height * 0.5), Color.DIM_GRAY)
	elif black_keys[5] == 2:
		draw_rect(Rect2(8.75 * key_width, piano_height, key_width * 0.5, piano_height * 0.5), Color.WEB_PURPLE)
	else:
		draw_rect(Rect2(8.75 * key_width, piano_height, key_width * 0.5, piano_height * 0.5), Color.BLACK)

	# looks weird so adding 2 keys to make it look more like a piano
	draw_rect(Rect2(0 * key_width, piano_height, key_width * 0.25, piano_height * 0.5), Color.BLACK)
	draw_rect(Rect2(9.75 * key_width, piano_height, key_width * 0.25, piano_height * 0.5), Color.BLACK)





# Music / Note Playing Functions

func playing():
	for x in pattern_length:
		var index = randi_range(0,15)
		pattern.append(notes[index])
	
	for note in pattern:
		active_key(note)
		play_note(note)
		await get_tree().create_timer(0.3).timeout
		play_note_off(note)
		await get_tree().create_timer(0.5).timeout
		
	started = false
	responding = true

# play note function
func play_note(pitch):
	var m = InputEventMIDI.new()
	m.message = MIDI_MESSAGE_NOTE_ON
	m.pitch = pitch
	m.velocity = 100
	m.channel = 0		
	$MidiPlayer.receive_raw_midi_message(m)	
	queue_redraw()

# stop playing note
func play_note_off(pitch):
	var m = InputEventMIDI.new()
	m.message = MIDI_MESSAGE_NOTE_ON
	m.pitch = pitch
	m.velocity = 0
	m.channel = 0		
	$MidiPlayer.receive_raw_midi_message(m)
	white_keys = [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]
	black_keys = [0, 0, 0, 0, 0, 0]
	queue_redraw()

# code brought over from create_music.gd to help with the recalling function
# function to take inputted key and play the appropiate music and display correctly
func _input(event):
	var note = 0
	if started:
		return

	if event is InputEventKey:
		if event.is_pressed() and not event.is_echo():
			note = key_to_note(event.keycode)
			if note != 0:
				active_key(note)
				play_note(note)
				
				if responding:
					response.append(note)
					recalling(response)
		
		elif event.is_released():
			play_note_off(note)







# Game Functions
# function to manage how correct a guess and adjust
func recalling(guess):
	if guess[index_position] == pattern[index_position]:
		score += 1
	elif abs(guess[index_position] - pattern[index_position]) == 1:
		score += 0.5
		incorrect_key(pattern[index_position])
	elif abs(guess[index_position] - pattern[index_position]) == 2:
		score += 0.25
		incorrect_key(pattern[index_position])
	else:
		incorrect_key(pattern[index_position])
	index_position += 1
	$Score.text = str('Score: ', score)
	if index_position == pattern_length:
		responding = false






# Searching Functions

# function to find key which is playing played and mark it as active
func active_key(key):
	match key:
		52: white_keys[0] = 1
		53: white_keys[1] = 1
		54: black_keys[0] = 1
		55: white_keys[2] = 1
		56: black_keys[1] = 1
		57: white_keys[3] = 1
		58: black_keys[2] = 1
		59: white_keys[4] = 1
		60: white_keys[5] = 1
		61: black_keys[3] = 1
		62: white_keys[6] = 1
		63: black_keys[4] = 1
		64: white_keys[7] = 1
		65: white_keys[8] = 1
		66: black_keys[5] = 1
		67: white_keys[9] = 1

# function to find the index of what is the correct key and mark it
func incorrect_key(key):
	match key:
		52: white_keys[0] = 2
		53: white_keys[1] = 2
		54: black_keys[0] = 2
		55: white_keys[2] = 2
		56: black_keys[1] = 2
		57: white_keys[3] = 2
		58: black_keys[2] = 2
		59: white_keys[4] = 2
		60: white_keys[5] = 2
		61: black_keys[3] = 2
		62: white_keys[6] = 2
		63: black_keys[4] = 2
		64: white_keys[7] = 2
		65: white_keys[8] = 2
		66: black_keys[5] = 2
		67: white_keys[9] = 2


# function to find what note is linked to the keyboard key
func key_to_note(key):
	match key:
		KEY_A: return 52
		KEY_S: return 53
		KEY_E: return 54
		KEY_D: return 55
		KEY_R: return 56
		KEY_F: return 57
		KEY_T: return 58
		KEY_G: return 59
		KEY_H: return 60
		KEY_U: return 61
		KEY_J: return 62
		KEY_I: return 63
		KEY_K: return 64
		KEY_L: return 65
		KEY_P: return 66
		KEY_SEMICOLON: return 67
		_: return 0
