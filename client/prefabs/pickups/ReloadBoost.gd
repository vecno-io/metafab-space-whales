extends Sprite


signal picked_up

# ToDo / FixMe: Values are unused,
# out dated by making these consumable
export(float) var timeout = 8.0
export(float) var reload_speed = 0.06

onready var effect = get_node("%AudioEffect")

func _on_hitbox_entered(area: Area2D):
	if !visible:
		return
	if area.is_in_group("player"):
		var player = area.get_parent()
		if player.firerate_boost_pickup(1):
			emit_signal("picked_up")
			visible = false
			effect.play()


func _on_AudioEffect_finished():
	queue_free()
