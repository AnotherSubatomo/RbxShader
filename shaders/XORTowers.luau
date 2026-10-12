
--[=[
	XORTowers
	Shader by @GregRostami found on his literal user description
	Ported to Luau — ran by my engine — `RbxShader`.

	Here's the entire shader, ungolfed:
	```glsl
	void mainImage(out vec4 fragColor, in vec2 fragCoord) {
		float t = 0.0;
		ivec3 b = ivec3(0);

		vec2 timeOffset = iTime * vec2(1.0, 4.0);
		vec2 base = 5.0 * (fragCoord / iResolution.y - 0.7);

		while ( ((b.x ^ b.y ^ b.z) % 99) > (b.z - 5) ) {
			t += 0.1;

			vec2 p = timeOffset + base * t;

			b.x = int(p.x);
			b.y = int(p.y);
			b.z = int(t);
		}

		fragColor = vec4(t) / 74.0;
	}
	```
]=]

--!strict
--!optimize 2
--!native

type vec3 = vector
type vec2 = vector

const vec3 = vector.create

local time_offset_x: number, time_offset_y: number
local resolution_y: number

-- Shader program
return {
	CONFIGURATION = {
		InterlaceFactor = 2;
		ScreenDivision = Vector2.new(4, 2);
	};

	init = function (iResolution: vec2): ()
		resolution_y = iResolution.y
	end;
	
	perFrame = function (iTime: number): ()
		time_offset_x = 1.0 * iTime
		time_offset_y = 4.0 * iTime
	end;

	mainImage = function (fragCoord: vec2): (vec3, number)
		local t = 0
		local b_x = 0
		local b_y = 0
		local b_z = 0

		const base_x = 5.0 * (fragCoord.x / resolution_y - 0.7)
		const base_y = 5.0 * (fragCoord.y / resolution_y - 0.7)

		while (bit32.bxor(b_x, b_y, b_z) % 99) > (b_z - 5) do
			t += 0.1

			const p_x = time_offset_x + base_x * t
			const p_y = time_offset_y + base_y * t

			b_x = (p_x) // 1
			b_y = (p_y) // 1
			b_z = (t) // 1
		end

		t /= 74.0
		return vec3(t, t, t), 1;
	end;
}