extends Node2D

@export var move_range: float = 100.0  # 在原点周围移动的范围
@export var move_duration: float = 2.0  # 移动持续时间
@onready var boxs:Node2D = $Boxs


func _on_timer_timeout() -> void:
	# 在x轴原点周围随机选择一个位置
	var random_x = randf_range(-move_range, move_range)
	var target_position = Vector2(random_x, global_position.y)
	
	# Tween平滑移动
	var tween = create_tween()
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(self, "global_position", target_position, move_duration)
	#tween.tween_callback(func(): print("Car moved to position: ", global_position))
	
	#清楚boxs节点下的所有盒子
func clear_box() -> void:
	
	for child in boxs.get_children():
		if child.has_method("start_disappear_animation"):
			child.start_disappear_animation()
		else:
			child.queue_free()
		
