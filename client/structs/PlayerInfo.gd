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

var owned_list: Array
var minted_list: Array
var reserved_list: Array

func _init(_id = "", _token = "", _wallet = "", _mints = 0, _minted = 0) -> void:
	id = _id
	token = _token
	wallet = _wallet
	actors_map = {}
	actors_mints = _mints
	actors_minted = _minted
	owned_list = []
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
	owned_list = []
	minted_list = []
	reserved_list = []
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
func parse_owned_actors(data: Dictionary) -> int:
	owned_list = []
	print("Owned Actors:")
	for key in data.keys():
		if typeof(key) != TYPE_STRING:
			continue
		var value = data[key]
		if typeof(key) != TYPE_STRING:
			continue
		if !value.is_valid_integer():
			continue
		if 0 >= value.to_int():
			continue
		var val = key_to_account_id(key)
		if 0 >= val.length():
			continue
		print(val)
		owned_list.append(val)
		actors_map[val] = ActorInfo.new(val, true)
	return OK


func key_to_account_id(val: String):
	var start = 0
	match val.length():
		30: start = 1
		31: start = 2
		32: start = 3
	if start == 0:
		return ""
	var ver = val.substr(0, start)
	var kind = val.substr(start, 3)
	var org_x = val.substr(start+3, 3)
	var org_y = val.substr(start+6, 3)
	var pos_x = val.substr(start+9, 5)
	var pos_y = val.substr(start+14, 5)
	var actor = val.substr(start+19, 10)
	if !ver.is_valid_integer():
		return ""
	return "%03d:%s:%s:%s:%s:%s::%s"	% [
		ver.to_int(), kind , org_x, org_y, pos_x, pos_y, actor
	]
	