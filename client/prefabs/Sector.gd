extends Node2D


func _ready():
	Global.sector_node = self


func _exit_tree():
	Global.sector_node = null
