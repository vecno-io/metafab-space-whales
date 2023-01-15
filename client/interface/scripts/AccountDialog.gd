extends Popup


# FixMe Had Coded Color
# Needs to fit the clear color
const clear_color = Color("#9c0e0c12")


var regex = RegEx.new()
var is_loading: bool = false

onready var tabs = get_node("%TabContainer")
onready var overlay = get_node("%ColorOverlay")

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


func _ready():
	overlay.modulate = clear_color
	if OK != regex.compile('.+\\@.+\\.[a-z][a-z]+'):
		push_error("[%s] - email regex failed to compile" % name)
	if !GameServer.has_session():
		_set_server_connecting()
	else: 
		_set_server_connected()


func signed_in():
	if !is_loading:
		_set_server_signed_in()


func signed_out():
	if !is_loading:
		_set_server_signed_out()


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


func _set_server_signed_in():
	if !GameServer.has_account():
		_set_server_signed_out()
		return
	btn_logout.show()
	form_login.hide()
	form_actors.show()
	is_loading = false
	tabs.set_tab_disabled(1, false)


func _set_server_signed_out():
	if GameServer.has_account():
		_set_server_signed_in()
		return
	btn_logout.hide()
	form_login.show()
	form_actors.hide()
	is_loading = false
	tabs.set_tab_disabled(1, true)


func _set_server_connected():
	tabs.set_tab_disabled(0, false)
	box_link.hide()
	box_actors.show()
	box_loading.hide()
	if !GameServer.has_account():
		_set_server_signed_out()
	else: 
		_set_server_signed_in()


func _set_server_connecting():
	tabs.set_tab_disabled(0, true)
	tabs.set_tab_disabled(1, true)
	box_link.show()
	box_actors.hide()
	box_loading.hide()

func _on_close_pressed():
	self.hide()


func _on_login_pressed():
	_start_server_loading()
	# TODO Add in the option to save and password conformation on register
	if OK != yield(GameServer.login_async(edit_email.text, edit_pass.text, true), "completed"):
		msg_actors.text = "Login failed, check info."
		_set_server_signed_out()
		_end_server_loading()
		return
	msg_actors.text = ""
	_set_server_signed_in()
	_end_server_loading()


func _on_logout_pressed():
	_start_server_loading()
	if OK != yield(GameServer.logout_async(), "completed"):
		msg_actors.text = "Logout failed, check files."
	else:
		msg_actors.text = ""
	_set_server_signed_out()
	_end_server_loading()


func _on_register_pressed():
	_start_server_loading()
	# TODO Add in the option to save and password conformation on register
	if OK != yield(GameServer.register_async(edit_email.text, edit_pass.text, true), "completed"):
		msg_actors.text = "Register failed, check info."
		_set_server_signed_out()
		_end_server_loading()
		return
	msg_actors.text = ""
	_set_server_signed_in()
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
	if !regex.search(edit_email.text): 
		return false
	return true
