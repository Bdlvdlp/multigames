extends Control
class_name HudLancer

## Références aux éléments UI
@onready var barre_force: ProgressBar = $PanelContainer/VBoxContainer/BarreForce
@onready var label_instructions: Label = $PanelContainer/VBoxContainer/LabelInstructions
@onready var mini_map: SubViewportContainer = $MiniMap
@onready var sub_viewport: SubViewport = $MiniMap/SubViewport
@onready var reticule: Control = $Reticule
@onready var label_message: Label = $LabelMessage

## Course aux points
@onready var label_score_manche_j1: Label = $CoursePoints/MarginContainer/VBox/HBoxIndicateurs/LabelScoreMancheJ1
@onready var label_score_manche_j2: Label = $CoursePoints/MarginContainer/VBox/HBoxIndicateurs/LabelScoreMancheJ2

## Joueur 1
@onready var label_score_j1: Label = $InfoJoueur1/MarginContainer/VBox/HBoxScore/LabelScoreJ1
@onready var label_nom_j1: Label = $InfoJoueur1/MarginContainer/VBox/HBoxNom/LabelNomJ1
@onready var palet1_j1: ColorRect = $InfoJoueur1/MarginContainer/VBox/HBoxPalets/PaletsRestants/Palet1J1
@onready var palet2_j1: ColorRect = $InfoJoueur1/MarginContainer/VBox/HBoxPalets/PaletsRestants/Palet2J1
@onready var palet3_j1: ColorRect = $InfoJoueur1/MarginContainer/VBox/HBoxPalets/PaletsRestants/Palet3J1
@onready var palet4_j1: ColorRect = $InfoJoueur1/MarginContainer/VBox/HBoxPalets/PaletsRestants/Palet4J1
@onready var icone_j1: ColorRect = $InfoJoueur1/MarginContainer/VBox/HBoxNom/IconeJoueur1

## Joueur 2
@onready var label_score_j2: Label = $InfoJoueur2/MarginContainer/VBox/HBoxScore/LabelScoreJ2
@onready var label_nom_j2: Label = $InfoJoueur2/MarginContainer/VBox/HBoxNom/LabelNomJ2
@onready var palet1_j2: ColorRect = $InfoJoueur2/MarginContainer/VBox/HBoxPalets/PaletsRestants/Palet1J2
@onready var palet2_j2: ColorRect = $InfoJoueur2/MarginContainer/VBox/HBoxPalets/PaletsRestants/Palet2J2
@onready var palet3_j2: ColorRect = $InfoJoueur2/MarginContainer/VBox/HBoxPalets/PaletsRestants/Palet3J2
@onready var palet4_j2: ColorRect = $InfoJoueur2/MarginContainer/VBox/HBoxPalets/PaletsRestants/Palet4J2
@onready var icone_j2: ColorRect = $InfoJoueur2/MarginContainer/VBox/HBoxNom/IconeJoueur2

var palets_j1: Array[ColorRect] = []
var palets_j2: Array[ColorRect] = []

# Noms des joueurs (pour l'affichage des messages)
var nom_j1: String = "Joueur 1"
var nom_j2: String = "Joueur 2"

func _ready() -> void:
	# Configurer la barre de progression
	barre_force.min_value = 0
	barre_force.max_value = 100
	barre_force.value = 0
	barre_force.show_percentage = false
	
	# Initialiser les tableaux de palets
	palets_j1 = [palet1_j1, palet2_j1, palet3_j1, palet4_j1]
	palets_j2 = [palet1_j2, palet2_j2, palet3_j2, palet4_j2]
	
	# Afficher le HUD pour tester
	visible = true
	
	print("HUD initialisé - Mini-map active")

func mettre_a_jour_noms(nom1: String, nom2: String) -> void:
	nom_j1 = nom1
	nom_j2 = nom2
	label_nom_j1.text = nom1
	label_nom_j2.text = nom2

func afficher_visee() -> void:
	visible = true
	mini_map.visible = true
	reticule.visible = true
	barre_force.value = 0
	barre_force.modulate = Color.GREEN
	label_instructions.text = "Souris pour viser | ESPACE pour lancer"

func masquer() -> void:
	# Ne masquer que les éléments de visée, pas tout le HUD
	# La mini-map et les infos joueurs restent visibles
	reticule.visible = false
	barre_force.value = 0
	barre_force.modulate = Color.GREEN
	label_instructions.text = ""

