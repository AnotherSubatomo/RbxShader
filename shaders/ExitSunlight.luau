
--[=[
	ExitSunlight
	Shader by @felixfaire on https://www.shadertoy.com/view/llBXWV
	Ported to Luau — ran by my engine — `RbxShader`.
]=]

--!strict
--!optimize 2
--!native

type vec3 = vector
type vec2 = vector

const vec3 = vector.create
const sin = math.sin
const abs = math.abs
const mix = math.lerp
const VEC3_Z = vector.create(0, 0, 1)

const function mix_v(a: vector, b: vector, t: number): (vector)
	return a + t * (b - a)
end

const function smoothstep(edge0: number, edge1: number, x: number): (number)
	const t = math.clamp((x - edge0) / (edge1 - edge0), 0, 1)
	return t * t * (3 - 2 * t)
end

const SUNSET_COLOR = vec3(0.938, 0.678, 0.375);
const SKY_COLOR = vec3(0.455, 0.456, 0.55);
const BASE_BRIGHTNESS = vec3(0.2, 0.2, 0.2);
const SCATTER_FACTOR = vec3(1.0, 1.0, 1.0);
const GLOW_FACTOR = vec3(0.3, 0.3, 0.3);
const HILL_SHADE = vec3(0.8, 0.8, 0.8);
const VIGNETTE_FACTOR = vec3(0.2, 0.2, 0.2);
const SHADOW_FACTOR = vec3(0.6, 0.6, 0.6);
const SAND_FACTOR = vec3(0.2, 0.2, 0.2);
const REFLECTION_FACTOR = vec3(0.3, 0.3, 0.3);

const hillSoftening = 0.01;
const reflectionSoftening = 0.1;
 
const function hash(n: number): (number)
    const v = sin(n) * 43758.5453
	return v - v // 1
end
 
const function noise(x_y: number): (number)
    const p_y = x_y // 1;
    local f_y = x_y - p_y;
    f_y = f_y * f_y * (3.0 - 2.0 * f_y);
    const n = p_y * 57.0;
    const res = mix(hash(n + 0.0), hash(n + 57.0), f_y);
    return res;
end
 
-- * optimized for our usage
const function fbm(p_y: number): (number)
    local f = 0.0;
    f += 0.50000 * noise(p_y); p_y = p_y * 2.02;
    f += 0.25000 * noise(p_y); p_y = p_y * 2.03;
    f += 0.12500 * noise(p_y); p_y = p_y * 2.01;
    f += 0.06250 * noise(p_y); p_y = p_y * 2.04;
    f += 0.03125 * noise(p_y);
    return f / 0.984375;
end

