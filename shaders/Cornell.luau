
--[=[
	Cornell
	Shader by @Xor on https://www.shadertoy.com/view/ssKyzh
	Ported to Luau — ran by my engine — `RbxShader`.
	```
]=]

--!strict
--!optimize 2
--!native

type vec3 = vector
type vec2 = vector

const vec3 = vector.create
const dot = vector.dot

const VEC3_0 = vector.zero
const VEC3_P5 = vec3(0.5, 0.5, 0.5)
const VEC3_3 = vec3(3, 3, 3)
const VEC3_P8 = vec3(0.8, 0.8, 0.8)
const VEC3_P01 = vec3(0.01, 0.01, 0.01)
const INIT_Px = 0.0
const INIT_Py = 0.0
const INIT_Pz = 2.5

-- Ungolfed + lightly optimized version of
-- "Cornell [267 chars]" by @XorDev

local
	res: vec2,
	res_x: number,
	res_y: number,
	inv_res_x: number

-- Shader program
return {
	CONFIGURATION = {
		InterlaceFactor = 4;
		ScreenDivision = Vector2.new(4, 2);
	};

	init = function (iResolution: vec2): ()
		-- Resolution for scaling
		res = iResolution
		res_x = res.x
		res_y = res.y
		inv_res_x = 1.0 / res_x
	end;

	mainImage = function (fragCoord: vec2): (vec3, number)
		-- Camera position (approx.)
		local p_x, p_y, p_z = INIT_Px, INIT_Py, INIT_Pz
		-- Ray direction
		const rd_x, rd_y, rd_z =
			(fragCoord.x * 2.0 - res_x) * inv_res_x,
			(fragCoord.y * 2.0 - res_y) * inv_res_x, -1

		local a_x, a_y, a_z = 0, 0, 0
		local dp_x, dp_y, dp_z = 0, 0, 0
		local col = VEC3_0

		-- Iterate (raymarch) 26 times and set color
		for i = 1, 26 do
			a_x, a_y, a_z = math.abs(p_x), math.abs(p_y), math.abs(p_z)

			-- Box SDF (Cornell box)
			const box = 1.0 - math.max(a_x, a_y, -p_z)

			-- Sphere SDF
			dp_x = p_x + 0.5
			dp_y = p_y + 0.5
			dp_z = p_z + 0.5
			const sphere = math.sqrt(dp_x * dp_x + dp_y * dp_y + dp_z * dp_z) - 0.5

			const d = math.min(box, sphere)
			p_x += rd_x * d
			p_y += rd_y * d
			p_z += rd_z * d
		end

		const p = vec3(p_x, p_y, p_z)
		
		-- Accumulate simple color
		col = vec3(p_x + 2.0, -p_x + 2.0, a_x + 2.0)

		-- Lighting terms
		const da_x = math.max(a_x / 0.2 - p_y, 0.0)
		const da_z = math.max(a_z / 0.2 - p_y, 0.0)
		const topLight = (0.01 / math.sqrt(da_x * da_x + da_z * da_z)) * vector.one;
		const bounce    = 0.8 / col;
		const walls     = 30.0 * vector.min(VEC3_3 - col, VEC3_P01);

		col = topLight + bounce + walls;

		-- AO / shading
		const ao = dot(p, p) + 0.4 / dot(p + VEC3_P5, p + VEC3_P8);
		col /= ao;

		return col, 1;
	end;
}