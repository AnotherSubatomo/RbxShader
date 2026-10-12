
--[=[
	Clouds
	Shader by @zxxuan1001 on https://www.shadertoy.com/view/tlB3zK
	Ported to Luau — ran by my engine — `RbxShader`.
	
	( Original comments are preserved. )
]=]

--!strict
--!optimize 2
--!native

type vec3 = vector
type vec2 = vector

const vec3 = vector.create
const dot = vector.dot
const mix = vector.lerp
const sin = math.sin

const function smoothstep(edge0: number, edge1: number, x: number): (number)
	const t = math.clamp((x - edge0) / (edge1 - edge0), 0, 1)
	return t * t * (3 - 2 * t)
end

-- noise function from iq: https://www.shadertoy.com/view/Msf3WH
const HASH_X1, HASH_Y1 = 127.1, 311.7
const HASH_X2, HASH_Y2 = 269.5, 183.3
const HASH_FLOAT = 43758.5453123

const function hash(p_x: number, p_y: number): (number, number)
	const p_hash_sin_x = sin((p_x * HASH_X1 + p_y * HASH_Y1)) * HASH_FLOAT
	const p_hash_sin_y = sin((p_x * HASH_X2 + p_y * HASH_Y2)) * HASH_FLOAT
	return
		(p_hash_sin_x - p_hash_sin_x // 1) * 2.0 - 1.0,
		(p_hash_sin_y - p_hash_sin_y // 1) * 2.0 - 1.0
end

const K1 = 0.366025404 -- (sqrt(3)-1)/2;
const K2 = 0.211324865 -- (3-sqrt(3))/6;
const K2_2 = K2 * 2
const NOISE_VEC = vec3(70, 70, 70)

const function noise(p_x: number, p_y: number): (number)
	const iK = (p_x + p_y) * K1 -- @temp
	const i_x = (p_x + iK) // 1
	const i_y = (p_y + iK) // 1
	const aK = (i_x + i_y) * K2 -- @temp
	const a_x = p_x - i_x + aK
	const a_y = p_y - i_y + aK
    const m = if a_x < a_y then 0 else 1
    const o_x, o_y = m, 1.0 - m
	const b_x = a_x - o_x + K2
	const b_y = a_y - o_y + K2
	const c_x = a_x - 1.0 + K2_2
	const c_y = a_y - 1.0 + K2_2
	const h_x = math.max(0.5 - (a_x * a_x + a_y * a_y), 0.0)
	const h_y = math.max(0.5 - (b_x * b_x + b_y * b_y), 0.0)
	const h_z = math.max(0.5 - (c_x * c_x + c_y * c_y), 0.0)
	const sh1_x, sh1_y = hash(i_x, i_y)
	const sh2_x, sh2_y = hash(i_x + o_x, i_y + o_y)
	const sh3_x, sh3_y = hash(i_x + 1.0, i_y + 1.0)
	const n = vec3(
		h_x * h_x * h_x * h_x * (a_x * sh1_x + a_y * sh1_y),
		h_y * h_y * h_y * h_y * (b_x * sh2_x + b_y * sh2_y),
		h_z * h_z * h_z * h_z * (c_x * sh3_x + c_y * sh3_y))
    return dot(n, NOISE_VEC)
end

const M2_A, M2_B, M2_C, M2_D = 1.6, 1.2, -1.2, 1.6

const function fbm4(p_x: number, p_y: number): (number)
    local h = 0.0
    local a = 0.5
	
    h += a * noise(p_x, p_y); p_x, p_y = M2_A * p_x + M2_C * p_y, M2_B * p_x + M2_D * p_y; a *= 0.5
    h += a * noise(p_x, p_y); p_x, p_y = M2_A * p_x + M2_C * p_y, M2_B * p_x + M2_D * p_y; a *= 0.5
    h += a * noise(p_x, p_y); p_x, p_y = M2_A * p_x + M2_C * p_y, M2_B * p_x + M2_D * p_y; a *= 0.5
    h += a * noise(p_x, p_y)

    return 0.5 + 0.5 * h
end

const SKY_COLOR = vec3(0.5, 0.7, 0.8)
const CLOUD_COLOR = vector.one

local mo_x: number, mo_y: number
local res_x: number, res_y: number
local sin_time_2_20: number
local sin_time_50: number
local sin_time_20: number

-- Shader program
return {
	CONFIGURATION = {
		InterlaceFactor = 2;
		ScreenDivision = Vector2.new(4, 2);
	};

	init = function (iResolution: vec2): ()
		res_x, res_y = iResolution.x, iResolution.y
	end;

	perFrame = function (iTime: number, _, iMouse: vec2): ()
		mo_x = iMouse.x / res_x
		mo_y = iMouse.y / res_y
		
		-- speed
		const v = 0.001;
		const sin_time_2 = sin(iTime * v * 2.0)
		const sin_time = sin(iTime * v)

		sin_time_2_20 = 20.0 * sin_time_2
		sin_time_50 = 50.0 * sin_time
		sin_time_20 = 20.0 * sin_time
	end;
	
	mainImage = function (fragCoord: vec2): (vec3, number)
		-- Normalized pixel coordinates (from 0 to 1)
		local uv_x = (fragCoord.x / res_x - .5) * res_x / res_y;
		local uv_y = fragCoord.y / res_y - .5;
		
		uv_x += mo_x * 10.;
		uv_y += mo_y * 10.;
		
		local col = vector.zero;

		-- layer1
		local turbulence_x = noise(uv_x * 10.0, uv_y * 10.0) * 0.008;
		local turbulence_y = turbulence_x;
		
		local scale_x = uv_x * 2. + turbulence_x;
		local scale_y = uv_y * 2. + turbulence_y;
		
		const n1 = fbm4(scale_x - sin_time_2_20, scale_y - sin_time_50);
		col = mix(SKY_COLOR, CLOUD_COLOR, smoothstep(0.5, 0.8, n1));
		
		-- layer2
		turbulence_x = noise(uv_x * 2.0, uv_y * 2.1) * 0.05;
		turbulence_y = noise(uv_x * 1.5, uv_y * 1.2) * 0.05;
		
		scale_x = uv_x * .5 + turbulence_x;
		scale_y = uv_y * .5 + turbulence_y;
		
		const n2 = fbm4(scale_x + sin_time_20, scale_y + sin_time_20);
		col = mix(col, CLOUD_COLOR, smoothstep(0.2, 0.9, n2));
		col = vector.min(col, vector.one);
		
		-- Output to screen
		return col, 1;
	end;
}