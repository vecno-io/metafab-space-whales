class_name MainOverlay
extends CanvasLayer


onready var start_menu = get_node("%StartMenu")
onready var server_state = get_node("%ServerState")
onready var account_dialog = get_node("%AccountDialog")


func _ready():
	#warning-ignore: return_value_discarded
	GameServer.connect("session_created", self, "_on_session_created")
	#warning-ignore: return_value_discarded
	GameServer.connect("session_closed", self, "_on_session_closed")
	#warning-ignore: return_value_discarded
	GameServer.connect("signed_out", self, "_on_signed_out")
	#warning-ignore: return_value_discarded
	GameServer.connect("signed_in", self, "_on_signed_in")
	#initialize server authentication
	GameServer.authenticate()
	start_menu.manager = self
	server_state.manager = self



func toggle_server_dialog() -> void:
	if account_dialog != null:
		if account_dialog.visible: 
			account_dialog.hide()
		else: 
			account_dialog.popup_centered()


func _on_signed_in():
	server_state.signed_in()
	account_dialog.signed_in()


func _on_signed_out():
	server_state.signed_out()
	account_dialog.signed_out()


func _on_session_created():
	server_state.session_created()
	account_dialog.session_created()


func _on_session_closed():
	server_state.session_closed()
	account_dialog.session_closed()
