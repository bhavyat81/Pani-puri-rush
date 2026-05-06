# stall.gd — Handles tap interactions on jugs, masala bowl, puri tray, and serving plate
class_name Stall
extends Node2D

signal puri_tray_tapped()
signal masala_tapped()
signal flavor_tapped(flavor: int)
signal plate_tapped()

@onready var puri_tray: TextureButton = $Counter/PuriTray
@onready var masala_bowl: TextureButton = $Counter/MasalaBowl
@onready var serving_plate: TextureButton = $Counter/ServingPlate
@onready var jug_container: HBoxContainer = $Counter/JugContainer

var available_flavors: Array = []
var _jug_buttons: Array = []

func setup(flavors: Array) -> void:
	available_flavors = flavors
	_build_jug_buttons()

func _ready() -> void:
	if puri_tray:
		puri_tray.pressed.connect(_on_puri_tray_pressed)
	if masala_bowl:
		masala_bowl.pressed.connect(_on_masala_pressed)
	if serving_plate:
		serving_plate.pressed.connect(_on_plate_pressed)

func _build_jug_buttons() -> void:
	if not jug_container:
		return
	for child in jug_container.get_children():
		child.queue_free()
	_jug_buttons.clear()

	for flavor_name in available_flavors:
		var flavor_idx = FlavorHelper.from_string(flavor_name)
		if flavor_idx < 0:
			continue
		var btn = Button.new()
		btn.custom_minimum_size = Vector2(100, 120)
		btn.text = flavor_name.left(1)
		var flavor_color = FlavorHelper.get_color(flavor_idx)
		var style = StyleBoxFlat.new()
		style.bg_color = flavor_color
		style.corner_radius_top_left = 12
		style.corner_radius_top_right = 12
		style.corner_radius_bottom_left = 12
		style.corner_radius_bottom_right = 12
		btn.add_theme_stylebox_override("normal", style)
		btn.add_theme_color_override("font_color", Color.WHITE if flavor_color.get_luminance() < 0.5 else Color.BLACK)
		btn.add_theme_font_size_override("font_size", 28)

		var captured_flavor = flavor_idx
		btn.pressed.connect(func(): _on_flavor_pressed(captured_flavor))
		jug_container.add_child(btn)
		_jug_buttons.append(btn)

func _on_puri_tray_pressed() -> void:
	AudioManager.play_tap()
	emit_signal("puri_tray_tapped")

func _on_masala_pressed() -> void:
	AudioManager.play_tap()
	emit_signal("masala_tapped")

func _on_flavor_pressed(flavor: int) -> void:
	AudioManager.play_tap()
	emit_signal("flavor_tapped", flavor)

func _on_plate_pressed() -> void:
	AudioManager.play_tap()
	emit_signal("plate_tapped")
