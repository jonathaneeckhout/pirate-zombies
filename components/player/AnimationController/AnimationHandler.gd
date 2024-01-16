extends Node

class_name AnimationHandler

@export var animation_player: AnimationPlayer

# Reference to the parent node (assumed to be a Player node).
var _player: Player = null

var _is_own_player: bool = false

var _prev_position: Vector3 = Vector3.ZERO


# Called when the node enters the scene tree for the first time.
func _ready():
	# Get the parent node (assumed to be a Player node).
	_player = get_parent()

	# Ensure that the player's multiplayer connection is not null.
	assert(_player.multiplayer_connection != null, "Player's multiplayer connection is null")

	if _player.multiplayer_connection.is_server():
		set_physics_process(false)
		queue_free()
		return

	_prev_position = _player.position

	_is_own_player = _player.multiplayer_connection.is_own_player(_player)

	# Wait an additional frame so others can get set.
	await get_tree().process_frame

	# Some entities take a bit to get added to the tree, do not update them until then.
	if not is_inside_tree():
		await tree_entered

	animation_player.play("idle")


func _physics_process(_delta):
	var movement: Vector3 = _player.position - _prev_position
	_prev_position = _player.position

	if movement.is_zero_approx():
		animation_player.play("idle")
	else:
		# if movement.x > 0:
		# 	animation_player.play("run-right")
		# elif movement.x < 0:
		# 	animation_player.play("run-left")
		# else:
		animation_player.play("run-forward")
