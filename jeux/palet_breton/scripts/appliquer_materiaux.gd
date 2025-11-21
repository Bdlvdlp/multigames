extends Node3D

## Script pour appliquer les matériaux PBR réalistes au bar
## À attacher temporairement à la scène pour upgrader visuellement

@onready var gestionnaire_mat = preload("res://jeux/palet_breton/scripts/gestionnaire_materiaux.gd").new()

func _ready():
	print("🎨 Application des matériaux PBR réalistes...")
	
	# Appliquer les matériaux
	_appliquer_materiaux()
	
	# Améliorer l'éclairage
	_ameliorer_eclairage()
	
	print("✅ Matériaux appliqués avec succès!")

func _appliquer_materiaux():
	var decoration = get_parent().get_node_or_null("DecorationBar")
	if not decoration:
		push_error("❌ Node DecorationBar non trouvé!")
		return
	
	# Murs
	var mur_fond = decoration.get_node_or_null("MurFond")
	if mur_fond:
		mur_fond.material = gestionnaire_mat.creer_materiau_platre()
		print("  ✓ Mur fond: matériau uni beige appliqué")
	
	var mur_gauche = decoration.get_node_or_null("MurGauche")
	if mur_gauche:
		mur_gauche.material = gestionnaire_mat.creer_materiau_platre()
		print("  ✓ Mur gauche: matériau uni beige appliqué")
	
	var mur_droit = decoration.get_node_or_null("MurDroit")
	if mur_droit:
		mur_droit.material = gestionnaire_mat.creer_materiau_platre()
		print("  ✓ Mur droit: matériau uni beige appliqué")
	
	# Plafond
	var plafond = decoration.get_node_or_null("Plafond")
	if plafond:
		plafond.material = gestionnaire_mat.creer_materiau_plafond()
		print("  ✓ Plafond: matériau uni marron clair appliqué")
	
	# Poutres
	var poutre1 = decoration.get_node_or_null("Poutre1")
	if poutre1:
		poutre1.material = gestionnaire_mat.creer_materiau_bois()
		print("  ✓ Poutre 1: matériau bois appliqué")
	
	var poutre2 = decoration.get_node_or_null("Poutre2")
	if poutre2:
		poutre2.material = gestionnaire_mat.creer_materiau_bois()
		print("  ✓ Poutre 2: matériau bois appliqué")
	
	# Comptoir
	var comptoir = decoration.get_node_or_null("Comptoir")
	if comptoir:
		var socle = comptoir.get_node_or_null("SocleComptoir")
		if socle:
			socle.material = gestionnaire_mat.creer_materiau_comptoir()
			print("  ✓ Socle comptoir: matériau uni marron appliqué")
		
		var plat = comptoir.get_node_or_null("PlatComptoir")
		if plat:
			plat.material = gestionnaire_mat.creer_materiau_comptoir()
			print("  ✓ Dessus comptoir: matériau uni marron appliqué")
	
	# Piste
	var piste = get_parent().get_node_or_null("PistePalet/StaticBody3D/MeshInstance3D")
	if piste and piste.mesh:
		var mat_piste = gestionnaire_mat.creer_materiau_piste()
		if piste.mesh.surface_get_material(0):
			piste.mesh.surface_set_material(0, mat_piste)
		else:
			piste.set_surface_override_material(0, mat_piste)
		print("  ✓ Piste: matériau bois verni appliqué")
	
	# Planche
	var planche = get_parent().get_node_or_null("PistePalet/Planche/PlateauPlanche/MeshInstance3D")
	if planche and planche.mesh:
		var mat_planche = gestionnaire_mat.creer_materiau_planche()
		if planche.mesh.surface_get_material(0):
			planche.mesh.surface_set_material(0, mat_planche)
		else:
			planche.set_surface_override_material(0, mat_planche)
		print("  ✓ Planche: matériau bois brut appliqué")
	
	# Bordures
	var piste_node = get_parent().get_node_or_null("PistePalet")
	if piste_node:
		var mat_bordure = gestionnaire_mat.creer_materiau_bordure()
		
		for i in range(1, 4):
			var bordure = piste_node.get_node_or_null("Bordure" + str(i))
			if bordure and bordure.mesh:
				if bordure.mesh.surface_get_material(0):
					bordure.mesh.surface_set_material(0, mat_bordure)
				else:
					bordure.set_surface_override_material(0, mat_bordure)
		print("  ✓ Bordures: matériau bois foncé appliqué")
	
	# Porte
	var porte_toilettes = decoration.get_node_or_null("PorteToilettes/Porte")
	if porte_toilettes:
		porte_toilettes.material = gestionnaire_mat.creer_materiau_porte()
		print("  ✓ Porte: matériau bois peint appliqué")

