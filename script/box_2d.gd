extends RigidBody2D
class_name Box

# 分数等级枚举
enum ScoreLevel {
	PERFECT,  # 完美
	EXCELLENT, # 优秀
	GOOD      # 好
}

#成功时发出的信号，更新top_box,分数等信息
signal box_stabilized(box: Box)
#盒子传出分数时发出的信号
signal box_score_emitted(box: Box,score_info: Dictionary)
#盒子掉落时发出的信号
signal box_fall_down()

#分数计算
const BASE_SCORE:int = 100 # 基础分数
const SCORE_MULTIPLIERS = {
	ScoreLevel.PERFECT: 2.0,   # 完美系数
	ScoreLevel.EXCELLENT: 1.5, # 优秀系数
	ScoreLevel.GOOD: 1.0       # 好系数
}
# 位置偏差阈值（像素）
const PERFECT_THRESHOLD: float = 5.0    # 完美范围
const EXCELLENT_THRESHOLD: float = 20.0  # 优秀范围

#状态标记
var is_frozen: bool = false## 添加冻结状态标记
var is_beheld:bool = true ##是否还没有释放
var is_ready:bool = false##用于判断出现动画是否播放
@export var is_top_box: bool = false ##是否是顶层盒子

@onready var live_timer:Timer = get_node_or_null("Timer_live")
@onready var smoke_emitter:GPUParticles2D = get_node_or_null("SmokeEmitter")
@onready var sprite:Sprite2D = get_node_or_null("Sprite2D")

#动画 
@export var smoke_speed_threshold: float = 0.0  ## 产生烟雾的最小速度阈值

#音效
@onready var impact_sounds:AudioStreamPlayer2D = $ImpactSoundStream
#修bug：高处时会导致位置偏移故记录上一帧位置修正
var pre_position:Vector2

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	contact_monitor = true
	max_contacts_reported = 10
	body_entered.connect(_on_box_body_entered)
	enable_outline(false)
	pre_position = self.global_position

	if sprite and sprite.material is ShaderMaterial:
		sprite.material = sprite.material.duplicate()
	
	# 初始化粒子发射器
	init_smokeEmitter()	

	TweenCollect.appear_animation(self,func(): 
		is_ready = true
		enable_outline(true)  # 出现动画结束后禁用轮廓	
	)
	


func _on_box_body_entered(body: Node) -> void:
	# 如果已经冻结，不再处理碰撞
	if is_frozen:
		return

	#var current_speed = linear_velocity.length()
	#if current_speed > smoke_speed_threshold:
	if body.is_in_group("Box"):
		impact_sounds.play()
		if check_stability(body):
			freeze_body()
			# 计算分数
			var score_info = calculate_score(body)
			# 使用 call_deferred 延迟发送信号
			call_deferred("emit_signal", "box_stabilized", self)
			#发出分数信号-分数计算器接收
			call_deferred("emit_signal", "box_score_emitted", self, score_info)
		else:
			# 如果判定失败，则施向外的力
			apply_out_force(body)
			call_deferred("emit_signal", "box_fall_down")
	

	create_smoke_effect()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if is_frozen:
		return
	pre_position = self.global_position
		
func freeze_body():
	# 设置冻结标记
	is_frozen = true
	
	# 立即停止所有运动
	linear_velocity = Vector2.ZERO
	angular_velocity = 0.0
	
	set_deferred("freeze", true)
	custom_integrator = true
	# 延迟关闭碰撞监听，防止重复触发
	call_deferred("set_contact_monitor", false)
	

#盒子稳定性判断
func check_stability(body: Box) -> bool:
	var result : bool = false
	if !body.is_top_box:
		return result
	
	var collision_shape = body.get_node("CollisionShape2D")# 如果碰撞的物体在"Box"组中，则判断是否在碰撞物体的上方
	if collision_shape and collision_shape.shape is RectangleShape2D:
			var shape = collision_shape.shape as RectangleShape2D
			var self_shape = get_node("CollisionShape2D").shape as RectangleShape2D
			# 计算两个盒子的距离
			if absf(self.global_position.y - body.global_position.y) >= (shape.size.y/2 + self_shape.size.y/2 - 10):
				if (absf(self.global_position.x - body.global_position.x) < shape.size.x/4 + self_shape.size.x/4):
					#调换is_top_box
					self.is_top_box = true
					body.is_top_box = false

					#调整旋转为0
					self.rotation = 0.0
					self.global_position.y = body.global_position.y - (shape.size.y/2 + self_shape.size.y/2)
					live_timer.stop()

					result = true
				else:
					#调整碰撞层级
					self.set_collision_mask_value(2, true)
					self.set_collision_mask_value(1, false)
					self.set_collision_layer_value(2, true)
					self.set_collision_layer_value(1, false)
					

	
	return result

