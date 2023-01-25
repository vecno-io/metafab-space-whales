extends Node2D

signal updated_difficulty

onready var stepper = get_node("%Stepper")

onready var death_btn = get_node("%DeathBtn")
onready var death_info = get_node("%DeathInfo")
onready var death_timer = get_node("%DeathTimer")


func _ready():
	death_info.hide()
	Global.local_sector = self
	emit_signal("updated_difficulty", 0)


func _exit_tree():
	Global.local_sector = null


func _unhandled_input(event: InputEvent):
	if event is InputEventKey:
		if event.pressed and event.scancode == KEY_TAB:
			if !death_btn.disabled:
				_on_next_pressed()


func _on_next_pressed():
	if stepper == null:
		return
	death_timer.start()
	death_btn.hide()
	death_info.hide()
	death_btn.disabled = true
	stepper.resume_step()
	Global.unpause_game()


func player_death():
	if death_timer.get_time_left() > 0:
		return false
	stepper.pause_step()
	Global.pause_game()
	death_info.show()
	death_btn.show()
	death_btn.disabled = false
	return true
