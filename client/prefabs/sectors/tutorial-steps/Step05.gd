extends TutorialStep

# TODO Setup Storage Huds
# TODO Storage should not despawn

"""
Step 5-F. Exploration
	-> Home Storage (Take some extra's)
	-> Jump To Random Sector (Intro Mode)
"""

var done = false

onready var info_exit = get_node("%InfoExit-05")
onready var info_enter = get_node("%InfoEnter-05")

#onready var storage_link = get_node("%StorageLink")


func _ready():
	info_exit.hide()
	info_enter.hide()
	#storage_link.hide()


func _exit_tree():
	print_debug("_exit_tree: %s" % name)
	


func _on_link_closed():
	if paused:
		return
	done = true
	info_exit.show()
	info_enter.hide()
	Global.can_jump = true


func _on_player_jumped():
	if paused || stepper == null:
		return
	if !done:
		return
	stepper.next()
	Global.disconnect("player_jumped", self, "_on_player_jumped")
	Global.local_store.disconnect("link_closed", self, "_on_link_closed")


func start_step(_stepper: TutorStepper):
	.start_step(_stepper)
	Global.can_jump = false
	info_exit.hide()
	info_enter.show()
	#storage_link.show()
	#var pos = Global.local_player.global_position
	#warning-ignore: return_value_discarded
	Global.connect("player_jumped", self, "_on_player_jumped")
	#warning-ignore: return_value_discarded
	Global.local_store.connect("link_closed", self, "_on_link_closed")
	# TODO: The Storage link is part of a players origin home node
	#storage_link.global_position = Vector2(pos.x - 225.0, pos.y - 35.0)
