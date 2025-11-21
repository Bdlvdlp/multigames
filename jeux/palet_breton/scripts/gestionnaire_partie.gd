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

## Manches (BO3)
var manches_joueur1: int = 0
var manches_joueur2: int = 0

## Noms des joueurs
var nom_joueur1: String = "Joueur 1"
var nom_joueur2: String = "Joueur 2"

## Camera
@onready var camera: Camera3D = $Camera3D
var camera_initial_transform: Transform3D
var cible_camera: Node3D = null
var est_en_suivi_camera: bool = false
var offset_camera: Vector3 = Vector3(0, 2, 2.5) # Position relative au palet

func _ready() -> void:
	# Sauvegarder la position initiale de la caméra
	if camera:
		camera_initial_transform = camera.global_transform
	
	# Créer les palets (4 bleus + 4 rouges)
	_creer_palets()
	
	# Créer le maître
	_creer_maitre()
	
	# Connecter les signaux
	controleur_lancer.palet_lance.connect(_on_palet_lance)
	
	# Commencer la partie
	_commencer_partie()

func mettre_a_jour_noms_joueurs() -> void:
	# Méthode appelée depuis le menu pour forcer l'actualisation si nécessaire
	if hud:
		hud.mettre_a_jour_noms(nom_joueur1, nom_joueur2)

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
	score_joueur1 = 0
	score_joueur2 = 0
	manches_joueur1 = 0
	manches_joueur2 = 0
	phase_actuelle = PhaseJeu.PLACEMENT_MAITRE
	tentatives_maitre = 0
	joueur_actuel = 1
	
	# Mettre à jour le HUD
	hud.mettre_a_jour_noms(nom_joueur1, nom_joueur2)
	hud.mettre_a_jour_scores(manches_joueur1, manches_joueur2)
	hud.mettre_a_jour_scores_manche(0, 0)
	hud.afficher_message("%s commence - Placement du maître" % nom_joueur1, 3.0)
	
	print("=== NOUVELLE PARTIE (BO3 en 5 points) ===")
	print("Phase : Placement du maître")
	_placer_maitre()

func _get_nom_joueur_actuel() -> String:
	return nom_joueur1 if joueur_actuel == 1 else nom_joueur2

func _placer_maitre() -> void:
	#Place le maître à la zone de lancement
	tentatives_maitre += 1
	
	if tentatives_maitre > 3:
		print("%s a échoué 3 fois, changement de joueur" % _get_nom_joueur_actuel())
		hud.afficher_message("%s a raté 3 fois ! Changement de joueur" % _get_nom_joueur_actuel(), 3.0)
		joueur_actuel = 2 if joueur_actuel == 1 else 1
		tentatives_maitre = 1
	
	print("%s - Tentative %d/3 pour placer le maître" % [_get_nom_joueur_actuel(), tentatives_maitre])
	
	# Mettre à jour le HUD avec le nombre de tentatives restantes
	var tentatives_restantes = 4 - tentatives_maitre
	hud.mettre_a_jour_joueur(joueur_actuel, tentatives_restantes, 3)
	
	maitre.global_position = zone_lancement.global_position
	maitre.visible = true
	maitre.reinitialiser()
	
	# Réinitialiser la caméra
	_reset_camera()
	
	# Informer le contrôleur du joueur actuel
	controleur_lancer.definir_joueur_actuel(joueur_actuel)
	
	# Préparer le lancer du maître
	controleur_lancer.preparer_lancer(maitre)
	hud.afficher_visee()

