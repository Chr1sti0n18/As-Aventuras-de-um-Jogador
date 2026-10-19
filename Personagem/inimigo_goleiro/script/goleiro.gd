extends CharacterBody2D

var velocidade       = 300
var direcao_inimigo2 = 1
var gravidade        = 10
var forcao_pulo      = 250

func _process(delta: float) -> void:
	velocity.y += gravidade
	#print(str($RayCast2D.get_collider().name))
	var personagem = get_tree().root.get_node("Fase/Jogador/Personagem")	
	var personagem_pos_x = personagem.global_position.x
	
	if (is_on_floor() and velocidade>0):
		if (global_position.x < personagem_pos_x):
			direcao_inimigo2 = 1
			$Sprite2D.flip_h = false
		else:
			direcao_inimigo2 = -1
			$Sprite2D.flip_h = true
		
		if ($RayCast2D.get_collider()!=null):
			if ($RayCast2D.get_collider().name=="Personagem"):
				$AnimationPlayer.play("atacando")
				velocity.y = -forcao_pulo
		else:
			$AnimationPlayer.play("correndo")
	
	if (velocidade==0):
		$AnimationPlayer.play("parado")
		
	velocity.x  = velocidade * direcao_inimigo2
	var visibleOnScreenPosX = $VisibleOnScreenNotifier2D.position.x
	$VisibleOnScreenNotifier2D.position.x = abs(visibleOnScreenPosX) * direcao_inimigo2
	
	move_and_slide()
	
func causar_dano_personagem(body: Node2D) -> void:
	if (body.name=="Personagem"):
		Global.qtd_vidas -= Global.valor_dano

func perseguir() -> void:
	velocidade = 300
	
func encerrar_perseguicao() -> void:
	velocidade = 0
