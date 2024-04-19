extends Node2D

@export var bobble_set : Array[PackedScene];

const MAX_ROTATION_ABSOLUTE = deg_to_rad(80);
const ROTATION_SPEED = 3.0;
const LAUNCH_SPEED_MAGNITUDE = 600;
# When instantiated the static bobbles are somehow smaller than the rigid body bobbles. This is the work around for that.
const STATIC_RIGIDBODY_SCALING_FACTOR = 1.0;


var static_bobble_blueprint : PackedScene = preload("res://scene/static_bobble.tscn");
var current_rotation = 0;

@export var cell_count_horizontal = 3;
var bubble_radius : float;
var row_height : float;

var row_start_offset : int = 0;

var bubble_grid : Array[Array];

# change this to be dynamic. This simply needs to be big enough that players never exceed it
var max_rows : int = 20;

func _ready():
	bubble_radius = ($BackgroundSprite.get_rect().size[0] * $BackgroundSprite.global_scale[0]) / (2 * cell_count_horizontal);
	row_height = sqrt(3) * bubble_radius;
	print("radius %s" % [bubble_radius]);
	init_grid();


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
	

func init_grid():
	for i in range(max_rows):
		var new_row;
		if i % 2 == 0:
			# Make big row
			new_row = [];
			for j in range(cell_count_horizontal):
				new_row.append(0);
		else:
			# Make small row
			new_row = [];
			for j in range(cell_count_horizontal - 1):
				new_row.append(0); 
			
		bubble_grid.append(new_row);
	
	
func launch_random_bobble():
	var new_bobble = bobble_set.pick_random().instantiate();
	# Adjust scale
	new_bobble.scale_bobble(bubble_radius);
	# Disable draw (re-enable in phyics loop)
	add_child(new_bobble);
	new_bobble.connect("impacted", freeze_bobble_in_place)
	new_bobble.global_position = $Tray/Gun/GunBase.global_position;
	new_bobble.set_velocity(Vector2(LAUNCH_SPEED_MAGNITUDE * sin(self.current_rotation), LAUNCH_SPEED_MAGNITUDE* -cos(self.current_rotation)));
	
	
func fire_bobble():
	$Tray/Gun/ShootSound.play();
	launch_random_bobble();
	
func try_rotate_left(delta, speed_multiplier = 1.0):
	self.current_rotation = clampf(self.current_rotation - (delta * ROTATION_SPEED * speed_multiplier), -MAX_ROTATION_ABSOLUTE, MAX_ROTATION_ABSOLUTE);
	
func try_rotate_right(delta, speed_multiplier = 1.0):
	self.current_rotation = clampf(self.current_rotation + (delta * ROTATION_SPEED * speed_multiplier), -MAX_ROTATION_ABSOLUTE, MAX_ROTATION_ABSOLUTE);
		
	
func freeze_bobble_in_place(bobble):
	var cell_indeces = get_nearest_empty_cell(bobble.global_position + Vector2(bubble_radius, bubble_radius));
	lock_bobble_to_grid(bobble, cell_indeces);
	
func lock_bobble_to_grid(bobble, indeces):
	var is_small_row : bool = indeces[1] % 2 == 1;
	var bobble_x : float;
	var bobble_y : float;
	
	if is_small_row:
		bobble_x = bubble_radius * 2 * (indeces[0] + 1);
	else:
		bobble_x = bubble_radius + bubble_radius * 2 * (indeces[0]);
	
	bobble_y = indeces[1] * row_height;
	
	
	var static_bobble = static_bobble_blueprint.instantiate();
	

	static_bobble.scale_bobble(STATIC_RIGIDBODY_SCALING_FACTOR * bubble_radius);
	add_child(static_bobble);
	static_bobble.global_position = Vector2($Hitborder/LeftWall/CollisionShape2D.global_transform.origin.x + bobble_x, $Hitborder/TopWall/CollisionShape2D.global_transform.origin.y + bubble_radius + bobble_y);
	static_bobble.get_child(0).get_child(0).texture = bobble.get_child(0).get_child(0).texture;
	static_bobble.get_child(0).get_child(1).texture = bobble.get_child(0).get_child(1).texture;
	
	# TODO: Set properties identifying node type on new static node.
	bobble.queue_free();

func print_grid():
	for row in bubble_grid:
		print(row);

func get_nearest_empty_cell(center_of_bobble) -> Vector2i:
	
	var row_width = $Hitborder/RightWall/CollisionShape2D.global_transform.origin.x - $Hitborder/LeftWall/CollisionShape2D.global_transform.origin.x;
	var top_border_ypos = $Hitborder/TopWall/CollisionShape2D.global_transform.origin.y + $Hitborder/TopWall/CollisionShape2D.shape.get_rect().size[1];
	
	# Make origin y-coord relative to top barrier
	center_of_bobble[1] -= top_border_ypos;

	# Make origin x-coord relative to left border
	# print("Original origin: %s, %s - New Y: %s" % [origin[0], origin[1], origin[0] - $Hitborder/LeftWall/CollisionShape2D.global_transform.origin.x])
	center_of_bobble[0] -= $Hitborder/LeftWall/CollisionShape2D.global_transform.origin.x
	
	print("Impact y: %s" % [center_of_bobble[1] - 2 * bubble_radius])
	var row_number : int = round((center_of_bobble[1] - 2 * bubble_radius) / row_height);
	var is_small_row : bool = (row_number - row_start_offset) % 2 == 1;
	var column_number : int;
	
	if is_small_row:
		print("small")
		column_number = round((center_of_bobble[0] - bubble_radius) / (2 * bubble_radius)) - 1;
	else:
		print("big")
		column_number = round((center_of_bobble[0])/ (2 * bubble_radius)) - 1;

	bubble_grid[row_number][column_number] = 1;
	print_grid();
	return Vector2(column_number,row_number);
