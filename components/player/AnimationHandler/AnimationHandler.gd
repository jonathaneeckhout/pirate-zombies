extends Node

class_name AnimationHandler

# The AnimationPlayer node responsible for playing animations.
@export var animation_player: AnimationPlayer

@export var shoot_synchronizer: ShootSynchronizer = null

# Reference to the parent node (assumed to be a Player node).
var _player: Player = null

# Flag indicating whether this instance represents the local player.
var _is_own_player: bool = false

# The previous position of the player.
var _prev_position: Vector3 = Vector3.ZERO

var _wait_to_finish: bool = false

var _moving: bool = false


# Called when the node enters the scene tree for the first time.
func _ready():
	# Get the parent node (assumed to be a Player node).
	_player = get_parent()

	# Ensure that the player's multiplayer connection is not null.
	assert(_player.multiplayer_connection != null, "Player's multiplayer connection is null")

	# If this node is on the server, disable physics processing, free the node, and return.
	if _player.multiplayer_connection.is_server():
		set_physics_process(false)
		queue_free()
		return

	# Initialize the previous position with the current player position.
	_prev_position = _player.position

	# Check if this instance represents the local player.
	_is_own_player = _player.multiplayer_connection.is_own_player(_player)

	# Wait an additional frame to allow other nodes to be set up.
	await get_tree().process_frame

	# Some entities take a bit to get added to the tree, do not update them until then.
	if not is_inside_tree():
		await tree_entered

	animation_player.animation_finished.connect(_on_animation_finished)

	shoot_synchronizer.shoot.connect(_on_shoot)

	# Play the idle animation when the player enters the scene.
	animation_player.play("idle")


# Called in each physics frame to update the player's animations based on movement.
func _physics_process(_delta):
	# Calculate the movement vector between the current and previous player positions.
	var movement: Vector3 = _player.position - _prev_position

	# Update the previous position to the current player position.
	_prev_position = _player.position

	# Check if the player is stationary.
	if movement.is_zero_approx():
		_moving = false

		if not _wait_to_finish:
			animation_player.play("idle")
	else:
		_moving = true

		if not _wait_to_finish:
			animation_player.play("run-forward")


func _on_animation_finished(_anim_name: String):
	_wait_to_finish = false


func _on_shoot():
	_wait_to_finish = true

	animation_player.stop()

	if _moving:
		animation_player.play("shoot-run")
	else:
		animation_player.play("shoot")
