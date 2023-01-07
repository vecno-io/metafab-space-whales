class_name ProtoEnemy
extends EnemyBase


export(Color) var base_color = Color(0.9,0.9,0.9)
export(Color) var stun_color = Color(0.9,0.9,0.9)


func _ready():
	modulate = base_color


func _process(delta):
	if _do_base_movement(delta):
		# ToDo Juice: Animate move
		pass


func _on_stun_timeout():
	modulate = base_color
	._on_stun_timeout()


func _on_hitbox_entered(area: Area2D):
	if ._do_base_knockback(area):
		modulate = stun_color
