
--[=[
	Currents
	Shader by @s23b on https://www.shadertoy.com/view/MsG3DK
	Ported to Luau — ran by my engine — `RbxShader`.
	
	( Original comments are preserved. )
]=]

--!strict
--!optimize 2
--!native

type vec3 = vector
type vec2 = vector

const vec3 = vector.create
const vec2 = vector.create
const dot = vector.dot
const mix_v = vector.lerp
const length = vector.magnitude
const mix = math.lerp
const sin = math.sin
const abs = math.abs
const VEC3_1 = vector.one
const VEC2_1 = vector.one

const HASH_VEC2 = vec2(.009123898, .00231233)
const VEC2_0A0 = vec2(0, 0)
const VEC2_0A1 = vec2(0, 1)
const VEC2_1A0 = vec2(1, 0)
const VEC2_1A1 = vec2(1, 1)
const VEC2_nXY = vec2(-1, 1)

const VEC2_BALL_PARAM_A = vec2(-.1, .1)
const VEC2_BALL_PARAM_B = vec2(-.3, .3)
const VEC2_BALL_PARAM_C = vec2(-.4, .4)
const VEC2_BALL_PARAM_D = vec2(.2, .6)
const VEC2_BALL_PARAM_E = vec2(.0, .0)

const VEC2_DIST1 = vec2(150, 130)
const VEC2_DIST2 = vec2(0, 20)
const VEC2_DIST3 = vec2(1.5, -2)

const VEC2_BALL_PARAM_F = vec2(.1, 0)

const VEC2_LRC = vec2(.4, -.85)

const VEC2_LINES_PARAM1 = vec2(1, 2)
const VEC2_LINES_PARAM2 = vec2(-1, -1)
const LINES_COLOR1 = vec3(.92, .16, .20)
const LINES_COLOR2 = vec3(.93, .64, .17)
const LINES_COLOR3 = vec3(.8, .68, .82)

const function smoothstep(edge0: number, edge1: number, x: number): (number)
	const t = math.clamp((x - edge0) / (edge1 - edge0), 0, 1)
	return t * t * (3 - 2 * t)
end

const TAU = 6.28318530718

const function hash(uv: vec2): (number)
	const val =	math.cos(sin(dot(uv, HASH_VEC2)) * 48.512353) * 11111.5452313
	return val - val // 1
end

const function noise(uv: vec2): (number)
	const fuv = uv // 1
	const c_x = hash(fuv + VEC2_0A0)
	const c_y = hash(fuv + VEC2_0A1)
	const c_z = hash(fuv + VEC2_1A0)
	const c_w = hash(fuv + VEC2_1A1)
	const uv_x, uv_y = uv.x, uv.y
	const t1 = smoothstep(0, 1, uv_y - uv_y // 1) -- * remove smoothstep for a rougher effect
	const t2 = smoothstep(0, 1, uv_x - uv_x // 1) -- * remove smoothstep for a rougher effect
	const axis_x, axis_y = mix(c_x, c_y, t1), mix(c_z, c_w, t1)
	return mix(axis_x, axis_y, t2)
end

const function fbm(uv: vec2, iTime: number): (number)
	local f = 0.
	local r = 1.
	const inc = VEC2_nXY * iTime / 16.
	const lim = 3 -- * or 8 for rougher effect
	for i = 0, lim - 1 do
		uv += inc
		const _r = r
		r *= 2.
		f += noise((uv)*_r) / r;
	end
	return f / (1. - 1. / r);
end

const function createBall(uv: vec2): (vec3)
	local f = smoothstep(0.5, 1.4, length(uv - VEC2_BALL_PARAM_A)) * .5;
    f += smoothstep(.0, .9, 1.3- length(uv - VEC2_BALL_PARAM_B)) * .5;
    f += smoothstep(.1, .5, .5- length(uv - VEC2_BALL_PARAM_C));
    f += smoothstep(.1, .5, .4- length(uv - VEC2_BALL_PARAM_D));
    f *= 1. - smoothstep(.95, 1., length(uv - VEC2_BALL_PARAM_E));
	return VEC3_1*f;
end

local res_x: number, res_y: number
local ball: vec2, time_weight: vec2

-- Shader program
return {
	CONFIGURATION = {
		InterlaceFactor = 2;
		ScreenDivision = Vector2.new(4, 2);
	};

	init = function (iResolution: vec2): ()
		res_x, res_y = iResolution.x, iResolution.y
	end;

	perFrame = function (iTime: number): ()
		ball = vec2(.2, -.4 + sin(iTime * 4.) / 40.);
		time_weight = VEC2_1 * ((iTime - iTime // 1) * 10000.);
	end;
	
	mainImage = function (fragCoord: vec2, _, iTime: number): (vec3, number)
		local fragColor: vec3
		const uv_x = fragCoord.x / res_x * 2. - 1.;
		const uv_y = fragCoord.y / res_y * 2. - 1.;
		const uv = vec2(uv_x * res_x / res_y, uv_y);

		const r = .2;

		-- create distorted version of the space
		local distuv = uv * VEC2_DIST1 + VEC2_DIST2;
		distuv *= length(uv - VEC2_DIST3) / 3.;

		const distuv_x = distuv.x + smoothstep(1. - r * 1.5, 1., 1. - length(uv - (ball - VEC2_BALL_PARAM_F))) * 15.;
		-- add distortion for the ball
		distuv = vec2(distuv_x, distuv.y)

		-- calculate distortion level from distance to lower right corner
		const t = smoothstep(0., 1., 1. - length((uv * .5) - VEC2_LRC));

		-- add noise to distortion weighted by distortion level
		distuv += VEC2_1 * (fbm(uv * 2., iTime) - .5) * t * 100.;

		-- calculate stripes
		const f = sin(distuv.x + distuv.y);

		-- calculate distance from distorted diagonal
		const d = (distuv.x + distuv.y) / TAU;

		if abs(uv.x) > 1. or abs(uv.y) > 1. then -- outside boundaries
			fragColor = vector.zero;
		elseif d < .5 and d > - 1. then -- inside red line
			const grad = math.min(1., (.75 - abs(d + .25)) * 5.);
			fragColor = mix_v(LINES_COLOR1, LINES_COLOR2, -uv.y) * grad;
		else -- lines
			const spot = math.clamp(3. - length((uv * VEC2_LINES_PARAM1) - VEC2_LINES_PARAM2), 0., 1.);
			fragColor = LINES_COLOR3 * f * spot;
		end

		-- create ball color
		const uv_ball = uv - ball
		const b = createBall(uv_ball / r);

		-- create ball mask
		local mask = 1. - smoothstep(r - .002, r + .01, length(uv_ball));
		mask *= smoothstep(-1.2, -.9, d);

		-- add ball
		fragColor = mix_v(fragColor, b, mask);

		-- add a noise
		fragColor -= VEC3_1 * noise(uv * 300. + time_weight) / 5.;

		return fragColor, 1;
	end;
}