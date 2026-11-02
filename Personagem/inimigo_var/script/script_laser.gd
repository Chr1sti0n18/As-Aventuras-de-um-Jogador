extends Node2D

var emissor: Node
var perigoso := false
var feixe_ativo := false

func _ready() -> void:
	$AnimationPlayer.animation_finished.connect(_ao_terminar_animacao)
	$AnimationPlayer.play("laser")

func _physics_process(_delta: float) -> void:
	if not is_instance_valid(emissor) or emissor.derrotado:
		queue_free()
		return
	if feixe_ativo:
		atualizar_colisao_feixe()
	var jogador = Global.personagem
	if not is_instance_valid(jogador):
		return
	var tocou_feixe: bool = feixe_ativo and $ZonaFeixe.overlaps_body(jogador)
	var tocou_circulo: bool = perigoso and $ZonaPerigo.overlaps_body(jogador)
	if tocou_feixe or tocou_circulo:
		# O proprio jogador impede dano duplicado e aplica sua protecao de 0.4 s.
		jogador.receber_dano(Global.valor_dano)

func atualizar_colisao_feixe() -> void:
	var sprite: Sprite2D = $SpriteFeixe
	var retangulo := sprite.get_rect()
	var centro_x: float = sprite.position.x + retangulo.get_center().x * sprite.scale.x
	var topo: float = sprite.position.y + retangulo.position.y * sprite.scale.y
	var base: float = minf(0.0, sprite.position.y + retangulo.end.y * sprite.scale.y)
	var meia_base: float = maxf(8.0, retangulo.size.x * absf(sprite.scale.x) * 0.3)
	var meia_ponta: float = maxf(4.0, meia_base * 0.1)
	var pontos := PackedVector2Array([
		Vector2(centro_x - meia_ponta, topo), Vector2(centro_x + meia_ponta, topo),
		Vector2(centro_x + meia_base, base), Vector2(centro_x - meia_base, base),
	])
	if $ZonaFeixe/CollisionPolygon2D.polygon != pontos:
		$ZonaFeixe/CollisionPolygon2D.polygon = pontos

# Os eventos da animacao separam mira, feixe e circulo residual.
func ativar_feixe() -> void:
	feixe_ativo = true

func desativar_feixe() -> void:
	feixe_ativo = false

func ativar() -> void:
	perigoso = true

func desativar() -> void:
	perigoso = false

func _ao_terminar_animacao(nome: StringName) -> void:
	if nome == &"laser":
		queue_free()
