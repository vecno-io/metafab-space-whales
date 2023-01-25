class_name TutorStepper
extends Node2D

"""
Step 0-A. Ready? or Skip?
	-> Skip to step 5
Step 1-B. Dust Pickup
	-> Show Dust (Visual)
	-> Guided pickup (WASD)
	-> Explain Dust Meter (Visual)
Step 2-C. Target Practice
	-> Show Target
	-> Explain Target
	-> Kill the target
Step 3-D. Boosters
	-> Try out booster
	-> Fire Rate (drop extra dust, booster, enemies)
	-> Speed (speed booster, enemies, flee)
Step 4-E. Jump Drive
	-> Explain the Jump Drive Mechanics
	-> Jump to random tutorial sector
	-> Kill a few target, then swarm
	-> pause and a force jump out
	-> Jumps from tutorial to home
Step 5-F. Exploration
	-> Home Storage (Take some extra's)
	-> Jump To Random Sector (Intro Mode)
	-> first jump from home to sector
Step 6-G. Sector Intro Mode
	-> Monkey Cleanup
	-> Claim Sector
"""

enum Step {
	x,
	a,
	b,
	c,
	d,
	e,
	f,
	g,
}

var active = null
var current = Step.x

export(PackedScene) var step_a
export(PackedScene) var step_b
export(PackedScene) var step_c
export(PackedScene) var step_d
export(PackedScene) var step_e
export(PackedScene) var step_f
export(PackedScene) var step_g


func _ready():
	current = Step.x
	#warning-ignore: return_value_discarded
	Global.connect("scene_move_ended", self, "_on_scene_move_ended")


func next():
	match current:
		Step.a: _spawn_step(Step.b)
		Step.b: _spawn_step(Step.c)
		Step.c: _spawn_step(Step.d)
		Step.d: _spawn_step(Step.e)
		Step.e: _spawn_step(Step.f)
		Step.f: _spawn_step(Step.g)
		Step.g: _spawn_step(Step.x)


func skip_to(step):
	_spawn_step(step)


func pause_step():
	if active == null: 
		return
	active.pause_step()


func resume_step():
	if active == null: 
		return
	if active.paused: 
		active.resume_step()


func _spawn_step(step):
	if current == step:
		return
	current = step
	if active != null:
		active.queue_free()
	match step:
		Step.x: active = null
		Step.a: active = step_a.instance()
		Step.b: active = step_b.instance()
		Step.c: active = step_c.instance()
		Step.d: active = step_d.instance()
		Step.e: active = step_e.instance()
		Step.f: active = step_f.instance()
		Step.g: active = step_g.instance()
	if active == null: return
	if Global.local_player == null: return
	self.add_child(active)
	active.global_position = Global.local_player.global_position
	yield(get_tree().create_timer(0.1), "timeout")
	# The yield above initializes the step
	active.start_step(self)


func _on_scene_move_ended():
	if Global.state == Global.State.Tutorial:
		_spawn_step(Step.a)
	# While it makes sense 
	# it also breaks the flow
	#	else: _spawn_step(Step.x)
