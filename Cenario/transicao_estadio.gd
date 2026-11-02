extends Node2D

signal transicao_iniciada
signal transicao_concluida

@export var fronteira_x: float = 6516.0
@export var largura_mapa: int = 13032
@export var tempo_escurecer: float = 0.25
@export var tempo_no_tunel: float = 0.18
@export var tempo_revelar: float = 0.30
@export_enum("Tunel", "Viaduto") var tipo_passagem: int = 0
@export var titulo_passagem: String = "TÚNEL DE ACESSO"
@export var mensagem_entrada: String = "ENTRANDO NO ESTÁDIO"
@export var mensagem_saida: String = "SAINDO DO ESTÁDIO"
@export var texto_placa_entrada: String = "ACESSO AO CAMPO →"
@export var texto_placa_saida: String = "← SAÍDA DO ESTÁDIO"

enum Lado { EXTERIOR, CAMPO }
var lado := Lado.EXTERIOR
var transicionando := false
var ultimo_x := 0.0

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	add_to_group("passagens_cenario")
	$Tela.visible = false
	$PlacaEntrada.text = texto_placa_entrada
	$PlacaSaida.text = texto_placa_saida
	if tipo_passagem == 1:
		$PlacaEntrada.position = Vector2(-235, 267)
		$PlacaEntrada.size = Vector2(225, 30)
		$PlacaSaida.position = Vector2(10, 267)
		$PlacaSaida.size = Vector2(225, 30)
	var jogador = Global.personagem
	if is_instance_valid(jogador):
		ultimo_x = jogador.global_position.x
		definir_lado(Lado.CAMPO if ultimo_x >= fronteira_x else Lado.EXTERIOR)

func _physics_process(_delta: float) -> void:
	var jogador = Global.personagem
	if transicionando or get_tree().paused or not is_instance_valid(jogador):
		return
	var x: float = jogador.global_position.x
	# Permite abrir/testar qualquer trecho no editor sem simular uma travessia.
	if absf(x - ultimo_x) > 700.0:
		definir_lado(Lado.CAMPO if x >= fronteira_x else Lado.EXTERIOR)
	elif lado == Lado.EXTERIOR and x >= fronteira_x - 48.0 and jogador.velocity.x > 0.0:
		atravessar(Lado.CAMPO)
	elif lado == Lado.CAMPO and x <= fronteira_x + 48.0 and jogador.velocity.x < 0.0:
		atravessar(Lado.EXTERIOR)
	ultimo_x = x

func definir_lado(novo: Lado) -> void:
	lado = novo
	var jogador = Global.personagem
	if not is_instance_valid(jogador):
		return
	var camera: Camera2D = jogador.get_node("Camera2D")
	var limite_esquerdo := 0
	var limite_direito := largura_mapa
	# Todas as passagens compartilham os limites da regiao atual.
	# Uma passagem nao pode reexibir a emenda que a outra ja ocultou.
	for passagem in get_tree().get_nodes_in_group("passagens_cenario"):
		var fronteira: int = int(passagem.fronteira_x)
		if jogador.global_position.x >= fronteira:
			limite_esquerdo = maxi(limite_esquerdo, fronteira)
		else:
			limite_direito = mini(limite_direito, fronteira)
	camera.limit_left = limite_esquerdo
	camera.limit_right = limite_direito
	camera.reset_smoothing()
	camera.force_update_scroll()

