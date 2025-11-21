extends Control

@onready var line_edit_j1: LineEdit = $Panel/VBoxContainer/VBoxJ1/LineEditJ1
@onready var line_edit_j2: LineEdit = $Panel/VBoxContainer/VBoxJ2/LineEditJ2

func _on_btn_retour_pressed() -> void:
	get_tree().change_scene_to_file("res://menus/menu_selection.tscn")

func _on_btn_jouer_pressed() -> void:
	var nom1 = line_edit_j1.text
	var nom2 = line_edit_j2.text
	
	if nom1.strip_edges().is_empty():
		nom1 = "Joueur 1"
	if nom2.strip_edges().is_empty():
		nom2 = "Joueur 2"
		
	# Charger la scène du jeu
	var scene_jeu = load("res://jeux/palet_breton/scenes/bar_palet.tscn")
	var instance_jeu = scene_jeu.instantiate()
	
	# Le script GestionnairePartie est attaché à la racine de la scène BarPalet
	# On peut donc caster directement et définir les variables
	if instance_jeu is GestionnairePartie:
		instance_jeu.nom_joueur1 = nom1
		instance_jeu.nom_joueur2 = nom2
	else:
		print("ERREUR: La scène chargée n'est pas un GestionnairePartie")
	
	# Option : Changer la scène racine
	var root = get_tree().root
	
	# Ajouter à l'arbre après avoir configuré les variables
	# Comme ça, _ready() utilisera les bonnes valeurs
	root.add_child(instance_jeu)
	
	# Supprimer le menu actuel
	queue_free()
	
	# Définir la nouvelle scène comme scène courante
	get_tree().current_scene = instance_jeu
