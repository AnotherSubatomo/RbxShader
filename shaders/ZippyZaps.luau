
--[=[
	ZippyZaps
	Shader by @SnoopethDuckDuck on https://www.shadertoy.com/view/XXyGzh
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
const pow = math.pow
const cos = math.cos

const VEC3_1 = vector.one
const VEC2_1 = vec2(1, 1)
const VEC3_COLOR = vec3(1, 2, 3)

const function tanh_v(v: vec2): (vec2)
	return vec2(math.tanh(v.x), math.tanh(v.y), math.tanh(v.z))
end

const function yx(v: vec2): (vec2)
	return vec2(v.y, v.x)
end

const function cos_v(v: vector): (vector)
	return vec3(math.cos(v.x), math.cos(v.y), math.cos(v.z))
end

const function sin_v(v: vector): (vector)
	return vec3(math.sin(v.x), math.sin(v.y), math.sin(v.z))
end

-- Shader program
return {
	CONFIGURATION = {
		InterlaceFactor = 2;
		ScreenDivision = Vector2.new(4, 2);
	};
	
	-- -13 thanks to Nguyen2007 ⚡
	mainImage = function (u: vec2, v: vec2, iTime: number): (vec3, number)
		u = .2*(u+u-v)/v.y;

		local o = VEC3_COLOR;
		const z = o;
		
		local a = .5;
		local t = iTime;
		local i = 0.0;

		while true do
			i += 1
			if i >= 19 then break end
			o += (VEC3_1 + cos_v(z+VEC3_1*t)) / vector.magnitude(
				(1+i*dot(v, v)) *
				sin_v(1.5*u/(.5-dot(u, u)) - 9*yx(u) + VEC2_1*t)
			)
			
			t += 1
			a += .03
			v = cos_v(VEC2_1*t - 7*u*pow(a, i)) - 5*u

			const r1 = i + 0.02 * t
			const r2 = cos(r1)
			u = vec2(
				(r2 * u.x) + (cos(r1 - 11) * u.y),
				(cos(r1 - 33) * u.x) + (r2 * u.y)
			)
			-- use stanh here if shader has black artifacts
			--  vvvv
			u += tanh_v(40 * dot(u, u) * cos_v(1e2*yx(u)+VEC2_1*t)) / 2e2
			+ .2 * a * u
			+ VEC2_1*(cos(4/math.exp(dot(o, o)/1e2) + t) / 3e2)
		end

		o = 25.6 / (vector.min(o, VEC3_1*13) + VEC3_1*164 / o) - VEC3_1*dot(u, u) / 250;

		return o, 1;
	end;
}