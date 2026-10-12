
--[=[
	Cosmic
	Shader by @Xor on https://www.shadertoy.com/view/msjXRK
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
const length = vector.magnitude

const R0_C1 = vec2(1, 2)
const R0_C2 = vec2(-1, 2)
const ITER = 3e1

const SINE_TIME_CACHE = table.create(ITER, 0)

--[[
/*
    "Cosmic" by @XorDev
    
    I love making these glowy shaders. This time I thought I'd try using discs instead.

    Tweet: twitter.com/XorDev/status/1601060422819680256
    Twigl: t.co/IhRk3HX4Kt
    
    <300 chars playlist: shadertoy.com/playlist/fXlGDN
*/
]]

local r: vec2

-- Shader program
return {
	CONFIGURATION = {
		InterlaceFactor = 2;
		ScreenDivision = Vector2.new(4, 2);
	};

	init = function (iResolution: vec2): ()
		-- Initialize resolution for scaling
		r = iResolution
	end;

	perFrame = function (iTime: number): ()
		for i = 1, ITER do
			const ii = i * i
			SINE_TIME_CACHE[i] = iTime * math.sin(ii) + ii
		end
	end;
	
	mainImage = function (fragCoord: vec2): (vec3, number)
		-- Clear fragcolor (hacky)
		local col_x = 0;
		local col_y = 0;
		local col_z = 0;
		-- Save centered pixel coordinates
		local p = (fragCoord - r * .6);
		p = R0_C1 * p.x + R0_C2 * p.y;
		
		-- Initialize loop iterator and arc angle
		fragCoord = p / (r + r - p).y;
		const atan2_fragCoord = math.atan2(fragCoord.y, fragCoord.x);
		const fragCoord_len_8e1 = length(fragCoord) * 8e1;
		const opt0 = 4e1 / r.y
		-- Loop 30 times
		for i = 1, ITER do
			-- Add with ring attenuation
			const a = atan2_fragCoord * math.ceil(i * .1) + SINE_TIME_CACHE[i];
			const a_i = a - i;
			const ring = .2 / (math.abs(fragCoord_len_8e1 - i) + opt0)
			-- Limit to arcs
			const arc = math.clamp(math.cos(a), .0, .6)
			-- Give them color
			col_x += ring * arc * (math.cos(a_i + 0) + 1)
			col_y += ring * arc * (math.cos(a_i + 1) + 1)
			col_z += ring * arc * (math.cos(a_i + 2) + 1)
		end

		return vec3(col_x, col_y, col_z), 1;
	end;
}