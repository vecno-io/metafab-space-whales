extends TutorialStep

"""
Step 3-D. Boosters
	-> Try out booster
	-> Fire Rate (drop extra dust, booster, enemies)
	-> Speed (speed booster, enemies, flee)
"""

var picked: int = 0

onready var next_btn = get_node("%Next-03")

onready var speed_a = get_node("%Speed-01")
onready var speed_b = get_node("%Speed-02")
onready var speed_c = get_node("%Speed-03")
onready var speed_d = get_node("%Speed-04")
onready var speed_e = get_node("%Speed-05")

onready var reload_a = get_node("%Reload-01")
onready var reload_b = get_node("%Reload-02")
onready var reload_c = get_node("%Reload-03")
onready var reload_d = get_node("%Reload-04")
onready var reload_e = get_node("%Reload-05")


func _ready():
	picked = 0;
	next_btn.hide()
	speed_a.hide()
	speed_b.hide()
	speed_c.hide()
	speed_d.hide()
	speed_e.hide()
	reload_a.hide()
	reload_b.hide()
	reload_c.hide()
	reload_d.hide()
	reload_e.hide()
	speed_a.connect("picked_up", self, "_on_picked_up")
	speed_b.connect("picked_up", self, "_on_picked_up")
	speed_c.connect("picked_up", self, "_on_picked_up")
	speed_d.connect("picked_up", self, "_on_picked_up")
	speed_e.connect("picked_up", self, "_on_picked_up")
	reload_a.connect("picked_up", self, "_on_picked_up")
	reload_b.connect("picked_up", self, "_on_picked_up")
	reload_c.connect("picked_up", self, "_on_picked_up")
	reload_d.connect("picked_up", self, "_on_picked_up")
	reload_e.connect("picked_up", self, "_on_picked_up")
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
	picked += 1
	if picked >= 3:
		next_btn.disabled = false


func start_step(_stepper: TutorStepper):
	.start_step(_stepper)
	Global.can_jump = false
	next_btn.show()
	next_btn.disabled = true
	speed_a.show()
	speed_b.show()
	speed_c.show()
	speed_d.show()
	speed_e.show()
	reload_a.show()
	reload_b.show()
	reload_c.show()
	reload_d.show()
	reload_e.show()
