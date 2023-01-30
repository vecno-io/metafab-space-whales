extends CPUParticles2D


signal picked_up


var dust_amount = 0

export(int) var dust_min = 50
export(int) var dust_max = 250

onready var effect = get_node("%AudioEffect")

func _ready():
	randomize()
	if 0 <= dust_amount:
		dust_amount = int(rand_range(dust_min, dust_max))


func _on_freeze_timeout():
	set_process(false)
	set_process_input(false)
	set_physics_process(false)
	set_process_internal(false)
	set_process_unhandled_input(false)
	set_process_unhandled_key_input(false)
	

func _on_hitbox_entered(area: Area2D):
	if !visible:
		return
	if area.is_in_group("player_pickup"):
		var player = area.get_parent()
		player.dust_pickup(
			dust_amount
		)
		emit_signal("picked_up")
		visible = false
		effect.play()



func _on_AudioEffect_finished():
	queue_free()
