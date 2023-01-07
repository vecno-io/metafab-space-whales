extends Node


onready var total_points = get_node("%TotalPoints")


func _ready():
	#warning-ignore: return_value_discarded
	Global.connect("updated_points", self, "_on_updated_points")


func _exit_tree():
	Global.disconnect("updated_points", self, "_on_updated_points")


func _on_updated_points():
	total_points.text = "%03d" % Global.points

