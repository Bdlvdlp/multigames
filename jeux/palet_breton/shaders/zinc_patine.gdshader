shader_type spatial;

// Shader pour zinc/métal patiné avec rayures et oxydation

uniform vec3 couleur_base : source_color = vec3(0.45, 0.42, 0.38);
uniform vec3 couleur_patine : source_color = vec3(0.35, 0.33, 0.30);
uniform float metallic : hint_range(0.0, 1.0) = 0.6;
uniform float rugosite : hint_range(0.0, 1.0) = 0.35;
uniform float intensite_rayures : hint_range(0.0, 1.0) = 0.4;
uniform float echelle_patine : hint_range(0.1, 5.0) = 2.0;

// Hash pour randomisation
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
	vec2 uv = UV * echelle_patine;
	
	// Rayures directionnelles (usure du comptoir)
	float rayures = 0.0;
	for (int i = 0; i < 8; i++) {
		float offset = float(i) * 0.3;
		float rayure = sin((uv.x + offset) * 80.0 + fbm(uv * 5.0) * 2.0);
		rayure = smoothstep(0.95, 1.0, rayure); // Rayures fines
		rayures += rayure;
	}
	rayures = clamp(rayures * intensite_rayures, 0.0, 1.0);
	
	// Patine/oxydation (zones sombres aléatoires)
	float patine = fbm(uv * 3.0);
	patine = smoothstep(0.3, 0.7, patine);
	
	// Micro-rayures aléatoires
	float micro_rayures = fbm(uv * 50.0) * 0.2;
	
	// Couleur finale : base + patine + rayures
	vec3 couleur = mix(couleur_patine, couleur_base, patine);
	couleur = mix(couleur, vec3(0.55, 0.52, 0.48), rayures * 0.3); // Rayures plus claires
	couleur += vec3(micro_rayures * 0.1);
	
	ALBEDO = couleur;
	
	// Métallic varie selon la patine (oxydé = moins métallique)
	METALLIC = metallic * (0.5 + patine * 0.5);
	
	// Rugosité varie (rayures = plus rugueux)
	ROUGHNESS = rugosite + rayures * 0.2 + micro_rayures;
	
	// Normal map pour rayures en relief
	float normal_rayures = fbm(vec2(uv.x * 80.0, uv.y * 5.0));
	NORMAL_MAP = vec3(0.5 + normal_rayures * 0.1, 0.5, 1.0);
	
	// Specular pour brillance du métal
	SPECULAR = 0.4 + patine * 0.2;
}
