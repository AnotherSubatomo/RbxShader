
--[=[
	SimpleOceanWaves
	Shader by @jarble on https://www.shadertoy.com/view/ftS3zh
	Ported to Luau — ran by my engine — `RbxShader`.
	
	( Original comments are preserved. )
	[ ⚠ NOT WORKING AS INTENDED ]
]=]

--!native

local g = require(game.ReplicatedStorage.RbxShader.GraphicsMathLib)

-- // `in` value system
--	* designed to consume less memory by reusing old `in`s (which are just tables)
local in_bookkeep : {[number] : boolean}	-- # maps a key to it's availability
local in_map : {[number] : {}} = {}			-- # maps a key to an `in` value

-- # looks for any previous `in`s that can be reused and returns them
local function alloc_in()
	local free_in : {} = nil
	-- # look for free unallocated `in`s
	for key : number, availability : boolean in in_bookkeep do
		if not availability then continue end
		free_in = in_map[key]
		in_bookkeep[key] = false
	end
	-- # make a new entry if everything before has been occupied
	if free_in == nil then
		free_in = {}
		local key = #in_map+1
		in_map[key] = free_in
		in_bookkeep[key] = false
	end

	return free_in
end

-- # frees up the data stored in the `in`s to be garbage collected
local function freeup_ins()
	for key : number, availability : boolean in in_bookkeep do
		in_bookkeep[key] = false
		table.clear(in_map[key])
	end
end

-- // #defines
local SC = 250
local OCTAVES = 4
local ITIME = 0

-- // aux functions

local function xyy( v : Vector3 ) : Vector3
	return Vector3.new( v.X, v.Y, v.Y )
end

local function yyx( v : Vector3 ) : Vector3
	return Vector3.new( v.Y, v.Y, v.X )
end

type Matrix3 = {Vector3}

local function mul_mat3vec3( m : Matrix3 , v : Vector3 ) : Vector3
	return Vector3.new(
		m[1].X * v.X + m[2].X * v.X + m[3].X * v.X,
		m[1].Y * v.Y + m[2].Y * v.Y + m[3].Y * v.Y,
		m[1].Z * v.Z + m[2].Z * v.Z + m[3].Z * v.Z
	)
end

-- // program functions

-- # uv is an in-value
function noise( uv : Vector2 ) : number
    return g.sin(uv.X - ITIME/2);
end

-- # uv is an in-value
function fbm( uv : Vector2 ) : number
	local value = 0;
	local amplitude = 1;
	local freq = 0.8;

	for i = 0, OCTAVES-1 do
		-- // value += noise(uv * freq) * amplitude;
		-- // uv = Vector2.new(uv.X - ITIME/2, uv.Y);

		-- // From Dave_Hoskins https://www.shadertoy.com/user/Dave_Hoskins
		value += (.25 - g.abs(noise(uv * freq)-.3) * amplitude);
        amplitude *= .37;
        freq *= 3.+1. / 3.;
        uv += g.yx(uv) / 10.0;
        -- // uv = g.yx(uv);
	end
	
	return value;
end

function f ( p : Vector3 ) : number
	return fbm(g.xz(p));
end

function getNormal ( p : Vector3 , t : number ) : Vector3
	local eps = Vector3.xAxis * .001 * t;
	return Vector3.new(
		f(p - xyy(eps)) - f(p + xyy(eps)),
		2 * eps.X,
		f(p - yyx(eps)) - f(p + yyx(eps))
	).Unit;
end

function rayMarching ( ro : Vector3 , rd : Vector3 , tMin : number , tMax : number ) : number
	local t = tMin;
	for _ = 1, 300 do
		local pos = ro + t * rd;
		local h = pos.Y - f(pos);
		if g.abs(h) < (0.0015 * t) or t > tMax then break end
		t += 0.4 * h;
	end
	return t;
end

