class_name UserInfo
extends Reference


var id: String
var name: String
var email: String

var regex = RegEx.new()


func _init(_id = "",_name = "",_email = "") -> void:
	id = _id
	name = _name
	email = _email
	if OK != regex.compile('.+\\@.+\\.[a-z][a-z]+'):
		push_error("[UserInfo] - email regex failed to compile")


func is_valid() -> bool:
	if 0 >= id.length():
		return false
	if 0 >= name.length():
		return false
	if 0 >= email.length():
		return false
	if null == regex.search(email): 
		return false
	return true