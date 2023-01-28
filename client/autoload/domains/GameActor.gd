class_name GameActor
extends Reference

signal actor_minted(tx)
signal actor_created(tx)
signal actor_reserved(id)


var _cfg: MetaConfig = null setget _no_set
var _actor: ActorInfo = null setget _no_set

var _client: NakamaClient setget _no_set
var _account: ServerAccount setget _no_set
var _exception: ServerException setget _no_set


func _init(client: NakamaClient, account: ServerAccount, exception: ServerException) -> void:
	_client = client
	_account = account
	_exception = exception


func set_config(config: MetaConfig):
	print("[Game.Actor] Game ID: %s" % config.game_id)
	_cfg = config


func mint_async() -> int:
	var session = yield(_account.get_session_async(), "completed")
	if session == null:
		return -1
	var result = yield(_client.rpc_async(
			session, "actor_mint", JSON.print({
				"id": _actor.id,
			})
	), "completed")
	if OK != _exception.parse_nakama(result):
		push_error("[RPC] %s (%s)" % [_exception.message, _exception.code])
		return _exception.code
	if result.payload.length() < 3:
		return -2
	var data = JSON.parse(result.payload)
	if OK != data.error:
		push_error("[JSON] %s (%s)" % [data.error_string, data.error])
		return -3
	print_debug("actor_minted >> %s" % data.result)
	emit_signal("actor_minted", data.result)
	return OK


func create_async(info: ActorInfo) -> int:
	var session = yield(_account.get_session_async(), "completed")
	if session == null:
		return -1
	var result = yield(_client.rpc_async(
			session, "actor_create", JSON.print({
				"id": info.id,
				"name": info.name,
				"stats": {
					"agility": info.stats.agility,
					"strength": info.stats.strength,
					"vitality": info.stats.vitality,
				},
				"skills": {
					"combat": info.skills.combat,
					"industry": info.skills.industry,
					"exploration": info.skills.exploration,
				},
				"attribs": {
					"back": info.attribs.back,
					"face": info.attribs.face,
					"shape": info.attribs.shape,
					"props": info.attribs.props,
					"color": info.attribs.color,
				},
			})
	), "completed")
	if OK != _exception.parse_nakama(result):
		push_error("[RPC] %s (%s)" % [_exception.message, _exception.code])
		return _exception.code
	if result.payload.length() < 3:
		return -2
	var data = JSON.parse(result.payload)
	if OK != data.error:
		push_error("[JSON] %s (%s)" % [data.error_string, data.error])
		return -3
	_actor = info
	# TODO Extract the actors origin from the actor_id
	print_debug("actor_created >> %s" % data.result)
	emit_signal("actor_created", data.result)
	return OK


func reserve_async() -> int:
	var session = yield(_account.get_session_async(), "completed")
	if session == null:
		return -1
	var result = yield(_client.rpc_async(
			session, "actor_reserve", JSON.print({})
	), "completed")
	if OK != _exception.parse_nakama(result):
		push_error("[RPC] %s (%s)" % [_exception.message, _exception.code])
		return _exception.code
	if result.payload.length() < 3:
		return -2
	var data = JSON.parse(result.payload)
	if OK != data.error:
		push_error("[JSON] %s (%s)" % [data.error_string, data.error])
		return -3
	print_debug("actor_reserved >> %s" % data.result)
	emit_signal("actor_reserved", data.result)
	return OK


func _no_set(_value) -> void:
	push_error("[Game.Actor] no set")
