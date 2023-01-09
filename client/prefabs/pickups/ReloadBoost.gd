extends Sprite

# ToDo / FixMe: Values are unused,
# out dated by making these consumable
export(float) var timeout = 8.0
export(float) var reload_speed = 0.06

func _on_hitbox_entered(area: Area2D):
	if area.is_in_group("player"):
		var player = area.get_parent()
		player.firerate_boost_pickup(1)
		queue_free()
