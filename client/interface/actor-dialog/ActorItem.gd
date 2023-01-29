extends Control

# TODO: Gracefull load up, remove poping

signal actor_loaded(actor)
signal actor_selected(actor)
signal actor_activated(actor)

var _info: ActorInfo
var is_selected = false

export(Texture) var color_active
export(Texture) var color_inactive

onready var actor_name = get_node("%ActorName")
onready var actor_color = get_node("%ActorColor")
onready var actor_origin = get_node("%ActorLocation")


func _ready():
	#warning-ignore: return_value_discarded
	_info.connect("actor_loaded", self, "_on_actor_loaded")
	actor_origin.text = _info.origin()
	actor_name.text = "< LOADING >"
	visible = false
	_info.load_actor_data()


func _exit_tree():
	_info.disconnect("actor_loaded", self, "_on_actor_loaded")


func set_active(val: bool):
	is_selected = val
	if val: actor_color.texture = color_active
	else: actor_color.texture = color_inactive


func set_values(actor: ActorInfo):
	_info = actor


func _on_actor_loaded(_id):
	visible = true
	if _info.name.length() > 0:
		actor_name.text = _info.name
	else:
		actor_name.text = "<NEW WHALE SLOT>"
	actor_color.modulate = Color(_info.attribs.color)
	emit_signal("actor_loaded", _info)


func _on_gui_input(event):
	if event is InputEventMouseButton && event.is_pressed():
		if event.button_index == BUTTON_LEFT && event.is_pressed():
			if event.doubleclick: emit_signal("actor_activated", _info)
			else: emit_signal("actor_selected", _info)
		

func _on_mouse_exited():
	if !is_selected:
		actor_color.texture = color_inactive


func _on_mouse_entered():
	actor_color.texture = color_active
