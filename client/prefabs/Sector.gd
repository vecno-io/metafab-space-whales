extends Node2D


signal updated_difficulty

var difficulty = 0

export(int) var spawn_inital = 3

export(float) var spawn_time_base = 1.8
export(float) var spawn_time_ticks = 0.1
export(float) var spawn_time_mimimum = 0.4

export(Array, PackedScene) var enemies

onready var spawn_timer = get_node("%SpawnTimer")


func _ready():
	randomize()
	Global.local_sector = self
	var time = spawn_time_base - (difficulty * spawn_time_ticks)
	if time > spawn_time_mimimum: spawn_timer.wait_time = time
	else: spawn_timer.wait_time = spawn_time_mimimum
	spawn_timer.wait_time = time
	emit_signal("updated_difficulty", difficulty)
	for __ in range(0, spawn_inital):_spawn_enemy()


func _exit_tree():
	Global.local_sector = null


func _spawn_enemy():
	if Global.camera == null:
		return
	var position = Global.camera.global_position
	# Note: Depend on screen size
	var x =	rand_range(position.x - 480, position.x + 480)
	var y =	rand_range(position.y - 270, position.y + 270)
	var z = rand_range(0, 999)
	if (int(z) % 2) == 0:
		if y < position.y: y -= 270 + 64
		else: y += 270 + 64
	else:
		if x < position.x: x -= 480 + 64
		else: x += 480 + 64
	var idx = round(rand_range(0, enemies.size() - 1))
	Global.instance_node(enemies[idx], self, Vector2(x, y))


func _on_spawn_timeout():
	if !Global.paused:
		_spawn_enemy()


func _on_difficulty_timeout():
	if spawn_timer.wait_time > spawn_time_mimimum:
		difficulty += 1
		var time = spawn_time_base - (difficulty * spawn_time_ticks)
		if time > spawn_time_mimimum: spawn_timer.wait_time = time
		else: spawn_timer.wait_time = spawn_time_mimimum
		spawn_timer.wait_time = time
		emit_signal("updated_difficulty", difficulty)
