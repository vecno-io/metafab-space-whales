extends Camera2D


var scene_move = false
var shake_screen = false
var shake_intensity = 0

var target_position = Vector2.ZERO

export(Vector2) var app_position = Vector2(480, 270)
export(Vector2) var home_position = Vector2(480, 270)
export(Vector2) var sector_position = Vector2(1440, 1620)
export(Vector2) var tutorial_position = Vector2(2400, 270)

onready var shake_timer = get_node("%ShakeTimer")
onready var scene_tween = get_node("%SceneTween")

func _ready():
	randomize()
	Global.camera = self
	global_position = app_position - Vector2(40.0, 0)
	target_position = app_position - Vector2(40.0, 0)
	#warning-ignore: return_value_discarded
	Global.connect("actor_died", self, "_on_actor_died")
	#warning-ignore: return_value_discarded
	Global.connect("state_updated", self, "_on_state_updated")


func _exit_tree():
	Global.camera = null
	Global.disconnect("actor_died", self, "_on_actor_died")
	Global.disconnect("state_updated", self, "_on_state_updated")


func _process(delta):
	if scene_move:
		return
	match Global.state:
		Global.State.Home:
			_process_home(delta)
		Global.State.Sector:
			_process_sector(delta)
		Global.State.Tutorial:
			_process_tutorial(delta)


func _process_home(_delta):
	# Camera follows instructor
	pass


func _process_sector(delta):
	# Camera follows player
	_follow_player_update()
	_movement_update(delta)


func _process_tutorial(delta):
	# Camera follows player and instructor
	# TODO Check tutorial instructor
	_follow_player_update()
	_movement_update(delta)


func _follow_player_update():
	if Global.local_player == null:
		return
	var target = Global.local_player.global_position - Vector2(40.0, 0)
	# ToDo Juice: smooth center between mouse and player
	target_position = lerp(target, target_position, 0.24)


func _movement_update(delta):
	zoom = lerp(zoom, Vector2(1, 1), 0.24)
	if shake_screen:
		var x = rand_range(-shake_intensity, shake_intensity)
		var y = rand_range(-shake_intensity, shake_intensity)
		
		global_position = lerp(global_position, target_position, 0.24)
		global_position += Vector2(x, y) * delta
	else:
		global_position = lerp(global_position, target_position, 0.24)


func screen_shake(intensity, time):
	zoom = Vector2.ONE - Vector2(intensity * 0.0008, intensity * 0.0008)
	shake_intensity = intensity
	shake_timer.wait_time = time
	shake_screen = true
	shake_timer.start()


func _on_shake_timeout():
	shake_intensity = 0
	shake_screen = false


func _on_actor_died():
	yield(get_tree().create_timer(0.1), "timeout")
	global_position = Vector2.ZERO


func _on_state_updated():
	if scene_tween.is_active():
		scene_tween.stop()
	# As the state updates, the camera moves to
	# transition and bring state elements in view.
	scene_move = true
	var tween_to = global_position
	match Global.state:
		Global.State.App:
			tween_to = app_position - Vector2(40.0, 0)
		Global.State.Home:
			tween_to = home_position - Vector2(40.0, 0)
		Global.State.Sector:
			tween_to = sector_position - Vector2(40.0, 0)
		Global.State.Tutorial:
			tween_to = tutorial_position - Vector2(40.0, 0)
	target_position = tween_to
	scene_tween.interpolate_property(
		self, "global_position",
		global_position, tween_to, 1.2,
		Tween.TRANS_QUINT, Tween.EASE_IN_OUT
	)
	scene_tween.start()
	Global.scene_move_started()


func _on_scene_tween_all_completed():
	target_position = global_position
	scene_move = false
	Global.scene_move_ended()
