
--[=[
	SimpleOceanWaves
	Shader by @jarble on https://www.shadertoy.com/view/ftS3zh
	Ported to Luau — ran by my engine — `RbxShader`.
	
	( Original comments are preserved. )
]=]

--!strict
--!optimize 2
--!native

type vec3 = vector
type vec2 = vector
type iTime = number

const vec3 = vector.create
const dot = vector.dot
const cross = vector.cross
const normalize = vector.normalize
const mix = vector.lerp
const sin = math.sin
const abs = math.abs
const max = math.max
const sqrt = math.sqrt
const clamp = math.clamp
const exp = math.exp
const pow = math.pow

const function smoothstep(edge0: number, edge1: number, x: number): (number)
	const t = math.clamp((x - edge0) / (edge1 - edge0), 0, 1)
	return t * t * (3 - 2 * t)
end

const SC = 250.0
const SC_INV = 1.0 / SC
const SC_BIG = SC * 1000.0
const SC_INV_SMALL = 0.0005 * SC_INV

const VEC3_Y = vec3(0, 1, 0)

const T_MIN = 0.1
const T_MAX = 20.0

const OCTAVES = 4
const PERSISTENCE = 0.37
const LACUNARITY = 3.0 + 1.0 / 3.0

const WAVE_OUTLINE_COLOR = vec3(1.0, 0.956, 0.839)
const SUN_EMISSION_COLOR = vec3(1.0, 0.7, 0.4) * 0.25
const SUN_GLOW_COLOR = vec3(1.0, 0.8, 0.6) * 0.25
const SUN_COLOR = vec3(1.0, 0.8, 0.6) * 0.2
const DIFFUSION_FACTOR = vec3(0.0, 0.6, 1.0) * 0.1
const CLOUD_COLOR = vec3(1.0, 0.95, 1.0)
const SKY_COLOR = vec3(0.3, 0.5, 0.85)
const HAZE_COLOR = vec3(0.7, 0.75, 0.85) * 0.85
const FADE_COLOR = vec3(0.4, 0.65, 1.0) * 0.68
const FOG_COLOR = vec3(0.4, 0.65, 1.0) * 0.65
const ALBEDO = 1

const LIGHT_DIR = normalize(vec3(-0.8, 0.15, -0.3))
const CAM_STEP = vec3(LIGHT_DIR.x, 0.0, LIGHT_DIR.z)
const CAM_POS = vec3(8.0, 2.0, 5.0) + CAM_STEP
const CAM_TARGET = vec3(1.0, 1.0, 4.0) + CAM_STEP
const CAM_ROLL = 0.0

const RR = vec3(sin(CAM_ROLL), math.cos(CAM_ROLL), 0.0)
const WW = normalize(CAM_TARGET - CAM_POS)
const UU = normalize(cross(WW, RR))
const VV = normalize(cross(UU, WW))

local res_x: number, res_y: number
local t: iTime

const function noise(x: number): (number)
	return sin(x - t)
end

const function fbm(uv_x: number, uv_y: number): (number)
	local value = 0.0
	local amplitude = 1.0
	local freq = 0.8

	for _ = 1, OCTAVES do
        -- value += noise(uv * freq) * amplitude;
        
        -- From Dave_Hoskins https://www.shadertoy.com/user/Dave_Hoskins
		value += (0.25 - abs(noise(uv_x * freq) - 0.3)) * amplitude
		amplitude *= PERSISTENCE
		freq *= LACUNARITY

		uv_x, uv_y =
			uv_x + uv_y / 10.0,
			uv_y + uv_x / 10.0
        -- uv_x, uv_y = uv_y, uv_x
	end

	return value
end

const function getNormal(p: vec3, t: number): (vec3)
	const eps = 0.001 * t
	const px, pz = p.x, p.z

	return normalize(vec3(
		fbm(px - eps, pz) - fbm(px + eps, pz),
		2.0 * eps,
		fbm(px, pz - eps) - fbm(px, pz + eps)
	))
