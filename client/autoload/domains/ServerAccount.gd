class_name ServerAccount
extends Reference


signal signed_in
signal signed_out

signal session_closed
signal session_created


var _hash = "" setget _no_set

var _email: String = "" setget _no_set
var _hashed: String = "" setget _no_set
var _password: String = "" setget _no_set

var _client: NakamaClient setget _no_set
var _session: NakamaSession setget _no_set
var _exception: ServerException setget _no_set


func _init(client: NakamaClient, exception: ServerException) -> void:
	_hash = ConfigWorker.get_client_hash()
	_client = client
	_session = null
	_exception = exception


func authenticate_device() -> int:
	if _session != null: _close_session()
	print("[Server.Account] Auth Hash: %s" % _hash)
	var session = yield(_client.authenticate_device_async(_hash), "completed")
	if OK != _exception.parse_nakama(session):
		_push_error(1, "Failed to authenticated")
		return 1
	else:
		_session = session
		emit_signal("session_created")
		print("[Server.Account] Authenticated: %s" % session)
		return OK


func _no_set(_value) -> void:
	push_error("[Server.Account] no set")


func _close_session():
	if _session == null: return yield()
	var session = _session
	_session = null
	var result = yield(_client.session_logout_async(session), "completed")
	if OK != _exception.parse_nakama(result): _push_error(
		4, "session logout failed: %s" % session
	)
	emit_signal("session_closed")

func _push_error(code: int, message: String) -> void:
		if code != OK: push_error("[Server.Account] Code: %s - %s" % [message, code])
