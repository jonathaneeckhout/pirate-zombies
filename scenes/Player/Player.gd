extends Player

@onready
var player_client_authority_controller: PlayerClientAuthorityController = $PlayerClientAuthorityController

@onready var network_view_synchronizer: NetworkViewSynchronizer = $NetworkViewSynchronizer

@onready var position_synchronizer: PositionSynchronizer = $PositionSynchronizer

@onready var stats_synchronizer: StatsSynchronizer = $StatsSynchronizer

@onready var animation_handler: AnimationHandler = $AnimationHandler

@onready var shoot_synchronizer: ShootSynchronizer = $ShootSynchronizer


func _ready():
	super()

	if multiplayer_connection.is_server():
		%Hands.hide()
		%Model.show()
	else:
		# Check if the player is the local client's own player instance.
		if multiplayer_connection.is_own_player(self):
			%Hands.show()
			%Model.hide()

			animation_handler.animation_player = %Hands.get_node("AnimationPlayer")
		else:
			%Hands.hide()
			%Model.show()

			animation_handler.animation_player = %Model.get_node("AnimationPlayer")
