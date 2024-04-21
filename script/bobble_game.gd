extends Node2D

@export var bobble_set : Array[PackedScene];

const MAX_ROTATION_ABSOLUTE = deg_to_rad(80);
const ROTATION_SPEED = 3.0;
const LAUNCH_SPEED_MAGNITUDE = 600;

const RAYCAST_COLLISION_LAYER = 0b0010;
const BOBBLE_COLLISION_LAYER = 0b0001;

var static_bobble_blueprint : PackedScene = preload("res://scene/static_bobble.tscn");
var current_rotation = 0;

@export var dot_textures : Array[Texture2D];
var dot_texture_index : int = 0;
const dot_seconds_per_cycle : float = 0.2;
var elapsed_seconds_for_dot : float = 0;

@export var cell_count_horizontal = 7;
var bubble_radius : float;
var row_height : float;

var row_start_offset : int = 0;


var help_lines = [];

var bubble_grid : Array[Array];


func _ready():
	bubble_radius = ($BackgroundSprite.get_rect().size[0] * $BackgroundSprite.global_scale[0]) / (2 * cell_count_horizontal);
	row_height = sqrt(3) * bubble_radius;
	add_hitboxes_for_help_lines();
	init_grid();


func _process(delta):
	var speed_multiplier = 1.0;
	if Input.is_action_pressed("shift"):
		speed_multiplier = 0.2;
	
	if Input.is_action_pressed("left"):
		try_rotate_left(delta, speed_multiplier);
	if Input.is_action_pressed("right"):
		try_rotate_right(delta, speed_multiplier);
	if Input.is_action_just_pressed("up"):
		fire_bobble();
	
	update_help_lines(delta);
	
	$Tray/Gun/GunBarrel.rotation = self.current_rotation;

func _physics_process(delta):
	calculate_raycast_help_lines();

func update_help_lines(delta):
	elapsed_seconds_for_dot += delta;
	if elapsed_seconds_for_dot >= dot_seconds_per_cycle:
		elapsed_seconds_for_dot -= dot_seconds_per_cycle;
	
	for c in $HelpLines.get_children():
		$HelpLines.remove_child(c);
			
	for coord in help_lines:
		var new_line = Line2D.new();
		$HelpLines.add_child(new_line);
		new_line.texture = dot_textures[int(round((elapsed_seconds_for_dot / dot_seconds_per_cycle) * (dot_textures.size() - 1)))];
		new_line.begin_cap_mode = Line2D.LINE_CAP_ROUND;
		new_line.end_cap_mode = Line2D.LINE_CAP_ROUND;
		new_line.texture_mode = Line2D.LINE_TEXTURE_TILE;
		new_line.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED;
		new_line.add_point(new_line.to_local(coord[0]));
		new_line.add_point(new_line.to_local(coord[1]));
		
	
func add_hitboxes_for_help_lines():
	var left_wall = $Hitborder/LeftWall.duplicate();
	var right_wall = $Hitborder/RightWall.duplicate();
	var top_wall = $Hitborder/TopWall.duplicate();
	
	left_wall.add_to_group("rayflector");
	right_wall.add_to_group("rayflector");
	
	left_wall.get_child(0).debug_color = Color(0.2, 1.0, 0.7, 0.8);
	right_wall.get_child(0).debug_color = Color(0.2, 1.0, 0.7, 0.8);
	top_wall.get_child(0).debug_color = Color(0.2, 1.0, 0.7, 0.8);
	
	left_wall.collision_layer = RAYCAST_COLLISION_LAYER;
	right_wall.collision_layer = RAYCAST_COLLISION_LAYER;
	top_wall.collision_layer = RAYCAST_COLLISION_LAYER;
	top_wall.collision_mask = RAYCAST_COLLISION_LAYER;
	
	
	$Hitborder.add_child(left_wall);
	$Hitborder.add_child(right_wall);
	$Hitborder.add_child(top_wall);

	left_wall.global_position = $Hitborder/LeftWall.global_position + Vector2(bubble_radius, 0);
	right_wall.global_position = $Hitborder/RightWall.global_position + Vector2(-bubble_radius, 0);
	top_wall.global_position = $Hitborder/TopWall.global_position + Vector2(0, bubble_radius);
	
	
func init_grid():
	var max_rows = ($BackgroundSprite.get_rect().size[1] * $BackgroundSprite.global_scale[1]) / row_height;
	# Increase max rows just to be extra safe in case of OOB or near OOB shots
	max_rows = int(max_rows * 1.2);

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
	static_bobble.collision_layer |= RAYCAST_COLLISION_LAYER; 

	static_bobble.scale_bobble(bubble_radius);
	add_child(static_bobble);
	var x_pos = $Hitborder/LeftWall/CollisionShape2D.global_transform.origin.x + bobble_x;
	var y_pos = $Hitborder/TopWall/CollisionShape2D.global_position.y + \
				($Hitborder/TopWall/CollisionShape2D.shape.get_rect().size.y * $Hitborder/TopWall/CollisionShape2D.global_scale[1]) / 2 + \
				bubble_radius + bobble_y;
				
	static_bobble.global_position = Vector2(x_pos, y_pos);
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
	center_of_bobble[0] -= $Hitborder/LeftWall/CollisionShape2D.global_transform.origin.x
	
	var row_number : int = round((center_of_bobble[1] - 2 * bubble_radius) / row_height);
	var is_small_row : bool = (row_number - row_start_offset) % 2 == 1;
	var column_number : int;
	
	if is_small_row:
		column_number = round((center_of_bobble[0] - bubble_radius) / (2 * bubble_radius)) - 1;
	else:
		column_number = round((center_of_bobble[0])/ (2 * bubble_radius)) - 1;

	bubble_grid[row_number][column_number] = 1;
	return Vector2(column_number,row_number);


# Only call in _physics_process()
func calculate_raycast_help_lines():
	help_lines = [];
	var direction = 1;
	var cast = individual_raycast($Tray/Gun/GunBase.global_position, direction, null);
	help_lines.append([cast[0], cast[1]]);

	while cast[2]:
		direction = -1 if direction == 1 else 1;
		cast = individual_raycast(cast[1], direction, cast[3]);
		if cast == null:
			break;
		
		help_lines.append([cast[0], cast[1]]);
	
func individual_raycast(start_pos, direction, last_collider_rid):
	var space_state = get_world_2d().direct_space_state;
	var ray_cast_start = start_pos;
	var ray_cast_direction = Vector2(direction * sin(self.current_rotation), -cos(self.current_rotation));
	
	# The large number here helps approximate the true line sufficiently. 
	# Without this the direction is correct, but the alignment is off.
	var query;
	if last_collider_rid == null:
		query = PhysicsRayQueryParameters2D.create(ray_cast_start, 100000000 * ray_cast_direction, RAYCAST_COLLISION_LAYER | BOBBLE_COLLISION_LAYER);
	else:
		query = PhysicsRayQueryParameters2D.create(ray_cast_start, 100000000 * ray_cast_direction, RAYCAST_COLLISION_LAYER | BOBBLE_COLLISION_LAYER, [last_collider_rid]);
	var result = space_state.intersect_ray(query);
	
	if result.size() == 0:
		return null;
	
	var should_cast_again = result.collider.is_in_group("rayflector");

	return [ray_cast_start, result.position, should_cast_again, result.rid];
