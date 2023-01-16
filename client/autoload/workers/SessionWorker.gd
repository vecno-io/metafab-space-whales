class_name SessionWorker
extends Reference


const ID_FILE = "user://%s.dat"
const META_FILE = "user://%s.mfd"
const USER_FILE = "user://user.ini"


static func clear() -> void:
	var file := ConfigFile.new()
	if OK == file.load(USER_FILE):
		var dir = Directory.new()
		var id = file.get_value("user", "id", "")
		_push_user_warning(dir.remove(USER_FILE), "delete user file failed")
		_push_user_warning(dir.remove(ID_FILE % id), "delete session file failed")
		_push_user_warning(dir.remove(META_FILE % id), "delete metafab file failed")


static func user_info() -> UserInfo:
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


static func player_info(user_id: String, password: String) -> PlayerInfo:
	var file := ConfigFile.new()
	var __ = file.load_encrypted_pass(
		META_FILE % user_id, password
	)
	return PlayerInfo.new(
		file.get_value("player", "id", ""),
		file.get_value("player", "token", ""),
		file.get_value("player", "wallet", "")
	)


static func save_player_info(user_id: String, password: String, player: PlayerInfo) -> void:
	var file := ConfigFile.new()
	var __ = file.load_encrypted_pass(
		META_FILE % user_id, password
	)
	file.set_value("player", "id", player.id)
	file.set_value("player", "token", player.token)
	file.set_value("player", "wallet", player.wallet)
	_push_meta_warning(file.save_encrypted_pass(META_FILE % user_id, password), "save file failed")


static func get_session_token(user_id: String, password: String) -> String:
	var file := ConfigFile.new()
	var __ = file.load_encrypted_pass(
		ID_FILE % user_id, password
	)
	return file.get_value("session", "token", "")


static func save_session_token(user_id: String, password: String, token: String) -> void:
	var file := ConfigFile.new()
	var __ = file.load_encrypted_pass(
		ID_FILE % user_id, password
	)
	file.set_value("session", "token", token)
	_push_id_warning(file.save_encrypted_pass(ID_FILE % user_id, password), "save file failed")


static func _push_id_warning(code: int, message: String) -> void:
	if code != OK: push_warning("[Session.Id] %s (%s)" % [message, code])


static func _push_meta_warning(code: int, message: String) -> void:
	if code != OK: push_warning("[Session.Meta] %s (%s)" % [message, code])


static func _push_user_warning(code: int, message: String) -> void:
	if code != OK: push_warning("[Session.User] %s (%s)" % [message, code])
