
--[=[
	Plasma
	Shader by @Xor on https://www.shadertoy.com/view/WfS3Dd
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

const VEC2_4 = vec2(4, 4)
const VEC2_0P7 = vec2(0.7, 0.7)
const COLOR_R, COLOR_G, COLOR_B = -1, 1, 2

--[[
/*
    "Plasma" by @XorDev
    
    X Post:
    x.com/XorDev/status/1894123951401378051
    
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
		-- Resolution for scaling
		r = iResolution
	end;
	
	mainImage = function (I: vec2, _, iTime: number): (vec3, number)
		-- Clear frag color
		local O_x, O_y, O_z, O_w = 0, 0, 0, 0
		-- Centered, ratio corrected, coordinates
		const p = (I+I-r) / r.y
		-- Z depth
		const z = VEC2_4
		-- Fluid coordinates
		local f = p*(z-VEC2_4*math.abs(.7-vector.dot(p, p)));
		
		-- loop 8 times
		for i_y = 1, 8 do
			const f_x, f_y = f.x, f.y --@temp;
			const s_x = math.sin(f_x)+1 --@temp; not in source code
			const s_y = math.sin(f_y)+1 --@temp;
			-- Set color waves and line brightness
			const f_absd = math.abs(f_x-f_y) --@temp;
			O_x += s_x * f_absd
			O_y += s_y * f_absd
			O_z += s_y * f_absd
			O_w += s_x * f_absd
			-- Add fluid waves
			f += vec2(
				math.cos(f_y * i_y + iTime),
				math.cos(f_x * i_y + i_y + iTime)
			) / i_y + VEC2_0P7
		end
		
		-- Tonemap, fade edges and color gradient
		const z_x_M4 = z.x-4.
		const p_y = p.y
		O_x = math.tanh(7. * math.exp(z_x_M4-p_y*COLOR_R) / O_x)
		O_y = math.tanh(7. * math.exp(z_x_M4-p_y*COLOR_G) / O_y)
		O_z = math.tanh(7. * math.exp(z_x_M4-p_y*COLOR_B) / O_z)
		O_w = math.tanh(7. * math.exp(z_x_M4) / O_w)

		return vec3(O_x, O_y, O_z), O_w;
	end;
}