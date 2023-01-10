extends Node


onready var music_player = get_node("%MusicPlayer")
onready var effect_players = get_node("%EffectPlayers")


func play_sfx_effect(sfx):
	var chidren = effect_players.get_children()
	for i in chidren.size():
		var effect = chidren[i]
		if !effect.playing:
			effect.global_position = sfx.global_position
			effect.pitch_scale = sfx.pitch_scale
			effect.volume_db = sfx.volume_db
			effect.stream = sfx.stream
			effect.play()
			return
