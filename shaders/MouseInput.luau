
--[=[
	MouseInput
	An example showing how to use the mouse input.
	Shows how to use the mouse input (only left button supported):
	
	     mouse.xy  = mouse position during last button down
	sign(mouse.z)  = clicked when = 1, down when = -1, and 0 when none.
	
	This implementation is based on  Inigo Quilez's mouse input example shader from 2013.
	Check it out here: https://www.shadertoy.com/view/Mss3zH
]=]

--!strict
--!optimize 2
--!native

type vec3 = vector
type vec2 = vector

const vec3 = vector.create
const vec2 = vector.create

const dot = vector.dot
const length = vector.magnitude
const mix = vector.lerp

const SEGMENT_COLOR = vec3(1.0, 1.0, 0.0)
const CIRCLE_COLOR = vec3(1.0, 1.0, 1.0)
const PA_COLOR = vec3(1.0, 0.0, 0.0)
const PB_COLOR = vec3(0.0, 0.0, 1.0)

const P_SIZE = 0.03
const P_SIZE_END = P_SIZE + 0.005
const CIRCLE_SIZE = 0.1
const CIRCLE_SIZE_END = CIRCLE_SIZE + 0.005
const LINE_SIZE = 0.004
const LINE_SIZE_END = LINE_SIZE * 2

const function inv_smoothstep(edge0: number, edge1: number, x: number): (number)
	const t = math.clamp((x - edge0) / (edge1 - edge0), 0, 1)
	return 1 - (t * t * (3 - 2 * t))
end

const function distanceToSegment(a: vec2, b: vec2, p: vec2): (number)
	const pa = p - a
	const ba = b - a
	const h = math.min(1, math.max(dot(pa, ba) / dot(ba, ba), 0))
	return length(pa - ba * h)
end

local m: vec2, m_z: number
local mclick = vector.zero
local cen: vec2, resolution_x: number, resolution_y: number

-- Shader program
return {
	CONFIGURATION = {
		InterlaceFactor = 2;
		ScreenDivision = Vector2.new(4, 2);
	};

	init = function (iResolution: vec2): ()
		resolution_x, resolution_y = iResolution.x, iResolution.y
		cen = vec2(0.5 * resolution_x / resolution_x, 0.5 * resolution_y / resolution_x)
	end;
	
	perFrame = function (_, _, iMouse: vec2): ()
		m = vec2(iMouse.x / resolution_x, iMouse.y / resolution_x)
		m_z = iMouse.z

		if m_z > 0 then
			mclick = m
		end
	end;

	mainImage = function (fragCoord: vec2): (vec3, number)
		const p = fragCoord / resolution_x
		local col = vector.zero

		if m_z < 0 then -- down
			const d = distanceToSegment(m, mclick, p) 
			col = mix(col, SEGMENT_COLOR, inv_smoothstep(LINE_SIZE, LINE_SIZE_END, d))
		end

		if m_z > 0 then -- click
			col = mix(col, CIRCLE_COLOR, inv_smoothstep(CIRCLE_SIZE, CIRCLE_SIZE_END, length(p - cen)))
		end

		col = mix(col, PA_COLOR, inv_smoothstep(P_SIZE, P_SIZE_END, length(p - m     )))
		col = mix(col, PB_COLOR, inv_smoothstep(P_SIZE, P_SIZE_END, length(p - mclick)))

		return col, 1;
	end;
}