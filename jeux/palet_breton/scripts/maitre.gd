extends RigidBody3D
class_name Maitre

## Est-ce que le maître est en jeu
var est_lance: bool = false

## Est-ce que le maître est sur la planche
var sur_planche: bool = false

## Est-ce que le maître a quitté la planche (= partie annulée)
var hors_planche: bool = false

func _ready() -> void:
	# Désactiver la physique au départ
	freeze = true
	
	# Connecter les signaux de collision
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func lancer(direction: Vector3, force: float) -> void:
	#Lance le maître dans une direction avec une force donnée
	print("=== LANCER MAÎTRE ===")
	print("Position: %s, Freeze AVANT: %s, Sleeping: %s" % [global_position, freeze, sleeping])
	
	# IMPORTANT: réinitialiser complètement le RigidBody3D
	freeze = false
	sleeping = false
	
	# Forcer l'activation avec une vélocité directe AVANT l'impulsion
	linear_velocity = Vector3.ZERO
	angular_velocity = Vector3.ZERO
	
	print("Freeze APRÈS: %s, Sleeping: %s" % [freeze, sleeping])
	
	est_lance = true
	
	# Déplacer le maître à hauteur de lancer (1.1m)
	global_position.y = 1.1
	global_position.z = -1.5
	
	# Appliquer une vélocité réaliste (force / masse = accélération, puis * temps)
	# Force de 10-60, masse 0.09kg, on divise par 5 pour avoir une vitesse en m/s réaliste
	var velocite = direction.normalized() * (force / 5.0)
	
	print("Vélocité à appliquer: %s (magnitude: %.2f m/s)" % [velocite, velocite.length()])
	linear_velocity = velocite
	print("Vélocité appliquée: %s" % linear_velocity)

func _on_body_entered(body: Node) -> void:
	if not est_lance:
		return
	
	# Si le maître entre en collision avec la planche
	if body.name == "PlateauPlanche":
		# Vérifier que le maître est bien AU-DESSUS de la planche (pas collé sur le côté)
		# La planche fait 0.02m de haut, donc son dessus est à Y ≈ 0.16m
		# Le maître fait 0.006m de haut, donc son centre doit être à Y ≈ 0.163m minimum
		if global_position.y > 0.15:  # Marge de sécurité
			sur_planche = true
			print("Maître sur la planche !")
		else:
			print("Maître a touché le CÔTÉ de la planche (invalide)")

func _on_body_exited(body: Node) -> void:
	if not est_lance:
		return
	
	# Si le maître quitte la planche pendant la partie = annulation
	if body.name == "PlateauPlanche" and sur_planche:
		hors_planche = true
		print("ATTENTION : Maître hors de la planche - Partie annulée !")

func _physics_process(_delta: float) -> void:
	if est_lance and not freeze:
		var vel = linear_velocity.length()
		
		# Debug: afficher vélocité régulièrement
		if vel > 0.01:
			print("Maître en mouvement - Vel: %.2f, Pos: %s" % [vel, global_position])
		
		# Arrêter le maître s'il est presque immobile
		if vel < 0.05:
			freeze = true
			linear_velocity = Vector3.ZERO
			angular_velocity = Vector3.ZERO
			print("Maître arrêté")

func reinitialiser() -> void:
	#Réinitialise le maître pour une nouvelle manche
	freeze = true
	est_lance = false
	sur_planche = false
	hors_planche = false
	linear_velocity = Vector3.ZERO
	angular_velocity = Vector3.ZERO

func distance_a_planche() -> float:
	#Calcule la distance du maître au centre de la planche
	# Position planche : Z=3.5, Y=0.145 (0.09 piste + 0.05 planche + 0.005 offset)
	var pos_planche = Vector3(0, 0.145, 3.5)
	var distance_2d = Vector2(global_position.x - pos_planche.x, global_position.z - pos_planche.z).length()
	return distance_2d

func est_vraiment_sur_planche() -> bool:
	"""Vérifie si le maître est réellement sur la planche après l'arrêt"""
	# Vérifier que le maître a bien touché la planche à un moment
	if not sur_planche:
		return false
	
	# Vérifier qu'il n'est pas sorti
	if hors_planche:
		print("⚠️ Maître sorti de la planche après glissement")
		return false
	
	# Vérifier que la position Y est correcte (au-dessus de la planche)
	if global_position.y < 0.15:
		print("⚠️ Maître pas au-dessus de la planche (Y=%.3f)" % global_position.y)
		return false
	
	# Vérifier que le maître est dans les limites X/Z de la planche
	# Planche 65cm x 65cm centrée à (0, ?, 3.5)
	var planche_demi_taille = 0.325  # 65cm / 2
	var pos_planche_z = 3.5
	
	if abs(global_position.x) > planche_demi_taille:
		print("⚠️ Maître hors limites X (X=%.3f)" % global_position.x)
		return false
	
	if abs(global_position.z - pos_planche_z) > planche_demi_taille:
		print("⚠️ Maître hors limites Z (Z=%.3f)" % global_position.z)
		return false
	
	return true
