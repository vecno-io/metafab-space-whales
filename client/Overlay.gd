extends Node

var score = 0

onready var highsocre = get_node("%LastHighsocre")

onready var total_points = get_node("%TotalPoints")
onready var sector_level = get_node("%SectorLevel")


func _ready():
	score = Global.highsocre
	highsocre.text = "%03d" % score
	#warning-ignore: return_value_discarded
	Global.connect("updated_points", self, "_on_updated_points")
	#warning-ignore: return_value_discarded
	Global.connect("updated_difficulty", self, "_on_updated_difficulty")


func _exit_tree():
	Global.disconnect("updated_points", self, "_on_updated_points")
	Global.disconnect("updated_difficulty", self, "_on_updated_difficulty")


func _on_updated_points(value):
	total_points.text = "%03d" % value
	if value > score: 
		score = value
		highsocre.text = total_points.text


func _on_updated_difficulty(value):
	sector_level.text = "%02d" % value
