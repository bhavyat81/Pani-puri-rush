# level_complete.gd — Level complete overlay
extends CanvasLayer

@onready var stars_label: Label = $Panel/VBoxContainer/StarsLabel
@onready var score_label: Label = $Panel/VBoxContainer/ScoreLabel
@onready var coins_label: Label = $Panel/VBoxContainer/CoinsLabel
@onready var continue_button: Button = $Panel/VBoxContainer/ButtonContainer/ContinueButton
@onready var replay_button: Button = $Panel/VBoxContainer/ButtonContainer/ReplayButton
@onready var menu_button: Button = $Panel/VBoxContainer/ButtonContainer/MenuButton

var _current_level: int = 1

func _ready() -> void:
	if continue_button:
		continue_button.pressed.connect(_on_continue)
	if replay_button:
		replay_button.pressed.connect(_on_replay)
	if menu_button:
		menu_button.pressed.connect(_on_menu)

func show_results(stars: int, score: int, coins: int, level_id: int) -> void:
	_current_level = level_id
	if stars_label:
		var star_text = ""
		for i in range(stars):
			star_text += "⭐"
		for i in range(3 - stars):
			star_text += "☆"
		stars_label.text = star_text
	if score_label:
		score_label.text = "Score: " + str(score)
	if coins_label:
		coins_label.text = "Coins: 🪙 " + str(coins)
	# Hide continue button if on last level
	if continue_button:
		if _current_level >= LevelLoader.get_level_count():
			continue_button.visible = false

func _on_continue() -> void:
	GameManager.current_level = _current_level + 1
	get_tree().change_scene_to_file("res://scenes/Main.tscn")

func _on_replay() -> void:
	get_tree().change_scene_to_file("res://scenes/Main.tscn")

func _on_menu() -> void:
	get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")
