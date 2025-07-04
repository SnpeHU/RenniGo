extends Node2D

@export var box_prefab: PackedScene  = preload("res://scene2d/box2D.tscn")#盒子预制体
@export var box_respawnser_prefab:PackedScene  = preload("res://scene2d/box_respawnser.tscn")

@onready var boxs_node: Node2D = $Boxs; #存放盒子的节点
var box_respwanser: Node2D#搬运猫
@export var respwanser_initial_pos: Vector2#

@onready var car:Node2D = $Boxs/Car
@export var car_box: Node2D
@export var top_box: Node2D #最顶上的盒子，即需要与坠落的盒子判定的盒子，最初为Car
var current_box: Node2D;#坠落中的盒子

@export var camera: PhantomCamera2D
@export var camera_follow :Node2D #相机跟随节点
@export var follow_point_offset:float  = 200#与顶部盒子y坐标的偏移量

#TODO 分数计算，完美，优秀。。
var box_count:int = 0
var score:int = 0

#TODO 重置游戏


# Called when the node enters the scene tree for the first time.
func _ready() -> void:		
	car_box = $Boxs/Car/RigidBody2D
	top_box = $Boxs/Car/RigidBody2D
	
	#初始化盒子出生的
	init_respawnser()

	
		
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	
	pass

func _input(event: InputEvent) -> void:
				
	if event.is_action_pressed("put_down"):
		if(box_respwanser.box_hold):
			box_respwanser.put_box_down()
	
	#按R键重置游戏
	if event.is_action_pressed("reset_game"):
		reset()


	#if event is InputEventKey:
		#if event.is_action_pressed("drop"):
			#var pos = get_global_mouse_position()
			## 如果点击位置不是在盒子上，则创建一个新的盒子
			## 检查是否有盒子在鼠标位置，根据CollisionShape2D来判断
			#var space_state = get_world_2d().direct_space_state
			#var query = PhysicsPointQueryParameters2D.new()
			#query.position = pos
			#var result = space_state.intersect_point(query)
			## 检查是否点击到了盒子
			#var found_box = false
			#for item in result:
				#var collider = item.collider
				#if is_instance_valid(collider) and collider.is_in_group("Box"):
					#collider.queue_free()
					#found_box = true
					#break
			#
			## 如果没有点击到盒子，则创建新盒子
			#if not found_box:
				#create_box_at_position_debug(pos)	

#TODO 清空数据
func new_game():
	box_count = 0
	score = 0
	$HUD.update_data(box_count,score)

#测试用
func create_box_at_position_debug(pos:Vector2):
	var box_instance = box_prefab.instantiate()
	if box_instance == null:
		return
	box_instance.set_deferred("freeze",false)
	current_box = box_instance
	box_instance.global_position = pos
	box_instance.set_top_box(top_box)
	# 将盒子添加到场景中的Boxs节点下
	boxs_node.add_child(box_instance)
	

# 释放盒子时，更新current_box
func _on_update_current_box(new_current_box:Node2D, velocity:Vector2):
	current_box = new_current_box
	#设置当前盒子需要判定的盒子
	current_box.set_top_box(top_box)
	current_box.reparent(boxs_node)
	current_box.set_deferred("freeze", false)
	
	# 应用惯性速度
	if current_box is RigidBody2D:
		current_box.linear_velocity = velocity
	elif current_box.has_method("set_linear_velocity"):
		current_box.set_linear_velocity(velocity)
	
	#连接盒子的信号
	current_box.box_stabilized.connect(_on_box_stabilized)
	current_box.live_timer.timeout.connect(_on_box_falldown)
	
	print("Current box updated to: ", new_current_box.name, " with velocity: ", velocity)

# 当盒子成功下落时，更新top_box,更新摄像机跟随点,分数。。
func _on_box_stabilized(new_top_box: Node2D):
	top_box = new_top_box
	#重设父节点为car内的boxs节点
	top_box.reparent($Boxs/Car/Boxs)
	
	box_respwanser.create_box_at_respawn_pos()
	box_respwanser.update_move_target(top_box.global_position)
	#更新分数
	box_count += 1
	score += 100
	$HUD.update_data(box_count,score)
	#更新相机追踪点
	if(top_box.global_position.y < camera_follow.global_position.y + follow_point_offset):
		camera_follow.global_position.y = top_box.global_position.y - follow_point_offset
	#print("Top box updated to: ", new_top_box.name)


func _on_box_falldown():
	box_respwanser.create_box_at_respawn_pos()
	score -= 20
	$HUD.update_data(box_count,score)
	

func init_respawnser() -> void:
	if(box_respwanser != null):
		box_respwanser.queue_free()
		
	box_respwanser = box_respawnser_prefab.instantiate()
	add_child(box_respwanser)
	box_respwanser.global_position = respwanser_initial_pos
	box_respwanser.update_current_box.connect(_on_update_current_box)
	box_respwanser.create_box_at_respawn_pos()
	box_respwanser.update_move_target(car.global_position)

#重置游戏状态
func reset()->void:
	box_count = 0
	score = 0
	
	# 清理car上的盒子）
	car.clear_box()

	# 重置top_box为初始状态（car）
	if car_box != null:
		top_box = car_box
	
	# 重置current_box
	current_box = null
	
	# 重置相机位置
	if camera_follow != null:
		camera_follow.global_position = Vector2.ZERO
	
	# 删除box_respwanser
	box_respwanser.queue_free()
	init_respawnser()

	# 更新HUD显示
	if has_node("HUD"):
		$HUD.update_data(box_count, score)
	
	print("Game reset completed")
