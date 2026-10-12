
--[=[
	Procedural3DOcean
	Shader by @jarble and @afl_ext on https://www.shadertoy.com/view/3scfD7
	Ported to Luau — ran by my engine — `RbxShader`.
	
	( Original comments are preserved. )
	[ ⚠ NOT WORKING AS INTENDED ]
]=]

--!native

local g = require(game.ReplicatedStorage.RbxShader.lib.GraphicsMath)
local uvec3 = Vector3.one
type float = number
type vec3 = Vector3
type vec2 = Vector2

-- // #defines
local Mouse: vec2
local Resolution: vec2
local Time: float

-- // Use your mouse to move the camera around! Press the Left Mouse Button on the image to look around!

local DRAG_MULT = 0.38 -- // changes how much waves pull on the water
local WATER_DEPTH = 2.1 -- // how deep is the water
local ITERATIONS_RAYMARCH = 12 -- // waves iterations of raymarching
local ITERATIONS_NORMAL = 28 -- // waves iterations when calculating normals

const function mat3(
	a: float, b: float, c: float,
	d: float, e: float, f: float,
	g: float, h: float, i: float
): (vec3, vec3, vec3)
	return Vector3.new(a, d, g),
		Vector3.new(b, e, h),
		Vector3.new(c, f, i)
end

-- // Helper function for multiplying two matrices
const function mat3_mul(
	A_C1: vec3, A_C2: vec3, A_C3: vec3,
	B_C1: vec3, B_C2: vec3, B_C3: vec3
): (vec3, vec3, vec3)
	return
		A_C1*B_C1.X + A_C2*B_C1.Y + A_C3*B_C1.Z,
		A_C1*B_C2.X + A_C2*B_C2.Y + A_C3*B_C2.Z,
		A_C1*B_C3.X + A_C2*B_C3.Y + A_C3*B_C3.Z
end

-- // Calculates wave value and its derivative, 
-- // for the wave direction, position in space, wave frequency and time
const function wavedx (position: vec2, direction: vec2, speed: float , frequency: float, timeshift: float): (Vector2)
	local x = direction:Dot(position) * frequency + timeshift * speed;
	local wave = math.exp(math.sin(x) - 1);
	local dx = wave * math.cos(x);
	return Vector2.new(wave, -dx);
end

-- // Calculates waves by summing octaves of various waves with various parameters
const function getWaves(position: vec2, iterations: float): (float)
	local iter = 0.0; 				-- // this will help generating well distributed wave directions
	local phase = 6.0;				-- // frequency of the wave, this will change every iteration
	local speed = 2.0;				-- // time multiplier for the wave, this will change every iteration
	local weight = 1.0;				-- // weight in final sum for the wave, this will change every iteration
	local sumOfValues = 0.0;		-- // will store final sum of values
	local sumOfWeights = 0.0;		-- // will store final sum of weights
	for i = 0, iterations-1 do
		-- // generate some wave direction that looks kind of random
		local p : Vector2 = Vector2.new(math.sin(iter), math.cos(iter));
		-- // calculate wave data
		local res : Vector2 = wavedx(position, p, speed, phase, Time);

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
function rayMarchWater(camera: vec3, start: vec3, ending: vec3, depth: float): (float)
	local pos = start;
	local h = 0;
	local hupper = depth;
	local hlower = 0;
	local zer = Vector2.zero;
	local dir = (ending - start).Unit;
	local eps = 0.01;
	for i = 0, 317 do
		h = getWaves(g.xz(pos) * 0.1, ITERATIONS_RAYMARCH) * depth - depth;
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
function getNormal(pos: vec2, e: float, depth: float): (vec3)
	local ex = Vector2.new(e, 0);
	local H = getWaves(pos, ITERATIONS_NORMAL) * depth;
	local a = Vector3.new(pos.X, H, pos.Y);
	return (a - Vector3.new(pos.X - e, getWaves(pos - ex, ITERATIONS_NORMAL) * depth, pos.Y)):Cross(
		a - Vector3.new(pos.X, getWaves(pos + g.yx(ex), ITERATIONS_NORMAL) * depth, pos.Y + e)
	).Unit;
end

-- // Helper function generating a rotation matrix around the axis by the angle
function rotmat(axis: vec3, angle: float) : (vec3, vec3, vec3)
	local s = math.sin(angle);
	local c = math.cos(angle);
	local oc = 1.0 - c;
	return mat3(
		oc * axis.X * axis.X + c, oc * axis.X * axis.Y - axis.Z * s,  oc * axis.Z * axis.X + axis.Y * s,
		oc * axis.X * axis.Y + axis.Z * s,  oc * axis.Y * axis.Y + c,           oc * axis.Y * axis.Z - axis.X * s, 
		oc * axis.Z * axis.X - axis.Y * s,  oc * axis.Y * axis.Z + axis.X * s,  oc * axis.Z * axis.Z + c
)
end

