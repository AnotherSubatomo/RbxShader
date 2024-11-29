
--[=[
	Procedural3DOcean
	Shader by @jarble and @afl_ext on https://www.shadertoy.com/view/4cyXWw
	Ported to Luau — ran by my engine — `RbxShader`.
	
	( Original comments are preserved. )
	[ ⚠ NOT WORKING AS INTENDED ]
]=]

--!native

local g = require(game.ReplicatedStorage.RbxShader.GraphicsMathLib)

-- // #defines
-- // Use your mouse to move the camera around! Press the Left Mouse Button on the image to look around!

local DRAG_MULT = 0.38 -- // changes how much waves pull on the water
local WATER_DEPTH = 1.0 -- // how deep is the water
local CAMERA_HEIGHT = 1.5 -- // how high the camera should be
local ITERATIONS_RAYMARCH = 12 -- // waves iterations of raymarching
local ITERATIONS_NORMAL = 37 -- // waves iterations when calculating normals

local function xz( v : Vector3 )
	return Vector2.new(v.X, v.Z)
end

local function clamp_v3( v : Vector3 , min : number , max : number ) : Vector3
	return Vector3.new(
		g.clamp(v.X, min, max),
		g.clamp(v.Y, min, max),
		g.clamp(v.Z, min, max)
	)
end

-- // Helper function for multiplying two matrices
local function matmul( A : {{number}} , B : {{number}} ) : {{number}}
	local result = {}

	for i = 1, 3 do
		result[i] = {}
		for j = 1, 3 do
			result[i][j] = 0
			for k = 1, 3 do
				result[i][j] = result[i][j] + A[i][k] * B[k][j]
			end
		end
	end

	table.clear(A)
	table.clear(B)
	return result
end

-- // Helper function for multiplying a matrix and a vector
local function mat_v3_mul( m : {{number}} , v : Vector3 ) : Vector3
	local result = Vector3.new(
		m[1][1] * v.X + m[2][1] * v.X + m[3][1] * v.X,
		m[1][2] * v.Y + m[2][2] * v.Y + m[3][2] * v.Y,
		m[1][3] * v.Z + m[2][3] * v.Z + m[3][3] * v.Z
	)

	table.clear(m)
	return result
end

-- // Calculates wave value and its derivative, 
-- // for the wave direction, position in space, wave frequency and time
local function wavedx ( position : Vector2, direction : Vector2, speed : number , frequency : number, timeshift : number) : Vector2
	local x = direction:Dot(position) * frequency + timeshift * speed;
	local wave = g.exp(g.sin(x) - 1);
	local dx = wave * g.cos(x);
	return Vector2.new(wave, -dx);
end

-- // Calculates waves by summing octaves of various waves with various parameters
local function getWaves( iTime : number , position : Vector2 , iterations : number ) : number
	local iter = 0.0; 				-- // this will help generating well distributed wave directions
	local phase = 6.0;				-- // frequency of the wave, this will change every iteration
	local speed = 2.0;				-- // time multiplier for the wave, this will change every iteration
	local weight = 1.0;				-- // weight in final sum for the wave, this will change every iteration
	local sumOfValues = 0.0;		-- // will store final sum of values
	local sumOfWeights = 0.0;		-- // will store final sum of weights
	for i = 0, iterations-1 do
		-- // generate some wave direction that looks kind of random
		local p : Vector2 = Vector2.new(g.sin(iter), g.cos(iter));
		-- // calculate wave data
		local res : Vector2 = wavedx(position, p, speed, phase, iTime);

		-- // shift position around according to wave drag and derivative of the wave
		position += p * res.Y * weight * DRAG_MULT;

		-- // add the results to sums
		sumOfValues += res.X * weight;
		sumOfWeights += weight;

		-- // modify next octave ;
		weight = g.mix(weight, 0, 0.2);
		phase *= 1.18;
		speed *= 1.07;

		-- // add some kind of random value to make next wave look random too
		iter += 12.0;
	end
	-- // calculate and return
	return sumOfValues / sumOfWeights;
end

--// Raymarches the ray from top water layer boundary to low water layer boundary
function rayMarchWater ( iTime : number , camera : Vector3, start : Vector3, ending : Vector3, depth : number ) : number
	local pos : Vector3 = start;
	local h = 0;
	local hupper = depth;
	local hlower = 0;
	local zer = Vector2.zero;
	local dir = (ending - start).Unit;
	local eps = 0.01;
	for i = 0, 317 do
		h = getWaves(iTime, xz(pos) * 0.1, ITERATIONS_RAYMARCH) * depth - depth;
		local dist_pos = (pos - camera).Magnitude;
		if h + eps*dist_pos > pos.Y then
			return dist_pos;
		end
		pos += dir * (pos.Y - h);
		-- // eps *= 1.01;
	end
	return -1;
end

-- // Calculate normal at point by calculating the height at the pos and 2 additional points very close to pos
function getNormal( iTime : number , pos : Vector2 , e : number , depth : number ) : Vector3
	local ex = Vector2.new(e, 0);
	local H = getWaves(iTime, pos, ITERATIONS_NORMAL) * depth;
	local a = Vector3.new(pos.X, H, pos.Y);
	return (a - Vector3.new(pos.X - e, getWaves(iTime, pos - ex, ITERATIONS_NORMAL) * depth, pos.Y)):Cross(
		a - Vector3.new(pos.X, getWaves(iTime, pos + g.yx(ex), ITERATIONS_NORMAL) * depth, pos.Y + e)
	).Unit;
end

