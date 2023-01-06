extends Sprite

var hp = 4
var speed = 100
var fire_up = true
var velocity = Vector2.ZERO

onready var base_color = modulate

var stuned = false
var stun_color = Color(0.9,0.9,0.9)
onready var stun_timer = get_node("%StunTimer")


func _process(delta):
	if hp <= 0:
		queue_free()
	if stuned:
		velocity = lerp(velocity, Vector2(0,0), 0.3)
	elif Global.local_player != null:
		var target = Global.local_player.global_position
		velocity = global_position.direction_to(target)
	global_position += velocity * speed * delta


func _on_hitbox_area_entered(area:Area2D):
	if area.is_in_group("player_bullets"):
		if !stuned: # No double negatives
			velocity = -velocity * 4
			stun_timer.start()
			stuned = true
		area.get_parent().queue_free()
		modulate = stun_color
		hp -= 1


func _on_stun_timeout():
	modulate = base_color
	stuned = false
