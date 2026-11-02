extends Node2D

func _process(_delta: float) -> void:
	$Label.text = " X " + str(Global.qtd_vidas)
	$Invencibilidade.visible = Global.invencibilidade
