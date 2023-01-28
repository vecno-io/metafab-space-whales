extends TutorialStep

# FixMe: split this up for code bravery

"""
Step 5-F. Exploration
	-> Needs Account Verification
		-> Mint Dust new account cration
		-> Then Reserve Actor ID and save state
	-> Needs A name for the actor
		-> Create The Actor
	-> Home Storage (Take some extra's)
	-> Jump To Random Sector (Intro Mode)
"""

enum State {
	None,
	Final,
	Store,
	NoUser,
	NoActor,
	NoSlots,
}

enum Forms {
	None,
	Actor,
	Login,
	Select,
	Server,
	Loading,
}

var done = false
var regex_name = RegEx.new()
var regex_email = RegEx.new()

# FixMe: This is a bit of hack to save time
var actor_map = {}
var selected_id =  ""
var actor_id = ""
var has_actor = false
var has_actor_id = false
var is_minting_id = false
var is_creating_id = false
var is_reserving_id = false

var total_stats = 12
var total_skills = 12

var login_is_valid = false
var loading_from = Forms.None

# TODO Loading Form Setup
# TODO Fix: Invisible lock jump without taking to litle from store

onready var actor_form = get_node("%ActorForm")
onready var login_form = get_node("%LoginForm")
onready var select_form = get_node("%SelectForm")
onready var server_form = get_node("%ServerForm")
onready var loading_form = get_node("%LoadingForm")

onready var info_final = get_node("%InfoFinal")
onready var info_store = get_node("%InfoStore")
onready var info_no_user = get_node("%InfoNoUser")
onready var info_no_actor = get_node("%InfoNoActor")
onready var info_no_slots = get_node("%InfoNoSlots")

onready var login_message = get_node("%LoginMessage")
onready var login_edit_pass = get_node("%PassEdit")
onready var login_edit_email = get_node("%EmailEdit")
onready var login_btn_singup = get_node("%LogInBtn")
onready var login_btn_regitser = get_node("%RegisterBtn")

onready var loading_timer = get_node("%LoadingTimer")

onready var actor_name_edit = get_node("%NameEdit")
onready var actor_btn_confirm = get_node("%ConfirmBtn")
onready var actor_color_selector = get_node("%ColorSelector")

onready var actor_stats_value = get_node("%StatsValue")
onready var actor_agility_slider = get_node("%AgilitySlider")
onready var actor_strength_slider = get_node("%StrengthSlider")
onready var actor_citality_slider = get_node("%VitalitySlider")

onready var actor_skills_value = get_node("%SkillsValue")
onready var actor_combat_slider = get_node("%CombatSlider")
onready var actor_industry_slider = get_node("%IndustrySlider")
onready var actor_exploration_slider = get_node("%ExplorationSlider")

onready var select_actor_msg = get_node("%ActorMsg")
onready var select_actors_list = get_node("%ActorsList")

var actor_item = preload("res://interface/actor-dialog/ActorItem.tscn")


func _ready():
	if OK != regex_name.compile('^[A-Za-z0-9]*$'):
		push_error("[%s] - name regex failed to compile" % name)
	if OK != regex_email.compile('.+\\@.+\\.[a-z][a-z]+'):
		push_error("[%s] - email regex failed to compile" % name)
	_set_info(State.None)
	_set_server_state()
	#warning-ignore: return_value_discarded
	GameServer.connect("player_updated", self, "_set_player_state")
	#warning-ignore: return_value_discarded
	GameServer.connect("session_closed", self, "_set_server_state")
	#warning-ignore: return_value_discarded
	GameServer.connect("session_created", self, "_set_server_state")
	#warning-ignore: return_value_discarded
	actor_name_edit.connect("text_changed", self, "_on_name_text_changed")
	#warning-ignore: return_value_discarded
	actor_color_selector.connect("color_selected", self, "_on_color_selected")
	#warning-ignore: return_value_discarded
	actor_agility_slider.connect("drag_ended", self, "_on_drag_ended_stats", [actor_agility_slider])
	#warning-ignore: return_value_discarded
	actor_strength_slider.connect("drag_ended", self, "_on_drag_ended_stats", [actor_strength_slider])
	#warning-ignore: return_value_discarded
	actor_citality_slider.connect("drag_ended", self, "_on_drag_ended_stats", [actor_citality_slider])
	#warning-ignore: return_value_discarded
	actor_combat_slider.connect("drag_ended", self, "_on_drag_ended_skill", [actor_combat_slider])
	#warning-ignore: return_value_discarded
	actor_industry_slider.connect("drag_ended", self, "_on_drag_ended_skill", [actor_industry_slider])
	#warning-ignore: return_value_discarded
	actor_exploration_slider.connect("drag_ended", self, "_on_drag_ended_skill", [actor_exploration_slider])

