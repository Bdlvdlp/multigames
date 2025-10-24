extends Node3D
class_name GestionnairePartie

## Scènes préchargées
@export var scene_palet: PackedScene
@export var scene_maitre: PackedScene

## Références
@onready var controleur_lancer: ControleurLancer = $ControleurLancer
@onready var hud: HudLancer = $HudLancer
@onready var zone_lancement: Marker3D = $ZoneLancement

## Palets en jeu
var palets_bleus: Array[Palet] = []
var palets_rouges: Array[Palet] = []
var maitre: Maitre = null

## État du jeu
enum PhaseJeu { PLACEMENT_MAITRE, JEU_PALETS, FIN_MANCHE }
var phase_actuelle: PhaseJeu = PhaseJeu.PLACEMENT_MAITRE

var joueur_actuel: int = 1  # 1 = Bleu, 2 = Rouge
var palets_lances: int = 0
var tentatives_maitre: int = 0

## Scores
var score_joueur1: int = 0
var score_joueur2: int = 0

func _ready() -> void:
	# Créer les palets (4 bleus + 4 rouges)
	_creer_palets()
	
	# Créer le maître
	_creer_maitre()
	
	# Connecter les signaux
	controleur_lancer.palet_lance.connect(_on_palet_lance)
	
	# Commencer la partie
	_commencer_partie()

func _creer_palets() -> void:
	#Crée les 8 palets (4 bleus + 4 rouges)#
	for i in range(4):
		# Palet bleu
		var palet_bleu = scene_palet.instantiate() as Palet
		palet_bleu.couleur = Palet.CouleurPalet.BLEU
		add_child(palet_bleu)
		palets_bleus.append(palet_bleu)
		palet_bleu.visible = false
		
		# Palet rouge
		var palet_rouge = scene_palet.instantiate() as Palet
		palet_rouge.couleur = Palet.CouleurPalet.ROUGE
		add_child(palet_rouge)
		palets_rouges.append(palet_rouge)
		palet_rouge.visible = false

func _creer_maitre() -> void:
	#Crée le maître#
	maitre = scene_maitre.instantiate() as Maitre
	add_child(maitre)
	maitre.visible = false

func _commencer_partie() -> void:
	#Démarre une nouvelle partie
	phase_actuelle = PhaseJeu.PLACEMENT_MAITRE
	tentatives_maitre = 0
	joueur_actuel = 1
	
	# Mettre à jour le HUD
	hud.mettre_a_jour_scores(score_joueur1, score_joueur2)
	hud.afficher_message("Joueur 1 commence - Placement du maître", 3.0)
	
	print("=== NOUVELLE PARTIE ===")
	print("Phase : Placement du maître")
	_placer_maitre()

func _placer_maitre() -> void:
	#Place le maître à la zone de lancement
	tentatives_maitre += 1
	
	if tentatives_maitre > 3:
		print("Joueur %d a échoué 3 fois, changement de joueur" % joueur_actuel)
		hud.afficher_message("Joueur %d a raté 3 fois ! Changement de joueur" % joueur_actuel, 3.0)
		joueur_actuel = 2 if joueur_actuel == 1 else 1
		tentatives_maitre = 1
	
	print("Joueur %d - Tentative %d/3 pour placer le maître" % [joueur_actuel, tentatives_maitre])
	
	# Mettre à jour le HUD avec le nombre de tentatives restantes
	var tentatives_restantes = 4 - tentatives_maitre
	hud.mettre_a_jour_joueur(joueur_actuel, tentatives_restantes, 3)
	
	maitre.global_position = zone_lancement.global_position
	maitre.visible = true
	maitre.reinitialiser()
	
	# Préparer le lancer du maître
	controleur_lancer.preparer_lancer(maitre)
	hud.afficher_visee()

func _on_palet_lance(palet: RigidBody3D, _force: float, _direction: Vector3) -> void:
	"""Callback quand un palet est lancé"""
	print("Palet lancé - attente arrêt...")
	hud.masquer()
	
	# Attendre que le palet s'arrête
	var timeout = 100  # Max 10 secondes
	while palet.linear_velocity.length() > 0.1 and timeout > 0:
		await get_tree().create_timer(0.1).timeout
		timeout -= 1
	
	print("Palet arrêté à: %s" % palet.global_position)
	
	# Vérifier si c'était le maître
	if palet is Maitre:
		var distance = maitre.distance_a_planche()
		print("Distance du maître à la planche: %.3f m" % distance)
		
		# Vérifier que le maître est VRAIMENT sur la planche (pas juste qu'il l'a touchée)
		if maitre.est_vraiment_sur_planche():
			print("✓ Maître placé avec succès !")
			hud.afficher_message("Maître placé ! Début du jeu", 2.0)
			phase_actuelle = PhaseJeu.JEU_PALETS
			palets_lances = 0
			joueur_actuel = 1  # Le joueur 1 commence à lancer ses palets
			_lancer_prochain_palet()
		else:
			print("✗ Maître raté (hors planche)")
			_placer_maitre()
	else:
		# C'est un palet normal
		var palet_jeu = palet as Palet
		if maitre != null:
			var distance = palet_jeu.distance_au_maitre(maitre)
			print("Distance du palet au maître: %.3f m" % distance)
		
		# Continuer avec le prochain palet
		palets_lances += 1
		if palets_lances < 8:  # 4 palets x 2 joueurs
			_lancer_prochain_palet()
		else:
			# Dernier palet lancé - il est déjà arrêté (on arrive ici après le while ci-dessus)
			print("Dernier palet arrêté, calcul des scores...")
			_fin_manche()

