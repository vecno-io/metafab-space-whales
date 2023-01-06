extends Node


var sector_node = null
var local_player = null


func instance_node(node, parent, location):
	var object = node.instance()
	parent.add_child(object)
	object.global_position = location
	return object