const function perlin(P_x: number, P_y: number, rep_x: number, rep_y: number): (number)
    const P_floor_x, P_floor_y = P_x // 1, P_y // 1;
    const P_fract_x, P_fract_y = P_x - P_floor_x, P_y - P_floor_y;
    
    -- `% rep` To create noise with explicit period
    -- `% 289` To avoid truncation effects in permutation
    local Pi_x = (P_floor_x % rep_x) % 289;
    const Pi_y = (P_floor_y % rep_y) % 289;
    local Pi_z = ((P_floor_x + 1.0) % rep_x) % 289;
    const Pi_w = ((P_floor_y + 1.0) % rep_y) % 289;
    
    const Pf_x = P_fract_x;
    const Pf_y = P_fract_y;
    const Pf_z = P_fract_x - 1.0;
    const Pf_w = P_fract_y - 1.0;
    
    Pi_x = ((Pi_x * 34.0 + 1.0) * Pi_x) % 289;
    Pi_z = ((Pi_z * 34.0 + 1.0) * Pi_z) % 289;
    
    local perm00 = Pi_x + Pi_y; perm00 = (((perm00 * 34.0) + 1.0) * perm00) % 289;
    local perm10 = Pi_z + Pi_y; perm10 = (((perm10 * 34.0) + 1.0) * perm10) % 289;
    local perm01 = Pi_x + Pi_w; perm01 = (((perm01 * 34.0) + 1.0) * perm01) % 289;
    local perm11 = Pi_z + Pi_w; perm11 = (((perm11 * 34.0) + 1.0) * perm11) % 289;

    -- Gradient
    const inv_41 = 1.0 / 41.0;
    local g00 = perm00 * inv_41; g00 = (g00 - g00 // 1) * 2.0 - 1.0;
    local g10 = perm10 * inv_41; g10 = (g10 - g10 // 1) * 2.0 - 1.0;
    local g01 = perm01 * inv_41; g01 = (g01 - g01 // 1) * 2.0 - 1.0;
    local g11 = perm11 * inv_41; g11 = (g11 - g11 // 1) * 2.0 - 1.0;
    
    -- Normalize gradients
    local g00y, g00x = abs(g00) - 0.5, g00 - (g00 + 0.5) // 1;
    local g10y, g10x = abs(g10) - 0.5, g10 - (g10 + 0.5) // 1;
    local g01y, g01x = abs(g01) - 0.5, g01 - (g01 + 0.5) // 1;
    local g11y, g11x = abs(g11) - 0.5, g11 - (g11 + 0.5) // 1;

    const norm_x = 1.79284291400159 - 0.85373472095314 * (g00x * g00x + g00y * g00y);
    const norm_y = 1.79284291400159 - 0.85373472095314 * (g01x * g01x + g01y * g01y);
    const norm_z = 1.79284291400159 - 0.85373472095314 * (g10x * g10x + g10y * g10y);
    const norm_w = 1.79284291400159 - 0.85373472095314 * (g11x * g11x + g11y * g11y);

    g00x *= norm_x; g00y *= norm_x;
    g01x *= norm_y; g01y *= norm_y;
    g10x *= norm_z; g10y *= norm_z;
    g11x *= norm_w; g11y *= norm_w;

    -- Dot products
    const n00 = g00x * Pf_x + g00y * Pf_y;
    const n10 = g10x * Pf_z + g10y * Pf_y;
    const n01 = g01x * Pf_x + g01y * Pf_w;
    const n11 = g11x * Pf_z + g11y * Pf_w;

    -- Fade
    const t_x = Pf_x;
    const t_y = Pf_y;
    const fade_x = t_x * t_x * t_x * (t_x * (t_x * 6.0 - 15.0) + 10.0);
    const fade_y = t_y * t_y * t_y * (t_y * (t_y * 6.0 - 15.0) + 10.0);

    -- Interpolate
    const nx0 = mix(n00, n10, fade_x);
    const nx1 = mix(n01, n11, fade_x);
    const nxy = mix(nx0, nx1, fade_y);

    return 2.3 * nxy;
end

const REP50 = 50.0;
const REP100 = 100.0;

local aspect: number
local res_x: number, res_y: number
local t: number

-- Shader program
return {
	CONFIGURATION = {
		InterlaceFactor = 4;
		ScreenDivision = Vector2.new(4, 2);
	};

	init = function (iResolution: vec2): ()
		res_x, res_y = iResolution.x, iResolution.y;
		aspect = res_x / res_y;
	end;

	perFrame = function (iTime: number): ()
		t = iTime * 0.5;
	end;
	
	mainImage = function (fragCoord: vec2): (vec3, number)
		local uv_x = ((fragCoord.x / res_x) * 2.0 - 1.0) * aspect;
		local uv_y = (fragCoord.y / res_y) * 2.0 - 1.0;

		local col = vector.zero;
		const ax = abs(uv_x);

		if (ax < 1.0) then
			const ay = abs(uv_y);

			-- sky
			col += mix_v(SUNSET_COLOR, SKY_COLOR, ay) + BASE_BRIGHTNESS;
			col += mix_v(SCATTER_FACTOR, GLOW_FACTOR, abs((uv_y - 0.45) * 1.5)) * 0.3;

			-- hills
			local ux3 = uv_x * 3.0;
			for i = 0, 1 do
				const edge = fbm(ux3 + i) * 0.15 + 0.1;
				if (uv_y < edge + hillSoftening and uv_y > 0.0) then
					col -= HILL_SHADE * smoothstep(edge + hillSoftening, edge, uv_y);
				end
			end

			-- vignette
			const r2 = uv_x * uv_x + uv_y * uv_y;
			col -= r2 * VIGNETTE_FACTOR;

			const dist = 1.0 - ay * 0.9;
			const dist2 = dist * dist;
			const dist3 = dist2 * dist;

			uv_y *= 0.9;

			-- shadows + sand
			if (uv_y < 0.1) then
				uv_x *= dist * 1.2;
				col -= SHADOW_FACTOR * smoothstep(-0.3, 0.1, uv_y);

				const p1_x, p1_y = uv_x * 3.5 * dist + dist * 100.0, uv_y * 40.0 * dist;
				const p2_x, p2_y = uv_x * 5.0 * dist3, uv_y * 1.0 * dist;

				const sand = perlin(p1_x, p1_y, REP100, REP100) - perlin(p2_x, p2_y, REP100, REP100);

				if (sand > 0.4) then
					col -= smoothstep(0.4, 0.7, dist) * smoothstep(0.4, 0.8, sand) * SAND_FACTOR;
				end
			end

			-- warp reflections
			if (uv_y < 0.0) then
				const p34_x = uv_x * 10.0 * dist;
				const p3_y = uv_y * 100.0 * dist + t;
				const p4_y = uv_y * (100.0 * dist + 20.0) + t;

				uv_x += 0.05 * perlin(p34_x, p3_y, REP100, REP100);
				uv_y += 0.04 * perlin(p34_x, p4_y, REP50, REP100) * (0.5 + ax * 2.0) - 0.05;
			end

			-- mountain reflections
			ux3 = uv_x * 3.0;
			for i = 0, 1 do
				const edge = fbm(ux3 + i) * 0.1 + 0.1;
				if (uv_y > -edge - reflectionSoftening and uv_y < 0.1) then
					col -= REFLECTION_FACTOR * smoothstep(-edge - reflectionSoftening, -edge, uv_y);
				end
			end

			-- highlights
			col = col + vector.one * (
				- smoothstep(0.5, 0.0, abs(uv_y + 0.6)) * 0.2
				+ smoothstep(0.3, 0.0, abs(uv_y + 0.3)) * 0.1
				- smoothstep(0.6, 0.0, abs(uv_y + 1.0)) * 0.1);
			col += VEC3_Z * 0.05 * (1.0 - dist);
		end

		return col, 1;
	end;
}