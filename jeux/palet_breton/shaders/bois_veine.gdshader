shader_type spatial;

// Shader pour bois avec veines réalistes
// Utilise du bruit pour créer des anneaux de croissance

uniform vec3 couleur_base : source_color = vec3(0.35, 0.22, 0.13);
uniform vec3 couleur_veine : source_color = vec3(0.25, 0.15, 0.08);
uniform float echelle_veines : hint_range(0.1, 10.0) = 2.0;
uniform float intensite_veines : hint_range(0.0, 1.0) = 0.5;
uniform float rugosite : hint_range(0.0, 1.0) = 0.4;
uniform float variation_couleur : hint_range(0.0, 0.5) = 0.15;
uniform vec2 direction_veines = vec2(10.0, 1.0); // Étirement horizontal

// Fonction de bruit simplex 2D
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

// Bruit fractal (FBM)
float fbm(vec2 p) {
	float value = 0.0;
	float amplitude = 0.5;
	float frequency = 1.0;
	
	for (int i = 0; i < 5; i++) {
		value += amplitude * noise(p * frequency);
		frequency *= 2.0;
		amplitude *= 0.5;
	}
	
	return value;
}

void fragment() {
	// Coordonnées UV avec direction des veines
	vec2 uv = UV * echelle_veines;
	vec2 uv_veines = uv * direction_veines;
	
	// Distance radiale pour anneaux de croissance
	float distance_centre = length(vec2(uv_veines.x * 0.1, uv_veines.y));
	
	// Anneaux de croissance avec variation
	float anneaux = sin(distance_centre * 15.0 + fbm(uv * 2.0) * 3.0) * 0.5 + 0.5;
	anneaux = pow(anneaux, 2.0); // Accentuer les contrastes
	
	// Veines longitudinales
	float veines_longitudinales = fbm(vec2(uv.x * 0.5, uv.y * 5.0));
	
	// Combinaison anneaux + veines
	float pattern_bois = mix(anneaux, veines_longitudinales, 0.3);
	pattern_bois = smoothstep(0.3, 0.7, pattern_bois);
	
	// Variation de couleur subtile
	float variation = fbm(uv * 3.0) * variation_couleur;
	
	// Couleur finale
	vec3 couleur_bois = mix(couleur_veine, couleur_base, pattern_bois);
	couleur_bois += vec3(variation);
	
	ALBEDO = couleur_bois;
	ROUGHNESS = rugosite + fbm(uv * 10.0) * 0.1; // Variation de rugosité
	METALLIC = 0.0;
	
	// Normal map subtile pour relief
	float detail = fbm(uv * 20.0) * 0.3;
	NORMAL_MAP = vec3(0.5, 0.5, 1.0 - detail * 0.2);
}
