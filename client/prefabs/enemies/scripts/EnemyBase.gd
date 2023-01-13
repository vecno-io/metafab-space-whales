class_name EnemyBase
extends Node2D


enum State {
	No,
	Flee,
	Harvest,
}

export(int) var hp = 4
export(int) var speed = 100
export(int) var knockback = 360

export(int) var min_loot_amount = 25
export(int) var max_loot_amount = 75

export(Color) var base_color = Color("e64949")
export(Color) var stun_color = Color("fcfcfc")

var loot = 0

var stuned = false
var fire_up = true

var state = State.Harvest
var target = Vector2.ZERO

var velocity = Vector2.ZERO
var turn_speed = PI * 2.6

onready var stun_timer = get_node("%StunTimer")

onready var dust_particles = preload("res://prefabs/enemies/effects/DustParticles.tscn")


func _ready():
	randomize()
	state = State.Harvest
	modulate = base_color


func _on_stun_timeout():
	modulate = base_color
	stuned = false


func _base_start_running():
	target = Vector2(rand_range(-8000, 8000), rand_range(-8000, 8000))
	# ToDo Select closest Home Planet
	state = State.Flee


func _has_died() -> bool:
	if hp > 0: 
		return false
	queue_free()
	Global.add_kill()
	Global.add_points(2)
	Global.screen_shake(48, 0.24)
	# TODO If has loot drop loot
	if Global.local_sector != null:
		var object = Global.instance_node(dust_particles, Global.local_sector, global_position)
		object.modulate = Color.from_hsv(base_color.h, base_color.s * 0.9, base_color.v * 0.6)
		object.rotation = velocity.angle()
		if loot > 0:
			object = Global.instance_node(dust_particles, Global.local_sector, global_position)
			object.dust_amount = int(loot * 1.4)
			object.rotation = velocity.angle()
	return true


func _do_base_look(delta, at):
	var direction = at - global_position
	var base = global_rotation
	var angle = direction.angle()
	angle = lerp_angle(base, angle, 1.0)
	var angle_delta = turn_speed * delta
	angle = clamp(angle, base - angle_delta, base + angle_delta)
	global_rotation = angle


func _do_base_movement(delta, to) -> bool:
	if stuned:
		velocity = lerp(velocity, Vector2(0,0), 0.3)
		global_position += velocity * delta
		return true
	velocity = global_position.direction_to(to)
	global_position += velocity * speed * delta
	return true


func _do_base_loot(area: Area2D) -> bool:
	if loot != 0: return false
	if Global.dust_inventory == 0: return false
	if !area.is_in_group("player_segment"): return false
	var amount = int(rand_range(min_loot_amount, max_loot_amount))
	if amount > Global.dust_inventory:
		loot = Global.dust_inventory
		Global.dust_inventory = 0
		speed -= 20
		return true
	Global.dust_inventory -= amount
	loot = amount
	speed -= 20
	return true


func _do_base_knockback(area: Area2D) -> bool:
	if !area.is_in_group("player_bullets"):
		return false
	hp -= 1
	area.get_parent().queue_free()
	if !stuned: # No double negatives
		velocity = -velocity * knockback
		modulate = stun_color
		stun_timer.start()
		stuned = true
	return true
