extends Node


onready var total_points = get_node("%TotalPoints")
onready var sector_level = get_node("%SectorLevel")


func _ready():
	#warning-ignore: return_value_discarded
	Global.connect("updated_points", self, "_on_updated_points")
	Global.connect("updated_difficulty", self, "_on_updated_difficulty")


func _exit_tree():
	Global.disconnect("updated_points", self, "_on_updated_points")
	Global.disconnect("updated_difficulty", self, "_on_updated_difficulty")


func _on_updated_points(value):
	total_points.text = "%03d" % value


func _on_updated_difficulty(value):
	sector_level.text = "%02d" % value
