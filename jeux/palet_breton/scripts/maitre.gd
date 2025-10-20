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
	freeze = false
	est_lance = true
	
	# Appliquer l'impulsion
	apply_impulse(direction.normalized() * force)
	
	# Petite rotation pour effet visuel
	apply_torque_impulse(Vector3(randf_range(-0.1, 0.1), randf_range(-0.1, 0.1), 0))

func _on_body_entered(body: Node) -> void:
	if not est_lance:
		return
	
	# Si le maître entre sur la planche
	if body.name == "PlateauPlanche":
		sur_planche = true
		print("Maître sur la planche !")

func _on_body_exited(body: Node) -> void:
	if not est_lance:
		return
	
	# Si le maître quitte la planche pendant la partie = annulation
	if body.name == "PlateauPlanche" and sur_planche:
		hors_planche = true
		print("ATTENTION : Maître hors de la planche - Partie annulée !")

func _physics_process(_delta: float) -> void:
	if est_lance and not freeze:
		# Arrêter le maître s'il est presque immobile
		if linear_velocity.length() < 0.05:
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
