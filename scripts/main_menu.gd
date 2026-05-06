# main_menu.gd — Main menu screen
class_name MainMenu
extends Node2D

@onready var play_button: Button = $VBoxContainer/PlayButton

func _ready() -> void:
	if play_button:
		play_button.pressed.connect(_on_play_pressed)

func _on_play_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/Main.tscn")
