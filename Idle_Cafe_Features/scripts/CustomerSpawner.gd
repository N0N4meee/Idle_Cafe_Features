extends Node2D

@export var customer_scene: PackedScene
@export var counter_target: Node2D
@export var spawn_interval: float = 3.0

var timer: Timer

func _ready():
	timer = Timer.new()
	timer.wait_time = spawn_interval
	timer.autostart = true
	timer.timeout.connect(_spawn_customer)
	add_child(timer)

func _spawn_customer():
	if customer_scene and counter_target:
		var customer = customer_scene.instantiate()
		customer.global_position = global_position
		get_parent().add_child(customer)
		customer.set_destination(counter_target.global_position)
