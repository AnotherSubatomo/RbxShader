
--[=[
	Canvas
	A simple EditableImage interface specifically built for RbxShader.
	
	NOTE:
	* vector RGB values are normalized (between 0 and 1)
]=]

--!strict
--!optimize 2
--!native

const writeu8 = buffer.writeu8
const VEC3_0 = vector.zero
const VEC3_1 = vector.one

export type Canvas = {
	Resolution: Vector2,
	Canvas: EditableImage,
	ImageBuffer: buffer,
	VirtualTexelMapArray: {vector}
}

export type vec3 = vector
export type vec2 = vector

-- Creates a new canvas context.
const function New(Patch: EditableImage): (Canvas)
	const Resolution = Patch.Size
	const PixelCount = Resolution.X * Resolution.Y
	const ImageBuffer = buffer.create(PixelCount * 4)
	const VirtualTexelMapArray = table.create(PixelCount, VEC3_0)

	return {
		Resolution = Resolution,
		Canvas = Patch,
		ImageBuffer = ImageBuffer,
		VirtualTexelMapArray = VirtualTexelMapArray
	-- ^^^ 'VTM' stands for 'virtual texel mapping'
	}
end

-- Sets the given texel's color components to the given color components, given a texel index.
const function SetRGBA(self: Canvas, TexelIndex: number, RGB: vec3, A: number?): ()
	const ImgBuffIndex = (TexelIndex - 1) * 4
	const ImgBuff = self.ImageBuffer

	const u8_RGB = vector.min(VEC3_1, vector.max(RGB, VEC3_0)) * 255
	const u8_RGB_w = if A then math.min(1, math.max(A, 0)) * 255 else 255

	writeu8(ImgBuff, ImgBuffIndex, u8_RGB.x)
	writeu8(ImgBuff, ImgBuffIndex + 1, u8_RGB.y)
	writeu8(ImgBuff, ImgBuffIndex + 2, u8_RGB.z)
	writeu8(ImgBuff, ImgBuffIndex + 3, u8_RGB_w)
end

-- Recalculates the virtual texel cache.
const function RecalculateVirtualTexelMapping(
	self: Canvas,
	VirtualOrigin: Vector2, --> in pixels
	RelativeOffset: Vector2, --> in pixels
	CountDirection: Vector2 --> sign vector
): ()
	const SaneVirtualOrigin_X = VirtualOrigin.X // 1
	const SaneVirtualOrigin_Y = VirtualOrigin.Y // 1

	-- pre-subtract by 0.5 as `fragCoords` are half-integers
	const SaneRelativeOffset_X = RelativeOffset.X // 1 - 0.5
	const SaneRelativeOffset_Y = RelativeOffset.Y // 1 - 0.5

	const SaneCountDirection_X = math.sign(CountDirection.X)
	const SaneCountDirection_Y = math.sign(CountDirection.Y)

	const Resolution = self.Resolution
	const VTMArray = self.VirtualTexelMapArray

	const Start_Y = ((1 + SaneRelativeOffset_Y) * SaneCountDirection_Y)  + SaneVirtualOrigin_Y
	const End_Y = ((Resolution.Y + SaneRelativeOffset_Y) * SaneCountDirection_Y)  + SaneVirtualOrigin_Y
	const Start_X = ((1 + SaneRelativeOffset_X) * SaneCountDirection_X)  + SaneVirtualOrigin_X
	const End_X = ((Resolution.X + SaneRelativeOffset_X) * SaneCountDirection_X)  + SaneVirtualOrigin_X

	local Index = 1
	for Y = Start_Y, End_Y, SaneCountDirection_Y do
		for X = Start_X, End_X, SaneCountDirection_X do
			VTMArray[Index] = vector.create(X, Y)
			Index += 1
		end
	end
end

-- Writes the current state of the image buffer onto the actual canvas.
const function Render(self: Canvas): ()
	const Canvas = self.Canvas
	Canvas:WritePixelsBuffer(Vector2.zero, Canvas.Size, self.ImageBuffer)
end

return {
	new = New,
	setRGBA = SetRGBA,
	recalculateVirtualTexelMapping = RecalculateVirtualTexelMapping,
	render = Render,
}