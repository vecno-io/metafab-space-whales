extends Node

var score = 0

var shake_screen = false
var shake_intensity = 0

onready var control = get_node("%Control")

onready var shake_timer = get_node("%ShakeTimer")

onready var highsocre = get_node("%LastHighsocre")

onready var total_points = get_node("%TotalPoints")
onready var sector_level = get_node("%SectorLevel")


func _ready():
	randomize()
	Global.overlay = self
	score = Global.highsocre
	highsocre.text = "%03d" % score
	#warning-ignore: return_value_discarded
	Global.connect("updated_points", self, "_on_updated_points")
	#warning-ignore: return_value_discarded
	Global.connect("updated_difficulty", self, "_on_updated_difficulty")


func _process(delta):
	control.rect_scale = lerp(control.rect_scale, Vector2(1, 1), 0.24)
	if shake_screen:
		var x = rand_range(-shake_intensity, shake_intensity)
		var y = rand_range(-shake_intensity, shake_intensity)
		control.rect_position += Vector2(x, y) * delta
	else:
		control.rect_position = lerp(control.rect_position, Vector2(0, 0), 0.24)


func screen_shake(intensity, time):
	control.rect_scale = Vector2.ONE - Vector2(intensity * 0.0004, intensity * 0.0004)
	shake_intensity = intensity * 0.5
	shake_timer.wait_time = time
	shake_screen = true
	shake_timer.start()


func _on_shake_timeout():
	shake_intensity = 0
	shake_screen = false


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