func _on_palet_lance(palet: RigidBody3D, _force: float, _direction: Vector3) -> void:
	"""Callback quand un palet est lancé"""
	print("Palet lancé - attente arrêt...")
	hud.masquer()
	
	# Jouer le son de lancer
	var audio_lancer = $AudioLancer
	if audio_lancer:
		audio_lancer.pitch_scale = randf_range(0.95, 1.05)
		audio_lancer.play()
	
	# Activer le suivi caméra
	cible_camera = palet
	est_en_suivi_camera = true
	
	# Attendre que le palet s'arrête
	var timeout = 100  # Max 10 secondes
	while palet.linear_velocity.length() > 0.1 and timeout > 0:
		await get_tree().create_timer(0.1).timeout
		timeout -= 1
	
	print("Palet arrêté à: %s" % palet.global_position)
	
	# Arrêter le suivi caméra après un court délai pour bien voir où il est
	await get_tree().create_timer(1.0).timeout
	est_en_suivi_camera = false
	
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
			# Tous les palets ont été lancés - calculer les points de cette série
			print("Tous les palets lancés, calcul des points...")
			_calculer_points_serie()

func _lancer_prochain_palet() -> void:
	#Prépare le prochain palet à lancer
	# Réinitialiser la caméra avant le prochain lancer
	_reset_camera()
	
	var palet_a_lancer: Palet
	
	# Calculer l'index du palet pour le joueur actuel
	# palets_lances compte tous les palets (alternés entre J1 et J2)
	# Donc index_palet = nombre de palets déjà lancés par ce joueur
	var index_palet = palets_lances / 2 # gdlint: ignore=integer-division
	
	# Calculer combien de palets restent APRÈS ce lancer (donc -1)
	var palets_restants = 4 - index_palet - 1
	
	if joueur_actuel == 1:
		palet_a_lancer = palets_bleus[index_palet]
		print("Tour %s - Palet %d/4" % [nom_joueur1, index_palet + 1])
	else:
		palet_a_lancer = palets_rouges[index_palet]
		print("Tour %s - Palet %d/4" % [nom_joueur2, index_palet + 1])
	
	# Mettre à jour le HUD avec les palets restants APRÈS ce lancer
	hud.mettre_a_jour_joueur(joueur_actuel, palets_restants, 4)
	
	palet_a_lancer.global_position = zone_lancement.global_position
	palet_a_lancer.visible = true
	palet_a_lancer.reinitialiser()
	
	# Informer le contrôleur du joueur actuel AVANT de préparer le lancer
	controleur_lancer.definir_joueur_actuel(joueur_actuel)
	
	controleur_lancer.preparer_lancer(palet_a_lancer)
	hud.afficher_visee()
	
	# Alterner les joueurs après chaque lancer (règle du palet breton)
	var ancien_joueur = joueur_actuel
	var nom_ancien_joueur = nom_joueur1 if ancien_joueur == 1 else nom_joueur2
	joueur_actuel = 2 if joueur_actuel == 1 else 1
	
	# Message de changement de joueur (sauf au premier lancer)
	if palets_lances > 0:
		await get_tree().create_timer(0.5).timeout
		hud.afficher_message("Au tour de %s" % nom_ancien_joueur, 2.0)

