class_name ActorInfo
extends Reference


signal actor_loaded(id)


var id: String
var name: String

var stats: Stats
var skills: Skills
var attribs: Attribs

var owned = false


func _init(_id, _owned) -> void:
	id = _id
	name = ""
	owned = _owned
	stats = Stats.new()
	skills = Skills.new()
	attribs = Attribs.new()
	attribs.color = Color.white.to_html()


func origin():
	return id.split("::")[0]


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


func load_actor_data():
	# Get the game configuration
	# FixMe Access Private variable
	var cfg = GameServer._meta._cfg
	var id_num = _id_as_number()
	if id_num.length() == 0:
		return _push_error(GameServer._exception.code, 
			"load_actor_data: called with invalid id: %s" % id
		)
	if OK != GameServer._exception.metafab_parse(MetaFab.get_collection_item(self,
		"_on_collection_item_result", cfg.collection_actors, _id_as_number()
	)):
		_push_error(GameServer._exception.code, 
			"metaFab.get_collection_item: %s"
			% GameServer._exception.message
		)


func _on_collection_item_result(code: int, result: String):
	var json = JSON.parse(result)
	if code != 200: return
	name = json.result["name"]
	var data = json.result.data
	for obj in data["stats"]:
		match obj["stat_type"]:
			"Agility": stats.agility = obj["value"]
			"Strength": stats.strength = obj["value"]
			"Vitality": stats.vitality = obj["value"]
	for obj in data["skills"]:
		match obj["skill_type"]:
			"Combat": skills.combat = obj["value"]
			"Industry": skills.industry = obj["value"]
			"Exploration": skills.exploration = obj["value"]
	for obj in json.result["attributes"]:
		match obj["trait_type"]:
			"Base": attribs.back = obj["value"]
			"Face": attribs.face = obj["value"]
			"Shape": attribs.shape = obj["value"]
			"Props": attribs.props = obj["value"]
			"Color": attribs.color = obj["value"]
			"Origin": attribs.origin = obj["value"]
	emit_signal("actor_loaded", id)


func id_values() -> Id:
	var res = Id.new()
	var key_list = id.split("::")
	if key_list.size() != 2:
		push_error("id_values: invalid id (key)")
		return res
	var sec_list = key_list[0].split(":")
	if sec_list.size() != 6:
		push_error("id_values: invalid id (sector)")
		return res
	res.ver = sec_list[0]
	res.kind = sec_list[1]
	res.org_x = sec_list[2]
	res.org_y = sec_list[3]
	res.pos_x = sec_list[4]
	res.pos_y = sec_list[5]
	res.actor = key_list[1]
	return res


func _id_as_number() -> String:
	var key_list = id.split("::")
	if key_list.size() != 2:
		push_error("id_values: invalid id (key)")
		return ""
	var sec_list = key_list[0].split(":")
	if sec_list.size() != 6:
		push_error("id_values: invalid id (sector)")
		return ""
	return "%d%s%s%s%s%s%s" % [
		sec_list[0].to_int(), # ver
		sec_list[1],          # kind
		sec_list[2],          # org_x
		sec_list[3],          # org_y
		sec_list[4],          # pos_x
		sec_list[5],          # pos_y
		key_list[1],          # actor
	]


func _push_error(code: int, message: String) -> void:
	if code != OK: push_error("[ActorInfo] Code: %s - %s" % [message, code])
		


class Id:
	var ver: String
	var kind: String
	var org_x: String
	var org_y: String
	var pos_x: String
	var pos_y: String
	var index: String


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
