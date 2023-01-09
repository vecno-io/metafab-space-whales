extends Camera2D

var shake_screen = false
var shake_intensity = 0

var target_position = Vector2.ZERO

onready var shake_timer = get_node("%ShakeTimer")


func _ready():
	randomize()
	Global.camera = self
	#warning-ignore: return_value_discarded
	Global.connect("actor_died", self, "_on_actor_died")


func _exit_tree():
	Global.camera = null
	Global.disconnect("actor_died", self, "_on_actor_died")


func _process(delta):
	match Global.state:
		Global.State.Game:
			_process_game(delta)
		Global.State.Dialog:
			_process_dialog(delta)
		Global.State.Tutorial:
			_process_tutorial(delta)


func _process_game(delta):
	_follow_player_movement()
	zoom = lerp(zoom, Vector2(1, 1), 0.24)
	if shake_screen:
		var x = rand_range(-shake_intensity, shake_intensity)
		var y = rand_range(-shake_intensity, shake_intensity)
		
		global_position = lerp(global_position, target_position, 0.24)
		global_position += Vector2(x, y) * delta
	else:
		global_position = lerp(global_position, target_position, 0.24)


func _process_dialog(_delta):
	if Global.local_player == null:
		return
	var target = Global.local_player.global_position - Vector2(40.0, 0)
	global_position = lerp(global_position, target, 0.24)


func _process_tutorial(_delta):
	if Global.local_player == null:
		return
	var target = Global.local_player.global_position - Vector2(40.0, 0)
	global_position = lerp(global_position, target, 0.24)


func _follow_player_movement():
	if Global.local_player == null:
		return
	var target = Global.local_player.global_position - Vector2(40.0, 0)
	# ToDo Juice: smooth center between mouse and player
	target_position = lerp(target, target_position, 0.24)


func reset_position():
	yield(get_tree().create_timer(0.1), "timeout")
	global_position = Vector2(-40.0, 0)


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
