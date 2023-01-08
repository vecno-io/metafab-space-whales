extends Node2D


onready var game_view  = get_node("%GameView")
onready var dialog_view  = get_node("%DialogView")
onready var tutorial_view  = get_node("%TutorialView")

func _ready():
	Global.world = self
	game_view.visible = false
	dialog_view.visible = false
	tutorial_view.visible = false


func _exit_tree():
	Global.world = null

