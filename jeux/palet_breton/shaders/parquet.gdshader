shader_type spatial;

// Shader pour parquet en bois (planches parallèles)

uniform vec3 couleur_base : source_color = vec3(0.25, 0.18, 0.12);
uniform vec3 couleur_veine : source_color = vec3(0.20, 0.14, 0.09);
uniform float largeur_planche : hint_range(0.05, 0.3) = 0.15;
uniform float largeur_joint : hint_range(0.001, 0.01) = 0.003;
uniform float variation_planches : hint_range(0.0, 0.2) = 0.08;
uniform float rugosite : hint_range(0.0, 1.0) = 0.5;

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

float fbm(vec2 p) {
	float value = 0.0;
	float amplitude = 0.5;
	
	for (int i = 0; i < 4; i++) {
		value += amplitude * noise(p);
		p *= 2.0;
		amplitude *= 0.5;
	}
	
	return value;
}

void fragment() {
	// Planches parallèles (direction Z)
	float planche_id = floor(UV.x / largeur_planche);
	float planche_pos = fract(UV.x / largeur_planche);
	
	// Joints entre planches
	float joint = smoothstep(largeur_joint, largeur_joint * 3.0, planche_pos) * 
				  smoothstep(largeur_joint, largeur_joint * 3.0, 1.0 - planche_pos);
	
	// Variation de couleur par planche
	float variation = (hash(vec2(planche_id, 0.0)) - 0.5) * variation_planches;
	vec3 couleur_planche = couleur_base + vec3(variation);
	
	// Veines du bois (direction longitudinale)
	float veines = fbm(vec2(UV.x * 50.0, UV.y * 2.0));
	veines = smoothstep(0.3, 0.7, veines);
	couleur_planche = mix(couleur_veine, couleur_planche, veines);
	
	// Texture fine du bois
	float detail = noise(UV * 80.0) * 0.04;
	couleur_planche += vec3(detail);
	
	// Joints sombres
	vec3 couleur_finale = mix(couleur_veine * 0.7, couleur_planche, joint);
	
	ALBEDO = couleur_finale;
	ROUGHNESS = rugosite + (1.0 - joint) * 0.2; // Joints plus rugueux
	METALLIC = 0.0;
	
	// Normal map subtile
	float relief_joint = (1.0 - joint) * 0.2;
	float relief_veine = (1.0 - veines) * 0.1;
	NORMAL_MAP = vec3(0.5, 0.5, 1.0 - relief_joint - relief_veine);
}
