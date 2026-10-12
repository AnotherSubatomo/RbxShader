
--[=[
	KeyboardInput
	An example showing how to use the keyboard input.
	
	Row 0: contain the current state of the 256 keys. 
	Row 1: contains Keypress.
	Row 2: contains a toggle for every key.
	
	Texel positions correspond to ASCII codes. Press WASD keys to test.

	The following GLSL code snippet, which this implementation is based on,
	is a modification of Inigo Quilez's keyboard input example shader from 2013.
	https://www.shadertoy.com/view/lsXGzf

	```glsl
	const int KEY_LEFT  = 37;
	const int KEY_UP    = 38;
	const int KEY_RIGHT = 39;
	const int KEY_DOWN  = 40;

	// colors
	const vec3 va = vec3(1.0, 0.0, 0.0);
	const vec3 vb = vec3(1.0, 1.0, 0.0);
	const vec3 vc = vec3(0.0, 1.0, 0.0);
	const vec3 vd = vec3(0.0, 0.0, 1.0);

	// uv-based positions
	const vec2 uvpa = vec2(-0.75,  0.0);
	const vec2 uvpb = vec2( 0.0 ,  0.5);
	const vec2 uvpc = vec2( 0.75,  0.0);
	const vec2 uvpd = vec2( 0.0 , -0.5);

	const float sa = 1.0, sb = 0.3, sc = 0.31, sd = 0.3, se = 0.7; // state signifier params
	const float ka = 1.0, kb = 0.0, kc = 0.01, kd = 0.35; // keypress signifier params
	const float ta = 1.0, tb = 0.0, tc = 0.01, td = 0.3; // toggle signifier params

	void mainImage( out vec4 fragColor, in vec2 fragCoord )
	{
		vec2 uv = (-iResolution.xy + 2.0*fragCoord) / iResolution.y;

		// uv-adjusted position magnitudes
		float mva = length(uv - uvpa);
		float mvb = length(uv - uvpb);
		float mvc = length(uv - uvpc);
		float mvd = length(uv - uvpd);

		vec3 col = vec3(0.0);

		// state
		col = mix(col, va, 
			(sa - smoothstep(sb, sc, mva)) *
			(sd + se * texelFetch(iChannel0, ivec2(KEY_LEFT, 0), 0).x)
		);
		col = mix(col, vb, 
			(sa - smoothstep(sb, sc, mvb)) *
			(sd + se * texelFetch(iChannel0, ivec2(KEY_UP, 0), 0).x)
		);
		col = mix( col, vc,
			(sa - smoothstep(sb, sc, mvc)) *
			(sd + se * texelFetch(iChannel0, ivec2(KEY_RIGHT, 0), 0).x)
		);
		col = mix( col, vd,
			(sa - smoothstep(sb, sc, mvd)) *
			(sd + se * texelFetch(iChannel0, ivec2(KEY_DOWN, 0), 0).x)
		);


		// keypress
		col = mix(col, va, 
			(ka - smoothstep(kb, kc, abs(mva - kd))) *
			texelFetch(iChannel0, ivec2(KEY_LEFT, 1), 0).x
		);
		col = mix(col, vb,
			(ka - smoothstep(kb, kc, abs(mvb - kd))) *
			texelFetch(iChannel0, ivec2(KEY_UP, 1), 0).x
		);
		col = mix(col, vc,
			(ka - smoothstep(kb, kc, abs(mvc - kd))) *
			texelFetch(iChannel0, ivec2(KEY_RIGHT, 1), 0).x
		);
		col = mix(col, vd,
			(ka - smoothstep(kb, kc, abs(mvd - kd))) *
			texelFetch(iChannel0, ivec2(KEY_DOWN, 1), 0).x
		);

		// toggle
		col = mix(col, va, 
			(ta - smoothstep(tb, tc, abs(mva - td))) *
			texelFetch(iChannel0, ivec2(KEY_LEFT, 2), 0).x
		);
		col = mix(col, vb,
			(ta - smoothstep(tb, tc, abs(mvb - td))) *
			texelFetch(iChannel0, ivec2(KEY_UP, 2), 0).x
		);
		col = mix(col, vc,
			(ta - smoothstep(tb, tc, abs(mvc - td))) *
			texelFetch(iChannel0, ivec2(KEY_RIGHT, 2), 0).x
		);
		col = mix(col, vd,
			(ta - smoothstep(tb, tc, abs(mvd - td))) *
			texelFetch(iChannel0, ivec2(KEY_DOWN, 2), 0).x
		);

		fragColor = vec4(col,1.0);
	}
	```
]=]

--!strict
--!optimize 2
--!native

type Sampler2D = { Buffer: {number}, X: number, Y: number }

type vec3 = vector
type vec2 = vector

const vec3 = vector.create
const vec2 = vector.create
const length = vector.magnitude
const mix = vector.lerp
const abs = math.abs

