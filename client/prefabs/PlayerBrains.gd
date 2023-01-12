class_name PlayerBrains
extends Node2D


# ToDo Juice: Hook up visual indicators
# Boosted particle efects and item glows
signal speed_boost_start
signal speed_boost_stoped
signal firerate_boost_start
signal firerate_boost_stoped

var speed = 150
var speed_boost = 275
var speed_default = speed
var speed_boost_up = true
var speed_boost_timeout = 6.0

var fire_up = true
var firerate = 0.09
var firerate_boost = 0.06
var firerate_default = firerate
var firerate_boost_up = true
var firerate_boost_timeout = 8.0

var velocity = Vector2.ZERO
var destroyed = false
var turn_speed = PI * 2.2

export(int) var bullet_cost_min = 8
export(int) var bullet_cost_max = 12

onready var firerate_timer = get_node("%Firerate")
onready var speed_boost_timer = get_node("%SpeedBoost")
onready var firerate_boost_timer = get_node("%FirerateBoost")

onready var fire_sfx = get_node("%SfxrStreamFire")

var bullet = preload("res://prefabs/Bullet.tscn")


func _ready():
	destroyed = false
	Global.local_player = self
	firerate_timer.wait_time = firerate


func _exit_tree():
	Global.local_player = null


func _process(delta):
	match Global.state:
		Global.State.Game:
			_process_game(delta)
		Global.State.Dialog:
			_process_dialog(delta)


func _process_game(delta):
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
	if Global.local_sector == null:
		return
	if fire_up && Input.is_action_pressed("fire_main"):
		self.fire_weapon()
	if speed_boost_up && Input.is_action_just_pressed("boost_speed"):
		self.start_speed_boost(speed_boost_timeout, speed_boost)
	if firerate_boost_up && Input.is_action_just_pressed("boost_firerate"):
		self.start_firerate_boost(firerate_boost_timeout, firerate_boost)


func _process_dialog(delta):
	var direction = Vector2.ZERO - global_position
	global_position = lerp(global_position, Vector2.ZERO, 0.018)
	if velocity != Vector2.ZERO:
		var base = global_rotation
		var angle = direction.angle()
		angle = lerp_angle(base, angle, 1.0)
		var angle_delta = turn_speed * delta
		angle = clamp(angle, base - angle_delta, base + angle_delta)
		global_rotation = angle


func get_segment_hook():
	return get_node("%SegmentHook")


func dust_pickup(amount):
	Global.dust_inventory += amount


func speed_boost_pickup(amount):
	Global.speed_inventory += amount


func firerate_boost_pickup(amount):
	Global.firerate_inventory += amount


func fire_weapon():
	if !fire_up:
		return
	var cost = int(rand_range(bullet_cost_min, bullet_cost_max))
	if cost > Global.dust_inventory: 
		print_debug("Fire out: %s > %s" % [cost, Global.dust_inventory])
		# TODO Juice: out of speed boost sfx
		return
	fire_up = false
	Global.dust_inventory -= cost
	Global.instance_node(bullet, Global.local_sector, global_position)
	AudioManager.play_sfx_effect(fire_sfx)
	firerate_timer.wait_time = firerate
	firerate_timer.start()


func _on_firerate_timeout():
	fire_up = true


func start_speed_boost(time, value):
	if !speed_boost_up:
		return
	if Global.speed_inventory <= 0:
		# TODO Juice: out of speed boost sfx
		print("Speed boost out: sfx")
		return
	speed = value
	speed_boost_up = false
	speed_boost_timer.wait_time = time
	speed_boost_timer.start()
	emit_signal("speed_boost_start")
	Global.speed_inventory -= 1


func _on_speed_boost_timeout():
	speed = speed_default
	speed_boost_up = true
	emit_signal("speed_boost_stoped")


func start_firerate_boost(time, value):
	if !firerate_boost_up:
		return
	if Global.firerate_inventory <= 0:
		# TODO Juice: out of firerate boost sfx
		print("Firerate boost out: sfx")
		return
	firerate = value
	firerate_boost_up = false
	firerate_boost_timer.wait_time = time
	firerate_boost_timer.start()
	emit_signal("firerate_boost_start")
	Global.firerate_inventory -= 1


func _on_reaload_boost_timeout():
	firerate = firerate_default
	firerate_boost_up = true
	emit_signal("firerate_boost_stoped")


func _on_hitbox_entered(area:Area2D):
	if destroyed: 
		return
	if area.is_in_group("enemy"):
		Global.dust_inventory -= int(Global.dust_inventory * 0.6)
		Global.firerate_inventory = 0
		Global.speed_inventory = 0
		Global.pause_game()
		Global.save_game()
		destroyed = true
		# TODO Juice: Explode into dust
		# TODO Juice: Jump head off screen
		yield(get_tree().create_timer(1.4), "timeout")
		get_parent().queue_free()
		Global.actor_died()
