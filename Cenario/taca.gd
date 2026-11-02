extends Area2D

@export var amplitude_levitacao: float = 5.0
@export var periodo_levitacao: float = 2.4
var coletada := false
var tempo_levitacao := 0.0
var posicao_sprite: Vector2
var posicao_colisao: Vector2

func _ready() -> void:
	body_entered.connect(coletar)
	posicao_sprite = $Sprite2D.position
	posicao_colisao = $CollisionShape2D.position

func _physics_process(delta: float) -> void:
	if coletada:
		return
	tempo_levitacao += delta
	var deslocamento := Vector2(0.0, sin(tempo_levitacao * TAU / maxf(periodo_levitacao, 0.1)) * amplitude_levitacao)
	$Sprite2D.position = posicao_sprite + deslocamento
	$CollisionShape2D.position = posicao_colisao + deslocamento
	if pode_coletar():
		for corpo in get_overlapping_bodies():
			coletar(corpo)

func pode_coletar() -> bool:
	var fase := get_parent()
	return not fase.has_method("pode_coletar_taca") or fase.pode_coletar_taca()

func coletar(corpo: Node2D) -> void:
	if coletada or Global.partida_encerrada or Global.qtd_vidas <= 0 or not pode_coletar():
		return
	if corpo.is_in_group("jogador"):
		coletada = true
		set_deferred("monitoring", false)
		# Mantem o conjunto visivel ate a tela fechar.
		Global.finalizar_partida(true)
