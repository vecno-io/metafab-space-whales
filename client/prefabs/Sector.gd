extends Node2D


onready var firerate = get_node("%SpawnTimer")

var enemy_one = preload("res://prefabs/Enemy.tscn")

func _ready():
	Global.sector_node = self


func _exit_tree():
	Global.sector_node = null


func _on_spawn_timeout():
	# Note: Depend on screen size
	var x =	rand_range(0, 960)
	if x < 480: x -= 480 + 64
	else: x += 480 + 64
	var y =	rand_range(0, 540)
	if y < 270: y -= 270 + 64
	else: y += 270 + 64
	Global.instance_node(enemy_one, self, Vector2(x, y))
