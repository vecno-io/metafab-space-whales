class_name PlayerBrains
extends Node2D


signal jumping_ended

# ToDo Juice: Hook up visual indicators
# Boosted particle efects and item glows

signal speed_boost_start
signal speed_boost_stoped
signal firerate_boost_start
signal firerate_boost_stoped

var high_color = Color.white

var speed = 140
var speed_boost = 240
var speed_default = speed
var speed_boost_up = true
var speed_boost_timeout = 6.0

var fire_up = true
var jumping = false
var trigger_down = false

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

onready var jump_tween = get_node("JumpTween")

onready var firerate_timer = get_node("%Firerate")
onready var speed_boost_timer = get_node("%SpeedBoost")
onready var firerate_boost_timer = get_node("%FirerateBoost")

onready var fire_sfx = get_node("%SfxrStreamFire")
onready var jumps_sfx = get_node("%SfxrStreamJumps")

var bullet = preload("res://prefabs/Bullet.tscn")


func _ready():
	destroyed = false
	Global.local_player = self
	firerate_timer.wait_time = firerate
	#warning-ignore: return_value_discarded
	Global.connect("color_updated", self, "_on_color_updated")
	#warning-ignore: return_value_discarded
	Global.connect("player_jumping", self, "_on_player_jumping")


func _exit_tree():
	Global.local_player = null
	Global.disconnect("color_updated", self, "_on_color_updated")
	Global.disconnect("player_jumping", self, "_on_player_jumping")


func _process(delta):
	if jumping:
		return
	match Global.state:
		Global.State.Home:
			_process_home(delta)
		Global.State.Sector:
			_process_sector(delta)
		Global.State.Tutorial:
			_process_tutorial(delta)


func _process_home(delta):
	if Global.paused: return
	# TODO: Pause based on Home State
	# Open Boxes and shops needs to pause
	_do_base_movement(delta)
	if fire_up && trigger_down: 
		self.fire_weapon()


func _process_sector(delta):
	if Global.paused: return
	_do_base_movement(delta)
	if fire_up && trigger_down: 
		self.fire_weapon()


func _process_tutorial(delta):
	if Global.paused: return
	# TODO: Pause based on Tutorial State
	_do_base_movement(delta)
	if fire_up && trigger_down: 
		self.fire_weapon()


func _do_base_movement(delta):
	velocity.x = int(Input.is_action_pressed("move_right")) - int(Input.is_action_pressed("move_left"))
	velocity.y = int(Input.is_action_pressed("move_down")) - int(Input.is_action_pressed("move_up"))
	var target =  global_position + velocity.normalized() * speed * delta
	var direction = target - global_position
	global_position = target
	if velocity != Vector2.ZERO:
		var base = global_rotation
		var angle = direction.angle()
		angle = lerp_angle(base, angle, 0.16)
		var angle_delta = turn_speed * delta
		angle = clamp(angle, base - angle_delta, base + angle_delta)
		global_rotation = angle
	if Global.local_sector == null:
		return
	if speed_boost_up && Input.is_action_just_pressed("boost_speed"):
		self.start_speed_boost(speed_boost_timeout, speed_boost)
	if firerate_boost_up && Input.is_action_just_pressed("boost_firerate"):
		self.start_firerate_boost(firerate_boost_timeout, firerate_boost)



func _unhandled_input(event: InputEvent):
	if jumping:
		return
	match Global.state:
		Global.State.Home:
			_check_home_input(event)
		Global.State.Sector:
			_check_combat_input(event)
		Global.State.Tutorial:
			_check_combat_input(event)


func _check_home_input(event: InputEvent):
	if event.is_action_pressed("jump"):
		jump_out()
		return


func _check_combat_input(event: InputEvent):
	if event.is_action_pressed("jump"):
		jump_out()
		return
	if event.is_action_pressed("fire_main"):
		trigger_down = true
		return
	if event.is_action_released("fire_main"):
		trigger_down = false
		return


func jump_out():
	if Global.jump_out():
		AudioManager.play_sfx_effect(jumps_sfx)
		# TODO Juice: Jump GXF


func _on_player_jumping(position: Vector2):
	jumping = true
	# TODO Look at and move to jump direction
	jump_tween.interpolate_property(
		self, "global_position",
		global_position, position, 0.8,
		Tween.TRANS_QUINT, Tween.EASE_IN_OUT
	)
	jump_tween.start()
	jumping = true

func _on_jump_tween_completed():
	jumping = false
	emit_signal("jumping_ended")


func get_segment_hook():
	return get_node("SegmentHook")


func dust_pickup(amount):
	Global.dust_inventory += amount


func speed_boost_pickup(amount) -> bool:
	if Global.speed_inventory >= Global.MAX_INVENTORY_BOOST:
		return false
	else:
		Global.speed_inventory += amount
		return true


func firerate_boost_pickup(amount):
	if Global.firerate_inventory >= Global.MAX_INVENTORY_BOOST:
		return false
	else:
		Global.firerate_inventory += amount
		return true


func fire_weapon():
	if !fire_up:
		return
	var cost = int(rand_range(bullet_cost_min, bullet_cost_max))
	if cost > Global.dust_inventory: 
		# TODO Juice: out of speed boost sfx
		return
	fire_up = false
	Global.dust_inventory -= cost
	var node = Global.instance_node(bullet, Global.local_sector, global_position)
	node.modulate = high_color
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
		if !area.get_parent().visible:
			print_debug("dead item")
			return
		Global.dust_inventory -= int(Global.dust_inventory * 0.6)
		Global.firerate_inventory = 0
		Global.speed_inventory = 0
		if Global.actor_died():
			Global.pause_game()
			Global.save_game()


func _on_color_updated(value):
	var back = get_node("BackDrop")
	back.modulate = value
	high_color = value


func world_death():
		destroyed = true
		# TODO Juice: Explode into dust
		# TODO Juice: Jump head off screen
		yield(get_tree().create_timer(1.4), "timeout")
		# TODO FixMe: Double call, null after timeout
		get_parent().queue_free()
