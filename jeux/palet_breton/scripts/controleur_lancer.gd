extends Node3D
class_name ControleurLancer

## Référence au palet/maître à lancer
var palet_actuel: RigidBody3D = null

## Force de lancer
var force_lancer: float = 0.0

## Angle de visée horizontal (gauche/droite)
var angle_horizontal: float = 0.0

## Angle de visée vertical (haut/bas pour tir en cloche)
var angle_vertical: float = 0.0

## Force minimale et maximale
@export var force_min: float = 10.0
@export var force_max: float = 80.0

## Angle max de visée horizontal (en degrés)
@export var angle_horizontal_max: float = 30.0

## Angle vertical min/max (en degrés) - pour tir en cloche
@export var angle_vertical_min: float = 5.0
@export var angle_vertical_max: float = 90.0

## Vitesse de chargement de la force
@export var vitesse_charge: float = 50.0

## Sensibilité de la souris
@export var sensibilite_souris: float = 0.1  # Réduite de 0.3 à 0.1 pour plus de précision

## Est-on en train de viser ?
var est_en_train_de_viser: bool = false

## Direction de lancer calculée
var direction_lancer: Vector3 = Vector3.FORWARD

## Signal émis quand un palet est lancé
signal palet_lance(palet: RigidBody3D, force: float, direction: Vector3)

## Référence au barman
var barman: Node3D

func _ready() -> void:
	# Capturer la souris pour qu'elle ne sorte pas de la fenêtre
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	
	# Forcer le mapping de la touche E (au cas où)
	if not InputMap.has_action("interagir"):
		InputMap.add_action("interagir")
		var ev = InputEventKey.new()
		ev.physical_keycode = KEY_E
		InputMap.action_add_event("interagir", ev)
	
	# Tenter de trouver le barman
	# 1. Chercher un noeud "Barman" frère
	if get_parent().has_node("Barman"):
		barman = get_parent().get_node("Barman")
		print("Controleur: Barman trouvé par nom.")
	
	# NE PAS connecter le signal biere_servie ici
	# (la gestion est faite directement dans gestionnaire_partie.gd pour éviter
	# que le mauvais joueur boive à cause du changement de joueur_actuel)
	if not barman:
		print("Controleur: ERREUR CRITIQUE - Barman introuvable dans la scène !")
	else:
		print("Controleur: Barman trouvé et prêt")

func preparer_lancer(palet: RigidBody3D) -> void:
	"""Prépare le lancer d'un palet"""
	palet_actuel = palet
	force_lancer = force_min
	angle_horizontal = 0.0
	angle_vertical = 15.0  # Angle par défaut légèrement en l'air
	est_en_train_de_viser = false
	
	# S'assurer que la souris est capturée
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	
	# Direction initiale vers la planche (forward = +Z dans Godot)
	_calculer_direction()
	
	print("Prêt à lancer - Bougez la souris pour viser")
	print("Appuyez sur E pour appeler le barman")

func definir_joueur_actuel(numero_joueur: int) -> void:
	"""Définit quel joueur est en train de jouer (1 ou 2)"""
	joueur_actuel = numero_joueur
	print("Controleur: Joueur actuel = %d" % joueur_actuel)

func _input(event: InputEvent) -> void:
	# Gérer ECHAP pour libérer/capturer la souris
	if event.is_action_pressed("ui_cancel"):  # ECHAP
		if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		else:
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
		return
	
	# Interaction avec le barman (Touche E)
	if event.is_action_pressed("interagir"):
		if barman:
			if barman.has_method("servir_joueur"):
				barman.servir_joueur(self)
			else:
				print("Erreur: Le barman n'a pas la méthode servir_joueur")
		else:
			# Tentative de reconnexion de dernière minute
			if get_parent().has_node("Barman"):
				barman = get_parent().get_node("Barman")
				barman.servir_joueur(self)
			else:
				print("Erreur: Toujours pas de barman !")
	
	if palet_actuel == null:
		return
	
	# Viser avec la souris (seulement si capturée)
	if event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		# Mouvement horizontal (gauche/droite)
		var delta_x = event.relative.x
		angle_horizontal += delta_x * sensibilite_souris
		angle_horizontal = clamp(angle_horizontal, -angle_horizontal_max, angle_horizontal_max)
		
		# Mouvement vertical (haut/bas) - inversé pour intuitivité
		var delta_y = -event.relative.y  # Inversé : souris vers le haut = angle plus élevé
		angle_vertical += delta_y * sensibilite_souris
		angle_vertical = clamp(angle_vertical, angle_vertical_min, angle_vertical_max)
		
		# Recalculer la direction en fonction des deux angles
		_calculer_direction()

