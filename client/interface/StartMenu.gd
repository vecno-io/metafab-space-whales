extends Node


var manager: MainOverlay = null

onready var new_game = get_node("%NewGame")
onready var load_game = get_node("%LoadGame")

onready var new_game_btn = get_node("%NewGameBtn")
onready var load_game_btn = get_node("%LoadGameBtn")

onready var connect_game = get_node("%ConnectLabel")
onready var connect_label = get_node("%ConnectGame")

func _ready():
	new_game.hide()
	load_game.hide()
	connect_game.show()
	connect_label.show()
	new_game_btn.disabled = true
	load_game_btn.disabled = true
	#warning-ignore: return_value_discarded
	GameServer.connect("player_updated", self, "_on_player_updated")
	#warning-ignore: return_value_discarded
	GameServer.connect("session_closed", self, "_on_session_closed")
	#warning-ignore: return_value_discarded
	GameServer.connect("session_created", self, "_on_session_created")


func _on_session_closed():
	new_game.hide()
	load_game.hide()
	connect_game.show()
	connect_label.show()
	load_game_btn.disabled = true


func _on_session_created():
	new_game.show()
	load_game.show()
	connect_game.hide()
	connect_label.hide()
	# Device sessions can load a game but
	# only start a game if no player is set
	load_game_btn.disabled = false
	_on_player_updated()


func _on_player_updated():
	# To play a valid game session is required
	if !GameServer.is_session_valid():
		new_game_btn.disabled = true
		return
	# Guest sessions can start the tutorial
	if !GameServer.is_player_valid():
		new_game_btn.disabled = false
		return
	# Registered players have mint limits
	var info = GameServer.player_info()
	new_game_btn.disabled = !info.has_actor_slots()



func _check_player_limits():
	var info = GameServer.player_info()
	if info.actors_minted >= info.actors_mints:
		new_game_btn.disabled = true
		return
	new_game_btn.disabled = false


func _on_new_game_pressed():
	Global.new_game()


func _on_load_game_pressed():
	if manager == null: push_error("missing manager")
	else: manager.toggle_server_dialog()


func _on_reconnect_pressed():
	GameServer.authenticate()
