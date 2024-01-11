extends MultiplayerConnection

# The server for this connection
var _server: WebSocketMultiplayerPeer = null

# The client for this connection
var _client: WebSocketMultiplayerPeer = null


## Client start function to be called after the inherited class client start
func websocket_client_start(url: String) -> bool:
	_client = WebSocketMultiplayerPeer.new()

	GodotLogger.info("Connecting to websocket server:[%s]" % url)
	var error: int = _client.create_client(url)

	if error != OK:
		GodotLogger.warn(
			"Failed to create client. Error code {0} ({1})".format([error, error_string(error)])
		)
		return false

	# Assign the client to the default multiplayer peer
	multiplayer.multiplayer_peer = _client

	client_start()

	return true


func websocket_server_start(
	port: int, use_tls: bool = true, cert_path: String = "", key_path: String = ""
) -> bool:
	_server = WebSocketMultiplayerPeer.new()
	if use_tls:
		# Get the tls optiojns
		var server_tls_options: TLSOptions = server_get_tls_options(cert_path, key_path)
		if server_tls_options == null:
			GodotLogger.error("Failed to load tls options")
			return false

		var error: int = _server.create_server(port, "*", server_tls_options)
		if error != OK:
			GodotLogger.error("Failed to create server")
			return false
	else:
		var error: int = _server.create_server(port)
		if error != OK:
			GodotLogger.error("Failed to create server")
			return false

	if _server.get_connection_status() == MultiplayerPeer.CONNECTION_DISCONNECTED:
		GodotLogger.error("Failed to start server")
		return false

	# Assign the client to the default multiplayer peer
	multiplayer.multiplayer_peer = _server

	server_start()

	return true
