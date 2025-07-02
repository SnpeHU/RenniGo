extends RigidBody2D

#成功时发出的信号，更新top_box,分数等信息
signal box_stabilized(box: Node2D)

# 添加冻结状态标记
var is_frozen: bool = false
var top_box: Node2D#当前需要判定的盒子

var is_beheld:bool = true #是否还没有释放

var live_timer:Timer

var main_scene:Node2D #主场景的引用

#动画
@export var disappear_duration: float = 1.0  # 消失动画持续时间
#TODO 还没有被释放时，箱子开启描边

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	live_timer = $Timer_live
	contact_monitor = true
	max_contacts_reported = 10
	body_entered.connect(_on_box_body_entered)

func _on_box_body_entered(body: Node) -> void:
	
	# 如果已经冻结，不再处理碰撞
	if is_frozen:
		return
		
		
	if body.is_in_group("Box"):

		if check_stability(body):
			freeze_body()
			box_stabilized.emit(self)
		else:
			pass
	

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
		
	
func freeze_body():
	# 设置冻结标记
	is_frozen = true
	
	# 立即停止所有运动
	linear_velocity = Vector2.ZERO
	angular_velocity = 0.0
	
	set_deferred("freeze", true)
	# 延迟关闭碰撞监听，防止重复触发
	call_deferred("set_contact_monitor", false)
	
func set_top_box(box:Node2D):
	top_box = box

#盒子稳定性判断
func check_stability(body: Node) -> bool:
	var result : bool = false
	var collision_shape = body.get_node("CollisionShape2D")# 如果碰撞的物体在"Box"组中，则判断是否在碰撞物体的上方
	if collision_shape and collision_shape.shape is RectangleShape2D:
			var shape = collision_shape.shape as RectangleShape2D
			var self_shape = get_node("CollisionShape2D").shape as RectangleShape2D
			# 计算两个盒子的距离
			if absf(self.global_transform.origin.y - body.global_transform.origin.y) >= (shape.size.y/2 + self_shape.size.y/2 - 10):
				if (absf(self.global_transform.origin.x - body.global_transform.origin.x) < shape.size.x/4 + self_shape.size.x/4) and (top_box == body):
					#调整旋转为0
					self.rotation = 0.0
					self.global_transform.origin.y = body.global_transform.origin.y - (shape.size.y/2 + self_shape.size.y/2)
					live_timer.stop()

					result = true
				else:
					#调整碰撞层级
					self.set_collision_mask_value(2, true)
					self.set_collision_mask_value(1, false)
					self.set_collision_layer_value(2, true)
					self.set_collision_layer_value(1, false)
					if self.global_transform.origin.x < body.global_transform.origin.x:
						#如在范围外则给一个向外的力
						linear_velocity.x = -100
						linear_velocity.y = -300
						angular_velocity = -2
					else:
						linear_velocity.x = 100
						linear_velocity.y = -300
						angular_velocity = 2
	
	return result



#被放下	
func put() -> void:
	is_beheld = false
	live_timer.start()


func _on_timer_live_timeout() -> void:
	# 创建消失动画
	var flicker_count := 3
	var flicker_interval := 0.2
	var total_flicker_time := flicker_count * flicker_interval * 2

	# 先创建用于闪烁的 tween
	var flicker_tween := create_tween()
	flicker_tween.set_parallel(false)  # 串行闪烁
	for i in flicker_count:
		flicker_tween.tween_property(self, "modulate:a", 0.0, flicker_interval).set_ease(Tween.EASE_IN_OUT)
		flicker_tween.tween_property(self, "modulate:a", 1.0, flicker_interval).set_ease(Tween.EASE_IN_OUT)

	# 闪烁结束后执行主消失动画
	flicker_tween.tween_callback(Callable(self, "_start_disappear_animation"))
	
	
func _start_disappear_animation() -> void:
	var tween = create_tween()
	tween.set_parallel(true)  # 允许多个动画同时进行
		
		# 缩小动画 - 从当前大小缩小到0
	var scale_tween = tween.tween_property(self, "scale", Vector2.ZERO, disappear_duration)
	scale_tween.set_ease(Tween.EASE_IN)
	scale_tween.set_trans(Tween.TRANS_BACK)
		
		# 旋转动画 - 旋转360度（2π弧度）
	#var current_rotation = rotation
	#var rotation_tween = tween.tween_property(self, "rotation", current_rotation + PI * 2, disappear_duration)
	#rotation_tween.set_ease(Tween.EASE_IN_OUT)
	#rotation_tween.set_trans(Tween.TRANS_CUBIC)
		
		# 透明度动画 - 从完全不透明到完全透明
	var fade_tween = tween.tween_property(self, "modulate:a", 0.0, disappear_duration)
	fade_tween.set_ease(Tween.EASE_OUT)
		
		# 动画结束后删除自己
	tween.tween_callback(Callable(self, "queue_free")).set_delay(disappear_duration)
