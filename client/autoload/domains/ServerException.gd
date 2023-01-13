class_name ServerException
extends Reference

var code: int
var message: String


func _init() -> void:
	clear()


func clear() -> void:
	message = ""
	code = OK


func parse_nakama(result: NakamaAsyncResult) -> int:
	if result.is_exception():
		var exception = result.get_exception()
		message = exception.message
		code = exception.status_code
		_push_exception()
		return code
	return OK


func _push_exception() -> void:
	push_error("[Server.Exception] Code: %s | Message: %s" % [code, message])