func _exit_tree():
	GameServer.disconnect("player_updated", self, "_set_player_state")
	GameServer.disconnect("session_closed", self, "_set_server_state")
	GameServer.disconnect("session_created", self, "_set_server_state")
	actor_color_selector.disconnect("color_selected", self, "_on_color_selected")


func _set_info(state):
	info_final.visible = State.Final == state
	info_store.visible = State.Store == state
	info_no_user.visible = State.NoUser == state
	info_no_actor.visible = State.NoActor == state
	info_no_slots.visible = State.NoSlots == state


func _set_form(state):
	actor_form.visible = Forms.Actor == state
	login_form.visible = Forms.Login == state
	select_form.visible = Forms.Select == state
	server_form.visible = Forms.Server == state
	loading_form.visible = Forms.Loading == state


func _set_server_state():
	if loading_from != Forms.None:
		return
	if !GameServer.has_session():
		Global.pause_game()
		_set_form(Forms.Server)
	else:
		_set_player_state()


func _set_player_state():
	if !GameServer.has_user():
		if loading_from == Forms.None:
			Global.pause_game()
			_set_form(Forms.Login)
			_set_info(State.NoUser)
	else:
		if loading_from != Forms.None:
			loading_from = Forms.None
		_set_actor_mint_state()


func _set_actor_mint_state():
	var info = GameServer.player_info()
	print_debug("_set_actor_mint_state: %s" % info.actors_map.size())
	if !info.has_actor_slots():
		Global.pause_game()
		_build_select_list(info)
		_set_form(Forms.Select)
		_set_info(State.NoSlots)
	else:
		_set_actor_state()


func _build_select_list(info):
	# Clear all items from the list
	for item in select_actors_list.get_children():
		select_actors_list.remove_child(item)
		item.queue_free()
	# Rebuild map from actor list
	for key in info.actors_map.keys():
		var actor = actor_item.instance()
		actor.set_values(info.actors_map[key])
		actor_map[key] = actor
		select_actors_list.add_child(actor)
		actor.connect("actor_selected", self, "_on_actor_selected")
		actor.connect("actor_activated", self, "_on_actor_activated")


func _on_actor_selected(actor):
	if selected_id.length() > 0:
		actor_map[selected_id].set_active(false)
	if actor == null:
		select_actor_msg.text = ""
		return
	select_actor_msg.text = "Double click to start"
	Global.color = Color(actor.attribs.color)
	actor_map[actor.id].set_active(true)
	selected_id = actor.id


func _on_actor_activated(actor):
	print_debug(">> activate: %s" % actor.id)
	# TODO Start Game with Actor
	select_actor_msg.text = ""
	actor_id = actor.id
	has_actor_id = true
	is_minting_id = false
	is_creating_id = false
	is_reserving_id = false
	if 0 < actor.name.length():
		has_actor = true
	_set_actor_state()