func _calculer_points_serie() -> void:
	#Calcule les points après une série de palets et vérifie si la manche continue
	# Réinitialiser la caméra
	_reset_camera()
	
	print("=== CALCUL DES POINTS ===")
	
	# Calculer la distance de chaque palet au maître
	var distances_bleu: Array[float] = []
	var distances_rouge: Array[float] = []
	
	for palet in palets_bleus:
		if palet.visible:
			var dist = palet.distance_au_maitre(maitre)
			distances_bleu.append(dist)
			print("Palet %s: %.3f m" % [nom_joueur1, dist])
	
	for palet in palets_rouges:
		if palet.visible:
			var dist = palet.distance_au_maitre(maitre)
			distances_rouge.append(dist)
			print("Palet %s: %.3f m" % [nom_joueur2, dist])
	
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

	print("Points marqués cette série: %d" % points)
	print("Score actuel de la manche: %s: %d - %s: %d" % [nom_joueur1, score_joueur1, nom_joueur2, score_joueur2])

	# Mettre à jour l'affichage
	hud.mettre_a_jour_scores_manche(score_joueur1, score_joueur2)
	
	if gagnant > 0:
		var nom_gagnant = nom_joueur1 if gagnant == 1 else nom_joueur2
		hud.afficher_message("%s marque %d point%s !" % [nom_gagnant, points, ("s" if points > 1 else "")], 2.0)
		await get_tree().create_timer(2.0).timeout
	
	# Vérifier si un joueur a atteint 5 points
	if score_joueur1 >= 5 or score_joueur2 >= 5:
		_fin_manche()
	else:
		# La manche continue - masquer les palets et relancer
		print("La manche continue...")
		for palet in palets_bleus:
			palet.visible = false
		for palet in palets_rouges:
			palet.visible = false
		
		# Masquer le maître pour le replacer
		maitre.visible = false
		
		hud.afficher_message("Manche à %d - %d, on continue !" % [score_joueur1, score_joueur2], 2.0)
		await get_tree().create_timer(2.0).timeout
		
		# Replacer le maître avant de relancer les palets
		print("Replacement du maître pour la nouvelle série")
		phase_actuelle = PhaseJeu.PLACEMENT_MAITRE
		tentatives_maitre = 0
		_placer_maitre()

func _fin_manche() -> void:
	#Termine la manche et vérifie si la partie est finie
	print("=== FIN DE MANCHE ===")
	print("Score final de la manche: %s: %d - %s: %d" % [nom_joueur1, score_joueur1, nom_joueur2, score_joueur2])
	
	# Déterminer le gagnant de la manche
	var gagnant_manche = 0
	if score_joueur1 >= 5:
		gagnant_manche = 1
		manches_joueur1 += 1
		print("%s remporte la manche ! (Manches: %d-%d)" % [nom_joueur1, manches_joueur1, manches_joueur2])
		hud.mettre_a_jour_scores(manches_joueur1, manches_joueur2)
		hud.afficher_message("%s remporte la manche !" % nom_joueur1, 3.0)
	elif score_joueur2 >= 5:
		gagnant_manche = 2
		manches_joueur2 += 1
		print("%s remporte la manche ! (Manches: %d-%d)" % [nom_joueur2, manches_joueur1, manches_joueur2])
		hud.mettre_a_jour_scores(manches_joueur1, manches_joueur2)
		hud.afficher_message("%s remporte la manche !" % nom_joueur2, 3.0)
	else:
		print("Erreur: fin de manche sans gagnant (scores: %d-%d)" % [score_joueur1, score_joueur2])
	
	await get_tree().create_timer(3.0).timeout
	
	# Vérifier si un joueur a gagné 2 manches (BO3)
	if manches_joueur1 >= 2:
		print("=== %s REMPORTE LA PARTIE (2 manches) ===" % nom_joueur1)
		hud.afficher_message("%s remporte la partie !" % nom_joueur1, 5.0)
		await get_tree().create_timer(5.0).timeout
		# Retourner au menu ou recommencer
		_commencer_partie()
		return
	elif manches_joueur2 >= 2:
		print("=== %s REMPORTE LA PARTIE (2 manches) ===" % nom_joueur2)
		hud.afficher_message("%s remporte la partie !" % nom_joueur2, 5.0)
		await get_tree().create_timer(5.0).timeout
		# Retourner au menu ou recommencer
		_commencer_partie()
		return
	
	# Masquer tous les palets et le maître pour la prochaine manche
	for palet in palets_bleus:
		palet.visible = false
	for palet in palets_rouges:
		palet.visible = false
	maitre.visible = false

	# Le barman sert une bière au vainqueur de la manche
	if gagnant_manche > 0:
		await _servir_biere_au_vainqueur(gagnant_manche)
		await get_tree().create_timer(1.0).timeout

	# Recommencer une nouvelle manche
	print("\n=== NOUVELLE MANCHE ===")
	print("Score des manches: %s %d - %d %s" % [nom_joueur1, manches_joueur1, manches_joueur2, nom_joueur2])
	hud.afficher_message("Nouvelle manche !", 2.0)
	await get_tree().create_timer(2.0).timeout

	# Réinitialiser les scores pour la nouvelle manche
	score_joueur1 = 0
	score_joueur2 = 0
	hud.mettre_a_jour_scores(manches_joueur1, manches_joueur2)
	hud.mettre_a_jour_scores_manche(0, 0)
	
	# Réinitialiser pour la prochaine manche
	phase_actuelle = PhaseJeu.PLACEMENT_MAITRE
	tentatives_maitre = 0
	palets_lances = 0
	joueur_actuel = 1

	_placer_maitre()

