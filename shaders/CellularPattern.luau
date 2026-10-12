
--[=[
	Cellular Pattern
	The following GLSL code snippet, which this implementation is based on,
	is a modification of @Shane's shader: https://www.shadertoy.com/view/MdKXDD

	```glsl
	const mat2 M = mat2(7, -5, 5, 7)*.1;
	const float E = 0.8653;
	const float R = 61.65;

	void mainImage(out vec4 o, vec2 p){
		p = p/R + iTime;
		
		p *= M;
		float a = length(fract(p) - .5);
		p *= M;
		float b = length(fract(p) - .5);
		p *= M;
		float c = length(fract(p) - .5);
		
		o = o - o + min(min(a, b), c)/E;
	}
	```

	Ported to Luau — ran by my engine — `RbxShader`.
]=]

--!strict
--!optimize 2
--!native

type vec3 = vector;
type vec2 = vector;

const Me0, Me1, Me2, Me3 = 0.7, -0.5, 0.5, 0.7;
const E = 0.8653;
const R = 61.65;

const function warp(x: number, y: number): (number, number)
	return Me0*x + Me1*y, Me2*x + Me3*y
end

const function cellDist(x: number, y: number): (number)
	x -= x // 1 + 0.5
	y -= y // 1 + 0.5
	return math.sqrt(x*x + y*y)
end

local time_vec: vec2

-- Shader program
return {
	CONFIGURATION = {
		InterlaceFactor = 2;
		ScreenDivision = Vector2.new(2, 2);
	};
	
	perFrame = function (iTime: number): ()
		time_vec =  vector.create(iTime, iTime);
	end;

	mainImage = function (p: vec2): (vec3, number)
		p = p/R + time_vec;
		local px, py = p.x, p.y;
		
		px, py = warp(px, py);
		const a = cellDist(px, py);
		px, py = warp(px, py);
		const b = cellDist(px, py);
		px, py = warp(px, py);
		const c = cellDist(px, py);
		
		const u = math.min(a, b, c)/E;
		return vector.create(u, u, u), 1.0;
	end;
}