extends Control

var note_names := ["C","D","E","F","G","A","B"]
var note_keys  := [KEY_A,KEY_S,KEY_D,KEY_F,KEY_G,KEY_H,KEY_J]
var midi_notes := [60, 62, 64, 65, 67, 69, 71]

var players   : Array[AudioStreamPlayer] = []
var key_rects : Array[ColorRect] = []
var key_held  := [false,false,false,false,false,false,false]
