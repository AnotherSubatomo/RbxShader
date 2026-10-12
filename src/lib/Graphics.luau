
--[=[
	Graphics
	Minimal reimplementation of commonly used GLSL math functions in Luau.
	
	TRICKS:
	`clamp(n, min, max)` = `vector.min(max, vector.max(min, n))`

	* GLSL matrices are column major, so:
	`vec2(x, y) * mat2(a, b, c, d)` = ```
		mat2_C1, mat2_C2 = vec2(a, c), vec2(b, d)
		vec2 = mat2_C1*vec2.x + mat2_C2*vec2.y
	```
]=]

--!strict
--!optimize 2
--!native

type vec2 = vector
type vec3 = vector

const vec2 = vector.create
const vec3 = vector.create

const VEC2_1 = vec3(1, 1)
const VEC3_1 = vec3(1, 1, 1)

const function vec2_mat2(v: vec2, mat2_c1: vec2, mat2_c2: vec2): (vec2)
	return mat2_c1 * v.x + mat2_c2 * v.y
end

const function fract(v: any): (any)
	return v - v // 1
end

const function smoothstep(edge0: number, edge1: number, x: number): (number)
	const t = math.clamp((x - edge0) / (edge1 - edge0), 0, 1)
	return t * t * (3 - 2 * t)
end

const function clamp_v3(v: vec3, min: number, max: number): (vec3)
	return vector.min(VEC3_1 * max, vector.max(VEC3_1 * min, v))
end

const function clamp_v2(v: vec2 , min: number , max: number): (vec2)
	return vector.min(VEC2_1 * max, vector.max(VEC2_1 * min, v))
end

const function sqrt_v(v: vector): (vector)
	return vec3(math.sqrt(v.x), math.sqrt(v.y), math.sqrt(v.z))
end

const function sin_v3(v: vec3): (vec3)
	return vec3(math.sin(v.x), math.sin(v.y), math.sin(v.z))
end

const function sin_v2(v: vec2): (vec2)
	return vec2(math.sin(v.x), math.sin(v.y))
end

const function cos_v3(v: vec3): (vec3)
	return vec3(math.cos(v.x), math.cos(v.y), math.cos(v.z))
end

const function cos_v2(v: vec2): (vec2)
	return vec2(math.cos(v.x), math.cos(v.y))
end

const function step_v3(edge: vec3, x: vec3): (vec3)
	return vec3(
		if x.x < edge.x then 0 else 1,
		if x.y < edge.y then 0 else 1,
		if x.z < edge.z then 0 else 1)
end

const function step_v2(edge: vec2, x: vec2): (vec2)
	return vec2(
		if x.x < edge.x then 0 else 1,
		if x.y < edge.y then 0 else 1)
end

const function step(edge: number, x: number): (number)
	return x < edge and 0 or 1
end

const function mod_v3(x: vec3, y: vec3): (vec3)
	return vec3(x.x % y.x, x.y % y.y, x.z % y.z)
end

const function mod_v2(x: vec2, y: vec2): (vec2)
	return vec2(x.x % y.x, x.y % y.y)
end

const function reflect(i: vec3, n: vec3): (vec3)
	return i - 2 * vector.dot(n, i) * n
end

const function exp_v3(v: vec3): (vec3)
	return vec3(math.exp(v.x), math.exp(v.y), math.exp(v.z))
end

const function exp_v2(v: vec2): (vec2)
	return vec2(math.exp(v.x), math.exp(v.y))
end

const function pow_v3(v: vec3, vp: vec3): (vec3)
	return vec3(math.pow(v.x, vp.x), math.pow(v.y, vp.y), math.pow(v.z, vp.z))
end

const function pow_v2(v: vec2, vp: vec2): (vec2)
	return vec2(math.pow(v.x, vp.x), math.pow(v.y, vp.y))
end

return {
	vec2_mat2 = vec2_mat2;
	
	fract = fract;
	smoothstep = smoothstep;
	clamp_v3 = clamp_v3;
	clamp_v2 = clamp_v2;
	sqrt_v = sqrt_v;
	sin_v3 = sin_v3;
	sin_v2 = sin_v2;
	cos_v3 = cos_v3;
	cos_v2 = cos_v2;
	step_v3 = step_v3;
	step_v2 = step_v2;
	step = step;
	mod_v3 = mod_v3;
	mod_v2 = mod_v2;
	reflect = reflect;
	exp_v3 = exp_v3;
	exp_v2 = exp_v2;
	pow_v3 = pow_v3;
	pow_v2 = pow_v2;
}