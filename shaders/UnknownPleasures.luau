
--[=[
	UnknownPleasures
	Shader by @smiarx on https://www.shadertoy.com/view/4sVyWR
	Ported to Luau — ran by my engine — `RbxShader`.
	
	( Original comments are preserved. )
]=]

--!strict
--!optimize 2
--!native

type vec3 = vector
type vec2 = vector

const mix = math.lerp
const HALF_PI = 3.14159/2.

-- Defines
const LINEWIDTH = 3.2
const H = 35
const WAVEHEIGHT = 6.6
const WIDTH = 0.6
const CLOSENESS = 45
const OCTAVES = 3

const function random(x: number): (number)
	const r = math.sin(x)*43758.5453123
	return r - r // 1
end

const function noise(x: number): (number)
	const i = x // 1
	const f = x - x // 1
	
	const a = random(i)
	const b = random(i+1)
	
	const u = f * f * (3 - 2 * f)

	return mix(a, b, u)
end

const function fbm(x): (number)
	local value	 = 0.0
	local amplitude = .5

	for i = 1, OCTAVES, 1 do
		value += amplitude * noise(x)
		x *= 2.
		amplitude *= .7
	end

	return value
end

const function smoothstep(edge0: number, edge1: number, x: number): (number)
	const t = math.clamp((x - edge0) / (edge1 - edge0), 0, 1)
	return t * t * (3 - 2 * t)
end

local res_x: number, res_y: number
local linewidth: number

-- Shader program
return {
	CONFIGURATION = {
		InterlaceFactor = 2;
		ScreenDivision = Vector2.new(4, 2);
	};
	
	init = function (iResolution: vec2): ()
		res_x, res_y = iResolution.x, iResolution.y
		linewidth = CLOSENESS * LINEWIDTH / res_y
	end;

	mainImage = function (fragCoord: vec2, _, iTime: number): (vec3, number)
		const st_x = (2 * fragCoord.x - res_x) / res_y
		const st_y = (2 * fragCoord.y - res_y) / res_y * CLOSENESS

		local val = 0

		if math.abs(st_x) < WIDTH then
			const env = math.pow(math.cos(st_x/WIDTH*HALF_PI), 4.9)
			const i	= st_y // 1

			for n = math.max(-H, i-6), math.min(H, i), 1 do
				const f	= st_y - n
				local y	= f - 0.5
				y -= WAVEHEIGHT
					* math.pow(fbm(st_x*10.504 +n*432.1 + 0.5*iTime), 3)
					* env
					+ (fbm(st_x*25.+n*1292.21)-0.32)*2 * 0.15
				
				const grid = math.abs(y)
				val += (1-smoothstep(0, linewidth, grid))
				-- val = grid
				if y < 0 then break end
			end
		end

		return vector.create(val, val, val), val;
	end;
}