func mettre_a_jour_force(pourcentage: float) -> void:
	barre_force.value = pourcentage
	
	# Changer la couleur selon la force
	if pourcentage < 33:
		barre_force.modulate = Color.GREEN
	elif pourcentage < 66:
		barre_force.modulate = Color.YELLOW
	else:
		barre_force.modulate = Color.RED

func mettre_a_jour_reticule(angle_horizontal: float, angle_vertical: float) -> void:
	# Déplace le réticule en fonction des angles de visée
	# Calculer le déplacement du réticule
	# angle_horizontal : -30 à +30 degrés
	# angle_vertical : 5 à 45 degrés
	
	var viewport_size = get_viewport_rect().size
	var center_x = viewport_size.x / 2
	var center_y = viewport_size.y / 2
	
	# Déplacement horizontal : 3 pixels par degré
	var deplacement_x = angle_horizontal * 3.0
	
	# Déplacement vertical : -2 pixels par degré (vers le haut quand angle augmente)
	# On centre sur 25° (milieu entre 5 et 45)
	var angle_vertical_centre = 25.0
	var deplacement_y = -(angle_vertical - angle_vertical_centre) * 2.0
	
	reticule.position.x = center_x + deplacement_x
	reticule.position.y = center_y + deplacement_y

func mettre_a_jour_joueur(numero_joueur: int, palets_restants: int, _palets_total: int) -> void:
	"""Met à jour l'affichage du joueur actuel et ses palets"""
	# Mettre en évidence le joueur actif
	if numero_joueur == 1:
		icone_j1.modulate = Color(1, 1, 1, 1)  # Pleine luminosité
		icone_j2.modulate = Color(1, 1, 1, 0.3)  # Atténué
	else:
		icone_j1.modulate = Color(1, 1, 1, 0.3)  # Atténué
		icone_j2.modulate = Color(1, 1, 1, 1)  # Pleine luminosité
	
	# Afficher les palets restants visuellement
	var palets_array = palets_j1 if numero_joueur == 1 else palets_j2
	for i in range(4):
		if i < palets_restants:
			palets_array[i].modulate = Color(1, 1, 1, 1)  # Visible
		else:
			palets_array[i].modulate = Color(1, 1, 1, 0.2)  # Grisé/utilisé

func mettre_a_jour_scores(score1: int, score2: int) -> void:
	"""Met à jour l'affichage des scores (manches gagnées)"""
	label_score_j1.text = "%d/2" % score1
	label_score_j2.text = "%d/2" % score2

func mettre_a_jour_scores_manche(points_j1: int, points_j2: int) -> void:
	"""Met à jour les points de la manche en cours (0-7)"""
	label_score_manche_j1.text = str(points_j1)
	label_score_manche_j2.text = str(points_j2)

func afficher_message(message: String, duree: float = 3.0) -> void:
	#Affiche un message temporaire au centre de l'écran
	label_message.text = message
	label_message.visible = true
	
	# Créer un timer pour masquer le message
	await get_tree().create_timer(duree).timeout
	label_message.visible = false
	label_message.text = ""

func afficher_fin_manche(score1: int, score2: int, gagnant: int, points: int) -> void:
	#Affiche le résultat de la manche sur le HUD
	var msg = "=== FIN DE MANCHE ===\n"
	msg += "Points : %s = %d | %s = %d\n" % [nom_j1, score1, nom_j2, score2]
	if gagnant == 0:
		msg += "Égalité - aucun point marqué"
	elif gagnant == 1:
		msg += "%s (🔵) marque %d point%s !" % [nom_j1, points, ("s" if points > 1 else "")]
	else:
		msg += "%s (🔴) marque %d point%s !" % [nom_j2, points, ("s" if points > 1 else "")]
	label_message.text = msg
	label_message.visible = true
	await get_tree().create_timer(4.0).timeout
	label_message.visible = false
	label_message.text = ""

func afficher_fin_partie(score1: int, score2: int) -> void:
	# Affiche la fin de partie sur le HUD
	var msg = "=== FIN DE PARTIE ===\n"
	msg += "Manches gagnées :\n%s (🔵) : %d\n%s (🔴) : %d\n\n" % [nom_j1, score1, nom_j2, score2]
	if score1 > score2:
		msg += "🏆 %s remporte la partie ! 🏆" % nom_j1
	elif score2 > score1:
		msg += "🏆 %s remporte la partie ! 🏆" % nom_j2
	else:
		msg += "Match nul !"
	label_message.text = msg
	label_message.visible = true
	await get_tree().create_timer(6.0).timeout
	label_message.visible = false
	label_message.text = ""
