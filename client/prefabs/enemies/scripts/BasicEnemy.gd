class_name ProtoEnemy
extends EnemyBase

export(bool) var freeze = false

onready var sfx_hit = get_node("%SfxrPlayerHit")
onready var sfx_explode = get_node("%SfxrPlayerExplode")

func _ready():
	if !freeze: return
	$Hitbox.queue_free()
	$StunTimer.queue_free()
	

func _process(delta):
	if Global.paused:
		return false
	if Global.local_player == null:
		return false
	_base_look_at(delta, Global.local_player)
	if hp <= 0: 
		AudioManager.play_sfx_effect(sfx_explode)
	if _do_base_movement(delta, Global.local_player):
		# ToDo Juice: Animate move
		pass


func _on_hitbox_entered(area: Area2D):
	if ._do_base_knockback(area):
		AudioManager.play_sfx_effect(sfx_hit)
		# ToDo Juice: Animate hit
		pass
