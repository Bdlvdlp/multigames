extends Node3D
class_name Barman

## Vitesse de déplacement du barman
@export var vitesse_deplacement: float = 2.0

## Vitesse de rotation (plus bas = plus lent/fluide)
@export var vitesse_rotation: float = 5.0

## Distance d'arrêt près du joueur
@export var distance_arret: float = 2.0

## Position initiale (derrière le bar)
var position_initiale: Vector3
var rotation_initiale: float

## Points de passage pour contourner le comptoir
var points_passage: Array[Vector3] = []
var index_point_actuel: int = 0

## Cible actuelle (null si pas de cible)
var cible: Node3D = null

## État du barman
enum Etat { ATTENTE, ALLER_SERVIR, SERVIR, RETOUR }
var etat_actuel: Etat = Etat.ATTENTE

## Signal émis quand la bière est servie
signal biere_servie

@onready var barman_model: Node3D = $Armature

func _ready() -> void:
	position_initiale = global_position
	# On sauvegarde la rotation Y initiale pour qu'il se remette face au client
	rotation_initiale = barman_model.rotation.y
	
	var point_sortie = position_initiale + Vector3(-3.1, 0, 0)
	points_passage.append(point_sortie)
	

func _physics_process(delta: float) -> void:
	match etat_actuel:
		Etat.ATTENTE:
			# En attente, on se remet doucement face à la position initiale
			if abs(angle_difference(barman_model.rotation.y, rotation_initiale)) > 0.01:
				barman_model.rotation.y = lerp_angle(barman_model.rotation.y, rotation_initiale, vitesse_rotation * delta)
			
		Etat.ALLER_SERVIR:
			if cible:
				# Suivre les points de passage
				if index_point_actuel < points_passage.size():
					var point_cible = points_passage[index_point_actuel]
					_deplacer_vers(point_cible, delta)
					
					# Si on est assez proche du point de passage
					var dist = global_position.distance_to(point_cible)
					if dist <= 1: # Seuil raisonnable pour valider le passage
						# On "snap" à la position exacte pour éviter les micro-ajustements
						global_position.x = point_cible.x
						global_position.z = point_cible.z
						
						print("[Barman] Point de passage %d atteint (%s). Passage au suivant." % [index_point_actuel, point_cible])
						index_point_actuel += 1
						if index_point_actuel < points_passage.size():
							print("[Barman] Nouveau point cible: %s" % points_passage[index_point_actuel])
				else:
					# Une fois tous les points passés, aller vers le joueur
					_deplacer_vers(cible.global_position, delta)
					var dist = global_position.distance_to(cible.global_position)
					if dist <= distance_arret:
						print("[Barman] Arrivé près du joueur (dist: %.2f)" % dist)
						changer_etat(Etat.SERVIR)
		
		Etat.SERVIR:
			pass # L'animation est gérée par le changement d'état
			
		Etat.RETOUR:
			# Suivre les points de passage en sens inverse
			if index_point_actuel > 0:
				var point_cible = points_passage[index_point_actuel - 1]
				_deplacer_vers(point_cible, delta)
				
				var dist = global_position.distance_to(point_cible)
				if dist <= 1:
					# Snap
					global_position.x = point_cible.x
					global_position.z = point_cible.z
					
					print("[Barman] Point de retour %d atteint (%s)" % [index_point_actuel - 1, point_cible])
					index_point_actuel -= 1
					if index_point_actuel > 0:
						print("[Barman] Prochain point retour: %s" % points_passage[index_point_actuel - 1])
			else:
				# Retour à la position initiale
				_deplacer_vers(position_initiale, delta)
				var dist = global_position.distance_to(position_initiale)
				if dist <= 1: 
					# Snap final
					global_position.x = position_initiale.x
					global_position.z = position_initiale.z
					
					print("[Barman] Retour à la position initiale: %s" % position_initiale)
					changer_etat(Etat.ATTENTE)
					print("Barman: De retour au poste.")

func changer_etat(nouvel_etat: Etat) -> void:
	if etat_actuel == nouvel_etat:
		return
		
	etat_actuel = nouvel_etat
	
	match etat_actuel:
		Etat.ATTENTE:
			pass # Le barman reste immobile
			
		Etat.ALLER_SERVIR:
			pass # Juste le déplacement, pas d'animation
			
		Etat.SERVIR:
			_servir_sequence()
			
		Etat.RETOUR:
			pass # Juste le déplacement, pas d'animation

func servir_joueur(joueur: Node3D) -> void:
	if etat_actuel == Etat.ATTENTE or etat_actuel == Etat.RETOUR:
		print("Barman: J'arrive avec une bière ! Joueur en %s" % joueur.global_position)
		cible = joueur
		index_point_actuel = 0  # Réinitialiser le parcours
		if points_passage.size() > 0:
			print("[Barman] Début du parcours. Premier point: %s" % points_passage[0])
		changer_etat(Etat.ALLER_SERVIR)

func _deplacer_vers(pos_cible: Vector3, delta: float) -> void:
	# On ignore l'axe Y pour le déplacement (reste au sol)
	var direction = (pos_cible - global_position)
	direction.y = 0
	
	# Si on est très proche, on ne bouge plus pour éviter le jitter
	if direction.length() < 1:
		return
		
	direction = direction.normalized()
	
	# Orienter le modèle face à la direction de déplacement avec interpolation
	var angle_cible = atan2(direction.x, direction.z) + PI
	# Utiliser lerp_angle pour une rotation fluide
	barman_model.rotation.y = lerp_angle(barman_model.rotation.y, angle_cible, vitesse_rotation * delta)
	
	# Déplacer
	global_position += direction * vitesse_deplacement * delta

func _servir_sequence() -> void:
	print("Barman: Voici votre bière !")
	
	# Attendre 1 seconde puis retourner au bar
	await get_tree().create_timer(1.0).timeout
	
	print("Barman: Je retourne au bar.")
	# Réinitialiser l'index pour le chemin retour (partir de la fin)
	index_point_actuel = points_passage.size()
	changer_etat(Etat.RETOUR)
	biere_servie.emit()
