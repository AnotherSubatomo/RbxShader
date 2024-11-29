
--[=[
	UnknownPleasures
	Shader by @smiarx on https://www.shadertoy.com/view/4sVyWR
	Ported to Luau — ran by my engine — `RbxShader`.
	
	( Original comments are preserved. )
]=]

--!native

local g = require(game.ReplicatedStorage.RbxShader.GraphicsMathLib)
local vec2 = Vector2.new

-- // #defines
local LINEWIDTH = 3.2;
local H = 35;
local WAVEHEIGHT = 6.6;
local WIDTH = 0.6;
local CLOSENESS = 45;
local OCTAVES = 3;

-- // aux functions

local function random(x : number) : number
	return g.fract(g.sin(x)*43758.5453123);
end

local function noise(x : number) : number
	local i : number = g.floor(x);
	local f : number = g.fract(x);
	
	local a : number = random(i);
	local b : number = random(i+1);
	
	local u : number = f * f * (3 - 2 * f);

	return g.mix(a, b, u);
end

local function fbm(x : number) : number
	local value : number	 = 0;
	local amplitude : number = .5;
	local frequency : number = 0;

	for i = 1, OCTAVES, 1 do
		value += amplitude * noise(x);
		x *= 2;
		amplitude *= .7;
	end

	return value;
end

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
		local st : Vector2		 = (2*(iResolution - fragCoords) - iResolution) / iResolution.Y;
		st = vec2(st.X, st.Y * CLOSENESS);

		local linewidth : number = CLOSENESS * LINEWIDTH / iResolution.Y;
		local val : number		 = 0;

		if g.abs(st.X) < WIDTH then
			local env : number	= g.pow(g.cos(st.X/WIDTH*3.14159/2), 4.9);
			local i : number	= g.floor(st.Y);

			for n = g.max(-H, i-6), g.min(H, i), 1 do
				local f : number	= st.Y - n;
				local y : number	= f - 0.5;
				y -= WAVEHEIGHT
					* g.pow(fbm(st.X*10.504 +n*432.1 + 0.5*iTime), 3)
					* env
					+ (fbm(st.X*25.+n*1292.21)-0.32)*2 * 0.15;
				local grid : number	= g.abs(y);
				val += (1-g.smoothstep(0, linewidth, grid));
				-- // val = grid;
				if y < 0 then break end;
			end
		end

		return val, val, val, val;
	end
}