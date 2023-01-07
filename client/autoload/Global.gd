extends Node


signal game_paused
signal game_unpaused

signal updated_points(value)
signal updated_difficulty(value)


var points = 0 setget _no_set
var paused = true setget _no_set

var local_camera = null
var local_player = null
var local_sector = null setget _set_sector


func _no_set(_value):
	pass


func _set_sector(value):
	_sector_disconnect()
	local_sector = value
	_sector_connect()
	_sector_reset()


func _sector_reset():
	points = 0;
	paused = false;
	emit_signal("updated_points", 0)
	emit_signal("updated_difficulty", 0)

func _sector_connect():
	if local_sector == null:
		return
	local_sector.connect("updated_difficulty", self, "_sector_updated_difficulty")


func _sector_disconnect():
	if local_sector == null:
		return
	local_sector.disconnect("updated_difficulty", self, "_sector_updated_difficulty")


func _sector_updated_difficulty(value):
	emit_signal("updated_difficulty", value)


func pause_game():
	paused = true
	emit_signal("game_paused")


func unpause_game():
	paused = false
	emit_signal("game_unpaused")


func add_points(value):
	points += value
	emit_signal("updated_points", points)


func instance_node(node, parent, location):
	var object = node.instance()
	parent.add_child(object)
	object.global_position = location
	return object
