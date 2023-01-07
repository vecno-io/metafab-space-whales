extends Node2D

signal updated_difficulty

var difficulty = 0

onready var spawn_timer = get_node("%SpawnTimer")

var enemy_one = preload("res://prefabs/Enemy.tscn")

func _ready():
	Global.local_sector = self


func _exit_tree():
	Global.local_sector = null


func _on_spawn_timeout():
	if Global.paused:
		return
	# Note: Depend on screen size
	var x =	rand_range(0, 960)
	var y =	rand_range(0, 540)
	var z = rand_range(0, 999)
	if (int(z) % 2) == 0:
		if y < 270: y -= 270 + 64
		else: y += 270 + 64
	else:
		if x < 480: x -= 480 + 64
		else: x += 480 + 64
	Global.instance_node(enemy_one, self, Vector2(x, y))


func _on_difficulty_timeout():
	if spawn_timer.wait_time > 0.6:
		difficulty += 1
		spawn_timer.wait_time -= 0.1
		emit_signal("updated_difficulty", difficulty)
