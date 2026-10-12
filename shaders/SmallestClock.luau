
--[=[
	SmallestClock
	Shader by @GregRostami on https://www.shadertoy.com/view/MsdXzH
	Ported to Luau — ran by my engine — `RbxShader`.
	
	( Original comments are preserved. )
]=]

--!strict
--!optimize 2
--!native

type vec3 = vector
type vec2 = vector

local resolution: vec2, resolution_y: number
local iDate_w: number

const function N(fragCoord: vec2, t: number): (vec3)
	fragCoord /= 0.8
	return vector.magnitude(fragCoord) < resolution_y
		and math.cos(iDate_w / t-math.atan2(fragCoord.x, fragCoord.y)) > 0.998
		and vector.one or vector.zero;
end

-- Shader program
return {
	CONFIGURATION = {
		InterlaceFactor = 2;
		ScreenDivision = Vector2.new(4, 2);
	};

	init = function (iResolution: vec2): ()
		resolution, resolution_y = iResolution, iResolution.y
	end;

	perFrame = function (_, iDate: {number}): ()
		iDate_w = iDate[4]
	end;
	
	mainImage = function (fragCoord: vec2): (vec3, number)
		-- Initialization of R and adjustment of u (fragCoord)
		fragCoord += fragCoord - resolution;

		-- Accumulate the result into fragColor (interpreted as o)
		const fragColor = N(fragCoord, 1e9 - 12.0) +
						N(fragCoord, 573.0) +
						N(fragCoord, 9.55) +
						N(fragCoord, 6875.0);
		
		return fragColor, 1;
	end;
}