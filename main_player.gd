extends CharacterBody2D

#=============================================================== MOVEMENT VALUES
const SPEED = 100
var can_grab: bool

#===================================================================== NODE REFS
@onready var dash_restriction = $dash_restriction
@onready var ray_cast_left = $rays/RayCastLeft
@onready var ray_cast_right = $rays/RayCastRight
@onready var grab_left = $rays/grab_left
@onready var grab_right = $rays/grab_right
@onready var g_left = $rays/g_left
@onready var g_right = $rays/g_right
@onready var collision_shape_2d = $CollisionShape2D

#==================================================== JUMPING AND GRAVITY VALUES
@export var JUMP_MAX = 2
@export var gravity = 980
@export var JUMP_VELOCITY = -250
var can_double_jump: bool
var JUMP_COUNT = 0


#==================================================================  DASH VALUES
@export var MAX_DASH = 2
var DASH_COUNT = 0
@export var DASH_DURATION = 500 #lerp(1000, 0, 0.1)
var DASH_TIMER = 3.0
var CURRENT_DASH_TIME = 1.0
var IS_DASHING = false 

#===================================================================================================

func handle_movement(delta):
	var direction = Input.get_action_strength("ui_right") - Input.get_action_strength("ui_left")
	var moving_speed = direction * SPEED 
	velocity.x = lerp(velocity.x, moving_speed, 0.2)

	position += velocity * delta # the gravity
	
#------everything dash------------------------------------------------------------------------------

	if Input.is_action_just_pressed("dash") and DASH_COUNT<MAX_DASH :
			#if velocity.x < -80 or velocity.x > 80: #for not dashing while being still because of lerp, but still exploitable
				dash(delta)

	if is_on_floor():
		DASH_COUNT = 0 #.......... reset dash
#---------------------------------------------------------- crouching ------------------------------

	if Input.is_action_pressed("ui_down"):
		collision_shape_2d.scale.y = 0.5
	else :
		collision_shape_2d.scale.y = 1
#---------------------------------------------------------------------------------------------------

func dash(_delta):
	
	IS_DASHING = true
	DASH_COUNT += 1
	velocity.y = 0
	velocity.x = DASH_DURATION if velocity.x > 0 else -DASH_DURATION # dash left or right
	
	if CURRENT_DASH_TIME <= DASH_TIMER:
		velocity.y = 0
		gravity = 0
		CURRENT_DASH_TIME += _delta
	else :
		gravity = 980
		velocity.y = 0

#
#func quickly_disable_gravity_for_debug():
	#if Input.is_action_pressed("stop gravity") :
		#gravity = 0
		#velocity.y = 0
	#else :
		#gravity = 980

#===================================================================================================
func handle_jump(delta):

	var _is_jumping = false

	
	if is_on_floor():
		JUMP_COUNT = 0

	if Input.is_action_just_pressed("jump"):
		if is_on_floor() or JUMP_COUNT<JUMP_MAX or can_grab :
			JUMP_COUNT += 1
			velocity.y = JUMP_VELOCITY
			_is_jumping = true #..........handles both jumps at once

	if not is_on_floor() and Input.is_action_just_released("jump") and velocity.y < 0:
		velocity.y = 0
		_is_jumping = false #.............fall down on action release


#-----------------WALL JUMP MECHANIC----------------------------------------------------------------

	if ray_cast_left.is_colliding() or ray_cast_right.is_colliding():
		var wall_jump = Vector2(300, -300)
		var wall_friction = Vector2(0, -300)
		var wall_jump_direction = 1
		DASH_COUNT = 1

		velocity = (velocity - wall_friction) * delta

		if Input.is_action_just_pressed("jump"):
			
			if ray_cast_left.is_colliding():
				wall_jump.x = wall_jump.x * wall_jump_direction
			if ray_cast_right.is_colliding():
				wall_jump.x = wall_jump.x * -wall_jump_direction
				
			velocity = wall_jump 
			
			JUMP_COUNT += 1
#----------------------------------ledge grab and climb---------------------------------------------

	can_grab = (g_left.is_colliding() == true and grab_left.is_colliding() == false) or (g_right.is_colliding() == true and grab_right.is_colliding() == false)
	if can_grab == true :
		
		var wall_jump = Vector2(300, -300)
		var wall_jump_direction = 1
		
		velocity.y = 0
		gravity = 0
		
		if Input.is_action_just_pressed("ui_up"):
			velocity.y = JUMP_VELOCITY * 3
		if Input.is_action_just_pressed("jump"):
			velocity = wall_jump * wall_jump_direction

#-------------------- disables the ray if not moving------------------------------------------------
	if Input.is_action_pressed("ui_left") or Input.is_action_pressed("ui_right") :
		grab_left.enabled = true
		g_left.enabled = true
		grab_right.enabled = true
		g_right.enabled = true
	else :
		grab_left.enabled = false
		g_left.enabled = false
		grab_right.enabled = false
		g_right.enabled = false



func add_gravity(delta):
	
	var quick_fall = 0
	
	if Input.is_action_pressed("ui_down") and velocity.y > 0 :
		quick_fall = 2000
	else:
		quick_fall = 0
	if not is_on_floor():
		velocity.y += (gravity + quick_fall) * delta

#============================================================= PROCESS FUNCTIONS

func _ready():
	pass

func _physics_process(delta):
	
	#quickly_disable_gravity_for_debug() 
	
	handle_movement(delta)
	handle_jump(delta)
	add_gravity(delta)
	move_and_slide()

