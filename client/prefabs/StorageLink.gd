extends Sprite

# TODO StorageLink Dialog Connection

signal link_opened
signal link_closed


func _on_link_area_exited(area: Area2D):
	if area.is_in_group("player"):
		emit_signal("link_opened")
		# var player = area.get_parent()
		print_debug("TOOD: Access becomes jump")


func _on_link_area_entered(area: Area2D):
	if area.is_in_group("player"):
		emit_signal("link_closed")
		# var player = area.get_parent()
		print_debug("TOOD: Jump becomes access")