func _lancer_prochain_palet() -> void:
	#Prépare le prochain palet à lancer
	var palet_a_lancer: Palet
	
	# Calculer l'index du palet pour le joueur actuel
	# palets_lances compte tous les palets (alternés entre J1 et J2)
	# Donc index_palet = nombre de palets déjà lancés par ce joueur
	var index_palet = palets_lances / 2  # gdlint: ignore=integer-division
	
	# Calculer combien de palets restent APRÈS ce lancer (donc -1)
	var palets_restants = 4 - index_palet - 1
	
	if joueur_actuel == 1:
		palet_a_lancer = palets_bleus[index_palet]
		print("Tour Joueur BLEU - Palet %d/4" % (index_palet + 1))
	else:
		palet_a_lancer = palets_rouges[index_palet]
		print("Tour Joueur ROUGE - Palet %d/4" % (index_palet + 1))
	
	# Mettre à jour le HUD avec les palets restants APRÈS ce lancer
	hud.mettre_a_jour_joueur(joueur_actuel, palets_restants, 4)
	
	palet_a_lancer.global_position = zone_lancement.global_position
	palet_a_lancer.visible = true
	palet_a_lancer.reinitialiser()
	
	controleur_lancer.preparer_lancer(palet_a_lancer)
	hud.afficher_visee()
	
	# Alterner les joueurs après chaque lancer (règle du palet breton)
	var ancien_joueur = joueur_actuel
	joueur_actuel = 2 if joueur_actuel == 1 else 1
	
	# Message de changement de joueur (sauf au premier lancer)
	if palets_lances > 0:
		await get_tree().create_timer(0.5).timeout
		hud.afficher_message("Au tour du Joueur %d" % ancien_joueur, 2.0)

func _fin_manche() -> void:
	#Calcule les scores et termine la manche
	print("=== FIN DE MANCHE ===")
	
	# Calculer la distance de chaque palet au maître
	var distances_bleu: Array[float] = []
	var distances_rouge: Array[float] = []
	
	for palet in palets_bleus:
		if palet.visible:
			var dist = palet.distance_au_maitre(maitre)
			distances_bleu.append(dist)
			print("Palet BLEU: %.3f m" % dist)
	
	for palet in palets_rouges:
		if palet.visible:
			var dist = palet.distance_au_maitre(maitre)
			distances_rouge.append(dist)
			print("Palet ROUGE: %.3f m" % dist)
	
	# Trouver le palet le plus proche
	var min_bleu = distances_bleu.min() if distances_bleu.size() > 0 else INF
	var min_rouge = distances_rouge.min() if distances_rouge.size() > 0 else INF
	
	# Le joueur avec le palet le plus proche marque des points
	var points = 0
	var gagnant = 0

	if min_bleu < min_rouge:
		gagnant = 1
		for dist in distances_bleu:
			if dist < min_rouge:
				points += 1
		score_joueur1 += points
	elif min_rouge < min_bleu:
		gagnant = 2
		for dist in distances_rouge:
			if dist < min_bleu:
				points += 1
		score_joueur2 += points

	# Mettre à jour les scores
	hud.mettre_a_jour_scores(score_joueur1, score_joueur2)

	print("Score final: Joueur 1: %d - Joueur 2: %d" % [score_joueur1, score_joueur2])

	# Afficher le résultat de la manche sur le HUD
	await hud.afficher_fin_manche(score_joueur1, score_joueur2, gagnant, points)

	# Masquer tous les palets et le maître pour la prochaine manche
	for palet in palets_bleus:
		palet.visible = false
	for palet in palets_rouges:
		palet.visible = false
	maitre.visible = false

	# Recommencer une nouvelle manche
	print("\n=== NOUVELLE MANCHE ===")
	hud.afficher_message("Nouvelle manche !", 2.0)
	await get_tree().create_timer(2.0).timeout

	# Réinitialiser pour la prochaine manche
	phase_actuelle = PhaseJeu.PLACEMENT_MAITRE
	tentatives_maitre = 0
	palets_lances = 0
	joueur_actuel = 1

	_placer_maitre()

func _process(_delta: float) -> void:
	# Mettre à jour l'affichage de la force et du réticule
	if controleur_lancer.palet_actuel != null:
		hud.mettre_a_jour_force(controleur_lancer.get_pourcentage_force())
		hud.mettre_a_jour_reticule(
			controleur_lancer.get_angle_horizontal(),
			controleur_lancer.get_angle_vertical()
		)
