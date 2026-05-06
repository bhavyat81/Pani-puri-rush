# hud.gd — HUD: score, coins, day timer, reputation hearts, combo badge
extends CanvasLayer

@onready var coins_label: Label = $TopBar/HBoxContainer/CoinsLabel
@onready var score_label: Label = $TopBar/HBoxContainer/ScoreLabel
@onready var timer_label: Label = $TopBar/HBoxContainer/TimerLabel
@onready var reputation_label: Label = $TopBar/HBoxContainer/ReputationLabel
@onready var combo_badge: Label = $TopBar/HBoxContainer/ComboBadge
@onready var level_label: Label = $LevelLabel
@onready var pause_button: Button = $PauseButton

signal pause_requested()

func _ready() -> void:
	if pause_button:
		pause_button.pressed.connect(_on_pause_pressed)
	_update_combo(1)

func update_score(new_score: int) -> void:
	if score_label:
		score_label.text = "⭐ " + str(new_score)

func update_coins(new_coins: int) -> void:
	if coins_label:
		coins_label.text = "🪙 " + str(new_coins)

func update_timer(seconds_remaining: float) -> void:
	if timer_label:
		var secs = int(seconds_remaining)
		timer_label.text = "⏱ " + str(secs) + "s"
		if secs <= 10:
			timer_label.modulate = Color("#e74c3c")
		else:
			timer_label.modulate = Color.WHITE

func update_reputation(rep: int) -> void:
	if reputation_label:
		var hearts = ""
		for i in range(rep):
			hearts += "❤"
		for i in range(3 - rep):
			hearts += "🖤"
		reputation_label.text = hearts

func update_level(level_id: int, level_name: String) -> void:
	if level_label:
		level_label.text = level_name

func _update_combo(multiplier: int) -> void:
	if combo_badge:
		combo_badge.visible = multiplier > 1
		combo_badge.text = "x" + str(multiplier) + " COMBO!"

func _on_pause_pressed() -> void:
	emit_signal("pause_requested")

func connect_to_game_manager() -> void:
	GameManager.score_changed.connect(update_score)
	GameManager.coins_changed.connect(update_coins)
	GameManager.reputation_changed.connect(update_reputation)
	GameManager.combo_changed.connect(_update_combo)
