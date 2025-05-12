
--[=[
	Vector4
	Partial implementation of the
	`vec4` data type in GLSL.
]=]

--!native

local cos = math.cos
local sin = math.sin

local Vector4 = {}

function Vector4.new(
	x : number , y : number ,
	z : number , w : number
)
	local vec4 = { X = x , Y = y , Z = z , W = w }

	function vec4:Cos()
		return Vector4.new(
			cos(self.X) ,
			cos(self.Y) ,
			cos(self.Z) ,
			cos(self.W)
		)
	end

	function vec4:Sin()
		return Vector4.new(
			sin(self.X) ,
			sin(self.Y) ,
			sin(self.Z) ,
			sin(self.W)
		)
	end

	function vec4:Lerp( b : Vector4 , t : number )
		return Vector4.new(
			self.X + ( b.X - self.X ) * t ,
			self.Y + ( b.Y - self.Y ) * t ,
			self.Z + ( b.Z - self.Z ) * t ,
			self.W + ( b.W - self.W ) * t
		)
	end

	local function IsAVector4( p : {} )
		return type(p) == 'table' and p.X and p.Y and p.Z and p.W
	end

	setmetatable(vec4, {
		__add = function( a , b )
			return Vector4.new(
				a.X + b.X ,
				a.Y + b.Y ,
				a.Z + b.Z ,
				a.W + b.W
			)
		end,

		__sub = function( a , b )
			return Vector4.new(
				a.X - b.X ,
				a.Y - b.Y ,
				a.Z - b.Z ,
				a.W - b.W
			)
		end,

		__mul = function ( a , b )
			if not IsAVector4(a) then
				a, b = b, a
			end

			if IsAVector4(b) then
				return Vector4.new(
					a.X * b.X ,
					a.Y * b.Y ,
					a.Z * b.Z ,
					a.W * b.W
				)
			else
				return Vector4.new(
					a.X * b ,
					a.Y * b ,
					a.Z * b ,
					a.W * b
				)
			end
		end,

		__div = function ( a , b )
			if not IsAVector4(a) then
				a, b = b, a
			end

			if IsAVector4(b) then
				return Vector4.new(
					a.X / b.X ,
					a.Y / b.Y ,
					a.Z / b.Z ,
					a.W / b.W
				)
			else
				return Vector4.new(
					a.X / b ,
					a.Y / b ,
					a.Z / b ,
					a.W / b
				)
			end
		end,
	})

	return vec4
end

setmetatable(Vector4, {
	__index = function( self , index )
		if index == 'one' then
			return Vector4.new(1, 1, 1, 1)
		elseif index == 'zero' then
			return Vector4.new(0, 0, 0, 0)
		end
	end,
})

export type Vector4 = typeof(Vector4)

return Vector4