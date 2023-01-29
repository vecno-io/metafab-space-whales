extends Popup


# FixMe Had Coded Color
# Needs to fit the clear color
const clear_color = Color("#9c0e0c12")

var actor_map = {}
var selected_id =  ""

var regex = RegEx.new()
var is_loading: bool = false

onready var tabs = get_node("%TabContainer")
onready var overlay = get_node("%ColorOverlay")
onready var auth_timer = get_node("%AuthTimer")

onready var txn_list = get_node("%TransactionList")
onready var txn_empty = get_node("%TransactionsEmpty")

onready var box_link = get_node("%LinkBox")
onready var box_actors = get_node("%ActorsBox")
onready var box_loading = get_node("%LoadingBox")

onready var form_login = get_node("%LoginForm")
onready var form_actors = get_node("%ActorsForm")

onready var msg_actors = get_node("%ActorsMsg")
onready var msg_loading = get_node("%LoadingMsg")

onready var btn_login = get_node("%LogInBtn")
onready var btn_logout = get_node("%LogOutBtn")
onready var btn_regitser = get_node("%RegisterBtn")

onready var edit_pass = get_node("%PassInputEdit")
onready var edit_email = get_node("%EmailInputEdit")

onready var actors_list = get_node("%ActorsList")
onready var actors_slots = get_node("%ActorsSlots")

var actor_item = preload("res://interface/actor-dialog/ActorItem.tscn")
var actor_mint = preload("res://interface/actor-dialog/ActorMint.tscn")


func _ready():
	overlay.modulate = clear_color
	if OK != regex.compile('.+\\@.+\\.[a-z][a-z]+'):
		push_error("[%s] - email regex failed to compile" % name)
	#warning-ignore: return_value_discarded
	GameServer.connect("player_updated", self, "_on_player_updated")
	# Check the initial session state
	if !GameServer.has_session():
		_set_server_connecting()
	else: 
		_set_server_connected()
	signed_out()


func signed_in():
	btn_logout.show()
	form_login.hide()
	form_actors.show()
	#FixMe: Enable for history tab
	#tabs.set_tab_disabled(1, false)
	if is_loading: _end_server_loading()


func signed_out():
	btn_logout.hide()
	form_login.show()
	form_actors.hide()
	actors_slots.hide()
	#FixMe: Enable for history tab
	#tabs.set_tab_disabled(1, true)
	if is_loading: _end_server_loading()


func session_created():
	if !is_loading:
		_set_server_connected()


func session_closed():
	if !is_loading:
		_set_server_connecting()


func _end_server_loading():
	is_loading = false
	if !GameServer.has_session():
		_set_server_connecting()
	else: 
		_set_server_connected()


func _start_server_loading():
	is_loading = true
	box_link.hide()
	box_actors.hide()
	box_loading.show()


func _set_player_signed_in():
	if !GameServer.has_user():
		_push_error("player signed in: no user")
		_set_player_signed_out()
		return
	btn_logout.show()
	form_login.hide()
	form_actors.show()
	is_loading = false
	#FixMe: Enable for history tab
	#tabs.set_tab_disabled(1, false)


func _set_player_signed_out():
	if GameServer.has_user():
		_push_error("player signed out: has user")
		_set_player_signed_in()
		return
	btn_logout.hide()
	form_login.show()
	form_actors.hide()
	is_loading = false
	#FixMe: Enable for history tab
	#tabs.set_tab_disabled(1, true)


func _set_server_connected():
	tabs.set_tab_disabled(0, false)
	box_link.hide()
	box_actors.show()
	box_loading.hide()


func _set_server_connecting():
	tabs.set_tab_disabled(0, true)
	#tabs.set_tab_disabled(1, true)
	box_link.show()
	box_actors.hide()
	box_loading.hide()


func _on_close_pressed():
	self.hide()


func _on_login_pressed():
	_start_server_loading()
	# TODO Add in the option to save and password conformation on register
	var result = yield(GameServer.login_async(edit_email.text, edit_pass.text, true), "completed")
	if OK != result:
		msg_actors.text = "Login failed, check info."
		push_error("login account: %s" % result)
		_end_server_loading()
		return
	msg_actors.text = ""
	auth_timer.start(12)


func _on_logout_pressed():
	_start_server_loading()
	var result = yield(GameServer.logout_async(), "completed")
	if OK != result:
		msg_actors.text = "Logout failed, check files."
		push_error("logout account: %s" % result)
		return
	msg_actors.text = ""
	auth_timer.start(12)


func _on_register_pressed():
	_start_server_loading()
	# TODO Add in the option to save and password conformation on register
	var result = yield(GameServer.register_async(edit_email.text, edit_pass.text, true), "completed")
	if OK != result:
		msg_actors.text = "Register failed, check info."
		push_error("register account: %s" % result)
		_end_server_loading()
		return
	msg_actors.text = ""
	auth_timer.start(12)


func _on_auth_timer_timeout():
	if is_loading:
		msg_actors.text = "Network timedout, try later."
		_end_server_loading()


func _on_pass_entered(_value):
	_on_login_pressed()


func _on_email_entered(_value):
	edit_pass.grab_focus()


func _on_pass_text_changed(_value):
	_check_account_buttons()


func _on_email_text_changed(_value):
	_check_account_buttons()


func _check_account_buttons():
	if _validate_account_input():
		btn_regitser.disabled = false
		btn_login.disabled = false
		return
	btn_regitser.disabled = true
	btn_login.disabled = true


func _validate_account_input() -> bool:
	if edit_pass.text.length() < 8: 
		return false
	if edit_pass.text.length() > 128:
		return false
	if edit_email.text.length() > 64:
		return false
	if null == regex.search(edit_email.text): 
		return false
	return true


func _on_player_updated():
	# TODO Spam Protect: only when changed
	# Clear all items from the list
	for item in actors_list.get_children():
		actors_list.remove_child(item)
		item.queue_free()
	# Grab the new player and update
	var player = GameServer.player_info()
	var actors = player.actors_map
	var slots = player.actors_mints - player.actors_minted
	actors_slots.text = "Claims: %s/%s" % [player.actors_minted, player.actors_mints]
	actors_slots.show()
	if actors.size() > 0:
		for key in actors.keys():
			var actor = actor_item.instance()
			actor.set_values(actors[key])
			actor_map[key] = actor
			actors_list.add_child(actor)
			actor.connect("actor_selected", self, "_on_actor_selected")
			actor.connect("actor_activated", self, "_on_actor_activated")
	if slots > 0: 
		for __ in range(0, slots):
			var mint = actor_mint.instance()
			actors_list.add_child(mint)


func _on_actor_selected(actor):
	if selected_id.length() > 0:
		actor_map[selected_id].set_active(false)
	if actor == null:
		msg_actors.text = ""
		return
	msg_actors.text = "Double click to start"
	actor_map[actor.id].set_active(true)
	selected_id = actor.id


func _on_actor_activated(actor):
	msg_actors.text = ""
	Global.new_game()
	GameServer.actor.set_info(actor)
	Global.local_sector.stepper.skip_to(
		TutorStepper.Step.f
	)


func _push_error(message: String) -> void:
	push_error("[GUI.AccountDialog] %s" % message)
