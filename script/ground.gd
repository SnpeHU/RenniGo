extends Area2D

func _ready() -> void:
	monitoring = true


func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("StaticBox"):
		return
	#if body.is_in_group("Box"):
		## 如果是盒子，直接删除
		#body.queue_free()
