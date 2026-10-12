
--[=[
	Balatro
	Shader by @stelabouras on https://www.shadertoy.com/view/XXjGDt
	Ported to Luau by @frostxoff (Roblox)
	Modified by @AnotherSubatomo (GitHub)
	For RbxShader v3.0.0
]=]

--!strict
--!optimize 2
--!native

type vec3 = vector
type vec2 = vector

const vec3 = vector.create
const vec2 = vector.create
const length = vector.magnitude

const sin = math.sin
const cos = math.cos
const abs = math.abs
const min = math.min
const max = math.max
const atan2 = math.atan2

const F0 = 0
const F1 = 1
const F2 = 2
const F4 = 4
const F5 = 5
const FP5 = .5
const FP3 = .3
const FP4 = .4
const FP1 = .1
const F30 = 30
const F302P2 = 302.2
const F5P112 = 5.1123314
const FP353 = .353
const FP113 = .113
const FP711 = .711
const VEC3_1 = vector.one

const PIXEL_SIZE_FAC = 10000
const SPIN_EASE = 0.5
const colour_1 = vec3(.85,.2,.2)
const colour_2 = vec3(.0,.611,1)
const colour_3 = vec3(0,0,0)
const spin_amount = 0.7
const contrast = 1.5

local res_scaled: vec2
local res_mag: number
local pixel_size: number
local speed_a: number, speed_b: number, speed_c: number

const SPIN_EASE_20 = SPIN_EASE * 20
const inverse_spin_amount = F1 - spin_amount
const contrast_mod = (.25 * contrast + FP5 * spin_amount + 1.2)
const FP035_contrast_mod = .035 * contrast_mod
const contrast_under_3 = FP3 / contrast
const contrasted_colour_1 = (contrast_under_3) * colour_1
const inverse_contrast_under_3 = (F1 - contrast_under_3)

-- Shader program
return {
	CONFIGURATION = {
		InterlaceFactor = 4;
		ScreenDivision = Vector2.new(4, 2);
	};

	init = function (iResolution: vec2): ()
		res_scaled = FP5 * iResolution
		res_mag = length(iResolution)
		pixel_size = res_mag / PIXEL_SIZE_FAC
	end;

	perFrame = function (iTime: number): ()
		speed_a = (iTime * SPIN_EASE * FP1) + F302P2
		speed_b = iTime * F1
		speed_c = speed_b * .131121
	end;
	
	mainImage = function (fragCoord: vec2): (vec3, number)
		-- Convert to UV coords (0-1) and floor for pixel effect
		local uv = (vector.floor(fragCoord * (F1 / pixel_size))
			* pixel_size - res_scaled) / res_mag
		const uv_len = length(uv)

	    -- Adding in a center swirl, changes with iTime. Only applies meaningfully if the 'spin amount' is a non-F0 number
		const new_pixel_angle = (atan2(uv.y, uv.x)) + speed_a - SPIN_EASE_20 * (spin_amount * uv_len + inverse_spin_amount)
		uv = vec2((uv_len * cos(new_pixel_angle)),
				(uv_len * sin(new_pixel_angle)))

		-- Now add the paint effect to the swirled UV
		uv *= F30
		const uv2_v = uv.x + uv.y
		local uv2 = vec2(uv2_v, uv2_v)

		for i = F0, F5 do
			const uv_cos_mag = cos(length(uv))
			uv2 += vec2(uv.x + uv_cos_mag, uv.y + uv_cos_mag)
			uv += FP5 * vec2(
				cos(F5P112 + FP353 * uv2.y + speed_c),
				sin(uv2.x - FP113 * speed_b))
			
			const uv_x, uv_y = uv.x, uv.y
			const trick = cos(uv_x + uv_y) - sin(uv_x * FP711 - uv_y)
			uv = vec2(uv_x - trick, uv_y - trick)
		end

	    -- Make the paint amount range from 0 - 2
		const paint_res = min(F2, max(F0, length(uv) * FP035_contrast_mod))
		const c1p = max(F0, F1 - contrast_mod * abs(F1 - paint_res))
		const c2p = max(F0, F1 - contrast_mod * abs(paint_res))
		const c3p = F1 - min(F1, c1p + c2p)
		
		local ret_col = contrasted_colour_1 + inverse_contrast_under_3 * (colour_1 * c1p + colour_2 * c2p + colour_3 * c3p)
		const maxA = FP3 * max(c1p * F5 - F4, F0)
		const maxB = FP4 * max(c2p * F5 - F4, F0)
		ret_col += (maxA + maxB) * VEC3_1
		
		return ret_col, 1;
	end;
}