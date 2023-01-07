class_name ProtoEnemy
extends EnemyBase


func _process(delta):
	if _do_base_movement(delta):
		# ToDo Juice: Animate move
		# ToDo Juice: Sound hit
		pass

func _on_hitbox_entered(area: Area2D):
	if ._do_base_knockback(area):
		# ToDo Juice: Animate hit
		# ToDo Juice: Sound hit
		pass
