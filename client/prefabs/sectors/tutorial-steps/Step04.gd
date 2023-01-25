extends TutorialStep

"""
Step 4-E. Jump Drive
	-> Explain the Jump Drive Mechanics
	-> Jump to random tutorial sector
	-> Kill a few target, then swarm
	-> pause and a force jump out
"""

var is_active = false

onready var ready_btn = get_node("%Ready-04")

onready var monkey_a = get_node("%Hunter-01")
onready var monkey_b = get_node("%Hunter-02")
onready var monkey_c = get_node("%Hunter-03")
onready var monkey_d = get_node("%Hunter-04")
onready var monkey_e = get_node("%Hunter-05")
onready var monkey_f = get_node("%Hauler-01")
onready var monkey_g = get_node("%Hauler-02")
onready var monkey_h = get_node("%Hauler-03")


func _ready():
	ready_btn.hide()
	monkey_a.disabled = true
	monkey_b.disabled = true
	monkey_c.disabled = true
	monkey_d.disabled = true
	monkey_e.disabled = true
	monkey_f.disabled = true
	monkey_g.disabled = true
	monkey_h.disabled = true
	ready_btn.connect("pressed", self, "_on_ready_pressed")


func _unhandled_input(event: InputEvent):
	if paused: 
		return
	if event is InputEventKey:
		if event.pressed and event.scancode == KEY_TAB:
			if !ready_btn.disabled:
				_on_ready_pressed()


func _on_ready_pressed():
	if paused:
		return
	Global.can_jump = true
	ready_btn.disabled = true
	monkey_a.disabled = false
	monkey_b.disabled = false
	monkey_c.disabled = false
	monkey_d.disabled = false
	monkey_e.disabled = false
	monkey_f.disabled = false
	monkey_g.disabled = false
	monkey_h.disabled = false


func _on_player_jumped():
	if paused || stepper == null:
		return
	stepper.next()
	Global.disconnect("player_jumped", self, "_on_player_jumped")


func start_step(_stepper: TutorStepper):
	.start_step(_stepper)
	Global.can_jump = false
	ready_btn.show()
	ready_btn.disabled = false
	#warning-ignore: return_value_discarded
	Global.connect("player_jumped", self, "_on_player_jumped")
