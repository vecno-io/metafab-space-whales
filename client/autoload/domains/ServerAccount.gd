class_name ServerAccount
extends Reference


signal session_closed
signal session_created


var _id: String = "" setget _no_set
var _name: String = "" setget _no_set
var _email: String = "" setget _no_set
var _password: String = "" setget _no_set

var _hash: String = "" setget _no_set
var _client: NakamaClient setget _no_set
var _session: NakamaSession setget _no_set
var _exception: ServerException setget _no_set

var _authenticating: bool = false


func _init(client: NakamaClient, exception: ServerException) -> void:
	_hash = ConfigWorker.get_client_hash()
	_client = client
	_session = null
	_exception = exception


func has_user() -> bool:
	# Authentication sets the password;
	# on failure the password is cleared.
	if _authenticating: 
		print(">>>> auth: %s" % _authenticating)
		return false
	if _id.empty(): 
		print(">>>> _id: %s" % _id)
		return false
	if _email.empty():
		print(">>>> _email: %s" % _email)
		return false
	if _password.empty(): 
		print(">>>> _password: %s" % _password)
		return false
	return true


func get_user_id() -> String:
	return _id


func get_user_info() -> UserInfo:
	return UserInfo.new(_id, _name, _email)


func has_session() -> bool:
	# Note: See get_session
	return _session != null


func get_session_async() -> NakamaSession:
	# If a session is available check the experation date,
	# if a refresh fails use the stored credentials, if
	# both fail then fallback to the device account.
	if _session != null && _session.expired:
		_session = yield(_client.session_refresh_async(_session), "completed")
		if OK != _exception.parse(_session):
			_session = yield(_client.authenticate_email_async(
				_email, _password, _name, false
			), "completed")
			if OK != _exception.parse(_session):
				_session = null
				yield(authenticate_device_async(), "completed")
			else:
				SessionWorker.save_session_token(
					_id, _password, _session.token
				)
	yield(GameServer.get_tree(), "idle_frame")
	return _session


func authenticate_device_async() -> int:
	if _authenticating:
		yield(GameServer.get_tree(), "idle_frame")
		return -401
	else: 
		_authenticating = true
	if _session != null: 
		yield(_close_session_async(), "completed")
	print("[Server.Account] Auth Hash: %s" % _hash)
	var session = yield(_client.authenticate_device_async(_hash), "completed")
	if OK != _exception.parse_nakama(session):
		_push_error(1, "Failed to authenticated")
		_authenticating = false
		return -1
	else:
		_session = session
		print("[Server.Account] Authenticated: %s" % session.user_id)
		_save_session_data(false)
		emit_signal("session_created")
		_authenticating = false
		return OK


func clear_account_async() -> int:
	yield(_close_session_async(), "completed")
	SessionWorker.clear()
	yield(authenticate_device_async(), "completed")
	_password = ""
	_email = ""
	return OK


func create_account_async(email: String, password: String, save_email: bool = false) -> int:
	if _authenticating:
		yield(GameServer.get_tree(), "idle_frame")
		return -401
	else: 
		_authenticating = true
	_email = email
	_password = password.sha256_text()
	print("[Server.Account] Link Account: %s" % email)
	if OK != yield(_link_account_email_async(), "completed"): 
		_authenticating = false
		yield(authenticate_device_async(), "completed")
		_password = ""
		_email = ""
		return -1
	else:
		# TODO Create the MetaFab Account
		_save_session_data(save_email)
		_authenticating = false
		return OK


func authenticate_account_async(email: String, password: String, save_email: bool = false) -> int:
	if _authenticating:
		yield(GameServer.get_tree(), "idle_frame")
		return -401
	else: 
		_authenticating = true
	_email = email
	print("[Server.Account] Auth Account: %s" % email)
	if OK != yield(_auth_account_async(false, password), "completed"):
		_authenticating = false
		yield(authenticate_device_async(), "completed")
		_password = ""
		_email = ""
		return -1
	else:
		# TODO Load the MetaFab Account
		_save_session_data(save_email)
		_authenticating = false
		return OK


func _no_set(_value) -> void:
	push_error("[Server.Account] no set")


func _save_session_data(save_email: bool):
	if _session == null: 
		return
	_id = _session.user_id
	_name = _session.username
	var email = ""
	if save_email: email = _email
	SessionWorker.save_user_info(
		UserInfo.new(_id, _name, email)
	)
	SessionWorker.save_session_token(
		_id, _password, _session.token
	)


func _close_session_async():
	if _session == null: 
		return yield(GameServer.get_tree(), "idle_frame")
	var session = _session
	_session = null
	var result = yield(_client.session_logout_async(session), "completed")
	if OK != _exception.parse_nakama(result): _push_error(
		4, "close session failed: %s" % session.user_id
	)
	emit_signal("session_closed")


func _auth_account_async(create: bool, password: String) -> int:
	if _session != null: 
		yield(_close_session_async(), "completed")
	_password = password.sha256_text()
	var session = yield(_client.authenticate_email_async(
		_email, _password, _name, create
	), "completed")
	if OK != _exception.parse_nakama(session):
		_push_error(-1, "Failed to authenticated")
		return -1
	_session = session
	emit_signal("session_created")
	print("[Server.Account] Authenticated: %s" % session.user_id)
	return OK


func _link_account_email_async() -> int:
	# Links the acount info and unlink
	# the clients hash from the account
	if _session == null: return -201
	if OK != _exception.parse_nakama(yield(
		_client.link_email_async(_session, _email, _password),
		"completed"
	)):
		_push_error(1, 
			"Email link: %s - %s" % 
			[_session.user_id, _email]
		)
		return 1
	var __ = _exception.parse_nakama(yield(
		_client.unlink_device_async(_session, _hash),
		"completed"
	))
	print(
		"[Server.Account] Email linked: %s - %s" % 
		[_session.user_id, _email]
	)
	return OK


func _push_error(code: int, message: String) -> void:
		if code != OK: push_error("[Server.Account] Code: %s - %s" % [message, code])
