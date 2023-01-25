class_name TutorialStep
extends Node2D

var paused: bool = false
var stepper: TutorStepper = null

onready var overlay = get_node("%Overlay")


func start_step(_stepper: TutorStepper):
	stepper = _stepper


func pause_step():
	overlay.hide()
	paused = true


func resume_step():
	overlay.show()
	paused = false