func _calculer_direction() -> void:
	#Calcule la direction de lancer en fonction des angles horizontal et vertical
	# Convertir les angles en radians
	var h_rad = deg_to_rad(angle_horizontal)
	var v_rad = deg_to_rad(angle_vertical)
	
	# Application de l'ivresse (bruit)
	var taux_ivresse = taux_ivresse_joueurs.get(joueur_actuel, 0.0)
	var noise_time = noise_time_joueurs.get(joueur_actuel, 0.0)
	if taux_ivresse > 0.0:
		var shake_amount = taux_ivresse * 10.0 # Degrés de tremblement max
		# Utilisation de sin/cos combinés pour un effet pseudo-aléatoire fluide
		var noise_h = sin(noise_time * 5.0) * cos(noise_time * 3.7) * shake_amount
		var noise_v = cos(noise_time * 4.2) * sin(noise_time * 2.9) * shake_amount
		
		h_rad += deg_to_rad(noise_h)
		v_rad += deg_to_rad(noise_v)
	
	# Direction de BASE : vers la planche = +Z dans notre scène
	# Pour une visée plus intuitive, on utilise une approche linéaire
	# au lieu de purement trigonométrique
	
	# Normaliser l'angle horizontal entre -1 et 1
	var h_normalized = angle_horizontal / angle_horizontal_max  # -1 à +1
	
	# Composante X linéaire basée sur l'angle normalisé
	# Facteur de 0.15 pour limiter la déviation (réduit de 0.5 à 0.15)
	var x = -h_normalized * 0.15  # Déviation latérale très réduite
	
	# Si ivresse, on ajoute aussi du bruit sur X directement pour plus d'imprédictibilité
	if taux_ivresse > 0.0:
		x += sin(noise_time * 8.0) * 0.05 * taux_ivresse
	
	# Composante Y pour le tir en cloche (garde le sin pour la parabole)
	var y = sin(v_rad)
	
	# Composante Z principale vers la planche (réduite si angle horizontal élevé)
	var z = cos(h_rad) * cos(v_rad)
	
	direction_lancer = Vector3(x, y, z).normalized()
	
	# Debug
	if palet_actuel != null:
		# print("Direction calculée: X:%.2f Y:%.2f Z:%.2f (H:%.1f° V:%.1f°)" % [
		# 	x, y, z, angle_horizontal, angle_vertical
		# ])
		pass

## Taux d'ivresse par joueur (0.0 à 1.0+)
var taux_ivresse_joueurs: Dictionary = {1: 0.0, 2: 0.0}

## Temps pour le bruit de Perlin par joueur
var noise_time_joueurs: Dictionary = {1: 0.0, 2: 0.0}

## Joueur actuel (sera mis à jour par le gestionnaire)
var joueur_actuel: int = 1

var visual_effect_active: bool = false
var shader_material: ShaderMaterial

