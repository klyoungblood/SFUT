extends CharacterBody3D

class_name PlayerCharacterShip 

var MOUSE_SENSITIVITY = 0.15
var JOY_SENSITIVITY = 3.5

const SPEED = 10.0

@export var health_system: HealthSystem

func _enter_tree():
	# With mesh type, be client authority.
	set_multiplayer_authority(str(name).to_int())
	#player_input.set_multiplayer_authority(str(name).to_int())

func _ready():
	add_to_group("Players")
		
	if is_multiplayer_authority():
		$Camera3D.current = true
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	else:
		add_to_group("Enemies")
		set_process(false)
		set_physics_process(false)
		
	LobbySystem.lobby_get_own()
		
	
func _input(event):
	if is_multiplayer_authority():
		if event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
			rotate_object_local(Vector3(1,0,0), deg_to_rad(event.relative.y * MOUSE_SENSITIVITY * -1))
			rotate_object_local(Vector3(0,1,0), deg_to_rad(event.relative.x * MOUSE_SENSITIVITY * -1))
			
		if Input.is_action_just_pressed("ui_cancel"):
			if Input.get_mouse_mode() == Input.MOUSE_MODE_VISIBLE:
				Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
			else:
				Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

func _physics_process(_delta):
	if is_multiplayer_authority():
		# get all the axis inputs
		var input_dir = Input.get_vector("move_left", "move_right", "move_up", "move_down")
		var input_look = Input.get_vector("look_left", "look_right", "look_up", "look_down")
		var input_fr = Input.get_axis("move_forward", "move_back")
		var input_roll = Input.get_axis("roll_left", "roll_right")
		
		# yaw up/down
		rotate_object_local(Vector3(1,0,0), deg_to_rad(input_look.y * JOY_SENSITIVITY))
		# pitch left/right
		rotate_object_local(Vector3(0,1,0), deg_to_rad(input_look.x * JOY_SENSITIVITY * -1))
		# roll left/right
		rotate_object_local(Vector3(0,0,1), deg_to_rad(input_roll * JOY_SENSITIVITY) * 0.5)
		
		# finally, movement
		var direction = transform.basis * Vector3(-input_dir.x, -input_dir.y, -input_fr)
		
		velocity = SPEED * direction

		move_and_slide()

func update_nameplate(username: String):
	%Nameplate.text = username

func hitscanHit(damageVal : float, _hitscanDir : Vector3, _hitscanPos : Vector3, source = 1):
	@warning_ignore("narrowing_conversion")
	var _damage_successful = health_system.damage(damageVal, source)
	#if damage_successful:
		##Hub.emit_signal('hit')

func projectileHit(damageVal : float, _hitscanDir : Vector3, source = 1):
	# TODO: Projectile source & physics
	@warning_ignore("narrowing_conversion")
	var _damage_successful = health_system.damage(damageVal, source)
	#if damage_successful:
		#Hub.emit_signal('hit')
