
--[=[
	ShootingStars
	Shader by @Xor on https://www.shadertoy.com/view/ctXGRn
	Ported to Luau — ran by my engine — `RbxShader`.
	
	( Original comments are preserved. )
	 * Modified to be more performant natively
]=]

--!strict
--!optimize 2
--!native

type vec3 = vector
type vec2 = vector

const vec3 = vector.create
const vec2 = vector.create
const cos = math.cos

const VEC3_1 = vector.one
const VEC2_1 = vector.one
const VEC2_BOX = vec2(.0, .22)
const VEC2_P5 = vec2(.5, .5)
const COLOR = vec3(0, 1, 2)

const ITER = 10
const R_R1Cache, R_R2Cache = {}, {}

for i = 0.9, ITER, 1 do
	R_R1Cache[i] = vec2(cos(i), cos(i+33))
	R_R2Cache[i] = vec2(cos(i+11), cos(i))
end

const function cos_v(v: vec3): (vec3)
	return vec3(math.cos(v.x), math.cos(v.y), math.cos(v.z))
end

--[[
/*
    "Shooting Stars" by @XorDev

    I got hit with inspiration for the concept of shooting stars.
    This is what I came up with.
    
    Tweet: twitter.com/XorDev/status/1604218610737680385
    Twigl: t.co/i7nkUWIpD8
    <300 chars playlist: shadertoy.com/playlist/fXlGDN
*/
]]

-- Shader program
return {
	CONFIGURATION = {
		InterlaceFactor = 2;
		ScreenDivision = Vector2.new(4, 2);
	};
	
	mainImage = function (I: vec2, iResolution: vec2, iTime: number): (vec3, number)
		--Clear fragcolor
		local O = vector.zero
		--Line dimensions (box) and position relative to line
		local b, p = VEC2_BOX, vector.zero
		--Rotation matrix
		local R_R1, R_R2
		--Iterate 20 times
		const v01 = I / iResolution.y * .2 -- @optimization @temp
		const v02 = VEC2_1 * iTime * b -- @optimization @temp
		for i = 0.9, ITER do
			--Rotate for each iteration
			R_R1 = R_R1Cache[i]
			R_R2 = R_R2Cache[i]
			--Using rotated boxes
			const v1 = (v01 * i + v02) -- @temp;
			const v2 = (R_R2 * v1.x) + (R_R1 * v1.y) -- @temp;
			const v3 = (v2 - v2 // 1) - VEC2_P5 -- @temp;
			p = (R_R2 * v3.x) + (R_R1 * v3.y)
			--Add attenuation
			const glow = 1e-3 / vector.magnitude(vector.min(b, vector.max(-b, p)) - p)
			--My favorite color palette
			O += glow * (cos_v((VEC3_1 * p.y / .1) + COLOR) + VEC3_1)
		end
			
		return O, 1;
	end;
}