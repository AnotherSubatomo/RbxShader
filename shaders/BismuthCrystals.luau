
--[=[
	BismuthCrystals
	Shader by @jarble on https://www.shadertoy.com/view/NdsXzl
	Ported to Luau — ran by my engine — `RbxShader`.
	
	( Original comments are preserved. )
]=]

--!strict
--!optimize 2
--!native

type vec3 = vector
type vec2 = vector

const ITERS = 12
const SCALE = 2.1
const MATTE = 2.125

local res_x: number, res_y: number
local time_1o25: number

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
		time_1o25 = (iTime / 25.0)
	end;
	
	mainImage = function (fragCoord: vec2): (vec3, number)
		local col_x = 0
		local col_y = 0
		local col_z = 0
		local col_prev_x = 0
		local col_prev_y = 0
		local col_prev_z = 0

		const a = res_y * 15.0
		local uv_x = (fragCoord.x * 10. - res_x) / a
		local uv_y = (fragCoord.y * 10. - res_y) / a + time_1o25

		for _ = 1, ITERS do
			const scale_a = 1.13
			const scale_b = scale_a * SCALE
			
			col_prev_x = col_x
			col_prev_y = col_y
			col_prev_z = col_z
			
			for _ = 1, ITERS do
				local fuv_x = - uv_x - ((uv_x / SCALE - uv_y / scale_a) / SCALE) -- @temp
				local fuv_y = - uv_y - ((uv_y / SCALE - uv_x / scale_a) / SCALE) -- @temp
				
				uv_x = (fuv_x - fuv_x // 1)
				uv_y = (fuv_y - fuv_y // 1) / scale_a
				
				fuv_x = -uv_y / scale_b
				fuv_y = -uv_x / scale_b
				
				uv_x = ((fuv_x - fuv_x // 1) * scale_b)
				uv_y = ((fuv_y - fuv_y // 1) * scale_b) / -scale_a
				--scale_a += (uv_x * (.0005 * fract(uv_x + iTime / 4.)))
			end
			col_z = math.abs((uv_y - uv_y // 1) - (uv_x - uv_x // 1))
			--col_z = fract((uv_y)-(uv_x));
			
			col_x = (col_x + col_prev_y) / MATTE
			col_y = (col_y + col_prev_z) / MATTE
			col_z = (col_z + col_prev_x) / MATTE
		end

		return vector.create(col_x * 3.0, col_y * 3.0, col_z * 3.0), 1;
	end;
}