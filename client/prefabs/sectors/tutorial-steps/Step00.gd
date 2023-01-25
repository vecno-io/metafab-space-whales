extends TutorialStep

"""
Step 0-A. Ready? or Skip?
	-> Skip to step 5
"""

onready var info_exit = get_node("%InfoExit-00")

onready var skip_button = get_node("%SkipButton-00")
onready var start_button = get_node("%StartButton-00")


func _ready():
	info_exit.hide()
	skip_button.hide()
	start_button.hide()
	skip_button.connect("pressed", self, "_on_skip_pressed")
	start_button.connect("pressed", self, "_on_start_pressed")


func _unhandled_input(event: InputEvent):
	if paused:
		return
	if event is InputEventKey:
		if event.pressed and event.scancode == KEY_TAB:
			if !start_button.disabled:
				_on_start_pressed()


func _on_skip_pressed():
	if paused || stepper == null:
		return
	Global.can_jump = true
	Global.dust_storage = 4200
	Global.speed_storage = 3
	Global.firerate_storage = 3
	Global.local_player.jump_out()


func _on_start_pressed():
	if paused || stepper == null:
		return
	stepper.next()
	Global.dust_storage = 2100
	Global.speed_storage = 1
	Global.firerate_storage = 1
	Global.disconnect("player_jumped", self, "_on_player_jumped")


func _on_player_jumped():
	if paused || stepper == null:
		return
	stepper.skip_to(TutorStepper.Step.f)
	Global.disconnect("player_jumped", self, "_on_player_jumped")


func start_step(_stepper: TutorStepper):
	.start_step(_stepper)
	Global.can_jump = false
	info_exit.show()
	skip_button.show()
	start_button.show()
	skip_button.disabled = false
	start_button.disabled = false
	#warning-ignore: return_value_discarded
	Global.connect("player_jumped", self, "_on_player_jumped")
