extends Node

## Gestionnaire de matériaux PBR pour le bar
## Utilise des shaders personnalisés pour des rendus réalistes et performants

# Matériau murs (couleur unie simple)
func creer_materiau_platre() -> StandardMaterial3D:
	var mat = StandardMaterial3D.new()
	
	mat.albedo_color = Color(0.75, 0.68, 0.60)
	mat.roughness = 0.85
	mat.metallic = 0.0
	
	return mat

# Matériau bois pour le comptoir et poutres
func creer_materiau_bois() -> ShaderMaterial:
	var shader = load("res://jeux/palet_breton/shaders/bois_veine.gdshader")
	var mat = ShaderMaterial.new()
	mat.shader = shader
	
	# Texture plus fine et détaillée
	mat.set_shader_parameter("couleur_base", Color(0.519, 0.338, 0.213, 1.0))
	mat.set_shader_parameter("couleur_veine", Color(0.25, 0.15, 0.08))
	mat.set_shader_parameter("echelle_veines", 4.0) # Augmenté pour détails plus fins
	mat.set_shader_parameter("intensite_veines", 0.3) # Réduit pour subtilité
	mat.set_shader_parameter("rugosite", 0.4)
	mat.set_shader_parameter("variation_couleur", 0.08)
	mat.set_shader_parameter("direction_veines", Vector2(15.0, 1.0)) # Plus étiré
	
	return mat

# Matériau dessus comptoir (zinc/métal patiné)
func creer_materiau_zinc() -> ShaderMaterial:
	var shader = load("res://jeux/palet_breton/shaders/zinc_patine.gdshader")
	var mat = ShaderMaterial.new()
	mat.shader = shader
	
	# Détails plus fins
	mat.set_shader_parameter("couleur_base", Color(0.45, 0.42, 0.38))
	mat.set_shader_parameter("couleur_patine", Color(0.35, 0.33, 0.30))
	mat.set_shader_parameter("metallic", 0.6)
	mat.set_shader_parameter("rugosite", 0.35)
	mat.set_shader_parameter("intensite_rayures", 0.3) # Réduit
	mat.set_shader_parameter("echelle_patine", 4.0) # Augmenté pour texture plus fine
	
	return mat

# Matériau sol (parquet bois foncé)
func creer_materiau_carrelage() -> ShaderMaterial:
	var shader = load("res://jeux/palet_breton/shaders/parquet.gdshader")
	var mat = ShaderMaterial.new()
	mat.shader = shader
	
	# Planches BEAUCOUP plus fines
	mat.set_shader_parameter("couleur_base", Color(0.25, 0.18, 0.12))
	mat.set_shader_parameter("couleur_veine", Color(0.20, 0.14, 0.09))
	mat.set_shader_parameter("largeur_planche", 0.05) # 3x plus fin !
	mat.set_shader_parameter("largeur_joint", 0.001) # Joints ultra-fins
	mat.set_shader_parameter("variation_planches", 0.06)
	mat.set_shader_parameter("rugosite", 0.5)
	
	return mat

# Matériau piste de palet (bois lisse verni)
func creer_materiau_piste() -> ShaderMaterial:
	var shader = load("res://jeux/palet_breton/shaders/bois_veine.gdshader")
	var mat = ShaderMaterial.new()
	mat.shader = shader
	
	# Bois clair et très lisse, texture TRÈS fine
	mat.set_shader_parameter("couleur_base", Color(0.82, 0.70, 0.55))
	mat.set_shader_parameter("couleur_veine", Color(0.80, 0.68, 0.53))
	mat.set_shader_parameter("echelle_veines", 6.0) # Augmenté pour texture ultra-fine
	mat.set_shader_parameter("intensite_veines", 0.08) # Très subtil
	mat.set_shader_parameter("rugosite", 0.15)
	mat.set_shader_parameter("variation_couleur", 0.02)
	mat.set_shader_parameter("direction_veines", Vector2(25.0, 1.0)) # Très étiré
	
	return mat

# Matériau planche (bois naturel)
func creer_materiau_planche() -> ShaderMaterial:
	var shader = load("res://jeux/palet_breton/shaders/bois_veine.gdshader")
	var mat = ShaderMaterial.new()
	mat.shader = shader
	
	# Texture plus fine
	mat.set_shader_parameter("couleur_base", Color(0.75, 0.60, 0.42))
	mat.set_shader_parameter("couleur_veine", Color(0.72, 0.58, 0.40))
	mat.set_shader_parameter("echelle_veines", 4.0) # Augmenté pour détails plus fins
	mat.set_shader_parameter("intensite_veines", 0.15) # Très subtil
	mat.set_shader_parameter("rugosite", 0.8)
	mat.set_shader_parameter("variation_couleur", 0.04)
	mat.set_shader_parameter("direction_veines", Vector2(18.0, 1.0))
	
	return mat

# Matériau bordures (bois foncé)
func creer_materiau_bordure() -> ShaderMaterial:
	var shader = load("res://jeux/palet_breton/shaders/bois_veine.gdshader")
	var mat = ShaderMaterial.new()
	mat.shader = shader
	
	# Bordures texture fine
	mat.set_shader_parameter("couleur_base", Color(0.39, 0.26, 0.13))
	mat.set_shader_parameter("couleur_veine", Color(0.35, 0.23, 0.11))
	mat.set_shader_parameter("echelle_veines", 6.0) # Augmenté pour texture plus fine
	mat.set_shader_parameter("intensite_veines", 0.15)
	mat.set_shader_parameter("rugosite", 0.6)
	mat.set_shader_parameter("variation_couleur", 0.04)
	mat.set_shader_parameter("direction_veines", Vector2(20.0, 1.0))
	
	return mat

# Matériau plafond (couleur unie marron clair)
func creer_materiau_plafond() -> StandardMaterial3D:
	var mat = StandardMaterial3D.new()
	
	mat.albedo_color = Color(0.68, 0.55, 0.42)
	mat.roughness = 0.75
	mat.metallic = 0.0
	
	return mat

# Matériau comptoir (couleur unie marron)
func creer_materiau_comptoir() -> StandardMaterial3D:
	var mat = StandardMaterial3D.new()
	
	mat.albedo_color = Color(0.48, 0.35, 0.25)
	mat.roughness = 0.5
	mat.metallic = 0.0
	
	return mat

# Matériau porte (bois peint simple - garde StandardMaterial3D)
func creer_materiau_porte() -> StandardMaterial3D:
	var mat = StandardMaterial3D.new()
	
	mat.albedo_color = Color(0.55, 0.35, 0.20)
	mat.roughness = 0.65
	mat.metallic = 0.0
	
	return mat
