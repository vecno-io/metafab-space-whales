class_name ActorInfo
extends Reference


var id: int

var name: String
var info: String

var stats: Stats
var skills: Skills
var attribs: Attribs

func _init(_id = -1) -> void:
	id = _id
	# TODO NExt Load Actor data


class Stats:
	var agility: int
	var strength: int
	var vitality: int


	func _init(_agility = 0, _strength = 0, _vitality = 0) -> void:
		agility = _agility
		strength = _strength
		vitality = _vitality


class Skills:
	var combat: int
	var defence: int
	var industry: int
	var exploration: int


	func _init(_combat = 0, _defence = 0, _industry = 0, _exploration = 0) -> void:
		combat = _combat
		defence = _defence
		industry = _industry
		exploration = _exploration


class Attribs:
	var back: String
	var color: String
	var origin: String


	func _init(_back = "base", _color = "white", _origin = "00.00:000.000") -> void:
		back = _back
		color = _color
		origin = _origin
