# PROTOTYPE - NOT FOR PRODUCTION
# Question: Does wire grapple (linear pull) feel satisfying in 2D?
# Date: 2026-04-26

extends CharacterBody2D

enum State { NORMAL, WIRE_TRAVELING, WIRE_FAILED, WALL_CLINGING }

const GRAVITY: float = 980.0
const MOVE_SPEED: float = 200.0
const JUMP_VELOCITY: float = -400.0
const WIRE_TRAVEL_SPEED: float = 800.0
const MIN_WIRE_RANGE: float = 50.0
const MAX_WIRE_RANGE: float = 500.0
const ARRIVE_THRESHOLD: float = 20.0
const WIRE_FAIL_DURATION: float = 0.3
const WALL_JUMP_SCALE: float = 1.2

# Collision layer 2 = wire-attachable surfaces
const WIRE_ATTACH_LAYER: int = 2

var state: State = State.NORMAL
var wire_target: Vector2 = Vector2.ZERO
var wire_normal: Vector2 = Vector2.ZERO
var wall_normal: Vector2 = Vector2.ZERO
var _wire_fail_start: Vector2 = Vector2.ZERO
var _wire_fail_end: Vector2 = Vector2.ZERO
var _wire_fail_point: Vector2 = Vector2.ZERO
var _pre_fail_state: State = State.NORMAL
var _jump_requested: bool = false
var _default_collision_mask: int = 0
var is_crouching: bool = false

@onready var wire_line: Line2D = $WireLine
@onready var _body: Polygon2D = $Body
@onready var _col_shape: CollisionShape2D = $CollisionShape2D


func _ready() -> void:
	_default_collision_mask = collision_mask
	wire_line.hide()


func _set_crouch(crouching: bool) -> void:
	if is_crouching == crouching:
		return
	is_crouching = crouching
	var rect := _col_shape.shape as RectangleShape2D
	if crouching:
		rect.size = Vector2(24.0, 20.0)
		_col_shape.position.y = 10.0
		_body.polygon = PackedVector2Array([
			Vector2(-12, 0), Vector2(12, 0),
			Vector2(12, 20), Vector2(-12, 20),
		])
	else:
		rect.size = Vector2(24.0, 40.0)
		_col_shape.position.y = 0.0
		_body.polygon = PackedVector2Array([
			Vector2(-12, -20), Vector2(12, -20),
			Vector2(12, 20), Vector2(-12, 20),
		])


func _physics_process(delta: float) -> void:
	match state:
		State.NORMAL:
			_process_normal(delta)
		State.WIRE_TRAVELING:
			_process_wire_traveling()
		State.WIRE_FAILED:
			if not is_on_floor():
				velocity.y += GRAVITY * delta
		State.WALL_CLINGING:
			_process_wall_clinging()

	move_and_slide()

	if state == State.WIRE_TRAVELING:
		if (wire_target - global_position).length() <= ARRIVE_THRESHOLD:
			_arrive_at_wire_target()

	_update_wire_visual()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton \
			and event.button_index == MOUSE_BUTTON_LEFT \
			and event.pressed:
		if state == State.NORMAL or state == State.WALL_CLINGING:
			_shoot_wire()
	if event is InputEventKey \
			and event.keycode == KEY_SPACE \
			and event.pressed \
			and not event.echo:
		_jump_requested = true


func _process_normal(delta: float) -> void:
	_set_crouch(Input.is_key_pressed(KEY_CTRL))

	if not is_on_floor():
		velocity.y += GRAVITY * delta
	else:
		velocity.y = 0.0

	var dir := 0.0
	if Input.is_key_pressed(KEY_D):
		dir += 1.0
	if Input.is_key_pressed(KEY_A):
		dir -= 1.0
	velocity.x = dir * MOVE_SPEED

	if _jump_requested and is_on_floor():
		velocity.y = JUMP_VELOCITY
	_jump_requested = false


func _process_wire_traveling() -> void:
	velocity = (wire_target - global_position).normalized() * WIRE_TRAVEL_SPEED


func _process_wall_clinging() -> void:
	velocity = Vector2.ZERO
	if Input.is_key_pressed(KEY_CTRL):
		_set_crouch(true)
		state = State.NORMAL
		_jump_requested = false
		return
	if _jump_requested:
		_set_crouch(false)
		velocity = wall_normal * 250.0
		velocity.y = JUMP_VELOCITY * WALL_JUMP_SCALE
		state = State.NORMAL
		wire_line.hide()
	_jump_requested = false


func _shoot_wire() -> void:
	var direction := (get_global_mouse_position() - global_position).normalized()
	var ray_end := global_position + direction * MAX_WIRE_RANGE
	var space_state := get_world_2d().direct_space_state

	# Single raycast against all layers — closest object wins.
	# Then check if that object has the wire-attachable layer bit set.
	var query := PhysicsRayQueryParameters2D.create(global_position, ray_end)
	query.exclude = [get_rid()]
	var result := space_state.intersect_ray(query)

	if result.is_empty():
		_fail_wire(ray_end)
		return

	var hit_pos: Vector2 = result["position"]
	var hit_normal: Vector2 = result["normal"]
	var body := result["collider"] as CollisionObject2D
	var is_wall := absf(hit_normal.x) > 0.7
	var too_close := (hit_pos - global_position).length() < MIN_WIRE_RANGE
	if (body.collision_layer & WIRE_ATTACH_LAYER) and (is_wall or not too_close):
		_set_crouch(false)
		wire_target = hit_pos
		wire_normal = hit_normal
		collision_mask = 0  # phase through everything during travel
		state = State.WIRE_TRAVELING
		wire_line.show()
	else:
		_fail_wire(hit_pos)


func _fail_wire(fail_end: Vector2) -> void:
	_pre_fail_state = state
	_wire_fail_start = global_position
	_wire_fail_end = fail_end
	state = State.WIRE_FAILED
	wire_line.show()

	var tween := create_tween()
	tween.tween_method(_update_fail_point, 0.0, 1.0, WIRE_FAIL_DURATION * 0.5)
	tween.tween_method(_update_fail_point, 1.0, 0.0, WIRE_FAIL_DURATION * 0.5)
	tween.tween_callback(_end_fail_wire)


func _update_fail_point(t: float) -> void:
	_wire_fail_point = _wire_fail_start.lerp(_wire_fail_end, t)


func _end_fail_wire() -> void:
	wire_line.hide()
	state = _pre_fail_state if _pre_fail_state != State.WIRE_FAILED else State.NORMAL


func _arrive_at_wire_target() -> void:
	collision_mask = _default_collision_mask
	velocity = Vector2.ZERO
	wire_line.hide()
	if absf(wire_normal.x) > 0.7:
		# Snap player center flush against the wall surface (half-width + 2px buffer).
		global_position = wire_target + wire_normal * 14.0
		wall_normal = wire_normal
		state = State.WALL_CLINGING
	else:
		state = State.NORMAL


func _update_wire_visual() -> void:
	if not wire_line.visible:
		return
	wire_line.set_point_position(0, Vector2.ZERO)
	match state:
		State.WIRE_TRAVELING:
			wire_line.set_point_position(1, wire_target - global_position)
		State.WIRE_FAILED:
			wire_line.set_point_position(1, _wire_fail_point - global_position)
