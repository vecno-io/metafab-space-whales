extends Sprite


signal picked_up


# ToDo / FixMe: Values are unused,
# out dated by making these consumable
export(float) var timeout = 6.0
export(int) var move_speed = 250

onready var effect = get_node("%AudioEffect")

func _on_hitbox_entered(area: Area2D):
	if !visible:
		return
	if area.is_in_group("player"):
		var player = area.get_parent()
		if player.speed_boost_pickup(1):
			emit_signal("picked_up")
			visible = false
			effect.play()


func _on_AudioEffect_finished():
	queue_free()
