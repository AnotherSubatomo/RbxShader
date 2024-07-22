
--[=[
	BasicVoxelTunnel
	Shader by @Miojo on https://www.shadertoy.com/view/mt2cWm
	Ported to Luau — ran by my engine — `RbxShader`.
	
	( Original comments are preserved. )
]=]

--!native

local g = require(game.ReplicatedStorage.RbxShader.GraphicsMathLib)

-- // Variables
local res = .6			-- @ voxel size
local max_iter = 80		-- @ raycast depth
local distFade = 6		-- @ distance fade
local speed = 2			-- @ travel speed

local lightClamp = distFade / 2

-- // The white part of the tunnel
local function path1 ( z : number )
	return Vector3.new(
		g.sin(z * .2) * 3 ,
		g.cos(z * .3) * 2 ,
		z
	)
end

-- // The yellow part of the tunnel
local function path2 ( z : number )
	return Vector3.new(
		g.sin(z * .2) * 1 ,
		g.cos(z * .3) * 4 - 1 ,
		z
	)
end

-- // The blue part of the tunnel
local function path3 ( z : number )
	return Vector3.new(
		g.sin(z * .3) * 3 ,
		g.cos(z * .2) - 1 ,
		z
	)
end

local cor : Vector3

local function map ( p : Vector3 )
	local d1 = (p - path1(p.Z)).Magnitude
	local d2 = (p - path2(p.Z)).Magnitude
	local d3 = (p - path3(p.Z)).Magnitude
	
	local s = 1.5
	local ret = s - g.min(d1, g.min(d2, d3))
	
	cor = Vector3.xAxis
	if ret == s - d1 then
		cor = Vector3.one
	elseif ret == s - d2 then
		cor = Vector3.new(1,1,0)
	elseif ret == s - d3 then
		cor = Vector3.new(0,1,1)
	end
	
	return ret
end

-- // Fragment shader
return {
	CONFIGURATION = {
		InterlaceFactor = 1 ,
		ScreenDivision = 4
	};
	-- // Image buffer
	mainImage = function (
		fragColor : Vector3 ,
		fragCoords : Vector2 ,
		iTime : number ,
		iTimeDelta : number ,
		iResolution : Vector2
	)
		local uv = (fragCoords - 0.5 * iResolution) / iResolution.Y
		
		-- // path
		local t = speed * iTime
		local ro = path1(t)
		local rd = path1(t + 1)
		
		-- // camera
		local f = (rd - ro).Unit
		local u = Vector3.yAxis
		local s = u:Cross(f).Unit
		u = f:Cross(s).Unit
		
		rd = (uv.X * s + uv.Y * u + f).Unit
		
		-- /*
		-- *    "Digital Differential Analysis" (DDA)
		-- */
		
		local mask, i
		
		local grid = (ro / res):Floor() * res
		local dGrid = rd:Sign() * res
		
		local dCubo = 1 / rd:Abs()
		local cubo = ( rd:Sign() * (grid - ro)
			+ (rd:Sign() * .5 + Vector3.one * .5) * res
		) * dCubo
		
		for __ = 1, max_iter do
			i = __
			if map(grid) < 0 then
				break
			end
			
			mask = g.step_v3(cubo, g.yzx(cubo)) * g.step_v3(cubo, g.zxy(cubo))
			
			grid += dGrid * mask
			cubo += dCubo * mask * res
		end
		
		local col = cor
		if i < max_iter then
			local d = (cubo * dCubo * res):Dot(mask)
			local p = ro + d * rd
			local q = g.fract_v3(p/res) - Vector3.one * 0.5
			
			-- // border
			q = q:Abs()
			local bd = 1 - g.smoothstep(.02, 0, .4 - .8 * g.yzx(q):Max(g.zxy(q)):Dot(mask))
			
			col += cor:Lerp(cor/2, bd) --mix(cor, cor/2, bd)
			--[[
			-- // sweeping line
			col *= g.cos(t/2) > uv.X and 2 or 1
			
			-- // dots
			col += Vector3.one * (g.cos(t/2) > uv.X and -1 or 1 - q.Magnitude * 4)
			]]
			-- // distance fade
			col *= distFade / (d * d) - .05
			
			-- // lights? shadows? oclusion?
		end
		
		-- // gamma correction
		col = g.sqrt_v3(col/lightClamp)
		return g.v3_rgb(col)
	end,
}