# 计算分数
func calculate_score(target_box: Box) -> Dictionary:
	var score_info = {
		"level": ScoreLevel.GOOD,
		"base_score": BASE_SCORE,
		"multiplier": 1.0,
		"final_score": BASE_SCORE,
		"level_text": "好"
	}
	
	if not target_box:
		return score_info
	
	# 获取两个盒子的碰撞形状
	var target_collision_shape = target_box.get_node("CollisionShape2D")
	var self_collision_shape = get_node("CollisionShape2D")
	
	if not target_collision_shape or not self_collision_shape:
		return score_info
		
	if not (target_collision_shape.shape is RectangleShape2D and self_collision_shape.shape is RectangleShape2D):
		return score_info
	
	
	# 计算X轴上的位置偏差（中心点对齐程度）
	var x_offset = absf(self.global_position.x - target_box.global_position.x)
	
	# 计算理想的X轴对齐位置（两个盒子中心完全对齐）
	#var ideal_x_offset = 0.0
	
	# 根据偏差程度判断分数等级
	var score_level: ScoreLevel
	var level_text: String
	
	if x_offset <= PERFECT_THRESHOLD:
		score_level = ScoreLevel.PERFECT
		level_text = "完美"
	elif x_offset <= EXCELLENT_THRESHOLD:
		score_level = ScoreLevel.EXCELLENT
		level_text = "优秀"
	else:
		score_level = ScoreLevel.GOOD
		level_text = "好"
	
	# 计算最终分数
	var multiplier = SCORE_MULTIPLIERS[score_level]
	var final_score = int(BASE_SCORE * multiplier)
	
	# 更新分数信息
	score_info["level"] = score_level
	score_info["multiplier"] = multiplier
	score_info["final_score"] = final_score
	score_info["level_text"] = level_text
	score_info["x_offset"] = x_offset  # 额外信息，可用于调试
	
	return score_info

#施加力
func apply_out_force(body: Node) -> void:
	global_position = pre_position
	if is_frozen:
		return
	if self.global_position.x < body.global_position.x:
		#如在范围外则给一个向外的力
		linear_velocity.x = -100
		linear_velocity.y = -300
		angular_velocity = -2
	else:
		linear_velocity.x = 100
		linear_velocity.y = -300
		angular_velocity = 2

#被放下	
func put() -> void:
	is_beheld = false
	live_timer.start()
	enable_outline(false)
	
	#更改碰撞层
	self.set_collision_mask_value(1, true)
	self.set_collision_mask_value(2, false)
	self.set_collision_layer_value(1, true)
	self.set_collision_layer_value(2, false)
	

func _on_timer_live_timeout() -> void:
	TweenCollect.timeout_animation(sprite, Callable(self, "start_disappear_animation"))
	
func start_disappear_animation() -> void:
	TweenCollect.disappear_animation(self, Callable(self, "queue_free"))

func enable_outline(tag: bool):
	if sprite and sprite.material is ShaderMaterial:
		var material = sprite.material as ShaderMaterial
		material.set_shader_parameter("enable_outline", tag)

#初始化粒子发射器
func init_smokeEmitter() -> void:
	if smoke_emitter:
		smoke_emitter.emitting = false
		smoke_emitter.one_shot = true  # 一次性发射
		smoke_emitter.visible = false  # 初始时隐藏发射器

# 创建烟雾效果
func create_smoke_effect() -> void:
	if not smoke_emitter:
		return
	var new_smoke = smoke_emitter.duplicate()
	get_parent().add_child(new_smoke)
	new_smoke.global_position = self.global_position
	new_smoke.rotation = 0.0
	new_smoke.emitting = true
	new_smoke.visible = true  # 显示烟雾发射器
	new_smoke.restart()

	var timer = Timer.new()
	timer.wait_time = new_smoke.lifetime + 1.0  # 粒子生命周期 + 缓冲时间
	timer.one_shot = true
	timer.timeout.connect(func(): 
		if is_instance_valid(new_smoke):
			new_smoke.queue_free()
		timer.queue_free()
	)
	get_parent().add_child(timer)
	timer.start()
