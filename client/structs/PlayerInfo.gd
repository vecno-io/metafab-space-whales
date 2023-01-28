class_name PlayerInfo
extends Reference


const KEY_ID = "id"
const KEY_TOKEN = "accessToken"
const KEY_WALLET = "walletId"


var id: String
var token: String
var wallet: String

var actors_map: Dictionary
var actors_mints: int
var actors_minted: int

var minted_list: Array
var reserved_list: Array

func _init(_id = "", _token = "", _wallet = "", _mints = 0, _minted = 0) -> void:
	id = _id
	token = _token
	wallet = _wallet
	actors_map = {}
	actors_mints = _mints
	actors_minted = _minted
	minted_list = []
	reserved_list = []


func is_valid() -> bool:
	if 0 >= id.length():
		return false
	if 5 != id.split("-").size():
		return false
	if 0 >= token.length():
		return false
	if !token.split("player_at_"):
		return false
	if 0 >= wallet.length():
		return false
	if 5 != wallet.split("-").size():
		return false
	return true


func has_actor_slots() -> bool:
	return actors_mints > actors_minted


func from_result(data: Dictionary) -> int:
	if data == null: return -1
	if !data.has_all([
		KEY_ID,
		KEY_TOKEN,
		KEY_WALLET
	]): return -2
	id = data[KEY_ID]
	token = data[KEY_TOKEN]
	wallet = data[KEY_WALLET]
	if !is_valid(): 
		return -3
	return OK


func parse_player_data(data: Dictionary) -> int:
	if data == null: return -1
	if !data.has_all([
		"updatedAt",
		"protectedData",
	]): return -2
	var protected = data["protectedData"]
	if typeof(protected) != TYPE_DICTIONARY:
		return -3
	if !protected.has_all([
		"actorMints",
		"actorMinted",
	]): return -4
	actors_mints = protected["actorMints"]
	actors_minted = protected["actorMinted"]
	return OK


# Parses the dictionary returned by a call to metafab
# that gets the balance of the players actors collection
# Note: This call is broken, the returned size is to big
# func parse_minted_actors(data: Dictionary) -> int:
# 	minted_list = []
# 	print_debug(">> Data %s" % data)
# 	for key in data.keys():
# 		if typeof(key) == TYPE_STRING:
# 			continue
# 		# FixMe: 256 bit ints, replace with regex
# 		# if !key.is_valid_integer():
# 		# 	continue
# 		var value = data[key]
# 		if typeof(value) == TYPE_STRING:
# 			continue
# 		if !value.is_valid_integer():
# 			continue
# 		if value == "1":
# 			minted_list.append(key)
# 	print_debug(">> List %s" % minted_list.size())
# 	return OK

# TODO Implement call below
func parse_reserved_actors(data: Dictionary) -> int:
	reserved_list = []
	print_debug(">> Data %s" % data)
	for key in data.keys():
		var value = data[key]
		if typeof(value) == TYPE_STRING:
			continue
		if !value.is_valid_integer():
			continue
		if value == "1":
			reserved_list.append(key)
	return OK
