extends Node


const MAX_INVENTORY_DUST = 6000
const MAX_INVENTORY_BOOST = 4

enum State {
	App,
	Home,
	Sector,
	Tutorial
}

signal game_paused
signal game_unpaused

signal state_updated
signal scene_move_ended
signal scene_move_started

signal actor_died

signal updated_kills(value)
signal updated_points(value)
signal updated_can_jump(value)
signal updated_difficulty(value)

signal player_jumped(value)
signal player_jumping(value)

signal dust_storage_updated(value)
signal dust_inventory_updated(value)

signal speed_storage_updated(value)
signal speed_inventory_updated(value)

signal firerate_storage_updated(value)
signal firerate_inventory_updated(value)

const SAVE_FILE := "user://%s.save"

var state = State.App setget _no_set

var kills = 0 setget _no_set
var points = 0 setget _no_set
var paused = true setget _no_set
var highsocre = 0 setget _no_set

var can_jump = false setget _set_can_jump

var dust_storage = 0 setget _set_dust_storage
var dust_inventory = 0 setget _set_dust_inventory

var speed_cost = 384 setget _no_set
var speed_storage = 0 setget _set_speed_storage
var speed_inventory = 0 setget _set_speed_inventory

var firerate_cost = 214 setget _no_set
var firerate_storage = 0 setget _set_firerate_storage
var firerate_inventory = 0 setget _set_firerate_inventory

var world = null
var camera = null
var overlay = null

var local_store = null
var local_player = null setget _set_player
var local_sector = null setget _set_sector

var difficulty = 1


func _no_set(_value):
	pass


func _ready():
	_load_game()
	# Give the loader some time to finish up
	# FixMe: The timer below should be a signal
	# But it is not clear where that is triggered
	yield(get_tree().create_timer(0.1), "timeout")
	state = Global.State.App
	emit_signal("state_updated")


func _set_player(value):
	_player_disconnect()
	local_player = value
	_player_connect()


func _set_sector(value):
	_sector_disconnect()
	local_sector = value
	_sector_connect()
	_sector_reset()
	unpause_game()


func _set_can_jump(value):
	can_jump = value
	emit_signal("updated_can_jump", value)


func _set_dust_storage(value):
	dust_storage = value
	# TODO Save to storage file
	emit_signal("dust_storage_updated", value)


func _set_dust_inventory(value):
	dust_inventory = value
	# TODO Save to storage file
	emit_signal("dust_inventory_updated", value)


func _set_speed_storage(value):
	speed_storage = value
	# TODO Save to storage file
	emit_signal("speed_storage_updated", value)


func _set_speed_inventory(value):
	speed_inventory = value
	# TODO Save to storage file
	emit_signal("speed_inventory_updated", value)


func _set_firerate_storage(value):
	firerate_storage = value
	# TODO Save to storage file
	emit_signal("firerate_storage_updated", value)


func _set_firerate_inventory(value):
	firerate_inventory = value
	# TODO Save to storage file
	emit_signal("firerate_inventory_updated", value)


func _sector_reset():
	if local_sector == null:
		return
	kills = 0;
	points = 0;
	paused = false;
	emit_signal("updated_kills", 0)
	emit_signal("updated_points", 0)
	emit_signal("updated_difficulty", 0)


func _player_connect():
	if local_player == null: return
	local_player.connect("jumping_ended", self, "_on_jumping_ended")


func _player_disconnect():
	if local_player == null: return
	local_player.disconnect("jumping_ended", self, "_on_jumping_ended")


func _on_jumping_ended():
	emit_signal("player_jumped")


func _sector_connect():
	if local_sector == null: return
	local_sector.connect("updated_difficulty", self, "_sector_updated_difficulty")


func _sector_disconnect():
	if local_sector == null: return
	local_sector.disconnect("updated_difficulty", self, "_sector_updated_difficulty")


func _sector_updated_difficulty(value):
	emit_signal("updated_difficulty", value)


func new_game():
	state = Global.State.Tutorial
	emit_signal("state_updated")


func leave_game():
	state = Global.State.App
	emit_signal("state_updated")


func pause_game():
	if !paused:
		paused = true
		emit_signal("game_paused")


func unpause_game():
	if paused:
		paused = false
		emit_signal("game_unpaused")


func show_home():
	state = Global.State.Home
	emit_signal("state_updated")


