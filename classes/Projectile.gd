extends CharacterBody3D

class_name Projectile

## The air speed of the projectile
var air_speed: float = 30.0

## The damage done by the projectile
var damage: int = 10

## Whether the projectile should instant hit or not (thus have fly time or not)
var instant_hit: bool = false

## Whether it is the original or synced projectile
var original: bool = true

## If the projectile should be affected by gravity
var is_gravity_affected: bool = false

## Wheter or not the projectile should despawn after a while
var persistent: bool = false

# The velocity facing downward (used for gravity)
var _down_velocity: float = 0.0

var _players_hit_radius: Array[Player] = []

# Whether or not the impact already occurred
var _impacted: bool = false

@onready var _visuals: Node3D = $Visuals
@onready var _particles: CPUParticles3D = $CPUParticles3D
var _hit_area: Area3D = null


func _ready():
	if not persistent:
		# Create a timer so that the projectiles get freed we not hitting anything
		var destroy_timer: Timer = Timer.new()
		destroy_timer.name = "DestroyTimer"
		destroy_timer.wait_time = 5.0
		destroy_timer.one_shot = true
		destroy_timer.autostart = true
		destroy_timer.timeout.connect(_on_destroy_timer_timeout)
		add_child(destroy_timer)

	if instant_hit:
		_particles.emitting = true

	if original and not instant_hit:
		_hit_area = $HitArea
		_hit_area.body_entered.connect(_on_hit_area_body_entered)
		_hit_area.body_exited.connect(_on_hit_area_body_exited)


func _physics_process(delta):
	# Don't change the position when it's a instant hit projectile
	if instant_hit:
		return

	# Get the correct velocity
	velocity = transform.basis * Vector3(0, 0, air_speed)

	if is_gravity_affected:
		# Calculate the gravity
		#_down_velocity -= FpsConfig.GRAVITY * delta

		# Apply the gravity
		velocity.y += _down_velocity

	var collision: KinematicCollision3D = move_and_collide(velocity * delta)
	if collision:
		# Handle the impact
		_handle_impact(collision)

		# Hide the projectile visually
		_visuals.hide()

		# Emit the particles
		_particles.emitting = true

		# Don't update the node anymore
		set_physics_process(false)

		# Wait a bit so that the patricles have time to fly
		await get_tree().create_timer(1.0).timeout

		# Remote yourself
		queue_free()


# If you manage to hit a player directly, deal double damage
func _handle_impact(collision: KinematicCollision3D):
	# Only handle on the original bullet. All the other synced bullets wont affect the hp
	if not original:
		return

	# Get the direct hit
	var collider: Object = collision.get_collider()
	# Check if it's a player
	#if collider.is_in_group("players"):
		## Deal the damage the target player
		#Connection.sync_rpc.projectile_sync_hit_to_server.rpc_id(1, collider.name, damage)

	#for player in _players_hit_radius:
		#Connection.sync_rpc.projectile_sync_hit_to_server.rpc_id(1, player.name, damage)

	_impacted = true


func _on_destroy_timer_timeout():
	queue_free()


func _on_hit_area_body_entered(body: Node3D):
	if body.is_in_group("players") and body not in _players_hit_radius:
		# Sometimes this signal is slower than the direct collision, so check after impact as well
		#if _impacted:
			#Connection.sync_rpc.projectile_sync_hit_to_server.rpc_id(1, body.name, damage)

		_players_hit_radius.append(body)


func _on_hit_area_body_exited(body: Node3D):
	if body.is_in_group("players") and body in _players_hit_radius and not _impacted:
		_players_hit_radius.erase(body)
