
--[=[
	Cosmic
	Shader by @Xor on https://www.shadertoy.com/view/msjXRK
	Ported to Luau — ran by my engine — `RbxShader`.
	
	( Original comments are preserved. )
]=]

--!native

local g = require(game.ReplicatedStorage.RbxShader.GraphicsMathLib)
local vec3 = Vector3.new
local vec2 = Vector2.new

--[[
/*
    "Cosmic" by @XorDev
    
    I love making these glowy shaders. This time I thought I'd try using discs instead.

    Tweet: twitter.com/XorDev/status/1601060422819680256
    Twigl: t.co/IhRk3HX4Kt
    
    <300 chars playlist: shadertoy.com/playlist/fXlGDN
*/
]]

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
		-- // Clear fragcolor (hacky);
		fragColor *= 0;
		-- // Initialize resolution for scaling
		local r : Vector2	= iResolution;
		-- // Save centered pixel coordinates
		local p = (fragCoords-r*.6);
		p = vec2(
			p.X + 2 * p.Y,
			-1 * p.X + 2 * p.Y
		);

		-- // Initialize loop iterator and arc angle
		local a : number = 0;
		for i = 1, 30 do
			-- // Add with ring attenuation
			fragCoords = p/(r+r-p).Y;
			a = g.atan2(fragCoords.Y, fragCoords.X)*g.ceil(i*.1)+iTime*g.sin(i*i)+i*i;
			fragColor += Vector3.one * .2 / (g.abs(fragCoords.Magnitude*8e1-i)+4e1/r.Y) *
			-- // Limit to arcs
				g.clamp(g.cos(a),.0,.6) *
			-- // Give them color
				(g.cos_v3(Vector3.one * (a-i) + vec3(0,1,2))+Vector3.one);
		end

		return g.v3_rgb(fragColor);
	end
}