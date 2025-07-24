extends Node2D

@export var center: Node2D
@export var respawn_pos: Node2D
@export var box_prefab: PackedScene = preload("res://scene2d/box2D.tscn") #盒子预制体

@export var inertia_factor: float = 1.0 #惯性系数，可以调节速度传递的强度

@export var radiusX: float = 200.0
@export var radiusY: float = 100.0
var timer_around #旋转计时器

var box_hold:Box#暂存新生成的box
var boxs_holder:Node2D#放下盒子后盒子将被放入此节点下
var previous_position: Vector2 #前一帧位置，用于计算速度
var current_velocity: Vector2 #当前速度

#中心点移动
@export var MOVE_SPEED = 2.0 # 用于跟随top_box的位置
@export var distance_to_topbox = 500 #距离顶部盒子的距离
var move_target: Vector2 

#signal update_current_box(current_box:Node2D, velocity:Vector2)
signal create_box(new_box:Box)

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	
	timer_around = $Timer_around
	# 初始化位置用于速度计算
	previous_position = respawn_pos.global_position
	
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	# 计算速度
	var current_position = respawn_pos.global_position
	if delta > 0:
		current_velocity = (current_position - previous_position) / delta
	previous_position = current_position
	
	#让respawn_pos绕center旋转,通过timer_around控制旋转速度
	if not timer_around.is_stopped():
		var angle = timer_around.time_left / timer_around.wait_time * 2 * PI
		respawn_pos.position.x = center.position.x + radiusX * cos(angle)
		respawn_pos.position.y = center.position.y + radiusY * sin(angle)

func _physics_process(delta: float) -> void:
	global_position = global_position.lerp(move_target,delta * MOVE_SPEED)

func create_box_at_respawn_pos():
	if(box_hold != null):
		return
	var box_instance = box_prefab.instantiate()
	if box_instance == null:
		return
	box_instance.is_beheld = true
	respawn_pos.add_child(box_instance)
	box_hold = box_instance
	
	create_box.emit(box_hold)

#放下盒子
func put_box_down():
	if(!box_hold.is_ready):
		return
		
	var applied_velocity = current_velocity * inertia_factor
	# 应用惯性速度
	box_hold.linear_velocity = applied_velocity
	box_hold.set_deferred("freeze", false)
	#update_current_box.emit(box_hold)
	box_hold.reparent(boxs_holder)
	box_hold.put()
	box_hold = null
	
	#创建新盒子
	create_box_at_respawn_pos()
	#print("Current box updated to: ", new_current_box.name, " with velocity: ", velocity)

#调整与顶部盒子的距离
func update_move_target(target:Vector2):
	move_target.y = target.y - distance_to_topbox
		
