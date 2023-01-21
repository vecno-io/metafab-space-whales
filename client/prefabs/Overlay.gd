extends Node


var active = null
var highsocre = 0

var shake_screen = false
var shake_intensity = 0

onready var game_view  = get_node("%GameView")
onready var dialog_view  = get_node("%DialogView")
onready var tutorial_view  = get_node("%TutorialView")

onready var shake_timer = get_node("%ShakeTimer")

onready var thread_lvl = get_node("%ThreadLvl")
onready var points_high = get_node("%PointsHigh")
onready var points_sector = get_node("%PointsSector")

onready var kill_count = get_node("%KillCount")
onready var dust_storage = get_node("%DustStorage")
onready var dust_inventory = get_node("%DustInventory")

onready var speed_inventory = get_node("%SpeedInventory")
onready var firerate_inventory = get_node("%FirerateInventory")


func _ready():
	randomize()
	Global.overlay = self
	game_view.visible = false
	dialog_view.visible = false
	tutorial_view.visible = false
	active = tutorial_view
	highsocre = Global.highsocre
	points_high.text = "%04d" % highsocre
	dust_storage.text = "%04d" % Global.dust_storage
	dust_inventory.text = "%04d" % Global.dust_inventory
	speed_inventory.text = "%d/8" % Global.speed_inventory
	firerate_inventory.text = "%d/8" % Global.firerate_inventory
	#warning-ignore: return_value_discarded
	Global.connect("updated_kills", self, "_on_updated_kills")
	#warning-ignore: return_value_discarded
	Global.connect("updated_points", self, "_on_updated_points")
	#warning-ignore: return_value_discarded
	Global.connect("updated_difficulty", self, "_on_updated_difficulty")
	#warning-ignore: return_value_discarded
	Global.connect("dust_storage_updated", self, "_on_dust_storage_updated")
	#warning-ignore: return_value_discarded
	Global.connect("dust_inventory_updated", self, "_on_dust_inventory_updated")
	#warning-ignore: return_value_discarded
	Global.connect("speed_inventory_updated", self, "_on_speed_inventory_updated")
	#warning-ignore: return_value_discarded
	Global.connect("firerate_inventory_updated", self, "_on_firerate_inventory_updated")


func _exit_tree():
	Global.overlay = null
	Global.disconnect("updated_kills", self, "_on_updated_kills")
	Global.disconnect("updated_points", self, "_on_updated_points")
	Global.disconnect("updated_difficulty", self, "_on_updated_difficulty")
	Global.disconnect("dust_storage_updated", self, "_on_dust_storage_updated")
	Global.disconnect("dust_inventory_updated", self, "_on_dust_inventory_updated")
	Global.disconnect("speed_inventory_updated", self, "_on_speed_inventory_updated")
	Global.disconnect("firerate_inventory_updated", self, "_on_firerate_inventory_updated")


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
	active.rect_scale = Vector2.ONE - Vector2(intensity * 0.0006, intensity * 0.0006)
	shake_intensity = intensity * 0.75
	shake_timer.wait_time = time
	shake_screen = true
	shake_timer.start()


func _on_shake_timeout():
	shake_intensity = 0
	shake_screen = false


func _on_updated_kills(value):
	kill_count.text = "%03d" % value


func _on_updated_points(value):
	points_sector.text = "%04d" % value
	if value > highsocre: 
		highsocre = value
		points_high.text = points_sector.text


func _on_updated_difficulty(value):
	thread_lvl.text = "%02d" % value


func _on_dust_storage_updated(value):
	dust_storage.text = "%04d" % value


func _on_dust_inventory_updated(value):
	dust_inventory.text = "%04d" % value


func _on_speed_storage_updated(_value):
	# TODO Implement in dialog
	pass


func _on_speed_inventory_updated(value):
	speed_inventory.text = "8/%d" % value


func _on_firerate_storage_updated(_value):
	# TODO Implement in dialog
	pass


func _on_firerate_inventory_updated(value):
	firerate_inventory.text = "%d/8" % value


func _on_start_pressed():
	Global.show_game()


func _on_jump_pressed():
	match Global.state:
		Global.State.No:
			Global.show_game()
		Global.State.Game:
			Global.show_dialog()
		Global.State.Dialog:
			Global.show_game()
