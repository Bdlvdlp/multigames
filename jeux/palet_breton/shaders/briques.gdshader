shader_type spatial;

// Shader pour mur de briques apparentes

uniform vec3 couleur_brique : source_color = vec3(0.45, 0.28, 0.20);
uniform vec3 couleur_joint : source_color = vec3(0.35, 0.32, 0.28);
uniform vec2 taille_brique = vec2(0.25, 0.12); // Largeur x Hauteur
uniform float largeur_joint : hint_range(0.005, 0.02) = 0.01;
uniform float variation_brique : hint_range(0.0, 0.3) = 0.15;
uniform float rugosite : hint_range(0.0, 1.0) = 0.85;

// Hash pour variation
float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453123);
}

vec2 hash22(vec2 p) {
	p = vec2(dot(p, vec2(127.1, 311.7)), dot(p, vec2(269.5, 183.3)));
	return -1.0 + 2.0 * fract(sin(p) * 43758.5453123);
}

float noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	vec2 u = f * f * (3.0 - 2.0 * f);
	
	return mix(
		mix(dot(hash22(i + vec2(0.0, 0.0)), f - vec2(0.0, 0.0)),
			dot(hash22(i + vec2(1.0, 0.0)), f - vec2(1.0, 0.0)), u.x),
		mix(dot(hash22(i + vec2(0.0, 1.0)), f - vec2(0.0, 1.0)),
			dot(hash22(i + vec2(1.0, 1.0)), f - vec2(1.0, 1.0)), u.x),
		u.y);
}

void fragment() {
	// Coordonnées de grille pour briques
	vec2 uv = UV;
	
	// Décalage alterné (pattern de briques)
	float row = floor(uv.y / taille_brique.y);
	float offset = mod(row, 2.0) * 0.5;
	
	vec2 brick_uv = vec2(uv.x / taille_brique.x + offset, uv.y / taille_brique.y);
	vec2 brick_id = floor(brick_uv);
	vec2 brick_gv = fract(brick_uv);
	
	// Joints (bords de chaque brique)
	vec2 joint = smoothstep(largeur_joint, largeur_joint * 2.0, brick_gv) * 
				 smoothstep(largeur_joint, largeur_joint * 2.0, 1.0 - brick_gv);
	float masque_joint = joint.x * joint.y;
	
	// Variation de couleur par brique
	float variation = (hash(brick_id) - 0.5) * variation_brique;
	vec3 couleur_brique_variee = couleur_brique + vec3(variation);
	
	// Texture subtile sur chaque brique
	float texture_brique = noise(brick_uv * 15.0) * 0.08;
	couleur_brique_variee += vec3(texture_brique);
	
	// Couleur finale : brique ou joint
	vec3 couleur_finale = mix(couleur_joint, couleur_brique_variee, masque_joint);
	
	ALBEDO = couleur_finale;
	ROUGHNESS = mix(rugosite + 0.15, rugosite, masque_joint); // Joints plus rugueux
	METALLIC = 0.0;
	
	// Normal map pour relief des joints
	float relief = (1.0 - masque_joint) * 0.4;
	NORMAL_MAP = vec3(0.5, 0.5, 1.0 - relief);
}
