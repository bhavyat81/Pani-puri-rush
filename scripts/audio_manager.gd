# audio_manager.gd — Autoload audio manager. Plays SFX; no-ops if files missing.
class_name AudioManager
extends Node

var _players: Dictionary = {}
var _sounds: Dictionary = {
	"tap": "res://assets/sounds/tap.wav",
	"serve_correct": "res://assets/sounds/serve_correct.wav",
	"serve_wrong": "res://assets/sounds/serve_wrong.wav",
	"customer_happy": "res://assets/sounds/customer_happy.wav",
	"customer_angry": "res://assets/sounds/customer_angry.wav",
	"combo": "res://assets/sounds/combo.wav",
	"level_complete": "res://assets/sounds/level_complete.wav",
}

func _ready() -> void:
	_preload_sounds()

func _preload_sounds() -> void:
	for key in _sounds:
		var path = _sounds[key]
		if ResourceLoader.exists(path):
			var stream = load(path)
			var player = AudioStreamPlayer.new()
			player.stream = stream
			player.bus = "SFX"
			add_child(player)
			_players[key] = player

func _play(key: String) -> void:
	if _players.has(key):
		_players[key].play()

func play_tap() -> void:
	_play("tap")

func play_serve_correct() -> void:
	_play("serve_correct")

func play_serve_wrong() -> void:
	_play("serve_wrong")

func play_customer_happy() -> void:
	_play("customer_happy")

func play_customer_angry() -> void:
	_play("customer_angry")

func play_combo() -> void:
	_play("combo")

func play_level_complete() -> void:
	_play("level_complete")