func atravessar(destino: Lado) -> void:
	if transicionando:
		return
	var fase := get_parent()
	if fase.has_method("pode_atravessar") and not fase.pode_atravessar(fronteira_x, destino == Lado.CAMPO):
		return
	var jogador = Global.personagem
	if not is_instance_valid(jogador):
		return
	transicionando = true
	transicao_iniciada.emit()
	var velocidade_anterior: Vector2 = jogador.velocity
	get_tree().paused = true
	$Tela.visible = true
	$Tela/Escurecimento.modulate.a = 0.0
	$Tela/Escurecimento/Titulo.text = titulo_passagem + "\n" + (mensagem_entrada if destino == Lado.CAMPO else mensagem_saida)
	var fechar := create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	fechar.tween_property($Tela/Escurecimento, "modulate:a", 1.0, tempo_escurecer)
	await fechar.finished
	if not is_instance_valid(jogador):
		get_tree().paused = false
		return
	# A emenda e a mudanca da camera so acontecem com a tela coberta.
	jogador.global_position.x = fronteira_x + (80.0 if destino == Lado.CAMPO else -80.0)
	jogador.reset_physics_interpolation()
	definir_lado(destino)
	await get_tree().create_timer(tempo_no_tunel, true).timeout
	var abrir := create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	abrir.tween_property($Tela/Escurecimento, "modulate:a", 0.0, tempo_revelar)
	await abrir.finished
	if is_instance_valid(jogador):
		jogador.velocity = velocidade_anterior
		ultimo_x = jogador.global_position.x
	$Tela.visible = false
	get_tree().paused = false
	transicionando = false
	transicao_concluida.emit()

func _draw() -> void:
	if tipo_passagem == 1:
		desenhar_viaduto()
		return
	# Estrutura do acesso: formas nativas, sem alterar as imagens originais.
	draw_rect(Rect2(-184, 402, 368, 218), Color("#202c39"))
	draw_rect(Rect2(-160, 448, 320, 172), Color("#080e17"))
	for i in range(6):
		var recuo := float(i) * 13.0
		draw_line(Vector2(-151 + recuo, 448), Vector2(-151 + recuo, 620), Color("#14212e"), 3.0)
		draw_line(Vector2(151 - recuo, 448), Vector2(151 - recuo, 620), Color("#14212e"), 3.0)
	draw_rect(Rect2(-190, 390, 380, 16), Color("#70808c"))
	draw_rect(Rect2(-190, 440, 380, 10), Color("#536574"))
	draw_rect(Rect2(-184, 450, 24, 170), Color("#556675"))
	draw_rect(Rect2(160, 450, 24, 170), Color("#556675"))
	draw_rect(Rect2(-184, 605, 24, 15), Color("#303f4c"))
	draw_rect(Rect2(160, 605, 24, 15), Color("#303f4c"))
	for x in [-134.0, 134.0]:
		draw_rect(Rect2(x - 12, 453, 24, 5), Color("#f4d987"))
	draw_line(Vector2(-160, 620), Vector2(160, 620), Color("#a4a99d"), 3.0)

func desenhar_viaduto() -> void:
	# Estrutura em primeiro plano e sombra sob o tabuleiro do viaduto.
	draw_rect(Rect2(-235, 298, 470, 322), Color("#111b27"))
	draw_rect(Rect2(-185, 310, 370, 310), Color("#080f19"))
	draw_rect(Rect2(-255, 250, 510, 14), Color("#788995"))
	draw_rect(Rect2(-250, 264, 500, 36), Color("#344758"))
	draw_rect(Rect2(-250, 298, 500, 12), Color("#1b2d3d"))
	for x in range(-244, 250, 36):
		draw_rect(Rect2(x, 220, 5, 30), Color("#8899a5"))
	draw_rect(Rect2(-255, 221, 510, 5), Color("#acb9c1"))
	for x in [-235.0, 185.0]:
		draw_rect(Rect2(x, 310, 50, 310), Color("#788994"))
		draw_rect(Rect2(x + 34, 310, 16, 310), Color("#4c606e"))
		draw_rect(Rect2(x - 5, 600, 60, 20), Color("#455866"))
		for y in range(505, 600, 24):
			draw_polygon(PackedVector2Array([Vector2(x, y), Vector2(x + 34, y - 10), Vector2(x + 34, y), Vector2(x, y + 10)]), PackedColorArray([Color("#dbc26d")]))
	draw_line(Vector2(-185, 620), Vector2(185, 620), Color("#91a1ab"), 3.0)
