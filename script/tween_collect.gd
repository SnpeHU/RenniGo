extends RefCounted
class_name TweenCollect

#闪烁两次
static func timeout_animation(target:Node2D, callback: Callable = Callable()) ->void:
	# 创建闪烁动画
	var flicker_count := 2# 2次闪烁
	var flicker_interval := 0.3# 闪烁间隔时间

	var tween = target.create_tween()

	if(target is Sprite2D):
		# 如果目标是Sprite，使用ShaderMaterial进行闪烁
		if target.material is ShaderMaterial:
			var material = target.material as ShaderMaterial

			for i in flicker_count:
				tween.tween_method(# 通过shader参数控制透明度
				func(alpha): material.set_shader_parameter("alpha",alpha),
				1.0, 0.0, flicker_interval
			).set_ease(Tween.EASE_IN_OUT)
			tween.tween_method(
				func(alpha): material.set_shader_parameter("alpha",alpha),
				0.0, 1.0, flicker_interval
			).set_ease(Tween.EASE_IN_OUT)
	else:
		# 如果目标不是Sprite，直接使用modulate属性进行闪烁
		for i in range(flicker_count):
			tween.tween_property(target, "modulate:a", 0.0, flicker_interval).set_ease(Tween.EASE_IN_OUT)
			tween.tween_property(target, "modulate:a", 1.0, flicker_interval).set_ease(Tween.EASE_IN_OUT)
	# 动画结束后的回调
	if callback.is_valid():
		tween.tween_callback(callback)
	
# 消失动画
static func disappear_animation(target: Node2D, callback: Callable = Callable()) -> void:
	var disappear_duration: float = 1.0  ## 消失动画持续时间
	
	var tween = target.create_tween()
	tween.set_parallel(true)  # 允许多个动画同时进行
		
	# 缩小动画 - 从当前大小缩小到0
	var scale_tween = tween.tween_property(target, "scale", Vector2.ZERO, disappear_duration)
	scale_tween.set_ease(Tween.EASE_IN)
	scale_tween.set_trans(Tween.TRANS_BACK)
		
	# 旋转动画 - 旋转360度（2π弧度）
	#var current_rotation = rotation
	#var rotation_tween = tween.tween_property(target, "rotation", current_rotation + PI * 2, disappear_duration)
	#rotation_tween.set_ease(Tween.EASE_IN_OUT)
	#rotation_tween.set_trans(Tween.TRANS_CUBIC)
		
	# 透明度动画 - 从完全不透明到完全透明
	var fade_tween = tween.tween_property(target, "modulate:a", 0.0, disappear_duration)
	fade_tween.set_ease(Tween.EASE_OUT)

	# 动画结束后的回调
	if callback.is_valid():
		tween.tween_callback(callback).set_delay(disappear_duration)

#出现动画
static func appear_animation(target: Node2D, callback: Callable = Callable()) -> void:
	# 设置初始状态
	target.scale = Vector2.ZERO
	target.modulate.a = 0.0

	var appear_duration: float = 1.0  ## 出现动画持续时间
	var tween = target.create_tween()
	tween.set_parallel(true)  # 允许多个动画同时进行
	# 缩放动画 - 从0缩放到当前大小
	var scale_tween = tween.tween_property(target, "scale", Vector2.ONE, appear_duration)
	scale_tween.set_ease(Tween.EASE_OUT)
	scale_tween.set_trans(Tween.TRANS_BACK)

	# 透明度动画 - 从完全透明到完全不透明
	var fade_tween = tween.tween_property(target, "modulate:a", 1.0, appear_duration)
	fade_tween.set_ease(Tween.EASE_IN)

	# 动画结束后的回调
	if callback.is_valid():
		tween.tween_callback(callback).set_delay(appear_duration)

#Control出现动画
static func appear_animation_control(target: Control, callback: Callable = Callable()) -> void:
	# 设置初始状态
	target.visible = true
	target.scale = Vector2.ZERO
	target.modulate.a = 0.0

	var appear_duration: float = 1.0  ## 出现动画持续时间
	var tween = target.create_tween()
	tween.set_parallel(true)  # 允许多个动画同时进行
	# 缩放动画 - 从0缩放到当前大小
	var scale_tween = tween.tween_property(target, "scale", Vector2.ONE, appear_duration)
	scale_tween.set_ease(Tween.EASE_OUT)
	scale_tween.set_trans(Tween.TRANS_BACK)

	# 透明度动画 - 从完全透明到完全不透明
	var fade_tween = tween.tween_property(target, "modulate:a", 1.0, appear_duration)
	fade_tween.set_ease(Tween.EASE_IN)

	# 动画结束后的回调
	if callback.is_valid():
		tween.tween_callback(callback).set_delay(appear_duration)
