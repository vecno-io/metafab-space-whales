extends Node2D


signal updated_difficulty

export(int) var spawn_inital = 3

export(float) var spawn_time_base = 1.8
export(float) var spawn_time_ticks = 0.1
export(float) var spawn_time_mimimum = 0.6

var difficulty = 0

onready var spawn_timer = get_node("%SpawnTimer")

var proto_enemy = preload("res://prefabs/enemies/ProtoEnemy.tscn")


func _ready():
	randomize()
	Global.local_sector = self
	spawn_timer.wait_time = spawn_time_base
	for __ in range(0, spawn_inital):_spawn_enemy()


func _exit_tree():
	Global.local_sector = null


func _spawn_enemy():
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
	Global.instance_node(proto_enemy, self, Vector2(x, y))


func _on_spawn_timeout():
	if !Global.paused:
		_spawn_enemy()


func _on_difficulty_timeout():
	if spawn_timer.wait_time > spawn_time_mimimum:
		difficulty += 1
		spawn_timer.wait_time -= spawn_time_ticks
		emit_signal("updated_difficulty", difficulty)
