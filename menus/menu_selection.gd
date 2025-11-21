extends Control

func _ready() -> void:
	pass

func _on_btn_palet_breton_pressed() -> void:
	# Aller vers le menu de saisie des noms pour le Palet Breton
	get_tree().change_scene_to_file("res://menus/menu_noms_palet.tscn")

func _on_btn_quitter_pressed() -> void:
	get_tree().quit()
