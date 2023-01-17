class_name MetaAccount
extends Reference

signal signed_in
signal signed_out


var _cfg: MetaConfig = null setget _no_set
var _player: PlayerInfo = null setget _no_set
var _password: String = "" setget _no_set

var _client: NakamaClient setget _no_set
var _account: ServerAccount setget _no_set
var _exception: ServerException setget _no_set


func _init(client: NakamaClient, account: ServerAccount, exception: ServerException) -> void:
	_client = client
	_account = account
	_exception = exception


func set_config(config: MetaConfig):
	print("[Meta.Account] Game ID: %s" % config.game_id)
	_cfg = config


func player_info() -> PlayerInfo:
	if _player != null: return PlayerInfo.new(
		_player.id, _player.token, _player.wallet
	)
	return PlayerInfo.new()


func clear_player() -> int:
	_player = null
	_password = ""
	emit_signal("signed_out")
	return OK


func create_player(password: String) -> int:
	var user = _account.user_info()
	if !user.is_valid(): return -1
	if OK != _exception.metafab_parse(MetaFab.create_player(self,
		"_on_create_player_result", ConfigWorker.game_key(), 
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
	var user = _account.user_info()
	if !user.is_valid(): return -1
	if OK != _exception.metafab_parse(MetaFab.auth_player(self,
		"_on_authenticate_player_result", ConfigWorker.game_key(), 
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
		_password = ""
		_player = null
		return
	var user_id = _account.user_id()
	var session = yield(_account.get_session_async(), "completed")
	if session == null:
		_push_error(-2, "meta_register session: %s - %s" % [user_id, json.result])
		_password = ""
		_player = null
		return
	if typeof(json.result) != TYPE_DICTIONARY:
		_push_error(-3, "meta_register json: %s - %s" % [user_id, json.result])
		_password = ""
		_player = null
		return
	
	_player = PlayerInfo.new()
	if OK != _player.from_result(json.result): 
		_push_error(-4, "meta_register json: %s - %s" % [user_id, json.result])
		_password = ""
		return
	if OK != _exception.parse_nakama(yield(_client.rpc_async(session, "meta_register", JSON.print({
		"wallet_id": _player.walletId,
		"metafab_id": _player.id,
	})), "completed")):
		_push_error(-5, "meta_register rpc: %s - %s" % [user_id, json.result])
		_password = ""
		_player = null
		return
	SessionWorker.save_player_info(user_id, _password, _player)
	emit_signal("signed_in")
	_get_user_metadata()


func _on_authenticate_player_result(code: int, result: String) -> void:
	var json = JSON.parse(result)
	if code != 200: 
		_push_error(-1, "auth_player: %s - %s" % [code, json.result])
		_password = ""
		return
	var user_id = _account.user_id()
	if typeof(json.result) != TYPE_DICTIONARY:
		_push_error(-3, "meta_register json: %s - %s" % [user_id, json.result])
		_password = ""
		return
	_player = PlayerInfo.new()
	if OK != _player.from_result(json.result): 
		_push_error(-4, "meta_register json: %s - %s" % [user_id, json.result])
		_password = ""
		return
	SessionWorker.save_player_info(user_id, _password, _player)
	emit_signal("signed_in")
	_get_user_metadata()


func _get_user_metadata():
	# TODO Implement this next
	# get the metadata for the user
	# load list of actors for the user
	pass


# static func _player_info_from_result(data: Dictionary) -> PlayerInfo:
# 	if data == null: return PlayerInfo.new()
# 	if !data.has_all([
# 		"id", 
# 		"walletId", 
# 		"accessToken"
# 	]): return PlayerInfo.new()
# 	return PlayerInfo.new(
# 		data["id"],
# 		data["accessToken"],
# 		data["walletId"]
# 	)


func _no_set(_value) -> void:
	push_error("[Metafab.Player] no set")


func _push_error(code: int, message: String) -> void:
	if code != OK: push_error("[Metafab.Player] Code: %s - %s" % [message, code])
