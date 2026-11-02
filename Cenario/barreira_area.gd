extends Node2D

var lado_positivo := false
var bloqueada := false
var corpo: StaticBody2D
var mensagem: Label

func _ready() -> void:
	z_index = 5
	corpo = StaticBody2D.new()
	corpo.collision_layer = 0
	corpo.collision_mask = 0
	add_child(corpo)
	var colisao := CollisionShape2D.new()
	var forma := RectangleShape2D.new()
	forma.size = Vector2(16, 1800)
	colisao.shape = forma
	corpo.add_child(colisao)
	mensagem = Label.new()
	mensagem.size = Vector2(350, 60)
	mensagem.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	mensagem.add_theme_font_size_override("font_size", 18)
	mensagem.add_theme_color_override("font_color", Color("#ffe563"))
	mensagem.add_theme_color_override("font_outline_color", Color("#092c22"))
	mensagem.add_theme_constant_override("outline_size", 5)
	add_child(mensagem)
	visible = false

func atualizar(restantes: int, x_jogador: float) -> void:
	var deve_bloquear := restantes > 0
	if deve_bloquear != bloqueada:
		bloqueada = deve_bloquear
		corpo.set_deferred("collision_layer", 16 if bloqueada else 0)
	visible = bloqueada
	mensagem.text = "PASSAGEM BLOQUEADA\nINIMIGOS RESTANTES: " + str(restantes)
	mensagem.position = Vector2(20 if lado_positivo else -370, 356)
	mensagem.visible = absf(x_jogador - global_position.x) < 440.0

func _draw() -> void:
	# Barreira de treino: a colisao impede tambem passar por cima com um pulo.
	draw_rect(Rect2(-12, 425, 24, 195), Color("#163b2e"))
	for y in range(429, 612, 24):
		draw_polygon(PackedVector2Array([Vector2(-12, y), Vector2(12, y + 10), Vector2(12, y + 22), Vector2(-12, y + 12)]), PackedColorArray([Color("#f9d54a")]))
	draw_rect(Rect2(-26, 610, 52, 10), Color("#f9d54a"))
