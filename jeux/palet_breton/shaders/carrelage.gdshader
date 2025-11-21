shader_type spatial;

// Shader pour carrelage avec joints et variation de tuiles

uniform vec3 couleur_tuile : source_color = vec3(0.32, 0.25, 0.19);
uniform vec3 couleur_joint : source_color = vec3(0.22, 0.18, 0.14);
uniform float taille_tuile : hint_range(0.1, 2.0) = 0.3;
uniform float largeur_joint : hint_range(0.01, 0.1) = 0.02;
uniform float rugosite_tuile : hint_range(0.0, 1.0) = 0.7;
uniform float variation_tuile : hint_range(0.0, 0.3) = 0.15;

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
	// Coordonnées de grille
	vec2 uv = UV / taille_tuile;
	vec2 id = floor(uv);
	vec2 gv = fract(uv);
	
	// Joints (bords de chaque tuile)
	vec2 joint = smoothstep(largeur_joint, largeur_joint * 2.0, gv) * 
				 smoothstep(largeur_joint, largeur_joint * 2.0, 1.0 - gv);
	float masque_joint = joint.x * joint.y;
	
	// Variation de couleur par tuile
	float variation = (hash(id) - 0.5) * variation_tuile;
	vec3 couleur_tuile_variee = couleur_tuile + vec3(variation);
	
	// Texture subtile sur chaque tuile
	float texture_tuile = noise(uv * 20.0) * 0.05;
	couleur_tuile_variee += vec3(texture_tuile);
	
	// Couleur finale : tuile ou joint
	vec3 couleur_finale = mix(couleur_joint, couleur_tuile_variee, masque_joint);
	
	ALBEDO = couleur_finale;
	ROUGHNESS = mix(rugosite_tuile + 0.2, rugosite_tuile, masque_joint); // Joints plus rugueux
	METALLIC = 0.0;
	
	// Normal map légère pour relief des joints
	float relief = (1.0 - masque_joint) * 0.3;
	NORMAL_MAP = vec3(0.5, 0.5, 1.0 - relief);
}
