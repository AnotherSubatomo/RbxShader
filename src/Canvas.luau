
--[=[
	Canvas
	A simple EditableImage interface that mimics
	CanvasDraw's API design. Specifically built for RbxShader.
	
	NOTE:
	* RGBA values are normalized (between 0 and 1)
]=]

--!native

local Asset = game:GetService('AssetService')

local Resampler = Enum.ResamplerMode
local writeu8 = buffer.writeu8
local readu8 = buffer.readu8
local writeu16 = buffer.writeu16
local readu16 = buffer.readu16
-- * denormalizes a normalized number
local uint8 = function(n: number) : number
	return math.clamp(math.ceil(n * 255), 0, 255)
end

local Canvas = {}
Canvas.__index = Canvas

type Parent = GuiObject | Decal | Texture | SurfaceAppearance | MeshPart
export type Canvas = typeof(Canvas) & {
	Resolution: Vector2 ,
	__Easel: ImageLabel ,
	__Canvas: EditableImage ,
	__ImageBuffer: buffer ,
	__VPMBuffer: buffer
}

function Canvas.new(Parent: Parent, Resolution: Vector2, Blur: boolean?): (Canvas)
	Blur = Blur or false

	-- Build the necessary objects
	local Easel = Instance.new("ImageLabel")
	Easel.Name = "FastCanvas"
	Easel.BackgroundTransparency = 1
	Easel.ClipsDescendants = true
	Easel.Size = UDim2.fromScale(1, 1)
	Easel.Position = UDim2.fromScale(0.5, 0.5)
	Easel.AnchorPoint = Vector2.new(0.5, 0.5)
	Easel.ResampleMode = not Blur and Resampler.Pixelated or Resampler.Default
	Easel.Parent = Parent

	local AspectRatio = Instance.new("UIAspectRatioConstraint")
	AspectRatio.AspectRatio = Resolution.X / Resolution.Y
	AspectRatio.Parent = Easel
	
	local InternalCanvas = Asset:CreateEditableImage({ Size = Resolution })
	Easel.ImageContent = Content.fromObject(InternalCanvas)

	-- Build the 'Canvas' object
	local self = setmetatable({}, Canvas)
	self.Resolution = Resolution
	self.__Easel = Easel
	self.__Canvas = InternalCanvas
	self.__ImageBuffer = buffer.create(Resolution.X * Resolution.Y * 4)
	self.__VPMBuffer = buffer.create(Resolution.X * Resolution.Y * 4)
	-- ^^^ 'VPM' stands for 'virtual pixel mapping'
	-- * pure coincidence that the size of both buffers are the same
	
	return self
end

function Canvas:__GetIndex(X: number, Y: number): (number)
	return (Y - 1) * (self.Resolution.X * 4) + (X - 1) * 4
end

function Canvas:SetRGBA(X: number, Y: number, R: number, G: number, B: number, A: number): ()
	local Index = self:__GetIndex(X, Y)
	local ImgBuff = self.__ImageBuffer
	writeu8(ImgBuff, Index, uint8(R))
	writeu8(ImgBuff, Index + 1, uint8(G))
	writeu8(ImgBuff, Index + 2, uint8(B))
	writeu8(ImgBuff, Index + 3, uint8(A or 1))
	return nil
end

function Canvas:GetRGB(X: number, Y: number): (number, number, number)
	local Index = self:__GetIndex(X, Y)
	local ImgBuff = self.__ImageBuffer
	return readu8(ImgBuff, Index) / 255,
		readu8(ImgBuff, Index + 1) / 255,
		readu8(ImgBuff, Index + 2) / 255
end

function Canvas:Fill(Color: Color3?, Alpha: number?): ()
	Color = Color or Color3.new(1, 1, 1)
	Alpha = Alpha or 1
	
	for X = 1, self.Resolution.X do
		for Y = 1, self.Resolution.Y do
			self:SetRGBA(X, Y, Color.R, Color.G, Color.B, Alpha)
		end
	end
end

function Canvas:RecalculateVirtualPixelMapping(
	VirtualOrigin: Vector2 , --> in pixels
	RelativeOffset: Vector2 , --> in pixels
	CountDirection: Vector2 --> sign vector
): ()
	VirtualOrigin = VirtualOrigin:Floor()
	RelativeOffset = RelativeOffset:Floor()
	CountDirection = CountDirection:Sign()
	
	-- CountDirection sanitization
	if CountDirection.X == 0 then CountDirection += Vector2.xAxis end
	if CountDirection.Y == 0 then CountDirection += Vector2.yAxis end
	local VPMBuff = self.__VPMBuffer

	for X = 1, self.Resolution.X do
		for Y = 1, self.Resolution.Y do
			local Index = self:__GetIndex(X, Y)
			writeu16(VPMBuff, Index, VirtualOrigin.X + CountDirection.X * (X + RelativeOffset.X))
			writeu16(VPMBuff, Index + 2, VirtualOrigin.Y + CountDirection.Y * (Y + RelativeOffset.Y))
		end
	end
end

function Canvas:GetVirtualPosition(X: number, Y: number): (number, number)
	local Index = self:__GetIndex(X, Y)
	local VPMBuff = self.__VPMBuffer
	return readu16(VPMBuff, Index),
		readu16(VPMBuff, Index + 2)
end

function Canvas:Render(): ()
	local Canvas : EditableImage = self.__Canvas
	Canvas:WritePixelsBuffer(Vector2.zero, Canvas.Size, self.__ImageBuffer)
	return nil
end

function Canvas:Destroy(): ()
	self.__Canvas:Destroy()
	self.__Easel:Destroy()
	setmetatable(self, nil)
	table.clear(self)
	self = nil
	return nil
end

return Canvas