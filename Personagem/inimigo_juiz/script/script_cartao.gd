extends CharacterBody2D

var direcao    = 1 #  1 => Direita, -1 => Esquerda
var velocidade = 550

func _process(delta: float) -> void:
	velocity.x = velocidade * direcao
	velocity.y = 0
	move_and_slide()


func causar_dano_personagem(body: Node2D) -> void:
	if (body.name=="Personagem"):
		Global.qtd_vidas -= Global.valor_dano
		get_parent().queue_free()
		
		
		
		
		
	
