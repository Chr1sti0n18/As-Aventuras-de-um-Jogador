extends Node2D

func _process(delta: float) -> void:
	$ParallaxBackground.scroll_base_offset.x -= 0.2