const function smoothstep(edge0: number, edge1: number, x: number): (number)
	const t = math.clamp((x - edge0) / (edge1 - edge0), 0, 1)
	return t * t * (3 - 2 * t)
end

const function texelFetch_keyboard(SamplerBuffer: {number}, SamplerWidth: number, X: number): (number, number, number)
	const Pixel = SamplerBuffer[X]
	return
		bit32.band(Pixel, 0xFF) / 255,
		bit32.band(bit32.rshift(Pixel, 8), 0xFF) / 255,
		bit32.band(bit32.rshift(Pixel, 16), 0xFF) / 255
end

-- * This is actually WASD instead because my
--   arrow keys don't seem to work properly haha
const KEY_LEFT  = 46;
const KEY_UP    = 68;
const KEY_RIGHT = 49;
const KEY_DOWN  = 64;

-- colors
const va = vec3(1.0, 0.0, 0.0)
const vb = vec3(1.0, 1.0, 0.0)
const vc = vec3(0.0, 1.0, 0.0)
const vd = vec3(0.0, 0.0, 1.0)

-- uv-based positions
const uvpa = vec2(-0.75,  0.0)
const uvpb = vec2( 0.0 ,  0.5)
const uvpc = vec2( 0.75,  0.0)
const uvpd = vec2( 0.0 , -0.5)

const sa, sb, sc, sd, se = 1.0, 0.3, 0.31, 0.3, 0.7; -- state signifier params
const ka, kb, kc, kd = 1.0, 0.0, 0.01, 0.35; -- keypress signifier params
const ta, tb, tc, td = 1.0, 0.0, 0.01, 0.3; -- toggle signifier params

local
	diff_res: vec2, res_y: number,
	left_state: number, left_keypress: number, left_toggle: number,
	up_state: number, up_keypress: number, up_toggle: number,
	right_state: number, right_keypress: number, right_toggle: number,
	down_state: number, down_keypress: number, down_toggle: number

-- Shader program
return {
	CONFIGURATION = {
		InterlaceFactor = 2;
		ScreenDivision = Vector2.new(2, 2);
	};

	CHANNELS = {
		Enum.UserInputType.Keyboard;
	};

	init = function (iResolution: vec2): ()
		diff_res, res_y = -iResolution, iResolution.y
	end;

	perFrame = function (_, _, _, iChannels: {Sampler2D}): ()
		const iChannel0 = iChannels[1]
		const iChannel0_buffer, iChannel0_width = iChannel0.Buffer, iChannel0.X
		
		left_state, left_keypress, left_toggle
			= texelFetch_keyboard(iChannel0_buffer, iChannel0_width, KEY_LEFT)
		up_state, up_keypress, up_toggle
			= texelFetch_keyboard(iChannel0_buffer, iChannel0_width, KEY_UP)
		right_state, right_keypress, right_toggle
			= texelFetch_keyboard(iChannel0_buffer, iChannel0_width, KEY_RIGHT)
		down_state, down_keypress, down_toggle
			= texelFetch_keyboard(iChannel0_buffer, iChannel0_width, KEY_DOWN)
		
		left_state  = sd + se * left_state
		up_state    = sd + se * up_state
		right_state = sd + se * right_state
		down_state  = sd + se * down_state
	end;

	mainImage = function (fragCoord: vec2): (vec3, number)
		const uv = (diff_res + 2.0 * fragCoord) / res_y
		local col = vector.zero

		-- uv-adjusted position magnitudes
		const mva = length(uv - uvpa)
		const mvb = length(uv - uvpb)
		const mvc = length(uv - uvpc)
		const mvd = length(uv - uvpd)

		-- state
		col = mix(col, va, (sa - smoothstep(sb, sc, mva)) * left_state)
		col = mix(col, vb, (sa - smoothstep(sb, sc, mvb)) * up_state)
		col = mix(col, vc, (sa - smoothstep(sb, sc, mvc)) * right_state)
		col = mix(col, vd, (sa - smoothstep(sb, sc, mvd)) * down_state)
		
		-- keypress
		col = mix(col, va, (ka - smoothstep(kb, kc, abs(mva - kd))) * left_keypress)
		col = mix(col, vb, (ka - smoothstep(kb, kc, abs(mvb - kd))) * up_keypress)
		col = mix(col, vc, (ka - smoothstep(kb, kc, abs(mvc - kd))) * right_keypress)
		col = mix(col, vd, (ka - smoothstep(kb, kc, abs(mvd - kd))) * down_keypress)

		-- toggle
		col = mix(col, va, (ta - smoothstep(tb, tc, abs(mva - td))) * left_toggle)
		col = mix(col, vb, (ta - smoothstep(tb, tc, abs(mvb - td))) * up_toggle)
		col = mix(col, vc, (ta - smoothstep(tb, tc, abs(mvc - td))) * right_toggle)
		col = mix(col, vd, (ta - smoothstep(tb, tc, abs(mvd - td))) * down_toggle)

		return col, 1;
	end;
}