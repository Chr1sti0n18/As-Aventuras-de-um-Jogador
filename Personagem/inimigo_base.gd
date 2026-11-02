extends CharacterBody2D

@export var vida_maxima: int = 2
@export var alcance_ativacao: float = 680.0
var vida: int
var derrotado := false
var protecao := 0.0
var tween_dano: Tween
var som_dano := "acerto"
var area_origem := -1
var limites_area := Vector2(-INF, INF)

func definir_area(indice: int, inicio: float, fim: float) -> void:
	area_origem = indice
	limites_area = Vector2(inicio + 40.0, fim - 40.0)

func limitar_a_area() -> void:
	if area_origem >= 0:
		global_position.x = clampf(global_position.x, limites_area.x, limites_area.y)

func _ready() -> void:
	vida = vida_maxima
	add_to_group("inimigos")

func atualizar_protecao(delta: float) -> void:
	protecao = maxf(0.0, protecao - delta)

func jogador_perto() -> bool:
	var jogador = Global.personagem
	return is_instance_valid(jogador) and absf(jogador.global_position.x - global_position.x) < alcance_ativacao

func receber_dano(quantidade: int = 1, _origem: String = "bola") -> bool:
	if derrotado or protecao > 0.0:
		return false
	vida -= quantidade
	Global.tocar_som(som_dano)
	protecao = 0.35
	piscar_vermelho()
	if vida <= 0:
		derrotar()
	return true

func piscar_vermelho() -> void:
	if tween_dano != null:
		tween_dano.kill()
	tween_dano = create_tween()
	for i in 3:
		tween_dano.tween_property($Sprite2D, "modulate", Color(1.0, 0.2, 0.2), 0.06)
		tween_dano.tween_property($Sprite2D, "modulate", Color.WHITE, 0.06)

func derrotar() -> void:
	derrotado = true
	velocity = Vector2.ZERO
	set_physics_process(false)
	$AnimationPlayer.stop()
	set_deferred("collision_layer", 0)
	set_deferred("collision_mask", 0)
	for area in find_children("*", "Area2D", true, false):
		area.set_deferred("monitoring", false)
		area.set_deferred("monitorable", false)
	Global.pontuacao += 100
	var saida = create_tween()
	saida.tween_interval(0.28)
	saida.tween_property(self, "modulate:a", 0.0, 0.18)
	saida.tween_callback(get_parent().queue_free)

func alinhar_pes(altura: float) -> void:
	$Sprite2D.position.y = altura - $Sprite2D.region_rect.size.y * $Sprite2D.scale.y * 0.5
