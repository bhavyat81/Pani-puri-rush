# game_over.gd — Game over overlay
extends CanvasLayer

@onready var score_label: Label = $Panel/VBoxContainer/ScoreLabel
@onready var retry_button: Button = $Panel/VBoxContainer/ButtonContainer/RetryButton
@onready var menu_button: Button = $Panel/VBoxContainer/ButtonContainer/MenuButton

func _ready() -> void:
	if retry_button:
		retry_button.pressed.connect(_on_retry)
	if menu_button:
		menu_button.pressed.connect(_on_menu)

func show_game_over(score: int) -> void:
	if score_label:
		score_label.text = "Score: " + str(score)

func _on_retry() -> void:
	get_tree().change_scene_to_file("res://scenes/Main.tscn")

func _on_menu() -> void:
	get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")
