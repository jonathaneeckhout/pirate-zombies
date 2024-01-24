extends Control

class_name ClientLoginPanel

signal joine_game_pressed(username: String, password: String)

## Random names which will be used when the username is empty and no account verification is needed
const RANDOM_PLAYER_NAMES = [
	"Alpha",
	"Bravo",
	"Charlie",
	"Delta",
	"Echo",
	"Foxtrot",
	"Golf",
	"Hotel",
	"India",
	"Juliet",
	"Kilo",
	"Lima",
	"Mike",
	"November",
	"Oscar",
	"Papa",
	"Quebec",
	"Romeo",
	"Sierra",
	"Tango",
	"Uniform",
	"Victor",
	"Whiskey",
	"X-ray",
	"Yankee",
	"Zulu"
]

# Called when the node enters the scene tree for the first time.
func _ready():
	%JoinGameButton.pressed.connect(_on_join_game_button_pressed)

func get_username() -> String:
	var username: String = %Username.text

	# Pick a random name merged with a timestamp if the username is empty
	if username.is_empty():
		username = "%s-%d" % [RANDOM_PLAYER_NAMES.pick_random(), Time.get_unix_time_from_system()]

	return username


func get_password() -> String:
	return ""


func _on_join_game_button_pressed():
	joine_game_pressed.emit(get_username(), get_password())

