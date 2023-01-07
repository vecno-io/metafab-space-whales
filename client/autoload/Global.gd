extends Node

signal game_paused
signal game_unpaused

signal updated_points

var points = 0 setget _no_set
var paused = true setget _no_set

var sector_node = null
var local_player = null


func _no_set(_value):
	pass


func pause_game():
	paused = true
	emit_signal("game_paused")


func unpause_game():
	paused = false
	emit_signal("game_unpaused")


func add_points(value):
	points += value
	emit_signal("updated_points")


func instance_node(node, parent, location):
	var object = node.instance()
	parent.add_child(object)
	object.global_position = location
	return object
