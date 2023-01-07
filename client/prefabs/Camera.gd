extends Camera2D

var shake_screen = false
var shake_intensity = 0

onready var shake_timer = get_node("%ShakeTimer")


func _ready():
	Global.local_camera = self


func _exit_tree():
	Global.local_camera = null


func _process(delta):
	zoom = lerp(zoom, Vector2(1, 1), 0.3)
	if shake_screen:
		var x = rand_range(-shake_intensity, shake_intensity)
		var y = rand_range(-shake_intensity, shake_intensity)
		global_position += Vector2(x, y) * delta


func screen_shake(intensity, time):
	zoom = Vector2.ONE - Vector2(intensity * 0.002, intensity * 0.002)
	shake_intensity = intensity
	shake_timer.wait_time = time
	shake_screen = true
	shake_timer.start()


func _on_shake_timeout():
	shake_intensity = 0
	shake_screen = false
