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

func _ready() -> void:
	# Capturer la souris pour qu'elle ne sorte pas de la fenêtre
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

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
	
	print("Prêt à lancer - Bougez la souris pour viser (X=horizontal, Y=vertical)")
	print("Appuyez sur ECHAP pour libérer la souris")

func _input(event: InputEvent) -> void:
	# Gérer ECHAP pour libérer/capturer la souris
	if event.is_action_pressed("ui_cancel"):  # ECHAP
		if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
			print("Souris libérée")
		else:
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
			print("Souris capturée")
		return
	
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
	
	# Direction de BASE : vers la planche = +Z dans notre scène
	# Pour une visée plus intuitive, on utilise une approche linéaire
	# au lieu de purement trigonométrique
	
	# Normaliser l'angle horizontal entre -1 et 1
	var h_normalized = angle_horizontal / angle_horizontal_max  # -1 à +1
	
	# Composante X linéaire basée sur l'angle normalisé
	# Facteur de 0.15 pour limiter la déviation (réduit de 0.5 à 0.15)
	var x = -h_normalized * 0.15  # Déviation latérale très réduite
	
	# Composante Y pour le tir en cloche (garde le sin pour la parabole)
	var y = sin(v_rad)
	
	# Composante Z principale vers la planche (réduite si angle horizontal élevé)
	var z = cos(h_rad) * cos(v_rad)
	
	direction_lancer = Vector3(x, y, z).normalized()
	
	# Debug
	if palet_actuel != null:
		print("Direction calculée: X:%.2f Y:%.2f Z:%.2f (H:%.1f° V:%.1f°)" % [
			x, y, z, angle_horizontal, angle_vertical
		])

func _process(delta: float) -> void:
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
