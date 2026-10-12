
--[=[
	Mandelbrot
	Derived from @Crazyblox's Mandelbrot shader for Penumbra.
	https://github.com/Crazyblox/Penumbra/blob/main/lib/Pipeline/Shaders/Fragment/Mandelbrot.luau
]=]

--!strict
--!optimize 2
--!native

type vec3 = vector
type vec2 = vector

const ITER = 40
const ZOOM = 0.8
const COLOR = vector.create(1, 1, 1.25)

local res: vec2, res_x: number, res_y: number
local mouse_res: vec2
local sin_time: number

-- Shader program
return {
	CONFIGURATION = {
		InterlaceFactor = 2;
		ScreenDivision = Vector2.new(4, 2);
	};

	init = function (iResolution: vec2): ()
		res, res_x, res_y = iResolution, iResolution.x, iResolution.y
	end;
	
	perFrame = function (iTime: number, _, iMouse: vec2): ()
		mouse_res = iMouse - res / 2
		sin_time = 0.2 * math.sin(iTime * 0.3)
	end;

	mainImage = function (fragCoord: vec2, _, iTime: number): (vec3, number)
		fragCoord += mouse_res
		const uvx = (fragCoord.x / res_x - 0.5) * 2 * (res_x / res_y)
		const uvy = (fragCoord.y / res_y - 0.5) * 2

		const cx = uvx * ZOOM - 0.5 + sin_time
		const cy = uvy * ZOOM

		local zx, zy = 0.0, 0.0
		local it = 0
		for i = 1, ITER do
			const zx_zx, zy_zy = zx*zx, zy*zy
			if zx_zx + zy_zy > 4 then break end
			zx, zy = zx_zx - zy_zy + cx, 2*zx*zy + cy
			it += 1
		end

		const t = it / ITER
		const r = t * t
		const g = t
		const b = math.sqrt(t)

		return vector.create(r, g, b) * COLOR, 1;
	end;
}