func _set_actor_state():
	# We know the player is logged in and has slots.
	# So check id, if null -> start id reservation
	# If no id, there is no actor so ask info
	# if id came back -> create the actor
	# then in step 6 -> mint the actor
	if has_actor:
		Global.unpause_game()
		_set_form(Forms.None)
		_set_info(State.Store)
		return
	Global.pause_game()
	_set_form(Forms.Actor)
	_set_info(State.NoActor)
	if !has_actor_id && !is_reserving_id:
		is_reserving_id = true
		GameServer.actor.connect("actor_reserved", self, "_handle_actor_reserved")
		var code = yield(GameServer.actor.reserve_async(), "completed")
		if OK != code:
			is_reserving_id = false
			# TODO Set Error Message
			print_debug("Error: Failed to reserve actor: %s" % code)


func _handle_actor_reserved(id):
	actor_id = id
	has_actor_id = true
	is_reserving_id = false
	_validate_actor_input()
	# TODO Clear Error Message
	GameServer.actor.disconnect("actor_reserved", self, "_handle_actor_reserved")


func _on_reconnect_pressed():
	GameServer.authenticate()


func _on_link_closed():
	if paused:
		return
	done = true
	_set_info(State.Final)
	Global.can_jump = true


func _on_player_jumped():
	if paused || stepper == null:
		return
	if !done:
		return
	stepper.next()
	Global.disconnect("player_jumped", self, "_on_player_jumped")
	Global.local_store.disconnect("link_closed", self, "_on_link_closed")


func start_step(_stepper: TutorStepper):
	.start_step(_stepper)
	Global.can_jump = false
	_set_info(State.None)
	_set_server_state()
	#warning-ignore: return_value_discarded
	Global.connect("player_jumped", self, "_on_player_jumped")
	#warning-ignore: return_value_discarded
	Global.local_store.connect("link_closed", self, "_on_link_closed")


func _on_pass_entered(_value):
	if login_is_valid:
		_on_login_pressed()


func _on_email_entered(_value):
	login_edit_pass.grab_focus()


func _on_pass_text_changed(_value):
	_check_account_buttons()


func _on_email_text_changed(_value):
	_check_account_buttons()


func _on_login_pressed():
	loading_from = Forms.Login
	_set_form(Forms.Loading)
	# TODO Add in the option to save and password conformation on register
	var result = yield(GameServer.login_async(
		login_edit_email.text, login_edit_pass.text, true
	), "completed")
	if OK != result:
		login_message.text = "Login failed, check info."
		push_error("login account: %s" % result)
		_set_form(Forms.Login)
		return
	login_message.text = ""
	loading_timer.start(12)


func _on_register_pressed():
	loading_from = Forms.Login
	_set_form(Forms.Loading)
	# TODO Add in the option to save and password conformation on register
	var result = yield(GameServer.register_async(
		login_edit_email.text, login_edit_pass.text, true
	), "completed")
	if OK != result:
		login_message.text = "Register failed, check info."
		push_error("register account: %s" % result)
		_set_form(Forms.Login)
		return
	login_message.text = ""
	loading_timer.start(12)


func _on_confirm_pressed():
	if !_validate_actor_input():
		return
	if is_creating_id:
		return
	is_creating_id = true
	var info =	ActorInfo.new(actor_id, false)
	info.attribs_randomize()
	info.name = actor_name_edit.text
	var rand = RandomNumberGenerator.new()
	rand.seed = Time.get_ticks_msec()
	info.stats.agility = "%03d" % ((32 * int(actor_agility_slider.value)) - rand.randi_range(1, 32))
	info.stats.strength = "%03d" % ((32 * int(actor_strength_slider.value)) - rand.randi_range(1, 32))
	info.stats.vitality = "%03d" % ((32 * int(actor_citality_slider.value)) - rand.randi_range(1, 32))
	info.skills.combat = "%03d" % ((32 * int(actor_combat_slider.value)) - rand.randi_range(1, 32))
	info.skills.industry = "%03d" % ((32 * int(actor_industry_slider.value)) - rand.randi_range(1, 32))
	info.skills.exploration = "%03d" % ((32 * int(actor_exploration_slider.value)) - rand.randi_range(1, 32))
	info.attribs_randomize()
	info.attribs_set_color(
		actor_color_selector.color()
	)
	GameServer.actor.connect("actor_created", self, "_handle_actor_created")
	var code = yield(GameServer.actor.create_async(info), "completed")
	if OK != code:
		is_reserving_id = false
		# TODO Set Error Message
		print_debug("Error: Failed to create actor: %s" % code)
	_set_actor_state()


