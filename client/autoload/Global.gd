extends Node

enum State {
	No,
	Game,
	Dialog,
	Tutorial
}

signal actor_died
signal state_updated

signal game_paused
signal game_unpaused

signal updated_kills(value)
signal updated_points(value)
signal updated_difficulty(value)

signal dust_storage_updated(value)
signal dust_inventory_updated(value)

signal speed_storage_updated(value)
signal speed_inventory_updated(value)

signal firerate_storage_updated(value)
signal firerate_inventory_updated(value)

const SAVE_FILE := "user://savefile.data"

var state = State.No setget _no_set

var kills = 0 setget _no_set
var points = 0 setget _no_set
var paused = true setget _no_set
var highsocre = 0 setget _no_set

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

var local_player = null
var local_sector = null setget _set_sector


func _no_set(_value):
	pass


func _ready():
	_load_game()
	yield(get_tree().create_timer(0.1), "timeout")
	show_tutorial()


func _set_sector(value):
	_sector_disconnect()
	local_sector = value
	_sector_connect()
	_sector_reset()
	unpause_game()


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


func _sector_connect():
	if local_sector == null:
		return
	local_sector.connect("updated_difficulty", self, "_sector_updated_difficulty")


func _sector_disconnect():
	if local_sector == null:
		return
	local_sector.disconnect("updated_difficulty", self, "_sector_updated_difficulty")


func _sector_updated_difficulty(value):
	emit_signal("updated_difficulty", value)


func show_game():
	self.save_game()
	state = Global.State.Game
	emit_signal("state_updated")
	if world != null: world.show_game()
	if overlay != null: overlay.show_game()


func show_dialog():
	self.save_game()
	world.reset_player()
	camera.reset_position()
	state = Global.State.Dialog
	emit_signal("state_updated")
	if world != null: world.show_dialog()
	if overlay != null: overlay.show_dialog()


func show_tutorial():
	state = Global.State.Tutorial
	emit_signal("state_updated")
	if world != null: world.show_tutorial()
	if overlay != null: overlay.show_tutorial()


func save_game():
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
	var err = file.save(SAVE_FILE)
	if err != OK: 
		push_warning("save_game: %s" % err)


func _load_game():
	var file := ConfigFile.new()
	var err = file.load(SAVE_FILE)
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
	# High Score
	if file.has_section_key("highsocre", "latest"):
		highsocre = file.get_value("highsocre", "latest") 


func pause_game():
	paused = true
	emit_signal("game_paused")


func unpause_game():
	paused = false
	emit_signal("game_unpaused")


func add_kill():
	kills += 1
	emit_signal("updated_kills", kills)

func add_points(value):
	points += value
	if points > highsocre: highsocre = points
	emit_signal("updated_points", points)


func actor_died():
	emit_signal("actor_died")
	show_dialog()


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
