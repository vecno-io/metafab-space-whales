class_name MetaAccount
extends Reference

signal signed_in
signal signed_out

signal player_updated

var _cfg: MetaConfig = null setget _no_set
var _actor: ActorInfo = null setget _no_set
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


func actor_id() -> String:
	if _actor == null: return ""
	return _actor.id


func actor_info() -> ActorInfo:
	if _actor != null: return _actor
	return ActorInfo.new("")


func player_id() -> String:
	if _player != null: return _player.id
	return "000000-0000-0000-0000-0000"


func player_info() -> PlayerInfo:
	if _player != null: return _player
	return PlayerInfo.new()


func is_player_valid() -> bool:
	if _player == null: return false
	return _player.is_valid()


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
		"wallet_id": _player.wallet,
		"metafab_id": _player.id,
	})), "completed")):
		_push_error(-5, "meta_register rpc: %s - %s" % [user_id, json.result])
		_password = ""
		_player = null
		return
	SessionWorker.save_player_info(user_id, _password, _player)
	print("[Meta.Account] Player ID: %s" % _player.id)
	emit_signal("signed_in")
	_get_player_actors()
	_get_player_data()


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
	print("[Meta.Account] Player ID: %s" % _player.id)
	emit_signal("signed_in")
	_get_player_actors()
	_get_player_data()


func _get_player_data():
	var __ = MetaFab.get_player_data(self, 
		"_on_get_player_data_result", _player.id
	)


func _get_player_actors():
	var __ = MetaFab.get_collection_item_balances(self, 
		"_on_get_player_actors_result", 
		_cfg.collection_actors, 
		_player.wallet
	)


func _on_get_player_data_result(code: int, result: String):
	var json = JSON.parse(result)
	if code != 200: 
		_push_error(code, "invalid data result: %s" % json.result)
		return
	if OK != _player.parse_player_data(json.result):
		_push_error(code, "invalid data object: %s" % json.result)
		return
	emit_signal("player_updated")


func _on_get_player_actors_result(code: int, result: String):
	var json = JSON.parse(result)
	if code != 200: 
		_push_error(code, "invalid actors result: %s" % json.result)
		return
	if OK != _player.parse_player_actors(json.result):
		_push_error(code, "invalid actors object: %s" % json.result)
		return
	emit_signal("player_updated")


func _no_set(_value) -> void:
	push_error("[Metafab.Player] no set")


func _push_error(code: int, message: String) -> void:
	if code != OK: push_error("[Metafab.Player] Code: %s - %s" % [message, code])
