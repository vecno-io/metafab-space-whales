class_name Player
extends Node2D


var speed = 150
var fire_up = true
var velocity = Vector2.ZERO

onready var firerate = get_node("%Firerate")

var bullet = preload("res://prefabs/Bullet.tscn")

func _process(delta):
	velocity.x = int(Input.is_action_pressed("move_right")) - int(Input.is_action_pressed("move_left"))
	velocity.y = int(Input.is_action_pressed("move_down")) - int(Input.is_action_pressed("move_up"))
	global_position += velocity.normalized() * speed * delta

	if fire_up && Input.is_action_pressed("fire_main") && Global.sector_node != null:
		Global.instance_node(bullet, Global.sector_node, global_position)
		firerate.start()
		fire_up = false


func _on_firerate_timeout():
	fire_up = true
