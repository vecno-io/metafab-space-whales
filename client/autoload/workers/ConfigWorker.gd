class_name ConfigWorker
extends Reference


const SERVER_REGION_EU = "eu"
const SERVER_REGION_USA = "usa"
const SERVER_REGION_ASIA = "asia"
const SERVER_REGION_DEFAULT = "main"


const APP_FILE = "user://app.ini"
const USER_FILE = "user://user.ini"


static func get_client_hash() -> String:
	var file := ConfigFile.new()
	var stamp = Time.get_ticks_msec()
	if OK == file.load(APP_FILE):
		if file.has_section_key("client", "hash"):
			return file.get_value("client", "hash")
	var out = _create_client_hash(stamp)
	file.set_value("client", "hash", out)
	_push_app_error(file.save(APP_FILE), "save failed: hash: %s" % out)
	return out


static func get_server_localhost() -> bool:
	var file := ConfigFile.new()
	if OK == file.load(APP_FILE) && file.has_section_key("server", "localhost"):
		return "true" == file.get_value("server", "localhost")
	if OS.has_feature("mainnet") || OS.has_feature("testnet"):
		return false
	return true


static func get_server_network() -> String:
	if OS.has_feature("mainnet"): return ""
	return ".testnet"


static func get_server_region() -> String:
	var file := ConfigFile.new()
	if OK == file.load(APP_FILE) && file.has_section_key("server", "region"):
		return file.get_value("server", "region")
	file.set_value("server", "region", SERVER_REGION_DEFAULT)
	_push_app_warning(file.save(APP_FILE), "save failed: region")
	return SERVER_REGION_DEFAULT


static func save_server_region(key: String) -> void:
	var file := ConfigFile.new()
	var __ = file.load(APP_FILE)
	file.set_value("server", "region", key)
	_push_app_warning(file.save(APP_FILE), "save failed: region: %s" % key)


static func _create_client_hash(timestamp: int) -> String:
	var rand = RandomNumberGenerator.new()
	rand.seed = Time.get_ticks_msec()
	var value = "%d" % timestamp
	for i in rand.randi_range(24, 64):
		value = value.sha256_text()
		value = "%s/%s" % [value, rand.randi()]
	rand.seed = Time.get_ticks_msec()
	value = "%s/%s" % [value, rand.seed]
	value = "%s/%s" % [value, rand.randi()]
	return value.sha256_text()


static func _push_app_error(code: int, message: String) -> void:
	if code != OK: push_error("[Config.App] %s (%s)" % [message, code])


static func _push_app_warning(code: int, message: String) -> void:
	if code != OK: push_warning("[Config.App] %s (%s)" % [message, code])
