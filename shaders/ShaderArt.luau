
--[=[
	ShaderArt
	Shader by @kishimisu on https://www.shadertoy.com/view/mtyGWy
	Ported to Luau — ran by my engine — `RbxShader`.
	
	( Original comments are preserved. )
]=]

--!native

local g = require(game.ReplicatedStorage.RbxShader.GraphicsMathLib)

--[=[
	This animation is the material of my first youtube tutorial about creative 
   coding, which is a video in which I try to introduce programmers to GLSL 
   and to the wonderful world of shaders, while also trying to share my recent 
   passion for this community.			Video URL: https://youtu.be/f4s1h2YETNY
]=]

-- // https://iquilezles.org/articles/palettes/
local function palette ( t : number )
	local a = Vector3.one * 0.5
	local b = Vector3.one * 0.5
	local c = Vector3.one
	local d = Vector3.new(0.263, 0.416, 0.557)
	
	return a + b*g.cos_v3(6.28318*(c*t+d))
end

-- // Fragment shader
return {
	CONFIGURATION = {
		InterlaceFactor = 2 ,
		DualAxisInterlacing = true ,
		ScreenDivision = 16
	};
	-- // Image buffer
	mainImage = function (
		fragColor : Vector3 ,
		fragCoords : Vector2 ,
		iTime : number ,
		iTimeDelta : number ,
		iResolution : Vector2
	)
		local uv = (fragCoords * 2 - iResolution) / iResolution.Y
		local uv0 = uv
		local finalColor = Vector3.zero
		
		for i = 0, 3 do
			uv = g.fract_v2(uv * 1.5) - Vector2.one * 0.5
			
			local d = uv.Magnitude * g.exp(-uv0.Magnitude)
			local col = palette(uv0.Magnitude + i * 0.4 + iTime * 0.4)
			
			d = g.sin(d * 8 + iTime) / 8
			d = g.abs(d)
			
			d = g.pow(0.01 / d, 1.2)
			
			finalColor += col * d
		end
		
		return g.v3_rgb(finalColor)
	end,
}