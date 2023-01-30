extends TutorialStep

# Setup the first sector event

"""
Step 6-G. Sector Intro Mode
	-> Monkey Cleanup
	-> Claim Sector
"""

signal updated_difficulty

var difficulty = 0

export(int) var spawn_inital = 3

export(float) var spawn_time_base = 1.8
export(float) var spawn_time_ticks = 0.1
export(float) var spawn_time_mimimum = 0.4

export(PackedScene) var player_whale
export(Array, PackedScene) var enemies

onready var respwn_box = get_node("%RespwnBox")
onready var cost_label = get_node("%CostLabel")


onready var spawn_node = get_node("%PlayerTargets")
onready var dificulty_label = get_node("%DificultyLabel")

# onready var spawn_timer = get_node("%SpawnBaseBtn")
# onready var spawn_timer = get_node("%SpawnScoutBtn")
# onready var spawn_timer = get_node("%SpawnFighterBtn")

onready var spawn_timer = get_node("%SpawnTimer")
onready var difficulty_timer = get_node("%DifficultyTimer")

# TODO ESC Disconnect and reset

# TODO Display dificulty value


func _ready():
	randomize()
	respwn_box.hide()
	Global.can_jump = true
	Global.local_sector = self
	#warning-ignore: return_value_discarded
	Global.connect("actor_died", self ,"_on_actor_died")
	#warning-ignore: return_value_discarded
	Global.connect("player_jumped", self ,"_on_player_jumped")
	if Global.state == Global.State.Sector: _init_combat()


func _exit_tree():
	Global.disconnect("actor_died", self ,"_on_actor_died")
	Global.disconnect("player_jumped", self ,"_on_player_jumped")


func start_step(_stepper: TutorStepper):
	Global.can_jump = true
	.start_step(_stepper)


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
	Global.instance_node(enemies[idx], spawn_node, Vector2(x, y))


func _on_spawn_timeout():
	if !Global.paused:
		_spawn_enemy()


func _on_difficulty_timeout():
	if spawn_timer.wait_time > spawn_time_mimimum:
		difficulty += 1
		print_debug("difficulty >> %s" % difficulty)
		var time = spawn_time_base - (difficulty * spawn_time_ticks)
		if time > spawn_time_mimimum: spawn_timer.wait_time = time
		else: spawn_timer.wait_time = spawn_time_mimimum
		spawn_timer.wait_time = time
		dificulty_label.text = "lvl: %02d" % difficulty
		emit_signal("updated_difficulty", difficulty)


func _on_actor_died():
	_end_combat()
	yield(get_tree().create_timer(0.64), "timeout")
	respwn_box.show()


func _on_player_jumped():
	_end_combat()
	yield(get_tree().create_timer(0.64), "timeout")
	if Global.state == Global.State.Sector:
		_init_combat()


func _end_combat():
	spawn_timer.stop()
	difficulty_timer.stop()
	GameServer.sector.end_combat()
	for item in spawn_node.get_children():
		item.queue_free()


func _init_combat():
	print_debug("init combat: %s" % difficulty)
	difficulty = Global.difficulty
	var time = spawn_time_base - (difficulty * spawn_time_ticks)
	if time > spawn_time_mimimum: spawn_timer.wait_time = time
	else: spawn_timer.wait_time = spawn_time_mimimum
	spawn_timer.wait_time = time
	difficulty_timer.start()
	spawn_timer.start()
	for __ in range(0, spawn_inital):_spawn_enemy()


func _on_spawn_exit():
	cost_label.text = ""


func _on_spawn_base_hover():
	cost_label.text = "Cost: 0 DUST"


func _on_spawn_base_pressed():
	respwn_box.hide()
	var player = player_whale.instance()
	get_parent().add_child(player)
	player.global_position = Global.camera.home_position
	player.modulate = Global.color
	Global.unpause_game()


func _on_spawn_scout_hover():
	cost_label.text = "Cost: 25.000 DUST"


func _on_spawn_scout_pressed():
	pass # Replace with function body.


func _on_spawn_assult_hover():
	cost_label.text = "Cost: 35.000 DUST"


func _on_spawn_assult_pressed():
	pass # Replace with function body.
