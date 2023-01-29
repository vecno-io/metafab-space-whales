class_name GameActor
extends Reference


signal info_updated

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


# id returns the current actors id or an empty string
func id() -> String:
	if _actor == null: return ""
	return _actor.id


# info returns the current actors info or an empty object
func info() -> ActorInfo:
	if _actor != null: return _actor
	return ActorInfo.new("", false)


# color returns the current actors color or the default
func color() -> Color:
	var hex = _actor.attribs.color
	if hex.length() == 0: return Color.white
	else: return Color(hex)


# set_info will set the current actor and emit a signal to update info
func set_info(info: ActorInfo):
	_actor = info
	emit_signal("info_updated")


# has id is a fast check to see if the id has been set (must be length 30)
func has_id() -> bool:
	if _actor == null:
		return false
	if _actor.id.length() < 30:
		return false
	return true


# is valid will do a fast state check to see if the actor info is all setup
func is_valid() -> bool:
	if !has_id():
		return false
	# If name is set all is?!
	if _actor.name.length() <= 0: 
		return false
	return true


func set_config(config: MetaConfig):
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
	# print_debug("actor_minted >> %s" % data.result)
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
	var id_val = info.id_values()
	info.attribs.origin = id_val.kind
	# print_debug("actor_created >> %s" % data.result)
	emit_signal("actor_created", data.result)
	emit_signal("info_updated")
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
	# print_debug("actor_reserved >> %s" % data.result)
	emit_signal("actor_reserved", data.result)
	return OK


func _no_set(_value) -> void:
	push_error("[Game.Actor] no set")