func _servir_biere_au_vainqueur(numero_joueur: int) -> void:
	#Fait venir le barman pour servir une bière au vainqueur de la manche
	var barman = get_node_or_null("Barman")
	if not barman:
		print("Erreur: Barman introuvable")
		return
	
	print("Le barman va servir une bière au vainqueur !")
	
	# Le barman se déplace vers le controleur_lancer (position du joueur)
	if barman.has_method("servir_joueur"):
		barman.servir_joueur(controleur_lancer)
		
		# Attendre que le barman soit arrivé et ait servi
		await barman.biere_servie
		
		# Faire boire le vainqueur APRÈS l'attente
		# Important : on passe numero_joueur pour être sûr que c'est le bon joueur
		if controleur_lancer.has_method("boire_biere_force"):
			var nom_vainqueur = nom_joueur1 if numero_joueur == 1 else nom_joueur2
			print("Application de l'ivresse au joueur %d (%s)" % [numero_joueur, nom_vainqueur])
			controleur_lancer.boire_biere_force(numero_joueur)
			hud.afficher_message("%s boit une bière ! Hips !" % nom_vainqueur, 2.0)
			print("%s a bu une bière, son adresse est désormais réduite..." % nom_vainqueur)
			
			# Debug : afficher les taux d'ivresse des deux joueurs
			print("Taux ivresse J1: %.2f" % controleur_lancer.taux_ivresse_joueurs[1])
			print("Taux ivresse J2: %.2f" % controleur_lancer.taux_ivresse_joueurs[2])
	else:
		print("Erreur: Le barman n'a pas la méthode servir_joueur")

func _reset_camera() -> void:
	est_en_suivi_camera = false
	cible_camera = null
	
	# Retour fluide à la position initiale
	if camera and camera_initial_transform:
		var tween = create_tween()
		tween.tween_property(camera, "global_transform", camera_initial_transform, 1.0).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)

func _process(delta: float) -> void:
	# Mettre à jour l'affichage de la force et du réticule
	if controleur_lancer.palet_actuel != null:
		hud.mettre_a_jour_force(controleur_lancer.get_pourcentage_force())
		hud.mettre_a_jour_reticule(
			controleur_lancer.get_angle_horizontal(),
			controleur_lancer.get_angle_vertical()
		)
	
	# Gestion de la caméra
	if est_en_suivi_camera and cible_camera != null and camera != null:
		var target_pos = cible_camera.global_position + offset_camera
		# Garder la caméra un peu en hauteur et en arrière
		# On ne change pas trop le X pour éviter le mal de mer si le palet part sur le côté
		target_pos.x = cible_camera.global_position.x * 0.5 # Suivi partiel en X
		
		# Limiter la position de la caméra pour ne pas traverser les murs/plafond
		# Mur du fond à Z=5, on garde une marge (4.5)
		target_pos.z = min(target_pos.z, 4.5)
		# Plafond à Y=3, on garde une marge (2.8)
		target_pos.y = min(target_pos.y, 2.8)
		
		# Interpolation fluide
		camera.global_position = camera.global_position.lerp(target_pos, delta * 5.0)
		camera.look_at(cible_camera.global_position)
