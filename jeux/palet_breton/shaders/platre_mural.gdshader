shader_type spatial;

// Shader pour plâtre mural avec texture granuleuse réaliste

uniform vec3 couleur_base : source_color = vec3(0.85, 0.78, 0.68);
uniform float rugosite : hint_range(0.0, 1.0) = 0.85;
uniform float echelle_texture : hint_range(0.1, 10.0) = 3.0;
uniform float intensite_grain : hint_range(0.0, 0.3) = 0.1;
uniform float intensite_relief : hint_range(0.0, 2.0) = 0.5;

// Hash pour bruit
vec3 hash33(vec3 p3) {
	p3 = fract(p3 * vec3(.1031, .1030, .0973));
	p3 += dot(p3, p3.yxz + 33.33);
	return fract((p3.xxy + p3.yxx) * p3.zyx);
}

// Bruit 3D pour variation
float noise3d(vec3 p) {
	vec3 i = floor(p);
	vec3 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	
	return mix(
		mix(mix(dot(hash33(i + vec3(0, 0, 0)), f - vec3(0, 0, 0)),
				dot(hash33(i + vec3(1, 0, 0)), f - vec3(1, 0, 0)), f.x),
			mix(dot(hash33(i + vec3(0, 1, 0)), f - vec3(0, 1, 0)),
				dot(hash33(i + vec3(1, 1, 0)), f - vec3(1, 1, 0)), f.x), f.y),
		mix(mix(dot(hash33(i + vec3(0, 0, 1)), f - vec3(0, 0, 1)),
				dot(hash33(i + vec3(1, 0, 1)), f - vec3(1, 0, 1)), f.x),
			mix(dot(hash33(i + vec3(0, 1, 1)), f - vec3(0, 1, 1)),
				dot(hash33(i + vec3(1, 1, 1)), f - vec3(1, 1, 1)), f.x), f.y), f.z);
}

// Bruit fractal
float fbm3d(vec3 p) {
	float value = 0.0;
	float amplitude = 0.5;
	
	for (int i = 0; i < 4; i++) {
		value += amplitude * noise3d(p);
		p *= 2.0;
		amplitude *= 0.5;
	}
	
	return value;
}

void fragment() {
	// Position 3D pour variation uniforme
	vec3 pos = vec3(UV * echelle_texture, 0.0);
	
	// Texture granuleuse fine
	float grain_fin = fbm3d(pos * 15.0) * intensite_grain;
	
	// Variation de couleur subtile (imperfections du plâtre)
	float variation_couleur = fbm3d(pos * 2.0) * 0.08;
	
	// Légères fissures/imperfections
	float imperfections = fbm3d(pos * 8.0) * 0.05;
	
	// Couleur finale avec toutes les variations
	vec3 couleur_finale = couleur_base + vec3(variation_couleur) + vec3(grain_fin);
	couleur_finale = clamp(couleur_finale, vec3(0.0), vec3(1.0));
	
	ALBEDO = couleur_finale;
	ROUGHNESS = rugosite + fbm3d(pos * 20.0) * 0.1; // Rugosité variable
	METALLIC = 0.0;
	
	// Normal map pour relief subtil
	float relief_x = fbm3d(pos + vec3(0.01, 0.0, 0.0)) - fbm3d(pos - vec3(0.01, 0.0, 0.0));
	float relief_y = fbm3d(pos + vec3(0.0, 0.01, 0.0)) - fbm3d(pos - vec3(0.0, 0.01, 0.0));
	
	vec3 normal_detail = vec3(relief_x, relief_y, 1.0) * intensite_relief;
	NORMAL_MAP = normalize(vec3(0.5) + normal_detail * 0.1);
}
