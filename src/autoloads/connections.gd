extends Node

enum ConnectionTypes {
	LOCAL,				# Local only game, tutorial
	DEDICATED_SERVER,	# Server only, no local client
	CLIENT_SERVER,		# Server with a local player
	CLIENT				# Client only, remote server
}

var connectionType: int = ConnectionTypes.LOCAL setget toss, getConnectionType
var myName: String = "" setget toss, getMyName
var serverName: String = "" setget toss, getServerName
const MAX_PLAYERS: int = 20
var listConnections: Dictionary = {}


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	get_tree().connect("connected_to_server", self, "connectedOK")
	get_tree().connect("connection_failed", self, "connectedFail")
	get_tree().connect("server_disconnected", self, "disconnectedFromServer")

func toss(_newValue) -> void:
	pass

func getConnectionType() -> int:
	return connectionType

func getMyName() -> String:
	return myName

func getServerName() -> String:
	return serverName

# -------------- Client side code --------------

func joinGame(serverName: String, portNumber: int, playerName: String) -> void:
	var peer: NetworkedMultiplayerENet = NetworkedMultiplayerENet.new()
	peer.create_client(serverName, portNumber)
	get_tree().network_peer = peer
	var id: int = get_tree().get_network_peer().get_unique_id()
	myName = playerName
	connectionType = ConnectionTypes.CLIENT
	#print_debug("Client_id is ", id)
	listConnections[id] = myName

func connectedOK() -> void:
	print_debug("Connected")
	rpc_id(1, "receiveNewPlayerData", myName)
	TransitionHandler.enterLobby()

func connectedFail() -> void:
	print_debug("Connection failed")
	assert(false, "Not implemented yet")

func disconnectedFromServer() -> void:
	assert(false, "Not implemented yet")

puppet func receiveBulkPlayerData(connections: Dictionary) -> void:
	listConnections = connections
	#print_debug("Connected clients: ", listConnections)
	var gameScene: Node = TransitionHandler.gameScene
	for player in listConnections:
		gameScene.addCharacter(player)

puppet func setServerName(serverNewName: String) -> void:
	serverName = serverNewName
	#print_debug("Server name: ", serverName)

puppet func receivePlayerData(id: int, name: String) -> void:
	if id != get_tree().get_network_unique_id():
		listConnections[id] = name
		var gameScene: Node = TransitionHandler.gameScene
		gameScene.addCharacter(id)
	#print_debug("Connected clients: ", listConnections)

# -------------- Server side code --------------

func createGame(portNumber: int, playerName: String) -> void:
	var peer: NetworkedMultiplayerENet = NetworkedMultiplayerENet.new()
	peer.create_server(portNumber, MAX_PLAYERS)
	get_tree().network_peer = peer
	get_tree().connect("network_peer_connected", self, "connectedNewPlayer")
	get_tree().connect("network_peer_disconnected", self, "disconnectedPlayer")
	connectionType = ConnectionTypes.CLIENT_SERVER
	listConnections[1] = playerName
	serverName = playerName + "'s Server"
	TransitionHandler.enterLobby()
	var gameScene: Node = TransitionHandler.gameScene
	gameScene.addCharacter(1)

func createDedicated(portNumber: int, srvName: String) -> void:
	var peer: NetworkedMultiplayerENet = NetworkedMultiplayerENet.new()
	peer.create_server(portNumber, MAX_PLAYERS)
	get_tree().network_peer = peer
	get_tree().connect("network_peer_connected", self, "connectedNewPlayer")
	get_tree().connect("network_peer_disconnected", self, "disconnectedPlayer")
	connectionType = ConnectionTypes.DEDICATED_SERVER
	serverName = srvName
	TransitionHandler.enterLobby()

# Once the newly joined player sent us their data, that's when we send them all the data
master func receiveNewPlayerData(newPlayerName: String) -> void:
	var senderId: int = get_tree().get_rpc_sender_id()
	listConnections[senderId] = newPlayerName
	#print_debug(listConnections)
	rpc_id(senderId, "setServerName", serverName)
	rpc_id(senderId, "receiveBulkPlayerData", listConnections)
	rpc("receivePlayerData", senderId, newPlayerName)
	var gameScene: Node = TransitionHandler.gameScene
	gameScene.addCharacter(senderId)

func connectedNewPlayer(id: int) -> void:
	pass
	
func disconnectedPlayer(id: int) -> void:
	assert(false, "Not implemented yet")

