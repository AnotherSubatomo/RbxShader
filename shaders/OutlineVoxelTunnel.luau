
--[=[
	OutlineVoxelTunnel
	Shader by @lsdlive on https://www.shadertoy.com/view/MscBRs
	Ported to Luau — ran by my engine — `RbxShader`.
	
	( Original comments are preserved. )
]=]

--!strict
--!optimize 2
--!native

type vec3 = vector
type vec2 = vector
type iTime = number

const vec2 = vector.create
const vec3 = vector.create
const sin = math.sin
const cos = math.cos
const min = math.min
const sign = math.sign
const abs = math.abs
const length = vector.magnitude
const normalize = vector.normalize
const cross = vector.cross
const mix = vector.lerp

const INV_SQRT3 = 0.5773502691896258 -- 1/sqrt(3)
const VEC3_Y = vec3(0, 1, 0)
const CONST_VEC_1 = vec3(1., .5, .75)
const CONST_VEC_2 = vec3(.2, .2, .7)
const CONST_VEC_3 = vec3(.2, .1, .2)

const function r2d(a: number): (vec2, vec2)
	const c, s = cos(a), sin(a)
	return vec2(c, -s), vec2(s, c)
end

const function path(t: number): (number, number)
	const a, b = sin(t*.2 + 1.5), sin(t*.2)
	return 2.*a, a*b
end


local g = 0.
local t: iTime
local sin_t: number

const function de(p_x: number, p_y: number, p_z: number): (number)
	const path_x, path_y = path(p_z)
	p_x -= path_x
	p_y -= path_y

	local d = 4 - (math.sqrt(p_x*p_x + p_y*p_y)) -- tunnel (inverted cylinder)

	const opt0 = cos(p_z + t) -- @temp
	p_x += opt0 * sin_t
	p_y += opt0
	p_z -= 6. + t * 6.
	d = min(d, (abs(p_x) + abs(p_y) + abs(p_z)) * INV_SQRT3 - 1.) -- octahedron (modified for optimization)
	-- I added this in the last 1-2 minutes, but I'm not sure if I like it actually!

	-- Trick inspired by balkhan's shadertoys.
	-- Usually, in raymarch shaders it gives a glow effect,
	-- here, it gives a colors patchwork & transparent voxels effects.
	g += .015 / (.01 + d * d)
	return d
end

local res_x: number, res_y: number
local dt: iTime

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
		t = iTime
		sin_t = sin(t)
		dt = iTime * 6.
	end;
	
	mainImage = function (fragCoord: vec2): (vec3, number)
		g = 0
		const uv = vec2(
			(fragCoord.x / res_x - .5) * (res_x / res_y),
			fragCoord.y / res_y - .5)

		const ro_z = -5. + dt
		const ta_z = dt
		const ro_x, ro_y = path(ro_z)
		const ta_x, ta_y = path(ta_z)
		const ro = vec3(ro_x, ro_y, ro_z)
		const ta = vec3(ta_x, ta_y, ta_z)

		const fwd = normalize(ta - ro)
		const right = cross(fwd, VEC3_Y)
		const up = cross(right, fwd)
		const rd = normalize(fwd + uv.x*right + uv.y*up)
		local rd_x, rd_y, rd_z = rd.x, rd.y, rd.z :: number

		const m1c1, m1c2 = r2d(sin(-ro_x / 3.14) * .3) -- @temp
		const rd0 = m1c1 * rd_x + m1c2 * rd_y -- @temp
		rd_x, rd_y = rd0.x, rd0.y

		-- Raycast in 3d to get voxels.
		-- Algorithm fully explained here in 2D (just look at dde algo):
		-- http://lodev.org/cgtutor/raycasting.html
		-- Basically, tracing a ray in a 3d grid space, and looking for 
		-- each voxel (think pixel with a third dimension) traversed by the ray.
		local p_x, p_y, p_z = ro_x // 1 + .5, ro_y // 1 + .5, ro_z // 1 + .5
		local mask_x, mask_y, mask_z = 0, 0, 0
		const drd_x, drd_y, drd_z = 1 / abs(rd_x), 1 / abs(rd_y), 1 / abs(rd_z)
		rd_x, rd_y, rd_z = sign(rd_x), sign(rd_y), sign(rd_z)
		local side_x = drd_x * rd_x * (p_x - ro_x) + .5
		local side_y = drd_y * rd_y * (p_y - ro_y) + .5
		local side_z = drd_z * rd_z * (p_z - ro_z) + .5

		local ti = 0
		for i = 0, .99, .01 do

			--[[
			-- sphere tracing algorithm (for comparison)
			p = ro + rd * ti
			const d = de(p)
			if(d < .001) theb break end
			ti += d
			]]

			if de(p_x, p_y, p_z) < 0 then break end -- distance field
								-- we test if we are inside the surface
			mask_x = if (side_y < side_x or side_z < side_x) then 0 else 1
			mask_y = if (side_z < side_y or side_x < side_y) then 0 else 1
			mask_z = if (side_x < side_z or side_y < side_z) then 0 else 1
			-- minimum value between x,y,z, output 0 or 1

			side_x += drd_x * mask_x
			side_y += drd_y * mask_y
			side_z += drd_z * mask_z
			p_x += rd_x * mask_x
			p_y += rd_y * mask_y
			p_z += rd_z * mask_z
		end
		ti = length(vec3(p_x - ro_x, p_y - ro_y, p_z - ro_z))

		const mask = vec3(mask_x, mask_y, mask_z)
		local c = mix(CONST_VEC_2, CONST_VEC_3, length(mask * CONST_VEC_1));
		const opt0 = g * .4 -- @temp
		const rings = sin_t * .2 + sin(p_z*.5 - t * 6.) -- red rings
		c = vec3(c.x + opt0 + rings, c.y + opt0, c.z + opt0)
		c = mix(c, CONST_VEC_3, 1. - math.exp(-.001*ti*ti)) -- fog

		return c, 1;
	end;
}