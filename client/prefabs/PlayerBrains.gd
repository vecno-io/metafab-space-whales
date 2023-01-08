class_name PlayerBrains
extends Node2D

signal speed_boost_ended
signal reload_boost_ended
signal speed_boost_started
signal reload_boost_started

var speed = 150
var fire_up = true
var velocity = Vector2.ZERO
var turn_speed = PI * 2.2
var speed_default = 150
var reload_default = 0.08

onready var firerate = get_node("%Firerate")
onready var speed_boost = get_node("%SpeedBoost")
onready var reload_boost = get_node("%ReloadBoost")

var bullet = preload("res://prefabs/Bullet.tscn")


func _ready():
	Global.local_player = self
	speed_default = speed
	reload_default = firerate.wait_time


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


func get_segment_hook():
	return get_node("%SegmentHook")


func start_speed_boost(time, move_speed):
	speed_boost.wait_time = time
	speed_boost.start()
	speed = move_speed
	emit_signal("speed_boost_started")


func start_reload_boost(time, reload_speed):
	reload_default = firerate.wait_time
	firerate.wait_time = reload_speed
	reload_boost.wait_time = time
	reload_boost.start()
	emit_signal("reload_boost_started")


func _on_firerate_timeout():
	fire_up = true


func _on_speed_boost_timeout():
	speed = speed_default
	emit_signal("speed_boost_ended")


func _on_reaload_boost_timeout():
	firerate.wait_time = reload_default
	emit_signal("reload_boost_ended")


func _on_hitbox_entered(area:Area2D):
	if area.is_in_group("enemy"):
		visible = false
		Global.save_game()
		Global.pause_game()
		yield(get_tree().create_timer(1.6), "timeout")
		#warning-ignore: return_value_discarded
		get_tree().reload_current_scene()
