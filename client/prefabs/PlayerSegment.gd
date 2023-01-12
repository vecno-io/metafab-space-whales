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
		Global.State.Game:
			_process_game(delta)
		Global.State.Dialog:
			_process_dialog(delta)


func _process_game(delta):
	if Global.paused:
		return
	var direction = target.global_position - global_position
	var base = global_rotation
	var angle = direction.angle()
	angle = lerp_angle(base, angle, 1.0)
	var angle_delta = turn_speed * delta
	angle = clamp(angle, base - angle_delta, base + angle_delta)
	global_rotation = angle

	global_position = lerp(global_position, segment.global_position, lerp_speed)


func _process_dialog(delta):
	if Global.paused:
		return
	var direction = target.global_position - global_position
	var base = global_rotation
	var angle = direction.angle()
	angle = lerp_angle(base, angle, 1.0)
	var angle_delta = turn_speed * delta
	angle = clamp(angle, base - angle_delta, base + angle_delta)
	global_rotation = angle

	global_position = lerp(global_position, segment.global_position, 0.24)


func get_segment_hook():
	return get_node("SegmentHook")
