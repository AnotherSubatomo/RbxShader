
--[=[
	SmallestClock
	Shader by @GregRostami on https://www.shadertoy.com/view/MsdXzH
	Ported to Luau — ran by my engine — `RbxShader`.
	
	( Original comments are preserved. )
]=]

--!native

local g = require(game.ReplicatedStorage.RbxShader.GraphicsMathLib)
local vec3 = Vector3.new

-- // Pixel shader
return {
	CONFIGURATION = {
		InterlaceFactor = 2 ,
		ScreenDivision = 4
	};
	-- // Image buffer
	mainImage = function (
		fragColor : Vector3 ,
		fragCoords : Vector2 ,
		iTime : number ,
		iTimeDelta : number ,
		iResolution : Vector2 ,
		iMouse : Vector2,
		iDate : {number}
	)
		-- Define N function as per the GLSL macro
		local function N( t : number ) : Vector3
			fragCoords /= 0.8
			return fragCoords.Magnitude < iResolution.Y
				and g.cos(iDate[4]/t-g.atan2(fragCoords.X, fragCoords.Y)) > 0.998
				and vec3(1, 1, 1) or vec3(0, 0, 0);
		end

		-- Initialization of R and adjustment of u (fragCoords)
		fragCoords += fragCoords - iResolution;

		-- Accumulate the result into fragColor (interpreted as o)
		fragColor = N(1e9 - 12.0) +
					N(573.0) +
					N(9.55) +
					N(6875.0);
		
		return g.v3_rgb(fragColor);
	end
}