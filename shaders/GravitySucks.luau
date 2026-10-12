
--[=[
	GravitySucks
	Shader by @mrange on https://www.shadertoy.com/view/4cyXWw
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
const length = vector.magnitude
const normalize = vector.normalize
const dot = vector.dot
const mix_v = vector.lerp
const sqrt = math.sqrt
const mix = math.lerp

const function sin_v3(v: vec3): (vec3)
	return vec3(math.sin(v.x), math.sin(v.y), math.sin(v.z))
end

const function reflect(i: vec3, n: vec3): (vec3)
	return i - 2 * vector.dot(n, i) * n
end

const function sqrt_v(v: vector): (vector)
	return vec3(math.sqrt(v.x), math.sqrt(v.y), math.sqrt(v.z))
end

const function smoothstep(edge0: number, edge1: number, x: number): (number)
	const t = math.clamp((x - edge0) / (edge1 - edge0), 0, 1)
	return t * t * (3 - 2 * t)
end

const VEC3_1 = vector.one
const RO_DEFAULT = vec3(0, 0, 10)
const DIFDIR_DEFAULT = normalize(vec3(1, 1.5, 2))
const SPEDIR_DEFAULT = normalize(vec3(1, 2, 1))

const BALLS_COLOR = vec3(0, 1, 2)
const REFLECT_COLOR = vec3(.05, .1, .2)
const REFLECT_COLOR_SQRT = sqrt_v(REFLECT_COLOR)
const FLOOR_COLOR = vec3(0, 0, 1)

-- CC0: Gravity sucks
-- Tinkering away....

const LAYERS = 5.
const SCALE  = 1.
const PI     = 3.141592654
const TAU    = (2.0*PI)

-- License: Unknown, author: Unknown, found: don't remember
const function hash(co: number): (number)
	const val = math.sin(co*12.9898) * 13758.5453
	return val - val // 1
end

const H0_CACHE = table.create(LAYERS, 0)
const H1_CACHE = table.create(LAYERS, 0)
const TF_CACHE = table.create(LAYERS, 0)

for i = 0, LAYERS - 1 do
	const h0 = hash(i+123.4)
	local h1 = 8667.0 * h0; h1 -= h1 // 1;
	--const h2 = 8707.0*h0; h2 -= h2 // 1;
	local h3 = 8887.0 * h0; h3 -= h3 // 1;
	const tf = mix(.5, 1.5, h3)

	const idx = i + 1
	H0_CACHE[idx] = h0
	H1_CACHE[idx] = h1
	TF_CACHE[idx] = tf
end

-- License: MIT OR CC-BY-NC-4.0, author: mercury, found: https://mercury.sexy/hg_sdf/
-- /* `p` is `inout`, meaning that change to it is global(?)
const function mod1(p: number, size: number): (number, number)
	const halfsize = size/2
	const c = (p + halfsize) // size
	p = ((p + halfsize) % size) - halfsize
	return c, p
end

-- License: Unknown, author: Unknown, found: don't remember
const function bounce(t: number, dy: number, dropOff: number): (number)
	const gr = 5
	const p0 = 2*dy/gr

	t += p0/2
		
	const ldo = math.log(dropOff)
		
	const yy = 1. - (1. - dropOff) * t / p0

	if yy > 1e-4 then
		const n	= math.log(yy) // ldo
		const dn = math.pow(dropOff, n)

		const yyy = dy * dn
		t -= p0 * (1 - dn) / (1 - dropOff)

		return - 0.5*gr*t*t + yyy*t

	else
		return 0
	end
end

const function ball(iResolution_y: number, col: vec3, pp: vec2, p: vec2, r: number, pal: number):  (vec3)
	const ro =  RO_DEFAULT
	const difDir = DIFDIR_DEFAULT
	const speDir = SPEDIR_DEFAULT
	const p3 = vec3(pp.x, pp.y, 0)
	const rd = normalize(p3-ro)


	const bcol = VEC3_1 * 0.5 + 0.5 * sin_v3(0.5 * BALLS_COLOR + VEC3_1 * TAU * pal)
	const aa = sqrt(8) / iResolution_y
	const z2 = r*r - dot(p, p)

	if z2 > 0 then
		const z = sqrt(z2)
		const cp = vec3(p.x, p.y, z)
		const cn = normalize(cp)
		const cr = reflect(rd, cn)
		const cd = math.max(dot(difDir, cn), 0.0)
		const cs = 1.008-dot(cr, speDir)

		const ccol = mix(0.1, 1, cd*cd) * bcol + sqrt_v(bcol) * (1e-2 / cs)
		const d = length(p) - r
		col = mix_v(col, ccol, smoothstep(0, -aa, d))
	end

	return col
end

const function effect(iResolution_y: number, iTime: number, p: vec2): (vec3)
	p += vec2(0, .5)
	const sy = math.sign(p.y)
	p = vec2(p.x, math.abs(p.y))
	if sy < 0 then
		p *= vec2(1,1.5)
	end

	local col = vector.zero
	--const aa = sqrt(4)/iResolution_y;
	for i = 0, LAYERS - 1 do
		const idx = i + 1
		const h0 = H0_CACHE[idx]
		const h1 = H1_CACHE[idx]
		const tf = TF_CACHE[idx]
		const it = tf * iTime
		const cw = mix(0.25, 0.75, h0*h0) * SCALE
		const per = mix(0.75, 1.5, h1*h1) * cw
		local p0 = p
		const nt = it // per
		p0 -= vec2(cw * (it - nt * per) / per, 0)
		local n0, p0x = mod1(p0.x, cw)
		n0 -= nt
		p0 = vec2(p0x, p0.y)
		if n0 > -7 - i * 3 then continue end
		const ct = it + n0 * per

		const ch0 = hash(h0+n0)
		local ch1 = 8667.0 * ch0; ch1 -= ch1 // 1;
		local ch2 = 8707.0 * ch0; ch2 -= ch2 // 1;
		local ch3 = 8887.0 * ch0; ch3 -= ch3 // 1;
		local ch4 = 9011.0 * ch0; ch4 -= ch4 // 1;

		const radii = cw * mix(.25, .5, ch0*ch0)
		const dy = mix(3., 2., ch3)
		const bf = mix(.6, .9, ch2)
		const b = bounce(ct / tf + ch4, dy, bf)
		p0 -= vec2(0, b + radii)
		col = ball(iResolution_y, col, p, p0, radii, ch1)
	end

	if sy < 0 then
		col *= mix_v(REFLECT_COLOR_SQRT, REFLECT_COLOR, p.y)
		col += .1 * FLOOR_COLOR * math.max(p.y * p.y, 0)
	end

	col = sqrt_v(col)
	return col
end

local diff_resolution: vec2, resolution_y: number

-- Shader program
return {
	CONFIGURATION = {
		InterlaceFactor = 2;
		ScreenDivision = Vector2.new(4, 2);
	};

	init = function (iResolution: vec2): ()
		diff_resolution, resolution_y = -iResolution, iResolution.y
	end;
	
	mainImage = function (fragCoord: vec2, _, iTime: number): (vec3, number)
		const p = (diff_resolution + 2 * fragCoord) / resolution_y
		const col = effect(resolution_y, iTime, p)

		return col, 1;
	end;
}