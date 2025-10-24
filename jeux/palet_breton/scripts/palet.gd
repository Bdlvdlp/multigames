extends RigidBody3D
class_name Palet

## Type de palet
enum CouleurPalet { BLEU, ROUGE }

## Couleur du palet (joueur 1 ou 2)
@export var couleur: CouleurPalet = CouleurPalet.BLEU

## Est-ce que le palet est en jeu
var est_lance: bool = false

## Est-ce que le palet est sur la planche
var sur_planche: bool = false

## Est-ce que le palet a touché le sol (= palet invalide)
var a_touche_sol: bool = false

func _ready() -> void:
	# Appliquer la couleur selon le joueur
	_appliquer_couleur()
	
	# Désactiver la physique au départ
	freeze = true
	
	# Connecter les signaux de collision
	body_entered.connect(_on_body_entered)

func _appliquer_couleur() -> void:
	var mesh_instance = $MeshInstance3D
	var material = mesh_instance.mesh.surface_get_material(0).duplicate()
	
	match couleur:
		CouleurPalet.BLEU:
			material.albedo_color = Color(0.2, 0.4, 0.8, 1)
		CouleurPalet.ROUGE:
			material.albedo_color = Color(0.8, 0.2, 0.2, 1)
	
	mesh_instance.set_surface_override_material(0, material)

func lancer(direction: Vector3, force: float) -> void:
	#Lance le palet dans une direction avec une force donnée
	print("=== LANCER PALET ===")
	print("Position: %s" % global_position)
	print("Direction: %s, Force: %.2f" % [direction, force])
	
	# Activer physique
	freeze = false
	sleeping = false
	
	# Forcer l'activation avec reset complet
	linear_velocity = Vector3.ZERO
	angular_velocity = Vector3.ZERO
	
	est_lance = true
	
	# Déplacer le palet à hauteur de lancer (1.1m)
	global_position.y = 1.1
	global_position.z=-1.5
	
	# Appliquer une vélocité réaliste (force / masse = accélération, puis * temps)
	# Force de 10-60, masse 0.16kg, on divise par 5 pour avoir une vitesse en m/s réaliste
	var velocite = direction.normalized() * (force / 5.0)
	
	print("Vélocité appliquée: %.2f m/s - %s" % [velocite.length(), velocite])
	linear_velocity = velocite

func _on_body_entered(body: Node) -> void:
	if not est_lance:
		return
	
	# Si le palet touche le sol du bar = invalide
	if body.name == "SolBar":
		a_touche_sol = true
		print("Palet %s invalide - a touché le sol" % ["BLEU" if couleur == CouleurPalet.BLEU else "ROUGE"])
	
	# Si le palet entre en collision avec la planche
	elif body.name == "PlateauPlanche":
		# Vérifier que le palet est bien AU-DESSUS de la planche (pas collé sur le côté)
		# La planche fait 0.02m de haut, donc son dessus est à Y ≈ 0.16m
		# Le palet fait 0.008m de haut, donc son centre doit être à Y ≈ 0.164m minimum
		if global_position.y > 0.15:  # Marge de sécurité
			sur_planche = true
			print("Palet %s est sur la planche !" % ["BLEU" if couleur == CouleurPalet.BLEU else "ROUGE"])
		else:
			print("Palet %s a touché le CÔTÉ de la planche (invalide)" % ["BLEU" if couleur == CouleurPalet.BLEU else "ROUGE"])

func _physics_process(_delta: float) -> void:
	if est_lance and not freeze:
		# Arrêter le palet s'il est presque immobile
		if linear_velocity.length() < 0.1:
			freeze = true
			linear_velocity = Vector3.ZERO
			angular_velocity = Vector3.ZERO
			print("Palet arrêté à: %s" % global_position)

func reinitialiser() -> void:
	#Réinitialise le palet pour une nouvelle manche
	freeze = true
	est_lance = false
	sur_planche = false
	a_touche_sol = false
	linear_velocity = Vector3.ZERO
	angular_velocity = Vector3.ZERO

func distance_au_maitre(maitre: Maitre) -> float:
	#Calcule la distance du palet au maître
	var distance_2d = Vector2(global_position.x - maitre.global_position.x, 
							  global_position.z - maitre.global_position.z).length()
	return distance_2d
