
--[=[
	Plasma
	Shader by @Xor on https://www.shadertoy.com/view/WfS3Dd
	Ported to Luau — ran by my engine — `RbxShader`.
	
	( Original comments are preserved. )
]=]

--!native

local g = require(game.ReplicatedStorage.RbxShader.GraphicsMathLib)
local vec3 = Vector3.new
local vec2 = Vector2.new
local uvec3 = Vector3.one
local uvec2 = Vector2.one
local abs = math.abs

local function tanh_v3(v: Vector3): Vector3
	return vec3(math.tanh(v.X), math.tanh(v.Y), math.tanh(v.Z))
end

--[[
/*
    "Plasma" by @XorDev
    
    X Post:
    x.com/XorDev/status/1894123951401378051
    
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
		local O = Vector3.zero
		local I = fragCoords
		-- //Resolution for scaling
		local r = iResolution
		-- //Centered, ratio corrected, coordinates
		local p = (I+I-r) / r.Y
		-- //Z depth
		local z = vec2(0)
		-- //Iterator (x=0)
		local i = vec2(0)
		-- //Fluid coordinates
		z += uvec2*4
		local f = p*(z-uvec2*4*abs(.7-p:Dot(p)));
		
		-- //Clear frag color and loop 8 times
		while i.Y < 8 do
			i += Vector2.yAxis
			local s = (g.sin_v2(f)+uvec2) --@temp; not in source code
			-- //Set color waves and line brightness
			O += vec3(s.X, s.Y, s.Y) * abs(f.X-f.Y)
			-- //Add fluid waves
			f += g.cos_v2(g.yx(f)*i.Y+i+(uvec2*iTime))/i.Y+uvec2*.7;
		end
		
		-- //Tonemap, fade edges and color gradient
		O = tanh_v3(7.*g.exp_v3(uvec3*(z.X-4.)-p.Y*vec3(-1,1,2))/O);
		return g.v3_rgb(O);
	end
}