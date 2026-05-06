# game_manager.gd — Autoload singleton: score, coins, day, customers served
extends Node

signal score_changed(new_score: int)
signal coins_changed(new_coins: int)
signal reputation_changed(new_rep: int)
signal combo_changed(multiplier: int)
signal game_over()
signal level_complete(stars: int, score: int, coins: int)

const MAX_REPUTATION: int = 3
const SCORE_PER_PURI: int = 10
const SCORE_ORDER_BONUS: int = 20
const COMBO_THRESHOLD: int = 3

var score: int = 0
var coins: int = 0
var reputation: int = MAX_REPUTATION
var current_level: int = 1
var customers_served: int = 0
var customers_angered: int = 0
var combo_count: int = 0
var combo_multiplier: int = 1
var total_puris_served: int = 0

func _ready() -> void:
	reset()

func reset() -> void:
	score = 0
	coins = 0
	reputation = MAX_REPUTATION
	customers_served = 0
	customers_angered = 0
	combo_count = 0
	combo_multiplier = 1
	total_puris_served = 0

func start_level(level_id: int) -> void:
	reset()
	current_level = level_id

func add_puri_score() -> void:
	var points = SCORE_PER_PURI * combo_multiplier
	score += points
	emit_signal("score_changed", score)

func complete_order(tip: int) -> void:
	customers_served += 1
	coins += tip
	score += SCORE_ORDER_BONUS * combo_multiplier
	combo_count += 1
	if combo_count >= COMBO_THRESHOLD:
		combo_multiplier = 2
		emit_signal("combo_changed", combo_multiplier)
		AudioManager.play_combo()
	emit_signal("score_changed", score)
	emit_signal("coins_changed", coins)

func customer_left_angry() -> void:
	customers_angered += 1
	combo_count = 0
	combo_multiplier = 1
	reputation -= 1
	emit_signal("combo_changed", combo_multiplier)
	emit_signal("reputation_changed", reputation)
	if reputation <= 0:
		emit_signal("game_over")

func get_stars(level_data: Dictionary) -> int:
	if not level_data.has("stars_thresholds"):
		return 1
	var thresholds = level_data["stars_thresholds"]
	if score >= int(thresholds["3"]):
		return 3
	elif score >= int(thresholds["2"]):
		return 2
	elif score >= int(thresholds["1"]):
		return 1
	return 0

func finish_level(level_data: Dictionary) -> void:
	var stars = get_stars(level_data)
	emit_signal("level_complete", stars, score, coins)
	AudioManager.play_level_complete()
