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
	freeze = false
	est_lance = true
	
	# Appliquer l'impulsion
	apply_impulse(direction.normalized() * force)
	
	# Petite rotation pour effet visuel
	apply_torque_impulse(Vector3(randf_range(-0.1, 0.1), randf_range(-0.1, 0.1), 0))

func _on_body_entered(body: Node) -> void:
	if not est_lance:
		return
	
	# Si le palet touche le sol du bar = invalide
	if body.name == "SolBar":
		a_touche_sol = true
		print("Palet %s invalide - a touché le sol" % ["BLEU" if couleur == CouleurPalet.BLEU else "ROUGE"])
	
	# Si le palet entre sur la planche
	elif body.name == "PlateauPlanche":
		sur_planche = true
		print("Palet %s est sur la planche !" % ["BLEU" if couleur == CouleurPalet.BLEU else "ROUGE"])

func _physics_process(_delta: float) -> void:
	if est_lance and not freeze:
		# Arrêter le palet s'il est presque immobile
		if linear_velocity.length() < 0.05:
			freeze = true
			linear_velocity = Vector3.ZERO
			angular_velocity = Vector3.ZERO
			print("Palet %s arrêté" % ["BLEU" if couleur == CouleurPalet.BLEU else "ROUGE"])

func reinitialiser() -> void:
	#Réinitialise le palet pour une nouvelle manche
	freeze = true
	est_lance = false
	sur_planche = false
	a_touche_sol = false
	linear_velocity = Vector3.ZERO
	angular_velocity = Vector3.ZERO
