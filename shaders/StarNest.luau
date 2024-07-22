
--[=[
	StarNest
	Shader by @Kali on https://www.shadertoy.com/view/XlfGRj
	Ported to Luau — ran by my engine — `RbxShader`.
	
	NOTE:
	- very resource intensive, our goal is to be able
	  to render this efficiently without changing this
	  programs code
]=]

--!native

local g = require(game.ReplicatedStorage.RbxShader.GraphicsMathLib)

-- // #define
local iterations = 17
local formuparam = 0.53

local volsteps = 20
local stepsize = 0.1

local zoom = 0.800
local tile = 0.850
local speed = 0.010 

local brightness = 0.0015
local darkmatter = 0.300
local distfading = 0.730
local saturation = 0.850

local Matrix2 = {}

function Matrix2.new(
	a : number, b : number ,
	c : number , d : number
)
	return {{a, b}, {c, d}}
end

-- // Fragment shader
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
		-- // get coords and direction
		local uv = Vector2.new(
			fragCoords.X/iResolution.X - .5,
			fragCoords.Y/iResolution.Y - .5 * iResolution.Y/iResolution.X
		) * zoom
		local dir = Vector3.new(uv.X, uv.Y, 1)
		local time = iTime * speed + .25
		
		-- // mouse rotation
		local a1 = 0.5 + iMouse.X / iResolution.X * 2
		local a2 = 0.8 + iMouse.Y / iResolution.Y * 2

		local rot1 = Matrix2.new(g.cos(a1), g.sin(a1), -g.sin(a1), g.cos(a1))
		local rot2 = Matrix2.new(g.cos(a2), g.sin(a2), -g.sin(a2), g.cos(a2))

		dir = Vector3.new(dir.X * rot1[1][1] + dir.Z * rot1[1][2], dir.Y, dir.X * rot1[2][1] + dir.Z * rot1[2][2])
		dir = Vector3.new(dir.X, dir.Y * rot2[1][1] + dir.Z * rot2[1][2], dir.X * rot2[2][1] + dir.Y * rot2[2][2])

		local from = Vector3.new(1, 0.5, 0.5)
		from += Vector3.new(time * 2, time, -2)

		from = Vector3.new(from.X * rot1[1][1] + from.Z * rot1[1][2], from.Y, from.X * rot1[2][1] + from.Z * rot1[2][2])
		from = Vector3.new(from.X, from.Y * rot2[1][1] + from.Z * rot2[1][2], from.X * rot2[2][1] + from.Y * rot2[2][2])
		
		-- // volumetric rendering
		local s, fade = 0.1, 1.0
		local v = Vector3.zero

		for r = 1, volsteps do
			local p = from+s*dir*.5
			p = Vector3.one * tile - g.mod_v3(p, Vector3.one * tile * 2)	-- // tiling fold
			local pa, a = 0, 0
			for i = 1, iterations do
				p = p:Abs() / p:Dot(p) - Vector3.one * formuparam			-- // the magic formula
				a += g.abs((p.Magnitude-pa))								-- // absolute sum of average change
				pa = p.Magnitude
			end
			local dm = g.max(0, darkmatter-a*a*0.001)	-- // dark matter
			a *= a*a									-- // add contrast
			if r > 6 then fade *= 1 - dm end			-- // dark matter, don't render near
			-- // v += Vector3.new(dm,dm*.5,0.)
			v += Vector3.one * fade
			v += Vector3.new(s, s^2, s^4)*a*brightness*fade	-- // coloring based on distance
			fade *= distfading								-- // distance fading
			s += stepsize
		end
		
		v = g.mix_v3(Vector3.one * v.Magnitude, v, saturation)	-- // color adjust
		return g.v3_rgb(v*.01)
	end,
}