-- // Helper function that generates camera ray based on UV and mouse
function getRay (uv: vec2): (vec3)
	uv = (uv * 2 - Vector2.one) * Vector2.new(Resolution.X / Resolution.Y, 1);
	-- // for fisheye, uncomment following line and comment the next one
	-- // local proj : Vector3 = (Vector3.new(uv.X, uv.Y, 1) + (Vector3.new(uv.X, uv.Y, -1) * uv.Magnitude^2 * 0.05)).Unit;
	local proj : Vector3 = Vector3.new(uv.X, uv.Y, 1.5).Unit;
	if Resolution.X < 400 then return proj end

	local R_C1, R_C2, R_C3 = mat3_mul(
		rotmat(-1 * Vector3.yAxis, 3 * (Mouse.X * 2 - 1)),
		rotmat(Vector3.xAxis, 1.5 * (Mouse.Y * 2 - 1))
	) --@temp
	return R_C1*proj.X + R_C2*proj.Y + R_C3*proj.Z;
end

-- // Ray-Plane intersection checker
function intersectPlane (origin: vec3, direction: vec3, point: vec3, normal: vec3): (float)
	return math.clamp((point - origin):Dot(normal) / direction:Dot(normal), -1, 9991999);
end

-- // Some very barebones but fast atmosphere approximation
function extra_cheap_amosphere(raydir: vec3, sundir: vec3): (vec3)
	local special_trick = 1.0 / (raydir.Y * 1.0 + 0.1);
	local special_trick2 = 1.0 / (sundir.Y * 11.0 + 1.0);
	local raysundt = math.abs(sundir:Dot(raydir))^2;
	local sundt = math.max(0.0, sundir:Dot(raydir))^8;
	local mymie = sundt * special_trick * 0.2;
	local suncolor = g.mix_v3(uvec3, Vector3.new(0.7544642686843872, 0.4196428656578064, 0), special_trick2);
	local bluesky = Vector3.new(0.2455357164144516, 0.5803571343421936, 1) * suncolor;
	local bluesky2 = Vector3.zero:Max(bluesky - Vector3.new(5.5, 13, 22.4) * 0.002 * (special_trick + -6 * sundir.Y * sundir.Y));
	bluesky2 *= special_trick * (0.24 + raysundt * 0.24);
	return bluesky2 * (1.0 + 1.0 * 1.0 - raydir.Y^3) + mymie * suncolor;
end


-- // Get atmosphere color for given direction
function getAtmosphere(ray: vec3): vec3
	return extra_cheap_amosphere(ray, uvec3.Unit) * 0.5;
end

-- // Get sun color for given direction
function getSun (ray: vec3): (float)
	return math.max(0, ray:Dot(uvec3.Unit))^528 * 110;
end

-- // Great tonemapping function from my other shader: https://www.shadertoy.com/view/XsGfWV
local c0 = uvec3*0.0245786 --@temp
local c1 = uvec3*0.000090537 --@temp
local c2 = uvec3*0.983729 --@temp
local c3 = uvec3*0.4329510 --@temp
local c4 = uvec3*0.238081 --@temp
local m1_c1, m1_c2, m1_c3 = mat3(
	0.59719, 0.07600, 0.02840,
	0.35458, 0.90834, 0.13383,
	0.04823, 0.01566, 0.83777
)
local m2_c1, m2_c2, m2_c3 = mat3(
	1.60475, -0.10208, -0.00327,
	-0.53108,  1.10813, -0.07276,
	-0.07367, -0.00605,  1.07602
);
function aces_tonemap(color: vec3): (vec3)
	local v = m1_c1*color.X + m1_c2*color.Y + m1_c3*color.Z;
	local c = (v * (v + c0) - c1) / (v * (c2 * v + c3) + c4);
	local cmul = m2_c1*c.X + m2_c2*c.Y + m2_c3*c.Z --@temp
	return g.pow_v3(g.clamp_v3(cmul, 0, 1), uvec3*(1 / 2.2));
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
		Mouse = iMouse/iResolution;
		Resolution = iResolution;
		Time = iTime;
		local uv = fragCoords / iResolution;
		
		local wfloor = Vector3.yAxis * -WATER_DEPTH;
		local wceil = Vector3.zero;
		local orig = Vector3.yAxis * 2;
		local ray = getRay(uv);
		local hihit = intersectPlane(orig, ray, wceil, Vector3.yAxis);

		if ray.Y >- -0.01 then
			local C = getAtmosphere(ray) * 2 + uvec3*getSun(ray);
			-- // tonemapping
			C = aces_tonemap(C);
			return g.v3_rgb(C);
		end

		local lohit = intersectPlane(orig, ray, wfloor, Vector3.yAxis);
		local hipos = orig + ray * hihit;
		local lopos = orig + ray * lohit;
		local dist = rayMarchWater(orig, hipos, lopos, WATER_DEPTH);
		local pos = orig + ray * dist;

		local N = getNormal(g.xz(pos), 0.001, WATER_DEPTH);
		N = g.mix(Vector3.yAxis, N, 1 / (dist * dist * 0.01 + 1));
		local R = g.reflect(ray, N);
		local fresnel = 0.04 + 0.96 * (1 - math.max(0, (-N):Dot(ray)))^5;

		local C = fresnel * getAtmosphere(R) * (2 + fresnel * getSun(R));
		-- // tonemapping
		return g.v3_rgb(aces_tonemap(C));
	end,
}