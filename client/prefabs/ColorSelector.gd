extends GridContainer

signal color_selected(color)

var active = null

onready var color_a = get_node("%Color01")
onready var color_b = get_node("%Color02")
onready var color_c = get_node("%Color03")
onready var color_d = get_node("%Color04")
onready var color_e = get_node("%Color05")
onready var color_f = get_node("%Color06")
onready var color_g = get_node("%Color07")
onready var color_h = get_node("%Color08")
onready var color_i = get_node("%Color09")
onready var color_j = get_node("%Color10")
onready var color_k = get_node("%Color11")
onready var color_l = get_node("%Color12")
onready var color_n = get_node("%Color13")
onready var color_o = get_node("%Color14")
onready var color_p = get_node("%Color15")
onready var color_q = get_node("%Color16")

func _ready():
	color_a.connect("pressed", self, "_on_color_pressed", [color_a])
	color_b.connect("pressed", self, "_on_color_pressed", [color_b])
	color_c.connect("pressed", self, "_on_color_pressed", [color_c])
	color_d.connect("pressed", self, "_on_color_pressed", [color_d])
	color_e.connect("pressed", self, "_on_color_pressed", [color_e])
	color_f.connect("pressed", self, "_on_color_pressed", [color_f])
	color_g.connect("pressed", self, "_on_color_pressed", [color_g])
	color_h.connect("pressed", self, "_on_color_pressed", [color_h])
	color_i.connect("pressed", self, "_on_color_pressed", [color_i])
	color_j.connect("pressed", self, "_on_color_pressed", [color_j])
	color_k.connect("pressed", self, "_on_color_pressed", [color_k])
	color_l.connect("pressed", self, "_on_color_pressed", [color_l])
	color_n.connect("pressed", self, "_on_color_pressed", [color_n])
	color_o.connect("pressed", self, "_on_color_pressed", [color_o])
	color_p.connect("pressed", self, "_on_color_pressed", [color_p])
	color_q.connect("pressed", self, "_on_color_pressed", [color_q])


func _on_color_pressed(btn):
	if active != null: 
		active.pressed = false
	active = btn
	btn.pressed = true
	emit_signal("color_selected", btn.modulate)


func color() -> Color:
	if active == null: return Color("#c2c2d1")
	return active.modulate

func selected() -> bool:
	return active != null