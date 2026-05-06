# puri.gd — Puri state machine: empty → masala-filled → flavored → ready
class_name Puri
extends Node2D

enum PuriState {
	EMPTY,
	MASALA_FILLED,
	FLAVORED,
	READY,
	WRONG,
}

signal state_changed(new_state: int)

var state: int = PuriState.EMPTY
var flavor: int = -1

@onready var body: ColorRect = $Body
@onready var masala_dot: ColorRect = $MasalaDot

const BASE_COLOR := Color("#f4a261")
const MASALA_COLOR := Color("#6b3a2a")
const WRONG_COLOR := Color("#ff0000")

func _ready() -> void:
	_update_visuals()

func apply_masala() -> bool:
	if state != PuriState.EMPTY:
		return false
	state = PuriState.MASALA_FILLED
	_update_visuals()
	emit_signal("state_changed", state)
	AudioManager.play_tap()
	return true

func apply_flavor(f: int) -> bool:
	if state != PuriState.MASALA_FILLED:
		return false
	flavor = f
	# Go directly to READY; FLAVORED is a transient internal step, no separate signal needed.
	state = PuriState.READY
	_update_visuals()
	emit_signal("state_changed", state)
	AudioManager.play_tap()
	return true

func mark_wrong() -> void:
	state = PuriState.WRONG
	_update_visuals()
	emit_signal("state_changed", state)

func reset() -> void:
	state = PuriState.EMPTY
	flavor = -1
	_update_visuals()
	emit_signal("state_changed", state)

func is_ready() -> bool:
	return state == PuriState.READY

func _update_visuals() -> void:
	if not is_inside_tree():
		return
	match state:
		PuriState.EMPTY:
			body.color = BASE_COLOR
			masala_dot.visible = false
		PuriState.MASALA_FILLED:
			body.color = BASE_COLOR
			masala_dot.visible = true
			masala_dot.color = MASALA_COLOR
		PuriState.FLAVORED, PuriState.READY:
			if flavor >= 0:
				body.color = FlavorHelper.get_color(flavor)
			masala_dot.visible = true
			masala_dot.color = MASALA_COLOR
		PuriState.WRONG:
			body.color = WRONG_COLOR
			masala_dot.visible = false
