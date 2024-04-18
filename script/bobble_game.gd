extends Node2D

@export var bobble_set : Array[PackedScene];
var MAX_ROTATION_ABSOLUTE = deg_to_rad(80);
var ROTATION_SPEED = 3.0;
var LAUNCH_SPEED_MAGNITUDE = 600;

var current_rotation = 0;




func _ready():
	pass; 


func _process(delta):
	var speed_multiplier = 1.0;
	if Input.is_action_pressed("shift"):
		speed_multiplier = 0.5;
	
	if Input.is_action_pressed("left"):
		try_rotate_left(delta, speed_multiplier);
	if Input.is_action_pressed("right"):
		try_rotate_right(delta, speed_multiplier);
	if Input.is_action_just_pressed("up"):
		fire_bobble();
		
	
		
	$Tray/Gun/GunBarrel.rotation = self.current_rotation;
		
		
func spawn_frozen_bobble():
	var new_bobble = bobble_set.pick_random().instantiate();
	add_child(new_bobble);
	new_bobble.global_position = $Tray/Gun/GunBase.global_position;
	new_bobble.launch(Vector2(LAUNCH_SPEED_MAGNITUDE * sin(self.current_rotation), LAUNCH_SPEED_MAGNITUDE* -cos(self.current_rotation)));
		
func fire_bobble():
	$Tray/Gun/ShootSound.play();
	spawn_frozen_bobble();
	
func try_rotate_left(delta, speed_multiplier = 1.0):
	self.current_rotation = clampf(self.current_rotation - (delta * ROTATION_SPEED * speed_multiplier), -MAX_ROTATION_ABSOLUTE, MAX_ROTATION_ABSOLUTE);
	
func try_rotate_right(delta, speed_multiplier = 1.0):
	self.current_rotation = clampf(self.current_rotation + (delta * ROTATION_SPEED * speed_multiplier), -MAX_ROTATION_ABSOLUTE, MAX_ROTATION_ABSOLUTE);
		
	
