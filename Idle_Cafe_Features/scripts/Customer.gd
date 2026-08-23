extends CharacterBody2D

@export var move_speed: float = 120.0
@onready var nav_agent: NavigationAgent2D = $NavigationAgent2D

var target_position: Vector2
var is_served: bool = false

func _ready():
	if nav_agent:
		nav_agent.velocity_computed.connect(_on_velocity_computed)

func set_destination(target: Vector2):
	target_position = target
	if nav_agent:
		nav_agent.target_position = target

func _physics_process(delta):
	if not nav_agent:
		return
	if nav_agent.is_navigation_finished():
		if not is_served:
			_on_reached_counter()
		return

	var next_path_pos = nav_agent.get_next_path_position()
	var new_velocity = (next_path_pos - global_position).normalized() * move_speed
	_on_velocity_computed(new_velocity)

func _on_velocity_computed(safe_velocity: Vector2):
	velocity = safe_velocity
	move_and_slide()

func _on_reached_counter():
	is_served = true
	GameManager.add_money(15.0 * GameManager.cafe_level)
	set_destination(Vector2(-100, global_position.y))
	get_tree().create_timer(3.0).timeout.connect(queue_free)
