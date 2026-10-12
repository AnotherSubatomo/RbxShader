
--[=[
	BasicVoxelTunnel
	Shader by @Miojo on https://www.shadertoy.com/view/mt2cWm
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
const normalize = vector.normalize
const cross = vector.cross
const sign_v = vector.sign
const abs_v = vector.abs
const dot = vector.dot
const mix = vector.lerp
const sin = math.sin
const cos = math.cos
const max = math.max

const PI = math.pi
const F0 = 0
const FP2 = 0.2
const FP3 = 0.3
const FP5 = 0.5
const F1 = 1
const F2 = 2
const F3 = 3
const VEC3_X = vec3(F1, F0, F0)
const VEC3_Y = vec3(F0, F1, F0)
const VEC3_1 = vec3(F1, F1, F0)
const VEC3_XY = vec3(F1, F1, F1)
const VEC3_YZ = vec3(F0, F1, F1)
const VEC3_0P5 = vec3(FP5, FP5, FP5)

const res = .5      -- voxel size
const max_iter = 80 -- raycast depth
const distFade = 4  -- distance fade
const speed = 2     -- travel speed

-- The white part of the tunnel
const function path1(z: number): (vec3)
	return vec3(
		sin(z * FP2) * F3,
		cos(z * FP3) * F2,
		z
	)
end

-- The yellow part of the tunnel
const function path2(z: number): (vec3)
	return vec3(
		sin(z * FP2),
		cos(z * FP3) * 4 - F1,
		z
	)
end

-- The blue part of the tunnel
const function path3(z: number): (vec3)
	return vec3(
		sin(z * FP3) * F3,
		cos(z * FP2) - F1,
		z
	)
end

local cor: vec3

const function map(p: vec3): (number)
	const p_z = p.z
	const d1 = length(p - path1(p_z))
	const d2 = length(p - path2(p_z))
	const d3 = length(p - path3(p_z))
	
	const s = 1.5
	const ret = s - math.min(d1, d2, d3)
	
	cor = VEC3_X
	if ret == s - d1 then
		cor = VEC3_1
	elseif ret == s - d2 then
		cor = VEC3_XY
	elseif ret == s - d3 then
		cor = VEC3_YZ
	end
	
	return ret
end

const function sqrt_v(v: vector): (vector)
	return vec3(math.sqrt(v.x), math.sqrt(v.y), math.sqrt(v.z))
end

const function smoothstep(edge0: number, edge1: number, x: number): (number)
	const t = math.clamp((x - edge0) / (edge1 - edge0), F0, F1)
	return t * t * (F3 - F2 * t)
end

local resolution: vec2, resolution_y: number
local t: number
local account_mouse: boolean
local cos_ra: number, sin_ra: number
local cos_rb: number, sin_rb: number

-- Shader program
return {
	CONFIGURATION = {
		InterlaceFactor = 2;
		ScreenDivision = Vector2.new(4, 2);
	};

	init = function (iResolution: vec2): ()
		resolution, resolution_y = iResolution, iResolution.y
	end;

	perFrame = function (iTime: number, _, iMouse: vec2): ()
		t = speed * iTime
		account_mouse = length(iMouse) > 40
	
		const mod_mouse = iMouse / resolution * PI
		const ra = -PI * FP5 + mod_mouse.y
		const rb = PI - mod_mouse.x * F2

		cos_ra, sin_ra = cos(ra), sin(ra)
		cos_rb, sin_rb = cos(rb), sin(rb)
	end;

	mainImage = function (fragCoord: vec2): (vec3, number)
		const uv = (fragCoord - FP5 * resolution) / resolution_y
		
		-- path
		const ro = path1(t)
		local rd = path1(t + F1)
		
		-- camera
		const f = normalize(rd - ro)
		local u = VEC3_Y
		const s = normalize(cross(u, f))
		u = normalize(cross(f, s))
		
		rd = normalize(uv.x * s + uv.y * u + f)

		-- mouse
		if account_mouse then
			const rd_y = cos_ra * rd.y + sin_ra * rd.z
			local rd_z = -sin_ra * rd.y + cos_ra * rd.z
			const rd_x = -sin_rb * rd_z + cos_rb * rd.x
			rd_z = cos_rb * rd_z + sin_rb * rd.x
			rd = vec3(rd_x, rd_y, rd_z)
			-- * alternate version of the code above
			--const rd_yz = vec2(cos_ra, -sin_ra) * rd.y + vec2(sin_ra, cos_ra) * rd.z;
			--const rd_zx = vec2(cos_rb, -sin_rb) * rd_yz.y + vec2(sin_rb, cos_rb) * rd.x;
			--rd = vec3(rd_zx.y, rd_yz.x, rd_zx.x)
		end
		
		-- "Digital Differential Analysis" (DDA)
		local mask: vec3, i: number
		
		local grid = ro // res * res
		const dGrid = sign_v(rd) * res
		
		const dCubo = F1 / abs_v(rd)
		const rd_sign = sign_v(rd)
		local cubo = ( rd_sign * (grid - ro)
			+ (rd_sign * FP5 + VEC3_0P5) * res
		) * dCubo
		
		for __ = F1, max_iter do
			i = __
			if map(grid) < F0 then break end
			
			const cubo_x, cubo_y, cubo_z = cubo.x, cubo.y, cubo.z
			const cubo_mask_a = vec3(
				if cubo_y < cubo_x then F0 else F1,
				if cubo_z < cubo_y then F0 else F1,
				if cubo_x < cubo_z then F0 else F1)

			const cubo_mask_b = vec3(
				if cubo_z < cubo_x then F0 else F1,
				if cubo_x < cubo_y then F0 else F1,
				if cubo_y < cubo_z then F0 else F1)

			mask = cubo_mask_a * cubo_mask_b
			
			grid += dGrid * mask
			cubo += dCubo * mask * res
		end
		
		local col = cor
		if i < max_iter then
			const d = dot(cubo - dCubo * res, mask)
			const p = ro + d * rd
			const p_over_res = p / res
			local q = p_over_res - p_over_res // F1 - VEC3_0P5
			
			-- border
			q = abs_v(q)
			const opt0 = dot(vec3( max(q.y, q.z), max(q.z, q.x), max(q.x, q.y)), mask)
			const bd = F1 - smoothstep(.02, F0, .4 - .8 * opt0)
			
			col += mix(cor, cor / F2, bd)
			
			--[[ sweeping line
			const opt1 = cos(t/F2) > uv.x
			col *= if opt1 then F2 else F1
			
			-- dots
			col += VEC3_1 * (if opt1 then -2 else F1 - length(q) * 4)]]
			
			-- distance fade
			col *= distFade / (d * d) - .05
			
			-- lights? shadows? oclusion?
		end
		
		-- gamma correction
		col = sqrt_v(col)
		return col, F1;
	end;
}