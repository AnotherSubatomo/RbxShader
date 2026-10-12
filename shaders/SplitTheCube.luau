
--[=[
	SplitTheCube
	Shader by @Rlsio on https://www.shadertoy.com/view/lf23DG
	Ported to Luau — ran by my engine — `RbxShader`.
	
	( Original comments are preserved. )
	 * Modified to be more performant natively
]=]

--!strict
--!optimize 2
--!native

type vec3 = vector
type vec2 = vector
type iTime = number

const vec3 = vector.create
const vec2 = vector.create
const normalize = vector.normalize
const length = vector.magnitude
const abs_v = vector.abs
const cos = math.cos
const sin = math.sin

const VECN_0 = vector.zero
const VEC3_1 = vector.one
const VEC3_2 = vec3(2, 2, 2)
const VEC3_P2 = vec3(.2, .2, .2)
const VEC3_P6 = vec3(.6, .6, .6)

const SIZE = vec3(20, 20, 20)
const VEC3_A = -SIZE / 2
const VEC3_B = SIZE / 2

const P_INIT = vec3(0, 0, -30)
const E = vec3(0, .001, 0)
const E_YXX = vec3(.001, 0, 0)
const E_XXY = vec3(0, 0, .001)

const CUBE_COLORSET = vec3(0, 23, 21)
const BACKGROUND = vec3(6, 7, 9)
const VIGNETTE = .05

const function smoothstep(edge0: number, edge1: number, x: number): (number)
	const t = math.clamp((x - edge0) / (edge1 - edge0), 0, 1)
	return t * t * (3 - 2 * t)
end

const function rot(a: number): (vec2, vec2)
	const cos_a = cos(a)
	return vec2(cos_a, cos(a+11)), vec2(cos(a+33), cos_a)
end

const function cor(a: number): (vec3)
	const cor1 = VEC3_1 * a * 6.3 + CUBE_COLORSET * a
	return (vec3(cos(cor1.x), cos(cor1.y), cos(cor1.z)) * .6 + VEC3_P6)
end

const function h11(a: number): (number)
	const val = sin(a * 12.9898) * 43758.5453123
	return val - val // 1
end

local id: number;
local t: iTime;
local rotD: vec3, rotD_abs: vec3;
local R1_C1, R1_C2 = VECN_0, VECN_0
local R2_C1, R2_C2 = VECN_0, VECN_0
local LIGHT_DIR = VECN_0

const function marchLimit(p: vec3, a: vec3, b: vec3): (number)
	const step = vec3(
		if rotD.x < 0 then a.x else b.x,
		if rotD.y < 0 then a.y else b.y,
		if rotD.z < 0 then a.z else b.z)
	const m = abs_v(p - step) / rotD_abs
	return math.min(m.x, m.y, m.z)
end

const function blocks(p: vec3): (number)
	local div, edges = VECN_0, VECN_0
	local a = VEC3_A
	local b = VEC3_B
	const a_, b_ = a, b
	
	local i, e, d, gCD = 0, 0, 0, 0

	while i < 3 do -- // split the cube
		i += 1
		-- step = step(p, div)
		const div_x, div_y, div_z = div.x, div.y, div.z
		const step_x = div_x < p.x
		const step_y = div_y < p.y
		const step_z = div_z < p.z
		b = vec3(
			if step_x then b.x else div_x,
			if step_y then b.y else div_y,
			if step_z then b.z else div_z)
		a = vec3(
			if step_x then div_x else a.x,
			if step_y then div_y else a.y,
			if step_z then div_z else a.z)

		id = length(vec3(
			1 + if step_x then -div_x else div_x,
			1 + if step_y then -div_y else div_y,
			1 + if step_z then -div_z else div_z))

		div = vector.min(b - VEC3_2,
			vector.max(a + VEC3_2, vec3(
				h11(i + id    ),
				h11(i + id + 2),
				h11(i + id + 4)
			) * (b - a) + a))
	end

	gCD = marchLimit(p, a, b)
	e = smoothstep(-1, 1, sin(t + h11(id)) * 2 - .5) * 3 + 1
	edges = vec3(
		if b_.x - b.x < .01 or  a.x - a_.x < .01 then e else 1,
		if b_.y - b.y < .01 or  a.y - a_.y < .01 then e else 1,
		if b_.z - b.z < .01 or  a.z - a_.z < .01 then e else 1
	)

	d = length(vector.max(abs_v(p-(a+b) / 2 * edges) - (b-a) / 2 + VEC3_P2, VECN_0)) - .2

	return math.min(d, gCD)
end

const function map(p: vec3): (number)
	const P_xz = R1_C1*p.x + R1_C2*p.z
	const P_xy = R2_C1*P_xz.x + R2_C2*p.y
	const rotP = vec3(P_xy.x, P_xy.y, P_xz.y)
	return blocks(rotP) + .01
end

-- // O que este shader tem em comum com este outro?
-- // https://www.shadertoy.com/view/McXyz2

local scaled_res: vec2, res_y: number

-- Shader program
return {
	CONFIGURATION = {
		InterlaceFactor = 2;
		ScreenDivision = Vector2.new(4, 2);
	};

	init = function (iResolution: vec2): ()
		scaled_res, res_y = iResolution / 2, iResolution.y
	end;

	perFrame = function (iTime: number): ()
		t = iTime * 0.5;
		R1_C1, R1_C2 = rot(cos(2. * t))
		R2_C1, R2_C2 = rot(t * .3)
		LIGHT_DIR = vec3(cos(iTime), sin(iTime), 0)
	end;
	
	mainImage = function (fragCoord: vec2): (vec3, number)
		local r, i, d, far, s = 0, 0, 0, 80., 1.;
		fragCoord = (fragCoord - scaled_res) / res_y;

		local N = VECN_0;
		local p = P_INIT;
		const D = normalize(vec3(fragCoord.x, fragCoord.y, 1));
		const L = normalize(LIGHT_DIR - D);

		const D_xz = R1_C1*D.x + R1_C2*D.z
		const D_xy = R2_C1*D_xz.x + R2_C2*D.y
		rotD = vec3(D_xy.x, D_xy.y, D_xz.y)
		rotD_abs = abs_v(rotD)

		while (i < 60. and d < far and s > .01) do
			i+= 1;
			s = map(p);
			d += s;
			p += s * D;
		end
		
		const map_p = map(p) --@temp;
		N = normalize(
            vec3( map(p + E_YXX) - map_p, map(p + E) - map_p,
                  map(p + E_XXY) - map_p));

		r = math.max(0, vector.dot(L, N));
		
		const fragColor = vector.lerp(
			(.3 * r + .4) -- diff
			* cor(id)    -- alb
			+ VEC3_1*math.pow(r, 120.), -- spec
			BACKGROUND -- bg
			* (.1 - length(fragCoord * VIGNETTE)), -- vig
			math.pow(math.clamp(d/far, 0., 1.), 1.5)); -- fog
		
		return fragColor, 1;
	end;
}