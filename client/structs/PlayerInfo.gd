class_name PlayerInfo
extends Reference


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
