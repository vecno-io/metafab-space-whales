extends Node2D

# Note: This is nolonger used?
# It was part of the original setup

var sector = null

export(PackedScene) var entry_sector
export(PackedScene) var player_actor

onready var game_view  = get_node("%GameView")
onready var dialog_view  = get_node("%DialogView")
onready var tutorial_view  = get_node("%TutorialView")



func _ready():
	Global.world = self
	game_view.visible = false
	dialog_view.visible = false
	tutorial_view.visible = false
	#warning-ignore: return_value_discarded
	Global.connect("actor_died", self, "_on_actor_died")


func _exit_tree():
	Global.world = null
	Global.disconnect("actor_died", self, "_on_actor_died")


func show_game():
	_load_active_sector()
	game_view.visible = true
	dialog_view.visible = false
	tutorial_view.visible = false


func show_dialog():
	_unload_active_sector()
	game_view.visible = false
	dialog_view.visible = true
	tutorial_view.visible = false


func show_tutorial():
	_unload_active_sector()
	game_view.visible = false
	dialog_view.visible = false
	tutorial_view.visible = true


func reset_player():
	if Global.local_player != null:
		Global.local_player.get_parent().queue_free()
	yield(get_tree().create_timer(0.1), "timeout")
	var player = player_actor.instance()
	get_parent().add_child(player)


func _load_active_sector():
	if sector != null: _unload_active_sector()
		# TODO Polish: Select random sector
	sector = entry_sector.instance()
	sector.difficulty = Global.difficulty
	game_view.add_child(sector)


func _unload_active_sector():
	if sector == null: return
	Global.difficulty = int(sector.difficulty * 0.5) + 1
	sector.queue_free()
	sector = null


func _on_actor_died():
	yield(get_tree().create_timer(0.2), "timeout")
	if Global.local_player != null: return
	var player = player_actor.instance()
	get_parent().add_child(player)
