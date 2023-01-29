extends Node


signal signed_in
signal signed_out

signal user_updated
signal actor_updated
signal player_updated

signal session_closed
signal session_created


# Note: Set key and domain before build
const SERVER_KEY = "Client-Key-420-1337"
const SERVER_DOMAIN = "%s%s.game-server.test"


var _client: NakamaClient = null setget _no_set

var actor: GameActor = null setget _no_set
var sector: GameSector = null setget _no_set

var _meta: MetaAccount = null setget _no_set
var _account: ServerAccount = null setget _no_set
var _exception: ServerException = null setget _no_set


func _init() -> void:
	# TODO FixMe Load metafab data set
	# - This is manualy set in the app file,
	# needs to be saved and loaded from nakama
	# Configure the servers client
	_exception = ServerException.new()
	if ConfigWorker.server_localhost():
		print("[Game.Server] Using: localhost")
		_server_setup("127.0.0.1")
		return
	var region = ConfigWorker.server_region()
	var network = ConfigWorker.server_network()
	var address = SERVER_DOMAIN % [ region, network ]
	print("[Game.Server] Using: %s" % address)
	_server_setup(address)


func game_id() -> String:
	return ConfigWorker.game_id()


func game_key() -> String:
	return ConfigWorker.game_key()


func user_id() -> String:
	return _account.user_id()


func user_info() -> UserInfo:
	return _account.user_info()


func player_id() -> String:
	return _meta.player_id()


func player_info() -> PlayerInfo:
	return _meta.player_info()


func authenticate():
	# TODO If user: auth old session else:
	# TODO Handle account and session error messages
	var __ = yield(_account.authenticate_device_async(), "completed")


func has_user() -> bool:
	return _account.has_user()


func has_session() -> bool:
	return _account.has_session()


func is_user_valid() -> bool:
	return _account.is_user_valid()


func is_player_valid() -> bool:
	return _meta.is_player_valid()


func is_session_valid() -> bool:
	return _account.is_session_valid()


func logout_async() -> int:
	var __ = yield(_account.clear_account_async(), "completed")
	return _meta.clear_player()


func login_async(email: String, password: String, save_email: bool = false) -> int:
	if OK == yield(_account.authenticate_account_async(email, password, save_email), "completed"):
		return _meta.authenticate_player(password)
	return -1


func register_async(email: String, password: String, save_email: bool = false) -> int:
	if OK == yield(_account.create_account_async(email, password, save_email), "completed"):
		return _meta.create_player(password)
	return -1


func _no_set(_value) -> void:
	push_error("[Game.Server] no set")


func _server_setup(address: String):
	# Create the Client, Account, and Storage; connect all signals
	_client = Nakama.create_client(SERVER_KEY, address, 7350, "http", 12, NakamaLogger.LOG_LEVEL.INFO)
	_client.auto_retry = false
	_account = ServerAccount.new(_client, _exception)
	_meta = MetaAccount.new(_client, _account, _exception)
	actor = GameActor.new(_client, _account, _exception)
	sector = GameSector.new(_client, _account, _exception)
	#warning-ignore: return_value_discarded
	_meta.connect("signed_in", self, "_on_meta_signed_in")
	#warning-ignore: return_value_discarded
	_meta.connect("signed_out", self, "_on_meta_signed_out")
	#warning-ignore: return_value_discarded
	_meta.connect("player_updated", self, "_on_meta_player_updated")
	#warning-ignore: return_value_discarded
	_account.connect("user_updated", self, "_on_account_user_updated")
	#warning-ignore: return_value_discarded
	_account.connect("session_closed", self, "_on_account_session_closed")
	#warning-ignore: return_value_discarded
	_account.connect("session_created", self, "_on_account_session_created")
	#warning-ignore: return_value_discarded
	actor.connect("info_updated", self, "_on_actor_info_updated")


func _on_actor_info_updated():
	Global.color = actor.color()
	emit_signal("actor_updated")


func _on_meta_signed_in():
	emit_signal("signed_in")


func _on_meta_signed_out():
	emit_signal("signed_out")


func _on_meta_player_updated():
	emit_signal("player_updated")


func _on_account_user_updated():
	emit_signal("user_updated")


func _on_account_session_closed():
	emit_signal("session_closed")


func _on_account_session_created():
	yield(_load_config_async(), "completed")
	emit_signal("session_created")


func _load_config_async():
	var session = yield(_account.get_session_async(), "completed")
	var response = yield(_client.rpc_async(session, "game_info"), "completed")
	if OK != _exception.parse_nakama(response):
		_push_error(-1, "rpc.game_info: %s - %s" % ["failed to load"])
		return
	var json = JSON.parse(response.payload)
	if OK != json.error:
		_push_error(-2, "json.game_info: %s - %s" % [json.error, json.error_string])
		return -3
	var config = MetaConfig.new()
	if OK != config.from_result(json.result): 
		_push_error(-4, "json.game_info result: is not valid")
		print_debug("[Game.Server] Invalid game info: %s" % json.result)
		return -4
	_meta.set_config(config)
	actor.set_config(config)
	sector.set_config(config)


func _push_error(code: int, message: String) -> void:
	if code != OK: push_error("[Game.Server] Code: %s - %s" % [message, code])
