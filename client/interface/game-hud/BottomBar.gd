extends MarginContainer

const DUST_PIP_MAX = 1000

export(Texture) var pip_small_1: Texture
export(Texture) var pip_small_2: Texture
export(Texture) var pip_small_3: Texture
export(Texture) var pip_small_4: Texture

export(Texture) var pip_medium_00: Texture
export(Texture) var pip_medium_01: Texture
export(Texture) var pip_medium_02: Texture
export(Texture) var pip_medium_03: Texture
export(Texture) var pip_medium_04: Texture
export(Texture) var pip_medium_05: Texture
export(Texture) var pip_medium_06: Texture
export(Texture) var pip_medium_07: Texture
export(Texture) var pip_medium_08: Texture
export(Texture) var pip_medium_09: Texture
export(Texture) var pip_medium_10: Texture

onready var btn_jump = get_node("%JumpBtn")
onready var btn_special = get_node("%SpecialBtn")

onready var dust_left_a = get_node("%DustLeft1")
onready var dust_left_b = get_node("%DustLeft2")
onready var dust_left_c = get_node("%DustLeft3")
onready var dust_left_d = get_node("%DustLeft4")
onready var dust_left_e = get_node("%DustLeft5")
onready var dust_left_f = get_node("%DustLeft6")

onready var dust_right_a = get_node("%DustRight1")
onready var dust_right_b = get_node("%DustRight2")
onready var dust_right_c = get_node("%DustRight3")
onready var dust_right_d = get_node("%DustRight4")
onready var dust_right_e = get_node("%DustRight5")
onready var dust_right_f = get_node("%DustRight6")

onready var boost_left_a = get_node("%BoostLeft1")
onready var boost_left_b = get_node("%BoostLeft2")
onready var boost_left_c = get_node("%BoostLeft3")
onready var boost_left_d = get_node("%BoostLeft4")

onready var boost_right_a = get_node("%BoostRight1")
onready var boost_right_b = get_node("%BoostRight2")
onready var boost_right_c = get_node("%BoostRight3")
onready var boost_right_d = get_node("%BoostRight4")


func _ready():
	# TODO Remove this or?
	# Global.overlay = null
	#warning-ignore: return_value_discarded
	Global.connect("dust_inventory_updated", self, "_on_dust_inventory_updated")
	#warning-ignore: return_value_discarded
	Global.connect("speed_inventory_updated", self, "_on_speed_inventory_updated")
	#warning-ignore: return_value_discarded
	Global.connect("firerate_inventory_updated", self, "_on_firerate_inventory_updated")


func _exit_tree():
	# TODO Remove this or?
	# Global.overlay = null
	Global.disconnect("dust_inventory_updated", self, "_on_dust_inventory_updated")
	#warning-ignore: return_value_discarded
	Global.disconnect("dust_inventory_updated", self, "_on_speed_inventory_updated")
	#warning-ignore: return_value_discarded
	Global.disconnect("firerate_inventory_updated", self, "_on_firerate_inventory_updated")


func _on_speed_inventory_updated(value):
	if value >= 1: boost_right_a.texture = pip_small_4
	else: boost_right_a.texture = pip_small_1
	if value >= 2: boost_right_b.texture = pip_small_4
	else: boost_right_b.texture = pip_small_1
	if value >= 3: boost_right_c.texture = pip_small_4
	else: boost_right_c.texture = pip_small_1
	if value >= 4: boost_right_d.texture = pip_small_4
	else: boost_right_d.texture = pip_small_1


func _on_firerate_inventory_updated(value):
	if value >= 1: boost_left_a.texture = pip_small_4
	else: boost_left_a.texture = pip_small_1
	if value >= 2: boost_left_b.texture = pip_small_4
	else: boost_left_b.texture = pip_small_1
	if value >= 3: boost_left_c.texture = pip_small_4
	else: boost_left_c.texture = pip_small_1
	if value >= 4: boost_left_d.texture = pip_small_4
	else: boost_left_d.texture = pip_small_1


func _on_dust_inventory_updated(value):
	var count =  value / DUST_PIP_MAX
	var leftover = value % DUST_PIP_MAX
	_set_dust_buttons(count, leftover)
	_chk_dust_pip_value(1, count, leftover)
	_chk_dust_pip_value(2, count, leftover)
	_chk_dust_pip_value(3, count, leftover)
	_chk_dust_pip_value(4, count, leftover)
	_chk_dust_pip_value(5, count, leftover)
	_chk_dust_pip_value(6, count, leftover)


func _chk_dust_pip_value(idx, count, leftover):
	if count > idx:
		_set_dust_pip_value(idx, DUST_PIP_MAX)
	elif count == idx:
		_set_dust_pip_value(idx, leftover)
	else:
		_set_dust_pip_value(idx, 0)


func _set_dust_buttons(count, leftover):
	# Refine this for initial pick-up
	# Some indication on the background
	if count > 0:
		btn_jump.disabled = false
		btn_special.disabled = false
	elif leftover > 600:
		btn_jump.disabled = false
		btn_special.disabled = false
	elif leftover > 200:
		btn_jump.disabled = false
		btn_special.disabled = true
	else:
		btn_jump.disabled = true
		btn_special.disabled = true

func _set_dust_pip_value(idx, value):
	var pips = _get_dust_pip(idx)
	if pips == null: return
	if value <= 0: 
		pips["left"].texture = pip_medium_00
		pips["right"].texture = pip_medium_00
	elif value < 100:
		pips["left"].texture = pip_medium_01
		pips["right"].texture = pip_medium_01
	elif value < 200:
		pips["left"].texture = pip_medium_02
		pips["right"].texture = pip_medium_02
	elif value < 300:
		pips["left"].texture = pip_medium_03
		pips["right"].texture = pip_medium_03
	elif value < 400:
		pips["left"].texture = pip_medium_04
		pips["right"].texture = pip_medium_04
	elif value < 500:
		pips["left"].texture = pip_medium_05
		pips["right"].texture = pip_medium_05
	elif value < 600:
		pips["left"].texture = pip_medium_06
		pips["right"].texture = pip_medium_06
	elif value < 700:
		pips["left"].texture = pip_medium_07
		pips["right"].texture = pip_medium_07
	elif value < 800:
		pips["left"].texture = pip_medium_08
		pips["right"].texture = pip_medium_08
	elif value < 900:
		pips["left"].texture = pip_medium_09
		pips["right"].texture = pip_medium_09
	else:
		pips["left"].texture = pip_medium_10
		pips["right"].texture = pip_medium_10


func _get_dust_pip(idx):
	match idx:
		0: return null
		1: return {
			"left": dust_left_a,
			"right": dust_right_a,
		}
		2: return {
			"left": dust_left_b,
			"right": dust_right_b,
		}
		3: return {
			"left": dust_left_c,
			"right": dust_right_c,
		}
		4: return {
			"left": dust_left_d,
			"right": dust_right_d,
		}
		5: return {
			"left": dust_left_e,
			"right": dust_right_e,
		}
		6: return {
			"left": dust_left_f,
			"right": dust_right_f,
		}
