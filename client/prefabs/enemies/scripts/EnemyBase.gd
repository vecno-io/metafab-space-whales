class_name EnemyBase
extends Sprite


export(int) var hp = 4
export(int) var speed = 100
export(int) var knockback = 360

export(Color) var base_color = Color("e64949")
export(Color) var stun_color = Color("fcfcfc")

var stuned = false
var fire_up = true

var velocity = Vector2.ZERO

onready var stun_timer = get_node("%StunTimer")

onready var dust_particles = preload("res://prefabs/enemies/effects/DustParticles.tscn")


func _ready():
	modulate = base_color


func _on_stun_timeout():
	modulate = base_color
	stuned = false


func _do_base_movement(delta) -> bool:
	if Global.paused:
		return false
	if hp <= 0:
		queue_free()
		Global.add_points(1)
		Global.screen_shake(24, 0.24)
		if Global.local_sector != null:
			var object = Global.instance_node(dust_particles, Global.local_sector, global_position)
			object.modulate = Color.from_hsv(base_color.h, base_color.s * 0.9, base_color.v * 0.6)
			object.rotation = velocity.angle()
	if stuned:
		velocity = lerp(velocity, Vector2(0,0), 0.3)
		global_position += velocity * delta
		return true
	if Global.local_player == null:
		return false
	var target = Global.local_player.global_position
	velocity = global_position.direction_to(target)
	global_position += velocity * speed * delta
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
	