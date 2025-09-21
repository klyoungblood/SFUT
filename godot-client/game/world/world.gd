extends Node3D

class_name World

var player_scene_new = preload("res://game/PlayerShip/player.tscn")

@export var player_container: Node3D

signal signal_player_death(id)
signal signal_player_kill(id)

## TODO: 
# - Reload weapons while dead
# - Log messages in-game (killed by X messages)? (upper right corner)
# - Add Melee 
# - Nerf or change how jump works?
# - Disconnect button hide/show game world. unmount wolrd, show

func _ready() -> void:
	add_to_group('World')
	
	multiplayer.connected_to_server.connect(RTCServerConnected)
	multiplayer.peer_connected.connect(RTCPeerConnected)
	multiplayer.peer_disconnected.connect(RTCPeerDisconnected)

	add_player_to_game(multiplayer.get_unique_id())

func RTCServerConnected():
	print("WORLD: rtc server connected")
	
func RTCPeerConnected(id: int):
	print("WORLD: rtc peer connected " + str(id))
	add_player_to_game(id)
	
func RTCPeerDisconnected(id):
	print("WORLD: rtc peer disconnected " + str(id))
	remove_player_from_game(id)

func add_player_to_game(id: int):
	var has_id = id in player_container.get_children().map(func(node): int(node.name))
	if has_id == true:
		return

	var player_to_add = player_scene_new.instantiate()
	
	player_to_add.name = str(id)
	player_to_add.position = Vector3(randi_range(-2, 2), 0.8, randi_range(-2, 2)) * 10
	player_container.add_child(player_to_add, true)

@rpc("any_peer", 'call_local', 'reliable')
func broadcast_player_death(id: String):
	signal_player_death.emit(id)
	
@rpc("any_peer", 'call_local', 'reliable')
func broadcast_player_kill(id: String):
	signal_player_kill.emit(id)

func remove_player_from_game(id):
	player_container.get_node(str(id)).queue_free()
