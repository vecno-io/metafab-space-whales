extends TutorialStep

"""
Step 2-C. Target Practice
	-> Show Hauler -> Ready
	-> On Kill Next
	-> Show Hunter -> Ready
	-> On Kill Next
	-> Explain Dust Use
"""

onready var hauler = get_node("%Hauler")
onready var hunter = get_node("%Hunter")

onready var next_btn = get_node("%Next-02")
onready var ready_btn_a = get_node("%Ready-02A")
onready var ready_btn_b = get_node("%Ready-02B")

onready var info_exit = get_node("%InfoExit-02")
onready var info_enter_a = get_node("%InfoEnter-02A")
onready var info_enter_b = get_node("%InfoEnter-02B")


func _ready():
	next_btn.hide()
	info_exit.hide()
	info_enter_a.hide()
	info_enter_b.hide()
	hauler.visible = false
	hauler.disabled = true
	hunter.visible = false
	hunter.disabled = true
	hauler.connect("died", self, "_on_hauler_died")
	hunter.connect("died", self, "_on_hunter_died")
	hauler.connect("escaped", self, "_on_hauler_died")
	hunter.connect("escaped", self, "_on_hunter_died")
	next_btn.connect("pressed", self, "_on_next_pressed")
	ready_btn_a.connect("pressed", self, "_on_ready_a_pressed")
	ready_btn_b.connect("pressed", self, "_on_ready_b_pressed")


func _unhandled_input(event: InputEvent):
	if paused: 
		return
	if event is InputEventKey:
		if event.pressed and event.scancode == KEY_TAB:
			if !ready_btn_a.disabled:
				_on_ready_a_pressed()
			elif !ready_btn_b.disabled:
				_on_ready_b_pressed()
			elif !next_btn.disabled:
				_on_next_pressed()


func _on_hauler_died():
	var pos = Global.local_player.global_position
	hunter.global_position = Vector2(pos.x + 275, pos.y)
	hunter.visible = true
	info_exit.hide()
	next_btn.hide()
	next_btn.disabled = true
	info_enter_a.hide()
	ready_btn_a.hide()
	ready_btn_a.disabled = true
	info_enter_b.show()
	ready_btn_b.show()
	ready_btn_b.disabled = false	


func _on_hunter_died():
	info_exit.show()
	next_btn.show()
	next_btn.disabled = false
	info_enter_a.hide()
	ready_btn_a.hide()
	ready_btn_a.disabled = true
	info_enter_b.hide()
	ready_btn_b.hide()
	ready_btn_b.disabled = true	


func _on_next_pressed():
	if paused || stepper == null:
		return
	stepper.next()


func _on_ready_a_pressed():
	if paused: 
		return
	ready_btn_a.disabled = true
	hauler.disabled = false


func _on_ready_b_pressed():
	if paused: 
		return
	ready_btn_b.disabled = true
	hunter.disabled = false


func start_step(_stepper: TutorStepper):
	.start_step(_stepper)
	Global.can_jump = false
	var pos = Global.local_player.global_position
	hauler.global_position = Vector2(pos.x + 225, pos.y)
	hauler.visible = true
	info_exit.hide()
	next_btn.hide()
	next_btn.disabled = true
	info_enter_a.show()
	ready_btn_a.show()
	ready_btn_a.disabled = false
	info_enter_b.hide()
	ready_btn_b.hide()
	ready_btn_b.disabled = true