func _ameliorer_eclairage():
	print("💡 Amélioration de l'éclairage...")
	
	var decoration = get_parent().get_node_or_null("DecorationBar")
	if not decoration:
		return
	
	# Améliorer lumière comptoir
	var lumiere_comptoir = decoration.get_node_or_null("LumiereComptoir")
	if lumiere_comptoir:
		lumiere_comptoir.light_color = Color(1.0, 0.85, 0.6, 1.0)  # Lumière chaude
		lumiere_comptoir.light_energy = 1.2
		lumiere_comptoir.omni_range = 4.0
		lumiere_comptoir.omni_attenuation = 0
		lumiere_comptoir.shadow_enabled = true
		print("  ✓ Lumière comptoir améliorée")
	
	# Améliorer lumière ambiance
	var lumiere_ambiance = decoration.get_node_or_null("LumiereAmbiance")
	if lumiere_ambiance:
		lumiere_ambiance.light_color = Color(1.0, 0.95, 0.88, 1.0)
		lumiere_ambiance.light_energy = 0.5
		lumiere_ambiance.omni_range = 10.0
		lumiere_ambiance.omni_attenuation = 0
		print("  ✓ Lumière ambiance améliorée")
	
	# Ajouter spotlight sur la planche
	var spot_planche = SpotLight3D.new()
	spot_planche.name = "SpotlightPlanche"
	spot_planche.light_color = Color(1.0, 1.0, 1.0, 1.0)
	spot_planche.light_energy = 2.0
	spot_planche.spot_range = 6.0
	spot_planche.spot_angle = 35.0
	spot_planche.spot_attenuation = 1.2
	spot_planche.shadow_enabled = true
	spot_planche.position = Vector3(0, 3.5, 0)
	spot_planche.rotation_degrees = Vector3(-90, 0, 0)
	decoration.add_child(spot_planche)
	spot_planche.owner = get_tree().edited_scene_root
	print("  ✓ Spotlight planche ajouté")
	
	# Améliorer la lumière directionnelle
	var lumiere_directionnelle = get_parent().get_node_or_null("DirectionalLight3D")
	if lumiere_directionnelle:
		lumiere_directionnelle.light_energy = 0.6
		lumiere_directionnelle.light_color = Color(1.0, 0.98, 0.92, 1.0)
		lumiere_directionnelle.shadow_enabled = true
		lumiere_directionnelle.shadow_blur = 1.5
		print("  ✓ Lumière directionnelle améliorée")
	
	# Ajouter environnement pour meilleure ambiance
	var world_env = get_parent().get_node_or_null("WorldEnvironment")
	if not world_env:
		world_env = WorldEnvironment.new()
		world_env.name = "WorldEnvironment"
		get_parent().add_child(world_env)
		world_env.owner = get_tree().edited_scene_root
		
		var env = Environment.new()
		world_env.environment = env
		
		# Configuration environnement
		env.background_mode = Environment.BG_COLOR
		env.background_color = Color(0.15, 0.12, 0.10, 1.0)  # Ambiance bar sombre
		env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
		env.ambient_light_color = Color(0.3, 0.28, 0.25, 1.0)
		env.ambient_light_energy = 0.4
		
		# Tonemap pour rendu plus réaliste
		env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
		env.tonemap_exposure = 1.1
		
		# Glow subtil
		env.glow_enabled = true
		env.glow_intensity = 0.3
		env.glow_bloom = 0.2
		env.glow_blend_mode = Environment.GLOW_BLEND_MODE_SOFTLIGHT
		
		# SSAO pour profondeur
		env.ssao_enabled = true
		env.ssao_radius = 0.5
		env.ssao_intensity = 1.5
		
		print("  ✓ WorldEnvironment créé avec effets PBR")
	
	print("✅ Éclairage amélioré!")