func show_sector():
	state = Global.State.Sector
	emit_signal("state_updated")


func jump_out() -> bool:
	if paused: 
		return false
	if !can_jump:
		return false
	match state:
		State.Home:
			return _jump_out_home()
		State.Sector:
			return _jump_out_sector()
		State.Tutorial:
			return _jump_out_tutorial()
	return false


func _jump_out_home() -> bool:
	# Note: The camera jumps on state change
	state = Global.State.Sector
	emit_signal("state_updated")
	# FixMe This is a bit of a hack
	emit_signal("player_jumping", camera.sector_position)
	return true


func _jump_out_sector() -> bool:
	# Note: The camera jumps on state change
	state = Global.State.Home
	emit_signal("state_updated")
	# FixMe This is a bit of a hack
	emit_signal("player_jumping", camera.home_position)
	return true


func _jump_out_tutorial() -> bool:
	# Note: The camera jumps on state change
	state = Global.State.Home
	emit_signal("state_updated")
	# FixMe This is a bit of a hack
	emit_signal("player_jumping", camera.home_position)
	return true


func save_game():
	# Note: This lacks a load so it needs to set all
	var id = GameServer.actor_id()
	if 0 >= id: return
	var file := ConfigFile.new()
	# Dust Currency
	file.set_value("dust", "storage", dust_storage)
	file.set_value("dust", "inventory", dust_inventory)
	# Speed Booster Currency
	file.set_value("speed_boost", "storage", speed_storage)
	file.set_value("speed_boost", "inventory", speed_inventory)
	# Firerate Booster Currency
	file.set_value("firerate_boost", "storage", firerate_storage)
	file.set_value("firerate_boost", "inventory", firerate_inventory)
	# High Score
	file.set_value("highsocre", "latest", highsocre)
	file.set_value("difficulty", "latest", difficulty)
	var err = file.save(SAVE_FILE % id)
	if err != OK: 
		push_warning("save_game: %s" % err)


func _load_game():
	var id = GameServer.actor_id()
	if 0 >= id: return
	var file := ConfigFile.new()
	var err = file.load(SAVE_FILE % id)
	if err != OK: 
		push_warning("_load_game: %s" % err)
	# Dust Currency
	if file.has_section_key("dust", "storage"):
		dust_storage = file.get_value("dust", "storage")
	if file.has_section_key("dust", "inventory"):
		dust_inventory = file.get_value("dust", "inventory")
	# Speed Booster Currency
	if file.has_section_key("speed_boost", "storage"):
		speed_storage = file.get_value("speed_boost", "storage")
	if file.has_section_key("speed_boost", "inventory"):
		speed_inventory = file.get_value("speed_boost", "inventory")
	# Firerate Booster Currency
	if file.has_section_key("firerate_boost", "storage"):
		firerate_storage = file.get_value("firerate_boost", "storage")
	if file.has_section_key("firerate_boost", "inventory"):
		firerate_inventory = file.get_value("firerate_boost", "inventory")
	# Globals
	if file.has_section_key("highsocre", "latest"):
		highsocre = file.get_value("highsocre", "latest") 
	if file.has_section_key("difficulty", "latest"):
		difficulty = file.get_value("difficulty", "latest") 


func scene_move_ended():
	emit_signal("scene_move_ended")


func scene_move_started():
	emit_signal("scene_move_started")


func add_kill():
	kills += 1
	emit_signal("updated_kills", kills)


func add_points(value):
	points += value
	if points > highsocre: highsocre = points
	emit_signal("updated_points", points)


func actor_died() -> bool:
	if state == State.Tutorial:
		return handle_tutorial_death()
	else:
		return handle_world_death()


func handle_world_death() -> bool:
	if local_player != null:
		local_player.world_death()
		emit_signal("actor_died")
		local_player = null
		show_home()
		return true
	return false


func handle_tutorial_death() -> bool:
	return local_sector.player_death()


func screen_shake(intensity, time):
	# ToDo Juice: Increase the shake intencity based on the 
	# sectors difficulty to impact the feeling difficulty gives.
	if Global.camera != null:
		Global.camera.screen_shake(intensity, time)
	if Global.overlay != null:
		Global.overlay.screen_shake(intensity, time)


func instance_node(node, parent, location):
	var object = node.instance()
	parent.add_child(object)
	object.global_position = location
	return object
