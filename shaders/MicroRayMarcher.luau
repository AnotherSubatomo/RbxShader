
--[=[
	MicroRayMarcher
	Shader by @iq on https://www.shadertoy.com/view/DlBcz1
	Ported to Luau — ran by my engine — `RbxShader`.
	
	( Original comments are preserved. )
]=]

--!native

local g = require(game.ReplicatedStorage.RbxShader.GraphicsMathLib)
local vec3 = Vector3.new
local vec2 = Vector2.new

-- // The MIT License
-- // Copyright © 2023 Inigo Quilez
-- // https://www.youtube.com/c/InigoQuilez
-- // https://iquilezles.org/
-- // Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions: The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software. THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.


-- // A raymarching shader using no more than the two input variables
-- // Original was 161 chars long. -1 by SnoopethDuckDuck. -4 chars by Xor.

local FOV = .7;
local NOISINESS = .01;
local CONECTEDNESS = 4;
local BRIGHTNESS = .1;

-- // Pixel shader
return {
	CONFIGURATION = {
		InterlaceFactor = 2 ,
		ScreenDivision = 4
	};
	-- // Image buffer
	mainImage = function (
		fragColor : Vector3 ,
		fragCoords : Vector2 ,
		iTime : number ,
		iTimeDelta : number ,
		iResolution : Vector2 ,
		iMouse : Vector2
	)
		-- Set up camera
		local f = fragCoords / iResolution.Y;
        fragColor = vec3(f.X, f.Y, 1) - Vector3.one * FOV;

        while fragCoords.X > 0 do
			fragCoords = vec2(fragCoords.X - 1, fragCoords.Y);
            -- March forward
			fragColor *= .9 + .1 * g.cos_v3(.7 * fragColor.X * Vector3.one + vec3(fragColor.Z+iTime, fragColor.X, fragColor.Y)).Magnitude + NOISINESS * g.cos(CONECTEDNESS*fragColor.Y);
        end
        -- Final color calculation
        fragColor = (fragColor + Vector3.one * fragColor.Z) * BRIGHTNESS;
		return g.v3_rgb(fragColor);
	end
}