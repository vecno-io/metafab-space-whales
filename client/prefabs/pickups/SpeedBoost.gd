extends Sprite

export(float) var timeout = 6.0
export(int) var move_speed = 250

func _on_hitbox_entered(area: Area2D):
	if area.is_in_group("player"):
		var player = area.get_parent()
		player.start_speed_boost(
			timeout, move_speed
		)
		queue_free()
