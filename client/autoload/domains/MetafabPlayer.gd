class_name MetafabPlayer
extends Reference

signal signed_in
signal signed_out


var _id: String = "" setget _no_set
var _password: String = "" setget _no_set

var _client: NakamaClient setget _no_set
var _account: ServerAccount setget _no_set
var _exception: ServerException setget _no_set


func _init(client: NakamaClient, account: ServerAccount, exception: ServerException) -> void:
	_client = client
	_account = account
	_exception = exception


func clear_player() -> int:
	_id = ""
	_password = ""
	emit_signal("signed_out")
	return OK


func create_player(password: String) -> int:
	var user = _account.get_user_info()
	if !user.is_valid(): return -1
	if OK != _exception.metafab_parse(MetaFab.create_player(self,
		"_on_create_player_result", GameServer.game_key(), 
		user.id, password
	)):
		_push_error(_exception.code, 
			"metaFab.create_player: %s"
			% _exception.message
		)
		return -2
	_password = password
	return OK


func authenticate_player(password: String) -> int:
	var user = _account.get_user_info()
	if !user.is_valid(): return -1
	if OK != _exception.metafab_parse(MetaFab.auth_player(self,
		"_on_authenticate_player_result", GameServer.game_key(), 
		user.id, password
	)): 
		_push_error(_exception.code, 
			"metaFab.auth_player: %s"
			% _exception.message
		)
		return -2
	_password = password
	return OK


func _on_create_player_result(code: int, result: String) -> void:
	var json = JSON.parse(result)
	if code != 200: 
		_push_error(-1, "auth_player: %s - %s" % [code, json.result])
		return
	var user_id = _account.get_user_id()
	var session = yield(_account.get_session_async(), "completed")
	if session == null:
		_push_error(-2, "meta_register session: %s - %s" % [user_id, json.result])
		_password = ""
		return
	if OK != _exception.parse_nakama(yield(_client.rpc_async(session, "meta_register", JSON.print({
		"wallet_id": json.result.walletId,
		"metafab_id": json.result.id,
	})), "completed")):
		_push_error(-3, "meta_register rpc: %s - %s" % [user_id, json.result])
		_password = ""
		return
	# TODO Enable again
	#user = SessionWorker.save_metafab_user(_hashed, _password, json.result)
	_id = json.result.id
	emit_signal("signed_in")


func _on_authenticate_player_result(code: int, result: String) -> void:
	var json = JSON.parse(result)
	if code != 200: 
		_push_error(-1, "auth_player: %s - %s" % [code, json.result])
		_password = ""
		return
	# TODO Enable again
	#user = SessionWorker.save_metafab_user(_hashed, _password, json.result)
	_id = json.result.id
	emit_signal("signed_in")


func _no_set(_value) -> void:
	push_error("[Metafab.Player] no set")


func _push_error(code: int, message: String) -> void:
	if code != OK: push_error("[Metafab.Player] Code: %s - %s" % [message, code])
