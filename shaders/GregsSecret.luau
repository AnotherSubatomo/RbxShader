
--[=[
	GregsSecret
	Shader by @GregRostami found on his literal user description
	Ported to Luau — ran by my engine — `RbxShader`.
]=]

--!native

local g = require(game.ReplicatedStorage.RbxShader.GraphicsMathLib)
local vec2 = Vector2.new
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
		fragColor *= 0;
		local fa : number	= 0;			-- // frag alpha
		local b : Vector3	= Vector3.zero;

		while (b.X^b.Y^b.Z) % 99 > b.Z - 5 do
			-- // Update b and fragColor
			fa += 0.1;
			fragColor += Vector3.one * 0.1;
			
			b = vec3(
				iTime * vec2(1, 4) + 5 * (fragCoords / iResolution.Y - 0.7) * fa,
				fragColor.X,
				fragColor.Y
			);
		end

		return g.c3_rgba(fragColor/74, fa/74);
	end
}
