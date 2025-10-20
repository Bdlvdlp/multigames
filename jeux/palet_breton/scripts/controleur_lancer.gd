extends Node3D
class_name ControleurLancer

## Référence au palet/maître à lancer
var palet_actuel: RigidBody3D = null

## Force de lancer (modifiable avec la souris)
var force_lancer: float = 0.0

## Force minimale et maximale
@export var force_min: float = 5.0
@export var force_max: float = 25.0

## Vitesse de chargement de la force
@export var vitesse_charge: float = 15.0

## Est-on en train de viser ?
var est_en_train_de_viser: bool = false

## Direction de lancer (toujours vers la planche)
var direction_lancer: Vector3 = Vector3.FORWARD

## Signal émis quand un palet est lancé
signal palet_lance(palet: RigidBody3D, force: float)

func _ready() -> void:
    # La direction est toujours vers l'avant (vers la planche)
    direction_lancer = Vector3.FORWARD

func preparer_lancer(palet: RigidBody3D) -> void:
    """Prépare le lancer d'un palet"""
    palet_actuel = palet
    force_lancer = force_min
    est_en_train_de_viser = false
    print("Prêt à lancer - Maintenez ESPACE pour charger la force")

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
    """Lance le palet avec la force chargée"""
    if palet_actuel == null:
        return
    
    print("Lancer avec force: %.2f" % force_lancer)
    
    # Appeler la fonction lancer du palet
    if palet_actuel.has_method("lancer"):
        palet_actuel.lancer(direction_lancer, force_lancer)
    
    # Émettre le signal
    palet_lance.emit(palet_actuel, force_lancer)
    
    # Réinitialiser
    palet_actuel = null
    force_lancer = force_min
    est_en_train_de_viser = false

func get_pourcentage_force() -> float:
    """Retourne le pourcentage de force actuel (0-100)"""
    return ((force_lancer - force_min) / (force_max - force_min)) * 100.0