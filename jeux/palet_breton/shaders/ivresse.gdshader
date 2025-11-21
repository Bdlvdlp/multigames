shader_type canvas_item;

uniform float force_ivresse : hint_range(0.0, 5.0) = 0.0;
uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_linear_mipmap;

void fragment() {
	// Si pas d'ivresse, on affiche juste l'écran normal
	if (force_ivresse <= 0.01) {
		COLOR = texture(screen_texture, SCREEN_UV);
	} else {
		vec2 uv = SCREEN_UV;
		
		// 1. Ondulation / Distorsion
		float time = TIME * 0.5;
		// Ondulation lente et large
		float wave_x = sin(uv.y * 2.0 + time) * 0.005 * force_ivresse;
		float wave_y = cos(uv.x * 2.0 + time * 1.3) * 0.005 * force_ivresse;
		
		uv.x += wave_x;
		uv.y += wave_y;
		
		// 2. Aberration Chromatique (décalage des canaux RGB)
		float aber_amount = 0.002 * force_ivresse;
		
		vec4 r = texture(screen_texture, uv + vec2(aber_amount, 0.0));
		vec4 g = texture(screen_texture, uv);
		vec4 b = texture(screen_texture, uv - vec2(aber_amount, 0.0));
		
		COLOR = vec4(r.r, g.g, b.b, 1.0);
		
		// Ajout d'un léger vignettage pulsant
		float vignette = 1.0 - distance(uv, vec2(0.5));
		vignette = smoothstep(0.2, 0.8, vignette);
		float pulse = 1.0 - (sin(time * 2.0) * 0.1 * force_ivresse);
		COLOR.rgb *= (0.9 + 0.1 * pulse);
	}
}
