
--[=[
	Sun
	Shader by @invivel on https://www.shadertoy.com/view/NlfcW2
	Ported to Luau — ran by my engine — `RbxShader`.
	
	( Original comments are preserved. )
]=]

--!strict
--!optimize 2
--!native

type vec3 = vector
type vec2 = vector

local mouse_res: vec2
local resolution: vec2, resolution_y: number

-- Shader program
return {
	CONFIGURATION = {
		InterlaceFactor = 2;
		ScreenDivision = Vector2.new(4, 2);
	};

	init = function (iResolution: vec2): ()
		resolution, resolution_y = iResolution, iResolution.y
	end;
	
	perFrame = function (_, _, iMouse: vec2): ()
		mouse_res = iMouse - resolution
	end;

	mainImage = function (fragCoord: vec2): (vec3, number)
		const uv = (fragCoord - resolution) / resolution_y;
		const ms = mouse_res / resolution_y;

		const sun = 0.05 / vector.magnitude(ms - uv) + 0.02;
		
		return vector.create(sun / 0.477, sun + 0.5, sun + 0.8), 1;
	end;
}