-- // Helper function generating a rotation matrix around the axis by the angle
function rotmat( axis : Vector3, angle : number ) : {{number}}
	local s = g.sin(angle);
	local c = g.cos(angle);
	local oc = 1.0 - c;
	return {
		{oc * axis.X * axis.X + c, oc * axis.X * axis.Y - axis.Z * s,  oc * axis.Z * axis.X + axis.Y * s},
		{oc * axis.X * axis.Y + axis.Z * s,  oc * axis.Y * axis.Y + c,           oc * axis.Y * axis.Z - axis.X * s}, 
		{oc * axis.Z * axis.X - axis.Y * s,  oc * axis.Y * axis.Z + axis.X * s,  oc * axis.Z * axis.Z + c}
	}
end

-- // Helper function that generates camera ray based on UV and mouse
function getRay ( iResolution : Vector2, iMouse : Vector2, uv : Vector2 ) : Vector3
	uv = (uv * 2 - Vector2.one) * Vector2.new(iResolution.X / iResolution.Y, 1);
	-- // for fisheye, uncomment following line and comment the next one
	-- // local proj : Vector3 = (Vector3.new(uv.X, uv.Y, 1) + (Vector3.new(uv.X, uv.Y, -1) * uv.Magnitude^2 * 0.05)).Unit;
	local proj : Vector3 = Vector3.new(uv.X, uv.Y, 1.5).Unit;
	if iResolution.X < 400 then return proj end

	return mat_v3_mul(
		matmul(
			rotmat(-1 * Vector3.yAxis, 3 * (iMouse.X * 2 - 1)),
			rotmat(Vector3.xAxis, 1.5 * (iMouse.Y * 2 - 1))
		),
		proj
	);
end

-- // Ray-Plane intersection checker
function intersectPlane ( origin : Vector3 , direction : Vector3 , point : Vector3 , normal : Vector3 ) : number
	return g.clamp((point - origin):Dot(normal) / direction:Dot(normal), -1, 9991999);
end

-- // Some very barebones but fast atmosphere approximation
function extra_cheap_amosphere( raydir : Vector3 , sundir : Vector3 ) : Vector3
	local special_trick = 1.0 / (raydir.Y * 1.0 + 0.1);
	local special_trick2 = 1.0 / (sundir.Y * 11.0 + 1.0);
	local raysundt = g.abs(sundir:Dot(raydir))^2;
	local sundt = g.max(0.0, sundir:Dot(raydir))^8;
	local mymie = sundt * special_trick * 0.2;
	local suncolor = g.mix_v3(Vector3.one, Vector3.new(0.7544642686843872, 0.4196428656578064, 0), special_trick2);
	local bluesky = Vector3.new(0.2455357164144516, 0.5803571343421936, 1) * suncolor;
	local bluesky2 = Vector3.zero:Max(bluesky - Vector3.new(5.5, 13, 22.4) * 0.002 * (special_trick + -6 * sundir.Y * sundir.Y));
	bluesky2 *= special_trick * (0.24 + raysundt * 0.24);
	return bluesky2 * (1.0 + 1.0 * 1.0 - raydir.Y^3) + mymie * suncolor;
end


-- // Get atmosphere color for given direction
function getAtmosphere( ray : Vector3 ) : Vector3
	return extra_cheap_amosphere(ray, Vector3.one.Unit) * 0.5;
end

-- // Get sun color for given direction
function getSun ( ray : Vector3 ) : number
	return g.max(0, ray:Dot(Vector3.one.Unit))^528 * 110;
end

-- // Great tonemapping function from my other shader: https://www.shadertoy.com/view/XsGfWV
function aces_tonemap( color : Vector3 ) : Vector3
	local m1 = {
		{0.59719, 0.07600, 0.02840},
		{0.35458, 0.90834, 0.13383},
		{0.04823, 0.01566, 0.83777}
	};
	local m2 = {
		{1.60475, -0.10208, -0.00327},
		{-0.53108,  1.10813, -0.07276},
		{-0.07367, -0.00605,  1.07602}
	};
	local v = mat_v3_mul(m1, color);
	local c = (v * (v + 0.0245786) - 0.000090537) / (v * (0.983729 * v + 0.4329510) + 0.238081);
	return g.pow_v3(clamp_v3(mat_v3_mul(m2, c), 0, 1), Vector3.one * 1 / 2.2);
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
		local uv = fragCoords / iResolution;

		local waterdepth = 2.1;
		local wfloor = Vector3.yAxis * -waterdepth;
		local wceil = Vector3.zero;
		local orig = Vector3.yAxis * 2;
		local ray = getRay(iResolution, iMouse, uv);
		local hihit = intersectPlane(orig, ray, wceil, Vector3.yAxis);

		if ray.Y >- -0.01 then
			local C = getAtmosphere(ray) * 2 + getSun(ray);
			-- // tonemapping
			C = aces_tonemap(C);
			return g.v3_rgb(C);
		end

		local lohit = intersectPlane(orig, ray, wfloor, Vector3.yAxis);
		local hipos = orig + ray * hihit;
		local lopos = orig + ray * lohit;
		local dist = rayMarchWater(iTime, orig, hipos, lopos, waterdepth);
		local pos = orig + ray * dist;

		local N = getNormal(iTime, xz(pos), 0.001, waterdepth);
		N = g.mix(Vector3.yAxis, N, 1 / (dist * dist * 0.01 + 1));
		local R = g.reflect(ray, N);
		local fresnel = 0.04 + 0.96 * (1 - g.max(0, (-N):Dot(ray)))^5;

		local C = fresnel * getAtmosphere(R) * (2 + fresnel * getSun(R));
		-- // tonemapping
		return g.v3_rgb(aces_tonemap(C));
	end,
}