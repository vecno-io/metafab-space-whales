extends Node

var score = 0
var active = null

var shake_screen = false
var shake_intensity = 0

onready var game_view  = get_node("%GameView")
onready var dialog_view  = get_node("%DialogView")
onready var tutorial_view  = get_node("%TutorialView")

onready var shake_timer = get_node("%ShakeTimer")

onready var last_socre = get_node("%LastHighsocre")
onready var tutorial_socre = get_node("%TutorialHighsocre")

onready var total_points = get_node("%TotalPoints")
onready var sector_level = get_node("%SectorLevel")


func _ready():
	randomize()
	Global.overlay = self
	game_view.visible = false
	dialog_view.visible = false
	tutorial_view.visible = false
	score = Global.highsocre
	active = tutorial_view
	last_socre.text = "%03d" % score
	tutorial_socre.text = last_socre.text
	#warning-ignore: return_value_discarded
	Global.connect("updated_points", self, "_on_updated_points")
	#warning-ignore: return_value_discarded
	Global.connect("updated_difficulty", self, "_on_updated_difficulty")


func _exit_tree():
	Global.overlay = null
	Global.disconnect("updated_points", self, "_on_updated_points")
	Global.disconnect("updated_difficulty", self, "_on_updated_difficulty")


func _process(delta):
	active.rect_scale = lerp(active.rect_scale, Vector2(1, 1), 0.24)
	if shake_screen:
		var x = rand_range(-shake_intensity, shake_intensity)
		var y = rand_range(-shake_intensity, shake_intensity)
		active.rect_position += Vector2(x, y) * delta
	else:
		active.rect_position = lerp(active.rect_position, Vector2(0, 0), 0.24)


func show_game():
	game_view.visible = true
	dialog_view.visible = false
	tutorial_view.visible = false


func show_dialog():
	game_view.visible = false
	dialog_view.visible = true
	tutorial_view.visible = false


func show_tutorial():
	game_view.visible = false
	dialog_view.visible = false
	tutorial_view.visible = true


func screen_shake(intensity, time):
	active.rect_scale = Vector2.ONE - Vector2(intensity * 0.0004, intensity * 0.0004)
	shake_intensity = intensity * 0.5
	shake_timer.wait_time = time
	shake_screen = true
	shake_timer.start()


func _on_shake_timeout():
	shake_intensity = 0
	shake_screen = false


func _on_updated_points(value):
	total_points.text = "%03d" % value
	if value > score: 
		score = value
		last_socre.text = total_points.text
		tutorial_socre.text = last_socre.text


func _on_updated_difficulty(value):
	sector_level.text = "%02d" % value


func _on_start_pressed():
	Global.show_game()


func _on_jump_in_pressed():
	Global.show_game()


func _on_jump_out_pressed():
	Global.show_dialog()
