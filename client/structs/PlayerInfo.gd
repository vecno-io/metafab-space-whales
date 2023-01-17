class_name PlayerInfo
extends Reference


const KEY_ID = "id"
const KEY_TOKEN = "accessToken"
const KEY_WALLET = "walletId"


var id: String
var token: String
var wallet: String


func _init(_id = "",_token = "",_wallet = "") -> void:
	id = _id
	token = _token
	wallet = _wallet


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
