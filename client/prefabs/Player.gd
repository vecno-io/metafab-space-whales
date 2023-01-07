class_name Player
extends Node2D


var speed = 150
var fire_up = true
var velocity = Vector2.ZERO
var turn_speed = PI * 2.2

onready var firerate = get_node("%Firerate")

var bullet = preload("res://prefabs/Bullet.tscn")


func _ready():
	Global.unpause_game()
	Global.local_player = self


func _exit_tree():
	Global.local_player = null


func _process(delta):
	if Global.paused:
		return

	velocity.x = int(Input.is_action_pressed("move_right")) - int(Input.is_action_pressed("move_left"))
	velocity.y = int(Input.is_action_pressed("move_down")) - int(Input.is_action_pressed("move_up"))
	var target =  global_position + velocity.normalized() * speed * delta
	var direction = target - global_position
	global_position = target

	if velocity != Vector2.ZERO:
		var base = global_rotation
		var angle = direction.angle()
		angle = lerp_angle(base, angle, 1.0)
		var angle_delta = turn_speed * delta
		angle = clamp(angle, base - angle_delta, base + angle_delta)
		global_rotation = angle

	if fire_up && Input.is_action_pressed("fire_main") && Global.local_sector != null:
		Global.instance_node(bullet, Global.local_sector, global_position)
		firerate.start()
		fire_up = false


func _on_firerate_timeout():
	fire_up = true


func _on_hitbox_entered(area:Area2D):
	if area.is_in_group("enemy"):
		visible = false
		Global.pause_game()
		yield(get_tree().create_timer(1.6), "timeout")
		#warning-ignore: return_value_discarded
		get_tree().reload_current_scene()
