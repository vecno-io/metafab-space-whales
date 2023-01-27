class_name ActorInfo
extends Reference


var id: String
var name: String

var stats: Stats
var skills: Skills
var attribs: Attribs

func _init(_id) -> void:
	id = _id
	stats = Stats.new()
	skills = Skills.new()
	attribs = Attribs.new()

func attribs_set_color(color: Color):
	attribs.color = color.to_html()

func attribs_randomize():
	var rand = RandomNumberGenerator.new()
	rand.seed = Time.get_ticks_msec()
	# Note: Origin and Color are predefined
	attribs.back = "%03d" % rand.randi_range(0, 255)
	attribs.face = "%03d" % rand.randi_range(0, 255)
	attribs.shape = "%03d" % rand.randi_range(0, 255)
	attribs.props = "%03d" % rand.randi_range(0, 255)
	attribs.origin = "%03d" % rand.randi_range(0, 255)


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
	var industry: int
	var exploration: int


	func _init(_combat = 0, _industry = 0, _exploration = 0) -> void:
		combat = _combat
		industry = _industry
		exploration = _exploration


class Attribs:
	var back: String
	var face: String
	var shape: String
	var props: String
	var color: String
	var origin: String


	func _init(_back = "base", _color = "white", _origin = "00.00:000.000") -> void:
		back = _back
		color = _color
		origin = _origin
