
--[=[
	MicroRayMarcher
	Shader by @iq on https://www.shadertoy.com/view/DlBcz1
	Ported to Luau — ran by my engine — `RbxShader`.
	
	( Original comments are preserved. )
]=]

--!strict
--!optimize 2
--!native

type vec3 = vector
type vec2 = vector

const vec3 = vector.create
const length = vector.magnitude
const cos = math.cos
const VEC3_1 = vector.one

-- The MIT License
-- Copyright © 2023 Inigo Quilez
-- https://www.youtube.com/c/InigoQuilez
-- https://iquilezles.org/
-- Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions: The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software. THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.


-- A raymarching shader using no more than the two input variables
-- Original was 161 chars long. -1 by SnoopethDuckDuck. -4 chars by Xor.

const FOV = .7;
const NOISINESS = .01;
const CONECTEDNESS = 4;
const BRIGHTNESS = .1;

local res_y: number

-- Shader program
return {
	CONFIGURATION = {
		InterlaceFactor = 2;
		ScreenDivision = Vector2.new(4, 2);
	};

	init = function (iResolution: vec2): ()
		res_y = iResolution.y
	end;

	mainImage = function (fragCoord: vec2, _, iTime: number): (vec3, number)
		-- Set up camera
		const f = fragCoord / res_y;
		local fragColor = vec3(f.x - FOV, f.y - FOV, 1 - FOV);

		local fragCoord_x = fragCoord.x
		while fragCoord_x > 0 do
			fragCoord_x -= 1;
			-- March forward
			const fragColor_x, fragColor_y = fragColor.x, fragColor.y
			const opt0 = .7 * fragColor_x
			fragColor *= .9 + .1 * length(
					vec3(
						cos(fragColor.z + iTime + opt0),
						cos(fragColor_x + opt0),
						cos(fragColor_y + opt0)
					)
			) + NOISINESS * cos(CONECTEDNESS * fragColor_y);
		end
		-- Final color calculation
		fragColor = (fragColor + VEC3_1 * fragColor.z) * BRIGHTNESS;
		return fragColor, 1;
	end;
}