
--[=[
	GravitySucks
	Shader by @mrange on https://www.shadertoy.com/view/4cyXWw
	Ported to Luau — ran by my engine — `RbxShader`.
	
	( Original comments are preserved. )
]=]

--!native

local g = require(game.ReplicatedStorage.RbxShader.GraphicsMathLib)

-- // CC0: Gravity sucks
-- //	Tinkering away....

local LAYERS		= 5.
local SCALE			= 1.

local PI			= 3.141592654
local TAU			= (2.0*PI)

-- // License: Unknown, author: Unknown, found: don't remember
local function hash( co : number ) : number
	return g.fract(g.sin(co*12.9898) * 13758.5453);
end

-- // License: MIT OR CC-BY-NC-4.0, author: mercury, found: https://mercury.sexy/hg_sdf/
-- /* `p` is `inout`, meaning that change to it is global(?)
local function mod1( p : number, size : number ) : (number, number)
	local halfsize = size/2
	local c = g.floor((p + halfsize)/size)
	p = ((p + halfsize) % size) - halfsize
	return c, p
end

-- // License: Unknown, author: Unknown, found: don't remember
local function bounce( t : number, dy : number , dropOff : number ) : number
	local gr = 5
	local p0 = 2*dy/gr

	t += p0/2
		
	local ldo = g.log(dropOff);
		
	local yy = 1. - (1. - dropOff) * t / p0;

	if yy > 1e-4 then
		local n	= g.floor(g.log(yy) / ldo);
		local dn = g.pow(dropOff, n);

		local yyy = dy * dn;
		t -= p0 * (1 - dn) / (1 - dropOff);

		return - 0.5*gr*t*t + yyy*t;

	else
		return 0
	end
end

local function ball(
	iResolution : Vector2 , col : Vector3 ,
	pp : Vector2 , p : Vector2 ,
	r : number , pal : number
) : Vector3
	local ro = Vector3.new(0,0,10)
	local difDir = Vector3.new(1, 1.5, 2).Unit
	local speDir = Vector3.new(1, 2, 1).Unit
	local p3 = Vector3.new(pp, 0)
	local rd = (p3-ro).Unit

	local bcol = Vector3.one*0.5+0.5*g.sin_v3(0.5*Vector3.new(0, 1, 2)+Vector3.one*TAU*pal)
	local aa = g.sqrt(8)/iResolution.Y
	local z2 = r*r-p:Dot(p)

	if z2 > 0 then
		local z = g.sqrt(z2)
		local cp = Vector3.new(p.X, p.Y, z)
		local cn = cp.Unit
		local cr = g.reflect(rd, cn)
		local cd = g.max(difDir:Dot(cn), 0.0)
		local cs = 1.008-cr:Dot(speDir)

		local ccol = g.mix(0.1, 1,cd*cd)*bcol+g.sqrt_v3(bcol)*(1e-2/cs)
		local d = p.Magnitude-r
		col = g.mix_v3(col, ccol, g.smoothstep(0, -aa, d))
	end

	return col
end

local function effect( iResolution : Vector2 , iTime : number , p : Vector2 ) : Vector3
	p += Vector2.new(0,.5);
	local sy = g.sign(p.Y);
	p = Vector2.new(p.X, g.abs(p.Y));
	if sy < 0 then
		p *= Vector2.new(1,1.5);
	end

	local col = Vector3.zero;
	local aa = g.sqrt(4)/iResolution.Y;
	for i = 0, LAYERS do
		local h0 = hash(i+123.4);
		local h1 = g.fract(8667.0*h0);
		local h2 = g.fract(8707.0*h0);
		local h3 = g.fract(8887.0*h0);
		local tf = g.mix(.5, 1.5, h3);
		local it = tf*iTime;
		local cw = g.mix(0.25, 0.75, h0*h0)*SCALE;
		local per = g.mix(0.75, 1.5, h1*h1)*cw;
		local p0 = p;
		local nt = g.floor(it/per);
		p0 -= Vector2.new(cw*(it-nt*per)/per, 0);
		local n0, p0x = mod1(p0.X, cw)
		n0 -= nt;
		p0 = Vector2.new(p0x, p0.Y)
		if n0 > -7-i*3 then continue end
		local ct = it+n0*per;

		local ch0 = hash(h0+n0);
		local ch1 = g.fract(8667.0*ch0);
		local ch2 = g.fract(8707.0*ch0);
		local ch3 = g.fract(8887.0*ch0);
		local ch4 = g.fract(9011.0*ch0);

		local radii = cw*g.mix(.25, .5, ch0*ch0);
		local dy = g.mix(3., 2., ch3);
		local bf = g.mix(.6, .9, ch2);
		local b = bounce(ct/tf+ch4, dy, bf);
		p0 -= Vector2.new(0, b+radii);
		col = ball(iResolution, col, p, p0, radii, ch1);
	end

	if sy < 0 then
		col *= g.mix_v3(g.sqrt_v3(Vector3.new(.05, .1, .2)), Vector3.new(.05, .1, .2), p.Y);
		col += .1*Vector3.zAxis*g.max(p.Y*p.Y, 0);
	end

	col = g.sqrt_v3(col);
	return col;
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
		iResolution : Vector2
	)
		local p : Vector2 = (-iResolution+2*fragCoords)/iResolution.Y
		local col : Vector3 = effect(iResolution, iTime, p);

		return g.v3_rgb(col)
	end,
}