function lighting ( p : Vector3 , normal : Vector3 , L : Vector3 , V : Vector3 ) : Vector3
	local sunColor = Vector3.new(1, .956, .839);
	local albedo = 1;
	local diff = Vector3.one * g.max(normal:Dot(L) * albedo, 0);

	local refl = g.reflect(L, normal).Unit;
	local spec = g.max(refl:Dot(-(V.Unit)), 0);
	spec ^= 18;
	spec = g.clamp(spec, 0, 1);
	local sky = g.max(0, Vector3.yAxis:Dot(normal));

	-- // local amb = 0.5 * g.smoothstep(0.0, 2.0, p.Y);

	local col = diff * sunColor;
	col += spec * sunColor;
	col += sky * Vector3.new(0, 0.6, 1) * .1;
	-- // col += amb * .2;
	
	return col;
end

function lookAt( origin : Vector3 , target : Vector3 , roll : number ) : Matrix3
	local rr = Vector3.new(g.sin(roll), g.cos(roll), 0);
	local ww = (target - origin).Unit;
	local uu = ww:Cross(rr);
	local vv = uu:Cross(ww);

	return {uu, vv, ww};
end

function camerapath ( t : number ) : Vector3
	return Vector3.new(
		-13.0 + 3.5 * g.cos(t),
		3.3,
		-1.1 + 2.4 * g.cos(2.4 * t + 2.0)
	)
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
		iMouse : Vector2
	)
		freeup_ins();
		ITIME = iTime;

		local uv = (fragCoords - iResolution * 0.5) / iResolution.Y;
		local lightDir = Vector3.new(-.8, .15, -.3).Unit;

		local camStep = Vector3.new(lightDir.X, 0, lightDir.Z);
		local camPos = Vector3.new(8, 2, 5) + camStep;
		local camTarget = Vector3.new(1, 1, 4) + camStep;
		local mat = lookAt(camPos, camTarget, 0);

		local ro = camPos;
		local rd = mul_mat3vec3(mat, Vector3.new(uv.X, uv.Y, 1)).Unit;

		local tMin = .1;
		local tMax = 20;
		local t = rayMarching(ro, rd, tMin, tMax);

		local col = Vector3.zero;

		if t > tMax then
			-- // from iq's shader, https://www.shadertoy.com/view/MdX3Rr
			local sundot = g.clamp(rd:Dot(lightDir), 0.0, 1.0);
			col = Vector3.new(.3, .5, .85) - Vector3.one * rd.Y*rd.Y*0.5;
			col = g.mix_v3(col, 0.85 * Vector3.new(.7, .75, .85), (1 - g.max(rd.Y, 0))^4);
			-- // sun
			col += 0.25 * Vector3.new(1, .7, .4) * sundot^5;
			col += 0.25 * Vector3.new(1, .8, .6) * sundot^64;
			col += 0.2 * Vector3.new(1, .8, .6) * sundot^512;
			-- // clouds
			local sc = g.xz(ro) + g.xz(rd) * (SC*1000-ro.Y) / rd.Y;
			col = g.mix_v3(col, Vector3.new(1, .95, 1), 0.5 * g.smoothstep(0.5, 0.8, fbm(0.0005*sc/SC)));
			-- // horizon
			col = g.mix_v3(col, 0.68 * Vector3.new(.4, .65, 1), (1 - g.max(rd.Y, 0))^16);
		else
			local p = ro + rd * t;
			local normal = getNormal(p, t);
			local viewDir = (ro - p).Unit;

			-- // lighting terrain
			col = lighting(p, normal, lightDir, viewDir);

			-- // fog
			local fo = 1 - g.exp((30 * t / SC)^1.5);
			local fco = 0.65 * Vector3.new(.4, .65, 1);
			col = g.mix_v3(col, fco, fo);
		end

		-- // Gamma correction
		col = g.pow_v3(g.clamp_v3(col, 0, 1), Vector3.one * .45);

		return g.v3_rgb(col)
	end
}