func _handle_actor_created(_tx):
	has_actor = true
	is_reserving_id = false
	# TODO Clear Error Message
	GameServer.actor.disconnect("actor_created", self, "_handle_actor_created")
	GameServer.actor.connect("actor_minted", self, "_handle_actor_minted")
	var code = yield(GameServer.actor.mint_async(), "completed")
	if OK != code:
		is_reserving_id = false
		# TODO Set Error Message
		print_debug("Error: Failed to mint actor: %s" % code)


func _handle_actor_minted(_tx):
	is_minting_id = false
	# TODO Clear Error Message



func _on_name_text_changed(_text):
	_validate_actor_input()


func _on_color_selected(color):
	Global.color = color
	_validate_actor_input()


func _on_drag_ended_stats(changed, slider):
	if !changed: 
		return
	var tot = 0
	tot += actor_agility_slider.value
	tot += actor_strength_slider.value
	tot += actor_citality_slider.value
	if tot > 12:
		slider.value = slider.value - (tot - 12)
		actor_stats_value.text = "12/12"
		total_stats = 12
	else:
		actor_stats_value.text = "%s/12" % tot
		total_stats = tot
	_validate_actor_input()

func _on_drag_ended_skill(changed, slider):
	if !changed: 
		return
	var tot = 0
	tot += actor_combat_slider.value
	tot += actor_industry_slider.value
	tot += actor_exploration_slider.value
	if tot > 12:
		slider.value = slider.value - (tot - 12)
		actor_skills_value.text = "12/12"
		total_skills = 12
	else:
		actor_skills_value.text = "%s/12" % tot
		total_skills = tot
	_validate_actor_input()


func _on_loading_timeout():
	if loading_from == Forms.None:
		return
	if loading_from == Forms.Login:
		login_message.text = "Network timedout, try later."
		loading_from = Forms.None
		_set_form(Forms.Login)
		return
	# TODO Link Other Messages
	loading_from = Forms.None
	_set_server_state()


func _check_account_buttons():
	if _validate_account_input():
		login_btn_regitser.disabled = false
		login_btn_singup.disabled = false
	else:
		login_btn_regitser.disabled = true
		login_btn_singup.disabled = true


func _validate_account_input() -> bool:
	if login_edit_pass.text.length() < 8:
		login_is_valid = false
		return false
	if login_edit_pass.text.length() > 128:
		login_is_valid = false
		return false
	if null == regex_email.search(login_edit_email.text):
		login_is_valid = false
		return false
	if login_edit_email.text.length() > 64:
		login_is_valid = false
		return false
	login_is_valid = true
	return true


func _validate_actor_input() -> bool:
	if !has_actor_id:
		actor_btn_confirm.disabled = true
		return false
	if null == regex_name.search(actor_name_edit.text):
		actor_name_edit.modulate = Color("#ff3b5f")
		actor_btn_confirm.disabled = true
		return false
	else:
		actor_name_edit.modulate = Color("#ffffff")
	if actor_name_edit.text.length() < 3:
		actor_btn_confirm.disabled = true
		return false
	if actor_name_edit.text.length() > 64:
		actor_btn_confirm.disabled = true
		return false
	if !actor_color_selector.selected():
		actor_btn_confirm.disabled = true
		return false
	if total_stats != 12:
		actor_btn_confirm.disabled = true
		return false
	if total_skills != 12:
		actor_btn_confirm.disabled = true
		return false
	actor_btn_confirm.disabled = false
	return true
