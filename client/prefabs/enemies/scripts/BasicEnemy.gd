class_name ProtoEnemy
extends EnemyBase


export(bool) var freeze = false
export(bool) var is_hunter = false

onready var sfx_hit = get_node("%SfxrPlayerHit")
onready var sfx_explode = get_node("%SfxrPlayerExplode")


func _ready():
	if !freeze: return
	$Hitbox.queue_free()
	$StunTimer.queue_free()
	

func _process(delta):
	if Global.paused:
		return
	if Global.local_player == null:
		return
	if _has_died(): 
		AudioManager.play_sfx_effect(sfx_explode)
		return
	match state:
		State.Flee:
			_do_base_look(delta, target)
			if _do_base_movement(delta, target):
				# ToDo Juice: Animate move
				pass
			if 0.1 > global_position.direction_to(target).length():
				._base_start_running()
		State.Harvest:
			var position = Global.local_player.global_position
			_do_base_look(delta, position)
			if _do_base_movement(delta, position):
				# ToDo Juice: Animate move
				pass


func _on_hitbox_entered(area: Area2D):
	if ._do_base_knockback(area):
		AudioManager.play_sfx_effect(sfx_hit)
		# ToDo Juice: Animate hit
	if ._do_base_loot(area):
		modulate = Color.from_hsv(base_color.h, base_color.s * 1.4, base_color.v * 1.4)
		base_color = modulate
		# ToDo Juice: Play loot sound
		if !is_hunter:
			._base_start_running()
		else:
			speed += 20
