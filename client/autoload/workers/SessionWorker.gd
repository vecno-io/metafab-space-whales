class_name SessionWorker
extends Reference


const USER_FILE = "user://user.ini"
const PRIVATE_FILE = "user://%s.dat"


static func clear() -> void:
	var file := ConfigFile.new()
	if OK == file.load(USER_FILE):
		var dir = Directory.new()
		var id = file.get_value("user", "id", "")
		_push_user_warning(dir.remove(USER_FILE), "clear user failed")
		_push_user_warning(dir.remove(PRIVATE_FILE % id), "clear session failed")


static func get_user_info() -> UserInfo:
	var file := ConfigFile.new()
	if OK != file.load(USER_FILE):
		return UserInfo.new()
	return UserInfo.new(
		file.get_value("user", "id", ""),
		file.get_value("user", "name", ""),
		file.get_value("user", "email", "")
	)


static func save_user_info(data: UserInfo) -> void:
	var file := ConfigFile.new()
	var __ = file.load(USER_FILE)
	file.set_value("user", "id", data.id)
	file.set_value("user", "name", data.name)
	file.set_value("user", "email", data.email)
	_push_user_warning(file.save(USER_FILE), "save failed: user: %s" % data.id)


static func get_metafab_token(user_id: String, password: String) -> String:
	return ""


static func save_metafab_token(user_id: String, password: String, id: String, token: String) -> void:
	pass


static func get_session_token(user_id: String, password: String) -> String:
	return ""


static func save_session_token(user_id: String, password: String, token: String) -> void:
	pass


static func _push_user_warning(code: int, message: String) -> void:
	if code != OK: push_warning("[Session.User] %s (%s)" % [message, code])


static func _push_private_warning(code: int, message: String) -> void:
	if code != OK: push_warning("[Session.Private] %s (%s)" % [message, code])