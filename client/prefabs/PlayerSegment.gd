class_name PlayerSegment
extends Node2D


var target = null
var segment = null

export(float) var lerp_speed = 0.4
export(float) var turn_speed = 7.6
export(String) var target_name = "PlayerHead"


func _ready():
	target = get_node("../%s" % target_name)
	segment = target.get_segment_hook()


func _process(delta):
	match Global.state:
		Global.State.Home:
			_process_home(delta)
		Global.State.Sector:
			_process_sector(delta)
		Global.State.Tutorial:
			_process_tutorial(delta)


func _process_home(delta):
	# TODO: Pause based on home State
	_do_follow_movement(delta)


func _process_sector(delta):
	if Global.paused: return
	_do_follow_movement(delta)


func _process_tutorial(delta):
	# TODO: Pause based on Tutorial State
	_do_follow_movement(delta)


func _do_follow_movement(delta):
	var direction = target.global_position - global_position
	var base = global_rotation
	var angle = direction.angle()
	angle = lerp_angle(base, angle, 1.0)
	var angle_delta = turn_speed * delta
	angle = clamp(angle, base - angle_delta, base + angle_delta)
	global_rotation = angle
	global_position = lerp(global_position, segment.global_position, lerp_speed)

func get_segment_hook():
	return get_node("SegmentHook")
