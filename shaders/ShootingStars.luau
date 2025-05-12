
--[=[
	Plasma
	Shader by @Xor on https://www.shadertoy.com/view/ctXGRn
	Ported to Luau — ran by my engine — `RbxShader`.
	
	( Original comments are preserved. )
]=]

--!native

local g = require(game.ReplicatedStorage.RbxShader.GraphicsMathLib)
local vec3 = Vector3.new
local vec2 = Vector2.new
local uvec3 = Vector3.one
local uvec2 = Vector2.one
local cos = math.cos

--[[
/*
    "Shooting Stars" by @XorDev

    I got hit with inspiration for the concept of shooting stars.
    This is what I came up with.
    
    Tweet: twitter.com/XorDev/status/1604218610737680385
    Twigl: t.co/i7nkUWIpD8
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
		local I = fragCoords
		-- //Clear fragcolor
		local O = Vector3.zero
		-- //Line dimensions (box) and position relative to line
		local b, p = vec2(0,.2), Vector2.zero;
		-- //Rotation matrix
		local R_b, R_c, R_ad = 0, 0, 0;
		-- //Iterate 20 times
		for i = 0.9, 20, 1 do
			-- //Rotate for each iteration
			R_b = cos(i+33); R_c = cos(i+11); R_ad = cos(i);
			-- //Using rotated boxes
			local v1 = (I/iResolution.Y*i*.1+uvec2*iTime*b) -- @temp;
			local v2 = g.fract_v2(vec2(
				(R_c*v1.X)+(R_ad*v1.Y),
				(R_ad*v1.X)+(R_b*v1.Y)
			)) - uvec2*.5 -- @temp;
			p = vec2(
				(R_c*v2.X)+(R_ad*v2.Y),
				(R_ad*v2.X)+(R_b*v2.Y)
			)
			-- //Add attenuation
			local glow = 1e-3/(b:Min((-b):Max(p))-p).Magnitude
			-- //My favorite color palette
			O += glow * (g.cos_v3((uvec3*p.Y/.1)+vec3(0,1,2))+uvec3)
		end
			
		return g.v3_rgba(O);
	end
}