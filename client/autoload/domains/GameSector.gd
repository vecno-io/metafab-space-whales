class_name GameSector
extends Reference

var _cfg: MetaConfig = null setget _no_set

var _client: NakamaClient setget _no_set
var _account: ServerAccount setget _no_set
var _exception: ServerException setget _no_set


func _init(client: NakamaClient, account: ServerAccount, exception: ServerException) -> void:
	_client = client
	_account = account
	_exception = exception


func set_config(config: MetaConfig):
	_cfg = config


func end_combat():
	# FixMe submit Action list for replay's
	# Hacked setup -> Nakama actor_combat_outcome
	var session = yield(_account.get_session_async(), "completed")
	if session == null:
		return -1
	var result = yield(_client.rpc_async(
			session, "actor_combat_outcome", JSON.print({
				"actor": GameServer.actor.id(),
				"dust": Global.dust_inventory,
				"speed": Global.speed_inventory,
				"attack": Global.firerate_inventory,
			})
	), "completed")
	if OK != _exception.parse_nakama(result):
		push_error("[RPC] %s (%s)" % [_exception.message, _exception.code])
		return _exception.code
	if result.payload.length() < 3:
		push_error("[JSON] invalid result: %s" % result.payload)
		return -2
	var data = JSON.parse(result.payload)
	if OK != data.error:
		push_error("[JSON] %s (%s)" % [data.error_string, data.error])
		return -3
	# Update global state
	for coin in data.result["coins"]:
		match coin.key:
			"DUST":
				Global.dust_storage = coin["stored"]
				Global.dust_inventory = coin["inventory"]
	for booster in data.result["boosters"]:
		match booster.type:
			"SPEED":
				Global.speed_storage = booster["stored"]
				Global.speed_inventory = booster["inventory"]
			"ATTACK":
				Global.firerate_storage = booster["stored"]
				Global.firerate_inventory = booster["inventory"]

func start_combat():
	# FixMe Initilize PRNG Values for Server Simulation
	pass

func _no_set(_value) -> void:
	push_error("[Game.Sector] no set")
