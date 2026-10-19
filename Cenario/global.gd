extends Node

var qtd_vidas     = 0
var fase_atual    = 0
var pontuacao     = 0
var musica_ligada = true
var valor_dano    = 0
var personagem    = null

func resetar_variaveis():
	qtd_vidas  = 10
	fase_atual = 1
	pontuacao  = 0
	valor_dano = 1

func _ready() -> void:	
	resetar_variaveis()
