
--[=[
	GraphicsMathLib
	Reimplementation of commonly used
	GLSL functions in Luau.
	
	NOTE:
	- Reimplementation is incomplete
	- Do not implement function swizzling
	  just like what GLSL did, as Luau
	  is not powerful enough to do that
]=]

--!native

local MathLib = {}

function MathLib.fract_v3 ( v : Vector3 )
	return Vector3.new(
		v.X - math.floor(v.X) ,
		v.Y - math.floor(v.Y) ,
		v.Z - math.floor(v.Z)
	)
end

function MathLib.fract_v2 ( v : Vector2 )
	return Vector2.new(
		v.X - math.floor(v.X) ,
		v.Y - math.floor(v.Y)
	)
end

function MathLib.fract ( x : number )
	return x - math.floor(x)
end

function MathLib.smoothstep ( edge0 : number , edge1 : number , x : number )
	local t = math.clamp((x - edge0) / (edge1 - edge0), 0, 1);
	return t * t * (3 - 2 * t);
end

function MathLib.clamp_v3 ( v : Vector3 , min : number , max : number )
	return Vector3.new(
		math.clamp(v.X, min, max),
		math.clamp(v.Y, min, max),
		math.clamp(v.Z, min, max)
	)
end

function MathLib.clamp_v2 ( v : Vector2 , min : number , max : number )
	return Vector2.new(
		math.clamp(v.X, min, max),
		math.clamp(v.Y, min, max)
	)
end

function MathLib.sqrt_v3 ( v : Vector3 )
	return Vector3.new(
		math.sqrt(v.X) ,
		math.sqrt(v.Y) ,
		math.sqrt(v.Z)
	)
end

function MathLib.sqrt_v2 ( v : Vector2 )
	return Vector2.new(
		math.sqrt(v.X) ,
		math.sqrt(v.Y)
	)
end

function MathLib.sin_v3 ( v : Vector3 )
	return Vector3.new(
		math.sin(v.X) ,
		math.sin(v.Y) ,
		math.sin(v.Z)
	)
end

function MathLib.sin_v2 ( v : Vector2 )
	return Vector2.new(
		math.sin(v.X) ,
		math.sin(v.Y)
	)
end

function MathLib.cos_v3 ( v : Vector3 )
	return Vector3.new(
		math.cos(v.X) ,
		math.cos(v.Y) ,
		math.cos(v.Z)
	)
end

function MathLib.cos_v2 ( v : Vector2 )
	return Vector2.new(
		math.cos(v.X) ,
		math.cos(v.Y)
	)
end

function MathLib.yzx ( v : Vector3 )
	return Vector3.new(v.Y, v.Z, v.X)
end

function MathLib.zxy ( v : Vector3 )
	return Vector3.new(v.Z, v.X, v.Y)
end

function MathLib.xz ( v : Vector3 )
	return Vector2.new(v.X, v.Z)
end

function MathLib.yx ( v : Vector2 | Vector3 )
	return Vector2.new(v.Y, v.X)
end

function MathLib.step ( edge : number , x : number )
	return x < edge and 0 or 1
end

function MathLib.step_v3 ( edge : Vector3 , x : Vector3 )
	return Vector3.new(
		MathLib.step( edge.X , x.X ) ,
		MathLib.step( edge.Y , x.Y ) ,
		MathLib.step( edge.Z , x.Z )
	)
end

function MathLib.step_v2 ( edge : Vector2 , x : Vector2 )
	return Vector2.new(
		MathLib.step( edge.X , x.X ) ,
		MathLib.step( edge.Y , x.Y )
	)
end

-- // Basically lerp
function MathLib.mix_v3 ( x : Vector3 , y : Vector3 , a : number )
	return x:Lerp(y,a)
end

function MathLib.mix_v2 ( x : Vector2 , y : Vector2 , a : number )
	return x:Lerp(y,a)
end
function MathLib.mix ( x : number , y : number , a : number )
	return x + (y - x) * a
end

function MathLib.mod_v3 ( x : Vector3 , y : Vector3 )
	return Vector3.new(
		x.X % y.X ,
		x.Y % y.Y ,
		x.Z % y.Z
	)
end

function MathLib.mod_v2 ( x : Vector2 , y : Vector2 )
	return Vector2.new(
		x.X % y.X ,
		x.Y % y.Y
	)
end

function MathLib.reflect ( i : Vector3 , n : Vector3 )
	return i - 2 * n:Dot(i) * n
end

function MathLib.exp_v3 ( v : Vector3 )
	return Vector3.new(
		math.exp(v.X) ,
		math.exp(v.Y) ,
		math.exp(v.Z)
	)
end

function MathLib.exp_v2 ( v : Vector2 )
	return Vector2.new(
		math.exp(v.X) ,
		math.exp(v.Y)
	)
end

function MathLib.pow_v3 ( v : Vector3 , vp : Vector3 )
	return Vector3.new(
		math.pow(v.X, vp.X) ,
		math.pow(v.Y, vp.Y) ,
		math.pow(v.Z, vp.Z)
	)
end

function MathLib.pow_v2 ( v : Vector2 , vp : Vector3 )
	return Vector2.new(
		math.pow(v.X, vp.X) ,
		math.pow(v.Y, vp.Y)
	)
end

--[=[=======================
	/* NON-GLSL FUNCTIONS */
--========================]=]
function MathLib.v3_rgb ( v : Vector3 )
	return v.X, v.Y, v.Z
end

function MathLib.c3_rgb ( c : Color3 )
	return c.R, c.G, c.B
end

function MathLib.v3_rgba ( v : Vector3 , alpha : number? )
	return v.X, v.Y, v.Z, alpha
end

function MathLib.c3_rgba ( c : Color3 , alpha : number? )
	return c.R, c.G, c.B, alpha
end

function MathLib.c3 ( a : Color3 | Vector3 )
	return typeof(a) == 'Color3' and a or Color3.new( a.X, a.Y, a.Z )
end

for operation : string, func : () -> any in math do
	MathLib[operation] = func
end

MathLib.Vector4 = require(script.Parent.Vector4)

return MathLib