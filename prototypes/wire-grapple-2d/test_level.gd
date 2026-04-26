# PROTOTYPE - NOT FOR PRODUCTION
# Question: Does wire grapple (linear pull) feel satisfying in 2D?
# Date: 2026-04-26

extends Node2D

# Wire-attachable surfaces use layer 2 (bit 1). Layer 1 (bit 0) is shared by all physics objects.
const LAYER_ALL: int = 1
const LAYER_WIRE_ATTACHABLE: int = 3  # bits 0 and 1 → layers 1 and 2
const LAYER_NO_ATTACH: int = 1        # bit 0 only → layer 1

@onready var _player: Node2D = $Player
@onready var _camera: Camera2D = $Camera2D


func _ready() -> void:
	_build_level()


func _process(_delta: float) -> void:
	_camera.global_position = _player.global_position


func _build_level() -> void:
	# Ground floor
	_make_platform(Vector2(0, 350), Vector2(1600, 24), true)

	# Boundary walls
	_make_platform(Vector2(-700, -50), Vector2(24, 800), true)
	_make_platform(Vector2(700, -50), Vector2(24, 800), true)

	# Interior walls (main grapple targets)
	_make_platform(Vector2(-350, 100), Vector2(24, 400), true)
	_make_platform(Vector2(350, 100), Vector2(24, 400), true)
	_make_platform(Vector2(-150, -100), Vector2(24, 300), true)
	_make_platform(Vector2(150, -100), Vector2(24, 300), true)

	# Platforms (floor surfaces — no stick)
	_make_platform(Vector2(-400, 150), Vector2(180, 20), true)
	_make_platform(Vector2(0, 50), Vector2(200, 20), true)
	_make_platform(Vector2(400, 150), Vector2(180, 20), true)
	_make_platform(Vector2(-200, -150), Vector2(160, 20), true)
	_make_platform(Vector2(200, -150), Vector2(160, 20), true)
	_make_platform(Vector2(0, -280), Vector2(200, 20), true)

	# Non-attachable obstacle (triggers fail feedback)
	_make_platform(Vector2(0, 200), Vector2(120, 24), false)


func _make_platform(pos: Vector2, size: Vector2, attachable: bool) -> void:
	var body := StaticBody2D.new()
	body.position = pos
	body.collision_layer = LAYER_WIRE_ATTACHABLE if attachable else LAYER_NO_ATTACH

	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = size
	shape.shape = rect
	body.add_child(shape)

	var hw := size.x * 0.5
	var hh := size.y * 0.5
	var visual := Polygon2D.new()
	visual.polygon = PackedVector2Array([
		Vector2(-hw, -hh), Vector2(hw, -hh),
		Vector2(hw, hh), Vector2(-hw, hh),
	])
	visual.color = Color(0.55, 0.38, 0.22) if attachable else Color(0.45, 0.45, 0.55)
	body.add_child(visual)

	add_child(body)