end

const function rayMarching(ro: vec3, rd: vec3): (number)
	local t = T_MIN

	for _ = 1, 300 do
		const pos = ro + rd * t
		const h = pos.y - fbm(pos.x, pos.z)
		if abs(h) < (0.0015 * t) or t > T_MAX then break end
		t += 0.4 * h
	end

	return t
end

const function lighting(p: vec3, normal: vec3, V: vec3): (vec3)
	const diff = max(dot(normal, LIGHT_DIR) * ALBEDO, 0.0)
	const refl = normalize(LIGHT_DIR - normal * (2.0 * dot(LIGHT_DIR, normal)))
	local spec = max(dot(refl, -normalize(V)), 0.0)
	spec = clamp(pow(spec, 18.0), 0.0, 1.0)
	const sky = max(0.0, dot(VEC3_Y, normal))

	-- float amb = 0.5 * smoothstep(0.0, 2.0, p.y)

	local col = diff * WAVE_OUTLINE_COLOR
	col += spec * WAVE_OUTLINE_COLOR
	col += sky * DIFFUSION_FACTOR

	-- col += amb * .2

	return col
end

-- Shader program
return {
	CONFIGURATION = {
		InterlaceFactor = 2;
		ScreenDivision = Vector2.new(4, 2);
	};

	init = function (iResolution: vec2): ()
		res_x, res_y = iResolution.x, iResolution.y
	end;
	
	perFrame = function (iTime: number): ()
		t = iTime / 2.0
	end;
	
	mainImage = function (fragCoord: vec2): (vec3, number)
		const uv_x = (fragCoord.x - res_x * 0.5) / res_y
		const uv_y = (fragCoord.y - res_y * 0.5) / res_y
		-- transform UV to camera parameters
		const rd = normalize(UU * uv_x + VV * uv_y + WW)
		const ro = CAM_POS

		const t = rayMarching(ro, rd)
		local col = vector.zero

		if t > T_MAX then
			-- from iq's shader, https://www.shadertoy.com/view/MdX3Rr
			const sd = clamp(dot(rd, LIGHT_DIR), 0.0, 1.0)
			const sd5 = sd * sd * sd * sd * sd
			const sd16 = sd5 * sd5 * sd5 * sd --@temp
			const sd64 = sd16 * sd16 * sd16 * sd16
			const sd256 = sd64 * sd64 * sd64 * sd64 --@temp

			col = SKY_COLOR - vector.one * rd.y * rd.y * 0.5
			col = mix(col, HAZE_COLOR, pow(1.0 - max(rd.y, 0.0), 4.0))
			-- sun
			col += SUN_EMISSION_COLOR * sd5
			col += SUN_GLOW_COLOR * sd64
			col += SUN_COLOR * sd256 * sd256
			-- clouds
			const opt0 = (SC_BIG - ro.y) / rd.y
			const sc_x = (ro.x + rd.x * opt0) * SC_INV_SMALL
			const sc_y = (ro.z + rd.z * opt0) * SC_INV_SMALL
			col = mix(col, CLOUD_COLOR, 0.5 * smoothstep(0.5, 0.8, fbm(sc_x, sc_y)))
			-- horizon
			col = mix(col, FADE_COLOR, pow(1.0 - max(rd.y, 0.0), 16.0))
		else
			const p = ro + rd * t
			const normal = getNormal(p, t)
			const viewDir = normalize(ro - p)
			-- lighting terrain
			col = lighting(p, normal, viewDir)
			-- fog
			const fo = 1.0 - exp(-pow(30.0 * t * SC_INV, 1.5))
			col = mix(col, FOG_COLOR, fo)
		end

		-- gamma correction (optimized)
		col = vec3(
			sqrt(clamp(col.x, 0, 1)),
			sqrt(clamp(col.y, 0, 1)),
			sqrt(clamp(col.z, 0, 1))
		)

		return col, 1;
	end;
}