extends Node


signal updated_points

var points = 0 setget _no_set

var sector_node = null
var local_player = null


func _no_set(_value):
	pass


func add_points(value):
	points += value
	emit_signal("updated_points")


func instance_node(node, parent, location):
	var object = node.instance()
	parent.add_child(object)
	object.global_position = location
	return object
