extends Sprite

export(float) var timeout = 8.0
export(float) var reload_speed = 0.06

func _on_hitbox_entered(area: Area2D):
	if area.is_in_group("player"):
		var player = area.get_parent()
		player.start_reload_boost(
			timeout, reload_speed
		)
		queue_free()
