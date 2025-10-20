extends Control
class_name HudLancer

## Références aux éléments UI
@onready var barre_force: ProgressBar = $PanelContainer/VBoxContainer/BarreForce
@onready var label_force: Label = $PanelContainer/VBoxContainer/LabelForce
@onready var label_instructions: Label = $PanelContainer/VBoxContainer/LabelInstructions
@onready var mini_map: SubViewportContainer = $MiniMap
@onready var sub_viewport: SubViewport = $MiniMap/SubViewport

func _ready() -> void:
    # Configurer la barre de progression
    barre_force.min_value = 0
    barre_force.max_value = 100
    barre_force.value = 0
    
    # Afficher le HUD pour tester
    visible = true
    
    print("HUD initialisé - Mini-map active")

func afficher_visee() -> void:
    visible = true
    mini_map.visible = true
    label_instructions.text = "Maintenez ESPACE pour charger la puissance"

func masquer() -> void:
    visible = false

func mettre_a_jour_force(pourcentage: float) -> void:
    barre_force.value = pourcentage
    label_force.text = "Puissance: %d%%" % int(pourcentage)
    
    # Changer la couleur selon la force
    if pourcentage < 33:
        barre_force.modulate = Color.GREEN
    elif pourcentage < 66:
        barre_force.modulate = Color.YELLOW
    else:
        barre_force.modulate = Color.RED