extends Node

export(Texture) var stats_h_a: Texture
export(Texture) var stats_h_b: Texture
export(Texture) var stats_h_c: Texture
export(Texture) var stats_h_d: Texture

export(Texture) var stats_n_a: Texture
export(Texture) var stats_n_b: Texture
export(Texture) var stats_n_c: Texture
export(Texture) var stats_n_d: Texture

export(Texture) var stats_p_a: Texture
export(Texture) var stats_p_b: Texture
export(Texture) var stats_p_c: Texture
export(Texture) var stats_p_d: Texture

var manager: MainOverlay = null

onready var info_box = get_node("%StateInfoBox")

onready var status = get_node("%StatusBtn")

onready var actor_label = get_node("%ActorLabel")
onready var account_label = get_node("%AccountLabel")
onready var connected_label = get_node("%ConnectedLabel")


func _ready():
	info_box.hide()


func actor_loaded():
	actor_label.text = "Ok - Actor"
	status.texture_hover = stats_h_d
	status.texture_pressed = stats_p_d
	status.texture_normal = stats_n_d
	status.texture_focused = stats_n_d
	status.texture_disabled = stats_n_d


func actor_cleared():
	actor_label.text = "None - Actor"
	status.texture_hover = stats_h_c
	status.texture_pressed = stats_p_c
	status.texture_normal = stats_n_c
	status.texture_focused = stats_n_c
	status.texture_disabled = stats_n_c


func signed_in():
	account_label.text = "Ok - Account"
	status.texture_hover = stats_h_c
	status.texture_pressed = stats_p_c
	status.texture_normal = stats_n_c
	status.texture_focused = stats_n_c
	status.texture_disabled = stats_n_c

func signed_out():
	account_label.text = "None - Account"
	status.texture_hover = stats_h_b
	status.texture_pressed = stats_p_b
	status.texture_normal = stats_n_b
	status.texture_focused = stats_n_b
	status.texture_disabled = stats_n_b

func session_created():
	connected_label.text = "Ok - Connected"
	status.texture_hover = stats_h_b
	status.texture_pressed = stats_p_b
	status.texture_normal = stats_n_b
	status.texture_focused = stats_n_b
	status.texture_disabled = stats_n_b


func session_closed():
	connected_label.text = "None - Connected"
	status.texture_hover = stats_h_a
	status.texture_pressed = stats_p_a
	status.texture_normal = stats_n_a
	status.texture_focused = stats_n_a
	status.texture_disabled = stats_n_a


func _on_mouse_exited():
	info_box.hide()


func _on_mouse_entered():
	info_box.show()


func _on_mouse_pressed():
	if manager == null: push_error("missing manager")
	else: manager.toggle_server_dialog()
