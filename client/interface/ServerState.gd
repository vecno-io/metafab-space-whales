extends Node


var manager: MainOverlay = null

onready var info_box = get_node("%StateInfoBox")

onready var actor_label = get_node("%ActorLabel")
onready var account_label = get_node("%AccountLabel")
onready var connected_label = get_node("%ConnectedLabel")


func _ready():
	info_box.hide()


func actor_loaded():
	actor_label.text = "Ok - Actor"


func actor_cleared():
	actor_label.text = "None - Actor"


func signed_in():
	account_label.text = "Ok - Account"


func signed_out():
	account_label.text = "None - Account"


func session_created():
	connected_label.text = "Ok - Connected"


func session_closed():
	connected_label.text = "None - Connected"


func _on_mouse_exited():
	info_box.hide()


func _on_mouse_entered():
	info_box.show()


func _on_mouse_pressed():
	if manager == null: push_error("missing manager")
	else: manager.toggle_server_dialog()
