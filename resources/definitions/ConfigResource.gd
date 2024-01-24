extends Resource

class_name ConfigResource

enum MODE {
	DEVELOPMENT,
	DEPLOYMENT
}

@export_group("Global Configuration")
@export var mode: MODE = MODE.DEVELOPMENT
@export var use_tls: bool = false

@export_group("Server Configuration")
@export var server_bind_address: String = "*"
@export var server_port: int = 9081
@export var server_fps: int = 30
@export var certh_path: String = ""
@export var key_path: String = ""

@export_group("Client Configuration")
@export var server_address: String = "ws://localhost:9081"
@export var client_fps: int = 30
