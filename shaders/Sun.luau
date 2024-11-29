
--[=[
	Sun
	Shader by @invivel on https://www.shadertoy.com/view/NlfcW2
	Ported to Luau — ran by my engine — `RbxShader`.
	
	( Original comments are preserved. )
]=]

--!native

local g = require(game.ReplicatedStorage.RbxShader.GraphicsMathLib)

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
		iMouse : Vector2
	)
		iMouse = Vector2.new(iMouse.X, iMouse.Y);
		local uv : Vector2 = (fragCoords - iResolution) / iResolution.Y;
		local ms : Vector2 = (iMouse - iResolution) / iResolution.Y;

		local sun : number = 0.05 / (ms - uv).Magnitude + 0.02;
		
		return sun / 0.477, sun + 0.5, sun + 0.8
	end
}