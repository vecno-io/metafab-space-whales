extends Sprite


signal picked_up


# ToDo / FixMe: Values are unused,
# out dated by making these consumable
export(float) var timeout = 6.0
export(int) var move_speed = 250


func _on_hitbox_entered(area: Area2D):
	if area.is_in_group("player"):
		var player = area.get_parent()
		player.speed_boost_pickup(1)
		emit_signal("picked_up")
		queue_free()
