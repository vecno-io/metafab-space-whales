extends TutorialStep

"""
Step 1-B. Dust Pickup
	-> Show Dust (Visual)
	-> Guided pickup (WASD)
	-> Explain Dust Meter (Visual)
"""

var picked_up = 0

onready var next_btn = get_node("%Next-01")
onready var info_exit = get_node("%InfoExit-01")
onready var info_enter = get_node("%InfoEnter-01")

onready var dust_a = get_node("%Dust-01")
onready var dust_b = get_node("%Dust-02")
onready var dust_c = get_node("%Dust-03")
onready var dust_d = get_node("%Dust-04")
onready var dust_e = get_node("%Dust-05")
onready var dust_f = get_node("%Dust-06")


func _ready():
	next_btn.hide()
	info_exit.hide()
	info_enter.hide()
	dust_a.connect("picked_up", self, "_on_picked_up")
	dust_b.connect("picked_up", self, "_on_picked_up")
	dust_c.connect("picked_up", self, "_on_picked_up")
	dust_d.connect("picked_up", self, "_on_picked_up")
	dust_e.connect("picked_up", self, "_on_picked_up")
	dust_f.connect("picked_up", self, "_on_picked_up")
	next_btn.connect("pressed", self, "_on_next_pressed")


func _unhandled_input(event: InputEvent):
	if paused: 
		return
	if event is InputEventKey:
		if event.pressed and event.scancode == KEY_TAB:
			if !next_btn.disabled:
				_on_next_pressed()


func _on_next_pressed():
	if paused || stepper == null:
		return
	stepper.next()


func _on_picked_up():
	picked_up += 1
	if picked_up >= 3:
		next_btn.show()
		info_exit.show()
		info_enter.hide()
		next_btn.disabled = false


func start_step(_stepper: TutorStepper):
	.start_step(_stepper)
	Global.can_jump = false
	next_btn.hide()
	info_exit.hide()
	info_enter.show()
