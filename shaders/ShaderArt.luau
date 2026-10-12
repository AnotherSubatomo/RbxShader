
--[=[
	ShaderArt
	Shader by @kishimisu on https://www.shadertoy.com/view/mtyGWy
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
const VEC2_0P5 = vec2(0.5, 0.5)

const function cos_v(v: vector): (vector)
	return vec3(math.cos(v.x), math.cos(v.y), math.cos(v.z))
end

--[=[
	This animation is the material of my first youtube tutorial about creative 
   coding, which is a video in which I try to introduce programmers to GLSL 
   and to the wonderful world of shaders, while also trying to share my recent 
   passion for this community.			Video URL: https://youtu.be/f4s1h2YETNY
]=]

-- https://iquilezles.org/articles/palettes/
const VEC3_0P5 = vec3(0.5, 0.5, 0.5)
const D = vec3(0.263, 0.416, 0.557)

const function palette (t: number): (vec3)
	return VEC3_0P5 + VEC3_0P5 * cos_v(6.28318*(vector.one*t+D))
end

-- Shader program
return {
	CONFIGURATION = {
		InterlaceFactor = 2;
		ScreenDivision = Vector2.new(4, 2);
	};
	
	mainImage = function (fragCoord: vec2, iResolution: vec2, iTime: number): (vec3, number)
		local uv = (fragCoord * 2 - iResolution) / iResolution.y
		const uv_mag = vector.magnitude(uv)
		const uv_mag_nexp = math.exp(-uv_mag)
		const uv_mag_add_time0P4 = uv_mag + iTime * 0.4
		local finalColor = vector.zero
		
		for i = 0, 3 do
			uv *= 1.5
			uv = (uv - uv // 1) - VEC2_0P5
			
			local d = vector.magnitude(uv) * uv_mag_nexp
			const col = palette(uv_mag_add_time0P4 + i * 0.4)
			
			d = math.sin(d * 8 + iTime) / 8
			d = math.abs(d)
			
			d = math.pow(0.01 / d, 1.2)
			
			finalColor += col * d
		end
		
		return finalColor, 1;
	end;
}