extends Sprite3D

@export var despawn_time: float = 3.0

@onready var _despawn_timer: Timer = null


# Called when the node enters the scene tree for the first time.
func _ready():
	_despawn_timer = Timer.new()
	_despawn_timer.name = "DespawnTimer"
	_despawn_timer.autostart = true
	_despawn_timer.wait_time = despawn_time
	_despawn_timer.timeout.connect(_on_despawn_timer_timeout)
	add_child(_despawn_timer)


func _on_despawn_timer_timeout():
	queue_free()
