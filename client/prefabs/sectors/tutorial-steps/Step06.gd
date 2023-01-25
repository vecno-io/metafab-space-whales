extends TutorialStep

# Setup the first sector event

"""
Step 6-G. Sector Intro Mode
	-> Monkey Cleanup
	-> Claim Sector
"""

onready var next_btn = get_node("%Next-06")


func _ready():
	print_debug("_ready: %s" % name)
	next_btn.hide()
	next_btn.connect("pressed", self, "_on_next_pressed")


func _on_next_pressed():
	if paused || stepper == null:
		return
	stepper.next()
	
	
func start_step(_stepper: TutorStepper):
	.start_step(_stepper)
	next_btn.show()
	next_btn.disabled = false
