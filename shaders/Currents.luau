
--[=[
	Currents
	Shader by @s23b on https://www.shadertoy.com/view/MsG3DK
	Ported to Luau — ran by my engine — `RbxShader`.
	
	( Original comments are preserved. )
]=]

--!native

local g = require(game.ReplicatedStorage.RbxShader.GraphicsMathLib)
local vec3 = Vector3.new
local vec2 = Vector2.new
local uvec3 = Vector3.one
local uvec2 = Vector2.one
local smoothstep = g.smoothstep

type float = number
type vec2 = Vector2
type vec3 = Vector3

local SMOOTH = true
local TAU = 6.28318530718

local function hash(uv: vec2): float
	return g.fract(math.cos(math.sin(uv:Dot(vec2(.009123898, .00231233))) * 48.512353) * 11111.5452313);
end

local function noise(uv: vec2): float
	local fuv = uv:Floor();
	local c_x = hash(fuv + vec2(0, 0))
	local c_y = hash(fuv + vec2(0, 1))
	local c_z = hash(fuv + vec2(1, 0))
	local c_w = hash(fuv + vec2(1, 1))
	local a1 = if SMOOTH then smoothstep(0, 1, g.fract(uv.Y)) else g.fract(uv.Y);
	local a2 = if SMOOTH then smoothstep(0, 1, g.fract(uv.X)) else g.fract(uv.X);
	local axis = g.mix_v2(vec2(c_x, c_z), vec2(c_y, c_w), a1);
	return g.mix(axis.X, axis.Y, a2);
end

local function fbm(uv: vec2, iTime: float): float
	local f = 0.;
	local r = 1.;
	local lim = if SMOOTH then 3 else 8
	for i = 0, lim-1, 1 do
		uv += vec2(-1, 1) * iTime / 16.
		local _r = r
		r *= 2.
		f += noise((uv)*_r) / r;
	end
	return f / (1. - 1. / r);
end

local function createBall(uv: vec2): vec3
	local f = g.smoothstep(0.5, 1.4, (uv-vec2(-.1, .1)).Magnitude) * .5;
    f += smoothstep(.0, .9, 1.3- (uv-vec2(-.3, .3)).Magnitude) * .5;
    f += smoothstep(.1, .5, .5- (uv-vec2(-.4, .4)).Magnitude);
    f += smoothstep(.1, .5, .4- (uv-vec2(.2, .6)).Magnitude);
    f *= 1. - smoothstep(.95, 1., (uv-vec2(.0, .0)).Magnitude);
	return uvec3*f;
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
		local uv = fragCoords / iResolution * 2. - uvec2;
		uv = vec2(uv.X * iResolution.X / iResolution.Y, uv.Y);

		local ball = vec2(.2, -.4 + (math.sin(iTime * 4.) / 40.));
		local r = .2;

		-- // create distorted version of the space
		local distuv = uv * vec2(150, 130) + vec2(0, 20);
		distuv *= (uv-vec2(1.5, -2)).Magnitude / 3.;

		-- vvv @temp; not from source code
		local dxa = distuv.X + smoothstep(1. - r * 1.5, 1., 1. - (uv-(ball - vec2(.1, 0))).Magnitude) * 15.;
		-- // add distortion for the ball
		distuv = vec2(dxa, distuv.Y)

		-- // calculate distortion level from distance to lower right corner
		local t = smoothstep(0., 1., 1. - ((uv * .5)-vec2(.4, -.85)).Magnitude);

		-- // add noise to distortion weighted by distortion level
		distuv += uvec2*(fbm(uv * 2., iTime) - .5) * t * 100.;

		-- // calculate stripes
		local f = math.sin(distuv.X + distuv.Y);

		-- // calculate distance from distorted diagonal
		local d = (distuv.X + distuv.Y) / TAU;

		if math.abs(uv.X) > 1. or math.abs(uv.Y) > 1. then -- // outside boundaries
			fragColor = Vector3.zero;
		elseif d < .5 and d > - 1. then -- // inside red line
			local grad = math.min(1., (.75 - math.abs(d + .25)) * 5.);
			fragColor = g.mix_v3(vec3(.92,.16,.20), vec3(.93, .64, .17), -uv.Y) * grad;
		else -- // lines
			local spot = math.clamp(3. - ((uv * vec2(1, 2))-vec2(-1, -1)).Magnitude, 0., 1.);
			fragColor = vec3(.8, .68, .82) * f * spot;
		end

		-- // create ball color
		local b = createBall((uv - ball) / r);

		-- // create ball mask
		local mask = 1. - smoothstep(r - .002, r + .01, (uv-ball).Magnitude);
		mask *= smoothstep(-1.2, -.9, d);

		-- // add ball
		fragColor = g.mix_v3(fragColor, b, mask);

		-- // add a noise
		fragColor -= uvec3*noise(uv * 300. + uvec2*(g.fract(iTime) * 10000.)) / 5.;

		return g.v3_rgb(fragColor);
	end
}