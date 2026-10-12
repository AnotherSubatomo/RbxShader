
--[=[
	VoxelShader
	Shader by @Xor on https://www.shadertoy.com/view/fstSRH
	Ported to Luau — ran by my engine — `RbxShader`.
	
	( Original comments are preserved. )
]=]

--!strict
--!optimize 2
--!native

type vec3 = vector
type vec2 = vector

const vec3 = vector.create
const length = vector.magnitude
const sin = math.sin
const min = math.min
const sqrt = math.sqrt

const VEC3_0 = vector.zero
const VEC3_18 = vec3(18, 18, 18)
const VEC3_9 = vec3(9, 9, 9)
const COLOR_R = 0
const COLOR_G = 2
const COLOR_B = 4
const VEC3_1EM4 = vec3(1e-4, 1e-4, 1e-4)
const VEC3_0P5 = vec3(0.5, 0.5, 0.5)

const function map(v: vec3 , iTime: number): (number)
	-- modulated vector
	const mv = v - v // VEC3_18 * VEC3_18
	return length(mv - VEC3_9) - 9.5 + sin(v.z * 0.3 - iTime * 0.1)
end

const function fract_v3(v: vec3): (vec3)
	return v - vector.floor(v)
end

const function smoothstep(edge0: number, edge1: number, x: number): (number)
	const t = math.clamp((x - edge0) / (edge1 - edge0), 0, 1)
	return t * t * (3 - 2 * t)
end

local res: vec2, res_x: number, res_y: number
local iTime_0P2: number
local cam: vec3

-- Shader program
return {
	CONFIGURATION = {
		InterlaceFactor = 2;
		ScreenDivision = Vector2.new(4, 2);
	};

	init = function (iResolution: vec2): ()
		res, res_x, res_y = iResolution, iResolution.x, iResolution.y
	end;

	perFrame = function (iTime: number): ()
		-- Camera position
		iTime_0P2 = iTime*0.2
		cam = vec3(
			sin(iTime_0P2+res_x),
			sin(iTime_0P2+res_y),
			iTime
		)
	end;
	
	mainImage = function (fragCoord: vec2, _, iTime: number): (vec3, number)
		-- Pixel position
		local pos = cam
		-- Ray direction
		const ray_xy = fragCoord*2 - res
		const ray = vector.normalize(vec3(ray_xy.x, ray_xy.y, res_y))
		-- Voxel cell
		local cell = VEC3_0

		-- Step up to 100 voxels.
		for i = 1, 100 do
			-- Axis distance to nearest cell (with a small bias).
			const dist = fract_v3(-pos * vector.sign(ray)) + VEC3_1EM4
			-- Alternative version (produces artifacts after a while)
			-- const dist = 1-fract_v3(pos * vector.sign(ray))
			-- Raytraced distance to each axis.
			const leng = dist / vector.abs(ray)
			-- Nearest axis' raytrace distance (as a vec3).
			const near = min(leng.x, leng.y, leng.z)

			-- Step to the nearest voxel cell.
			pos += ray * near
			-- Get the cell position (center of the voxel).
			cell = vector.ceil(pos) - VEC3_0P5
			-- Stop if we hit a voxel.
			if map(cell, iTime) < 0 then
				break
			end
		end

		-- Rainbow color based off the voxel cell position.
		const cell_z = cell.z
		local color = vec3(
			sin(COLOR_R + cell_z),
			sin(COLOR_G + cell_z),
			sin(COLOR_B + cell_z)
		) * 0.5 + VEC3_0P5
		-- Square for gamma encoding.
		color *= color

		-- Compute cheap ambient occlusion from the SDF.
		const ao = smoothstep(-1, 1, map(pos, iTime))
		-- Fade out to black using the distance.
		const fog = min(1, math.exp(1 - length(pos-cam)/8))

		-- Output final color with ao and fog (sqrt for gamma correction).
		const fragColor = color * ao * fog
		return vec3(sqrt(fragColor.x), sqrt(fragColor.y), sqrt(fragColor.z)), 1;
	end;
}