
--[=[
	GraphicsMathLab
	Reimplementation of commonly used
	GLSL functions in Luau.
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

for operation : string, func : () -> any in math do
	MathLib[operation] = func
end

return MathLib
