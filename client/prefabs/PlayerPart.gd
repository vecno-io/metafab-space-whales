extends Sprite

var target = null
var segment = null
var turn_speed = PI * 1.8

export(String) var target_name = "PlayerHead"


func _ready():
	target = get_node("../%s" % target_name)
	segment = target.get_segment_hook()


func _process(delta):
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
	return get_node("%SegmentHook")
