class_name ProtoEnemy
extends EnemyBase


func _process(delta):
	if Global.paused:
		return false
	if Global.local_player == null:
		return false
	_base_look_at(delta, Global.local_player)
	if _do_base_movement(delta, Global.local_player):
		# ToDo Juice: Animate move
		# ToDo Juice: Sound hit
		pass


func _on_hitbox_entered(area: Area2D):
	if ._do_base_knockback(area):
		# ToDo Juice: Animate hit
		# ToDo Juice: Sound hit
		pass
