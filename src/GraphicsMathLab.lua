
--[=[
	GraphicsMathLab
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

function MathLib.fract ( v : Vector3 )
	return Vector3.new(
		v.X - math.floor(v.X) ,
		v.Y - math.floor(v.Y) ,
		v.Z - math.floor(v.Z)
	)
end

function MathLib.smoothstep ( edge0 : number , edge1 : number , x : number )
	local t = math.clamp((x - edge0) / (edge1 - edge0), 0, 1);
	return t * t * (3 - 2 * t);
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

function MathLib.v3_rgb ( v : Vector3 )
	return v.X, v.Y, v.Z
end

function MathLib.yzx ( v : Vector3 )
	return Vector3.new(v.Y, v.Z, v.X)
end

function MathLib.zxy ( v : Vector3 )
	return Vector3.new(v.Z, v.X, v.Y)
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

-- // Basically lerp
function MathLib.mix ( x : number , y : number , a : number )
	return x + (y - x) * a
end

function MathLib.mix_v3 ( x : Vector3 , y : Vector3 , a : number )
	return x:Lerp(y,a)
end

function MathLib.mix_v2 ( x : Vector2 , y : Vector2 , a : number )
	return x:Lerp(y,a)
end

for operation : string, func : () -> any in math do
	MathLib[operation] = func
end

return MathLib
