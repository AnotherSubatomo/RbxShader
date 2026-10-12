
--[=[
	StarNest
	Shader by @Kali on https://www.shadertoy.com/view/XlfGRj
	Ported to Luau — ran by my engine — `RbxShader`.
	
	( Original comments are preserved. )
	
	NOTE:
	- very resource intensive, our goal is to be able
	  to render this efficiently without changing this
	  programs code
]=]

--!strict
--!optimize 2
--!native

type vec3 = vector
type vec2 = vector
type iTime = number

const vec2 = vector.create
const vec3 = vector.create
const cos = math.cos
const sin = math.sin
const abs = math.abs

-- Star Nest by Pablo Roman Andrioli
-- License: MIT

-- DEFINES
const iterations = 17
const formuparam = 0.53

const volsteps = 20
const stepsize = 0.1

const zoom = 0.800
const tile = 0.850
const speed = 0.010 

const brightness = 0.0015
const darkmatter = 0.300
const distfading = 0.730
const saturation = 0.850

const tile2 = tile * 2

local time: iTime
local init_from: vec3
local res_x: number, res_y: number
local R1_C1: vec2, R1_C2: vec2
local R2_C1: vec2, R2_C2: vec2

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
		time = iTime * speed + .25
		init_from = vec3(1, 0.5, 0.5)
		init_from += vec3(time * 2, time, -2)

		const a1 = 0.5 + iMouse.x / res_x * 2
		const a2 = 0.8 + iMouse.y / res_y * 2

		R1_C1, R1_C2 = vec2(cos(a1), -sin(a1)), vec2(sin(a1), cos(a1))
		R2_C1, R2_C2 = vec2(cos(a2), -sin(a2)), vec2(sin(a2), cos(a2))
	end;
	
	mainImage = function (fragCoord: vec2): (vec3, number)
		-- get coords and direction
		const _dir_x = (fragCoord.x/res_x - .5) * zoom
		const _dir_y = (fragCoord.y/res_y - .5 * res_y/res_x) * zoom
		
		-- mouse rotation
		const dir_xz = R1_C1 * _dir_x + R1_C2
		const dir_xy = R2_C1 * dir_xz.x + R2_C2 * _dir_y
		const dir_x, dir_y, dir_z = dir_xy.x, dir_xy.y, dir_xz.y

		const from_xz = R1_C1 * init_from.x + R1_C2 * init_from.z
		const from_xy = R2_C1 * from_xz.x + R2_C2 * init_from.y
		const from_x, from_y, from_z = from_xy.x, from_xy.y, from_xz.y
		
		-- volumetric rendering (scalar optimized)
		local s, fade = 0.1, 1.0
		local v_x, v_y, v_z = 0.0, 0.0, 0.0

		for r = 1, volsteps do
			const k = s * 0.5
			local p_x = from_x + dir_x * k
			local p_y = from_y + dir_y * k
			local p_z = from_z + dir_z * k

			-- tiling fold
			p_x = tile - (p_x % tile2)
			p_y = tile - (p_y % tile2)
			p_z = tile - (p_z % tile2)

			local pa, a = 0.0, 0.0

			for i = 1, iterations do
				-- the magic formula
				const ax, ay, az = abs(p_x), abs(p_y), abs(p_z)
				const r2 = p_x*p_x + p_y*p_y + p_z*p_z
				const inv = 1 / r2

				p_x = ax * inv - formuparam
				p_y = ay * inv - formuparam
				p_z = az * inv - formuparam

				-- absolute sum of average change
				const l = math.sqrt(p_x*p_x + p_y*p_y + p_z*p_z)
				a += math.abs(l - pa)
				pa = l
			end

			-- dark matter
			const dm = math.max(0, darkmatter - a*a*0.001)
			-- add contrast
			a = a * a * a
			-- dark matter, don't render near
			if r > 6 then
				fade *= 1 - dm
			end

			-- v += vec3(dm,dm*.5,0.)

			v_x += fade
			v_y += fade
			v_z += fade

			-- coloring based on distance
			const sb = s*s
			const sc = sb*sb
			const kcol = a * brightness * fade
			v_x += s  * kcol
			v_y += sb * kcol
			v_z += sc * kcol

			-- distance fading
			fade *= distfading
			s += stepsize
		end

		-- color adjust
		const lv = math.sqrt(v_x*v_x + v_y*v_y + v_z*v_z)
		v_x = lv + (v_x - lv) * saturation
		v_y = lv + (v_y - lv) * saturation
		v_z = lv + (v_z - lv) * saturation

		return vec3(v_x * 0.01, v_y * 0.01, v_z * 0.01), 1;
	end;
}