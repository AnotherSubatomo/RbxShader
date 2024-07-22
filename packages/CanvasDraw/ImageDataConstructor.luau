local Module = {}

local function Lerp(A, B, T)
	return A + (B - A) * T
end

local function deepCopy(original)
	local copy = {}
	for k, v in pairs(original) do
		if type(v) == "table" then
			v = deepCopy(v)
		end
		copy[k] = v
	end
	return copy
end

local function deepFreeze(tbl)
	table.freeze(tbl)
	for _, v in pairs(tbl) do
		if type(v) == "table" then
			deepFreeze(v)
		end
	end
end

function Module.new(ImageDataResX, ImageDataResY, PixelArray)
	local ImageData = {
		ImagePixels = PixelArray, 
		ImageResolution = Vector2.new(ImageDataResX, ImageDataResY),
		Width = ImageDataResX,
		Height = ImageDataResY,
	}

	local function GetIndex(X, Y)
		return (X + (Y - 1) * ImageDataResX) * 4 - 3
	end

	--== ImageData methods ==--

	function ImageData:GetPixel(Point: Vector2): (Color3, number)
		local X, Y = math.floor(Point.X), math.floor(Point.Y)
		local Array = self.ImagePixels
		local Index = GetIndex(X, Y)

		return Color3.new(Array[Index], Array[Index + 1], Array[Index + 2]), Array[Index + 3]
	end

	function ImageData:GetPixelXY(X: number, Y: number): (Color3, number)
		local Array = self.ImagePixels
		local Index = GetIndex(X, Y)

		return Color3.new(Array[Index], Array[Index + 1], Array[Index + 2]), Array[Index + 3]
	end

	function ImageData:GetRGB(X: number, Y: number): (number, number, number)
		local Array = self.ImagePixels
		local Index = GetIndex(X, Y)

		return Array[Index], Array[Index + 1], Array[Index + 2]
	end
	
	function ImageData:GetRGBA(X: number, Y: number): (number, number, number)
		local Array = self.ImagePixels
		local Index = GetIndex(X, Y)

		return Array[Index], Array[Index + 1], Array[Index + 2], Array[Index + 3]
	end

	function ImageData:GetAlpha(X: number, Y: number): number
		return self.ImagePixels[GetIndex(X, Y) + 3]
	end

	function ImageData:Tint(Colour: Color3, T: number)
		local Array = self.ImagePixels

		for X = 1, ImageDataResX do
			for Y = 1, ImageDataResY do
				local Index = GetIndex(X, Y)

				Array[Index] = Lerp(Array[Index], Colour.R, T)
				Array[Index + 1] = Lerp(Array[Index + 1], Colour.G, T)
				Array[Index + 2] = Lerp(Array[Index + 2], Colour.B, T)
			end
		end
	end

	function ImageData:TintRGB(R: number, G: number, B: number, T: number)
		local Array = self.ImagePixels

		for X = 1, ImageDataResX do
			for Y = 1, ImageDataResY do
				local Index = GetIndex(X, Y)

				Array[Index] = Lerp(Array[Index], R, T)
				Array[Index + 1] = Lerp(Array[Index + 1], G, T)
				Array[Index + 2] = Lerp(Array[Index + 2], B, T)
			end
		end
	end

	function ImageData:SetPixel(X: number, Y: number, Colour: Color3, Alpha: number?)
		local Array = self.ImagePixels
		local Index = GetIndex(X, Y)

		Array[Index] = Colour.R
		Array[Index + 1] = Colour.G
		Array[Index + 2] = Colour.B
		Array[Index + 3] = Alpha or 1
	end

	function ImageData:SetRGB(X: number, Y: number, R: number, G: number, B: number)
		local Array = self.ImagePixels
		local Index = GetIndex(X, Y)

		Array[Index] = R
		Array[Index + 1] = G
		Array[Index + 2] = B
	end
	
	function ImageData:SetRGBA(X: number, Y: number, R: number, G: number, B: number, A: number)
		local Array = self.ImagePixels
		local Index = GetIndex(X, Y)

		Array[Index] = R
		Array[Index + 1] = G
		Array[Index + 2] = B
		Array[Index + 3] = A
	end

	function ImageData:SetAlpha(X: number, Y: number, Alpha: number)
		self.ImagePixels[GetIndex(X, Y) + 3] = Alpha
	end

	function ImageData:Clone()
		return deepCopy(ImageData)
	end
	
	function ImageData:Freeze()
		deepFreeze(ImageData)
	end

	return ImageData
end

return Module