func _process(delta: float) -> void:
	# Gestion de l'ivresse pour chaque joueur
	for joueur_id in [1, 2]:
		if taux_ivresse_joueurs[joueur_id] > 0:
			noise_time_joueurs[joueur_id] += delta
			# Diminution lente de l'ivresse avec le temps
			taux_ivresse_joueurs[joueur_id] = max(0.0, taux_ivresse_joueurs[joueur_id] - delta * 0.01)  # 0.05 par seconde
	
	# Recalculer la direction pour le joueur actuel si ivre
	if taux_ivresse_joueurs.get(joueur_actuel, 0.0) > 0:
		_calculer_direction()
	
	# Mise à jour de l'effet visuel (seulement pour le joueur actuel)
	var taux_actuel = taux_ivresse_joueurs.get(joueur_actuel, 0.0)
	if taux_actuel > 0 or (taux_actuel == 0.0 and visual_effect_active):
		_update_visual_effect()
	
	# Interaction avec le barman (Touche E)
	if Input.is_action_just_pressed("interagir"):
		print("Input 'interagir' détecté !")
		if barman:
			print("Barman trouvé, appel de servir_joueur")
			if barman.has_method("servir_joueur"):
				barman.servir_joueur(self)
			else:
				print("Erreur: Le barman n'a pas la méthode servir_joueur")
		else:
			print("Erreur: Pas de référence au barman")
	
	# Debug temporaire pour voir toutes les touches
	if Input.is_key_pressed(KEY_E):
		print("Touche E physique pressée (via is_key_pressed)")

	if palet_actuel == null:
		return
	
	# Maintenir ESPACE pour charger la force
	if Input.is_action_pressed("ui_accept"):  # ESPACE
		if not est_en_train_de_viser:
			est_en_train_de_viser = true
		
		# Augmenter la force progressivement
		force_lancer = min(force_lancer + vitesse_charge * delta, force_max)
	
	# Relâcher ESPACE pour lancer
	if Input.is_action_just_released("ui_accept") and est_en_train_de_viser:
		_lancer_palet()

func _update_visual_effect() -> void:
	if not shader_material:
		# Essayer de récupérer le material du ColorRect
		var effet_node = get_parent().get_node_or_null("EffetIvresse/EcranIvresse")
		if effet_node and effet_node is ColorRect:
			shader_material = effet_node.material as ShaderMaterial
	
	if shader_material:
		var taux_actuel = taux_ivresse_joueurs.get(joueur_actuel, 0.0)
		shader_material.set_shader_parameter("force_ivresse", taux_actuel)
		visual_effect_active = (taux_actuel > 0.0)

func boire_biere() -> void:
	print("Glou glou glou... Hips !")
	taux_ivresse_joueurs[joueur_actuel] += 2
	print("Joueur %d - Taux d'ivresse: %.2f" % [joueur_actuel, taux_ivresse_joueurs[joueur_actuel]])

func boire_biere_force(numero_joueur: int) -> void:
	#Fait boire un joueur spécifique (utilisé par le gestionnaire de partie)
	print("Le joueur %d boit une bière (forcé) !" % numero_joueur)
	taux_ivresse_joueurs[numero_joueur] += 2.0
	print("Joueur %d - Taux d'ivresse: %.2f" % [numero_joueur, taux_ivresse_joueurs[numero_joueur]])

func _lancer_palet() -> void:
	#Lance le palet avec la force chargé
	if palet_actuel == null:
		return
	
	print("=== LANCEMENT ===")
	print("Force: %.2f, Direction: %s" % [force_lancer, direction_lancer])
	
	# Appeler la fonction lancer du palet
	if palet_actuel.has_method("lancer"):
		palet_actuel.lancer(direction_lancer, force_lancer)
	
	# Émettre le signal
	palet_lance.emit(palet_actuel, force_lancer, direction_lancer)
	
	# Réinitialiser
	palet_actuel = null
	force_lancer = force_min
	angle_horizontal = 0.0
	angle_vertical = 15.0
	est_en_train_de_viser = false
	_calculer_direction()

func get_pourcentage_force() -> float:
	#Retourne le pourcentage de force actuel (0-100)
	var denom = force_max - force_min
	if denom == 0:
		return 0.0
	var pct = ((force_lancer - force_min) / denom) * 100.0
	return clamp(pct, 0.0, 100.0)

func get_angle_visee() -> float:
	#Retourne l'angle de visée horizontal actuel en degrés (-angle_horizontal_max..angle_horizontal_max)
	return angle_horizontal

func get_angle_horizontal() -> float:
	#Retourne l'angle de visée horizontal en degrés#
	return angle_horizontal

func get_angle_vertical() -> float:
	#Retourne l'angle de visée vertical en degrés
	return angle_vertical
