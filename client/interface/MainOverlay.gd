class_name MainOverlay
extends CanvasLayer

# FixMe: Tweak the gameserver delegate patern
# Update it to the delegate manager setup below

var shake_screen = false
var shake_intensity = 0

onready var game_hud = get_node("%GameHud")
onready var tutor_hud = get_node("%TutorHud")

onready var start_menu = get_node("%StartMenu")
onready var server_state = get_node("%ServerState")
onready var account_dialog = get_node("%AccountDialog")

onready var shake_timer = get_node("%ShakeTimer")


func _ready():
	#warning-ignore: return_value_discarded
	GameServer.connect("session_created", self, "_on_session_created")
	#warning-ignore: return_value_discarded
	GameServer.connect("session_closed", self, "_on_session_closed")
	#warning-ignore: return_value_discarded
	GameServer.connect("signed_out", self, "_on_signed_out")
	#warning-ignore: return_value_discarded
	GameServer.connect("signed_in", self, "_on_signed_in")
	#warning-ignore: return_value_discarded
	Global.connect("scene_move_ended", self, "_on_scene_move_ended")
	#warning-ignore: return_value_discarded
	Global.connect("state_updated", self, "_on_state_updated")
	#set self onto overlay delegates
	server_state.manager = self
	server_state.show()
	start_menu.manager = self
	start_menu.show()
	Global.overlay = self
	#initialize server authentication
	GameServer.authenticate()


func _exit_tree():
	Global.overlay = null
	start_menu.manager = null
	server_state.manager = null
	Global.disconnect("state_updated", self, "_on_state_updated")
	Global.disconnect("scene_move_ended", self, "_on_scene_move_ended")
	GameServer.disconnect("signed_in", self, "_on_signed_in")
	GameServer.disconnect("signed_out", self, "_on_signed_out")
	GameServer.disconnect("session_closed", self, "_on_session_closed")
	GameServer.disconnect("session_created", self, "_on_session_created")


func _process(delta):
	game_hud.rect_scale = lerp(game_hud.rect_scale, Vector2(1, 1), 0.24)
	if shake_screen:
		var x = rand_range(-shake_intensity, shake_intensity)
		var y = rand_range(-shake_intensity, shake_intensity)
		game_hud.rect_position += Vector2(x, y) * delta
	else:
		game_hud.rect_position = lerp(game_hud.rect_position, Vector2(0, 0), 0.24)


func screen_shake(intensity, time):
	game_hud.rect_scale = Vector2.ONE - Vector2(intensity * 0.0006, intensity * 0.0006)
	shake_intensity = intensity * 0.75
	shake_timer.wait_time = time
	shake_screen = true
	shake_timer.start()


func _on_shake_timeout():
	shake_intensity = 0
	shake_screen = false


func toggle_server_dialog() -> void:
	if account_dialog == null:
		return
	if Global.state != Global.State.App:
		# TODO: Implement in game dialog
		account_dialog.hide()
		return
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


func _on_state_updated():
	account_dialog.hide()
	start_menu.hide()
	tutor_hud.hide()
	game_hud.hide()


func _on_scene_move_ended():
	match Global.state:
		Global.State.App:
			start_menu.show()
		Global.State.Home:
		#	# ToDo Home Gui
			game_hud.show()
		Global.State.Sector:
			game_hud.show()
		Global.State.Tutorial:
			tutor_hud.show()
			game_hud.show()
