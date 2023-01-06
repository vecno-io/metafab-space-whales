class_name Bullet
extends Node2D


var speed = 450
var looked = false
var velocity = Vector2(1, 0)


func _process(delta):
	if !looked:
		looked = true
		look_at(get_global_mouse_position())
	global_position += velocity.rotated(rotation) * speed * delta


func _on_screen_exit():
	print("exit: %s" % name)
	queue_free()
