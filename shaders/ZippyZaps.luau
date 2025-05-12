
--[=[
	ZippyZaps
	Shader by @SnoopethDuckDuck on https://www.shadertoy.com/view/XXyGzh
	Ported to Luau — ran by my engine — `RbxShader`.
	
	( Original comments are preserved. )
]=]

--!native

local g = require(game.ReplicatedStorage.RbxShader.GraphicsMathLib)
local vec3 = Vector3.new
local vec2 = Vector2.new
local uvec3 = Vector3.one
local uvec2 = Vector2.one
local pow = math.pow
local cos = math.cos

local function tanh_v2(v: Vector2): Vector2
	return vec2(math.tanh(v.X), math.tanh(v.Y))
end

-- // Pixel shader
return {
	CONFIGURATION = {
		InterlaceFactor = 3 ,
		ScreenDivision = 4 ,
		IsBlurred = true
	};
	-- // Image buffer
	-- // -13 thanks to Nguyen2007 ⚡
	mainImage = function (
		fragColor : Vector3 ,
		fragCoords : Vector2 ,
		iTime : number ,
		iTimeDelta : number ,
		iResolution : Vector2 ,
		iMouse : Vector2,
		iDate : {number}
	)
		local v = iResolution;
		local u = fragCoords;
		u = .2*(u+u-v)/v.Y;

		local o = vec3(1, 2, 3);
		local z = o;
		
		local a = .5;
		local t = iTime;
		local i = 0.0;

		while true do
			i += 1
			if i >= 19 then break end
			o += (uvec3 + g.cos_v3(z+uvec3*t)) / (
				(1+i*v:Dot(v)) *
				g.sin_v2(1.5*u/(.5-u:Dot(u)) - 9*g.yx(u) + uvec2*t)
			).Magnitude
			
			t += 1
			a += .03
			v = g.cos_v2(uvec2*t - 7*u*pow(a, i)) - 5*u

			local r1 = i + 0.02 * t
			local r2 = cos(r1)
			u = vec2(
				(r2 * u.X) + (cos(r1 - 11) * u.Y),
				(cos(r1 - 33) * u.X) + (r2 * u.Y)
			)
			-- use stanh here if shader has black artifacts
			--  vvvv
			u += tanh_v2(40 * u:Dot(u) * g.cos_v2(1e2*g.yx(u)+uvec2*t)) / 2e2
			+ .2 * a * u
			+ uvec2*(cos(4/math.exp(o:Dot(o)/1e2) + t) / 3e2)
		end

		o = 25.6 / (o:Min(uvec3*13) + uvec3*164 / o) - uvec3*u:Dot(u) / 250;

		fragColor = o
		return g.v3_rgb(fragColor);
	end
}