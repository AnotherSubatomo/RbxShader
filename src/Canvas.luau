
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
-- * denormalizes a normalized number
local uint8 = function(n: number) : number
	return math.ceil(n * 255)
end

local Canvas = {}
Canvas.__index = Canvas

type Parent = GuiObject | Decal | Texture | SurfaceAppearance | MeshPart
export type Canvas = typeof(Canvas)

function Canvas.new(
	Parent: Parent,
	Resolution: Vector2,
	CanvasColor: Color3?,
	Blur: boolean?
) : Canvas
	-- Set defaults
	CanvasColor = CanvasColor or Color3.new(1, 1, 1)
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
	self.CanvasColor = CanvasColor or Color3.new(1, 1, 1)
	self.Resolution = Resolution
	self.__Easel = Easel
	self.__Canvas = InternalCanvas
	self.__ImageBuffer = buffer.create(Resolution.X * Resolution.Y * 4)

	-- Initialize the canvas to match the canvas color
	for X = 1, Resolution.X do
		for Y = 1, Resolution.Y do
			self:SetRGBA(
				X, Y,
				CanvasColor.R ,
				CanvasColor.G ,
				CanvasColor.B ,
				1
			)
		end
	end
	
	return self
end

function Canvas:__GetIndex(X: number, Y: number) : number
	return (Y - 1) * (self.Resolution.X * 4) + (X - 1) * 4
end

function Canvas:SetRGBA(X: number, Y: number, R: number, G: number, B: number, A: number)
	A = A or 1
	local Index = self:__GetIndex(X, Y)
	local ImgBuff = self.__ImageBuffer
	writeu8(ImgBuff, Index, uint8(R))
	writeu8(ImgBuff, Index + 1, uint8(G))
	writeu8(ImgBuff, Index + 2, uint8(B))
	writeu8(ImgBuff, Index + 3, uint8(A))
	return nil
end

function Canvas:GetRGB(X: number, Y: number) : (number, number, number)
	local Index = self:__GetIndex(X, Y)
	local ImgBuff = self.__ImageBuffer
	return readu8(ImgBuff, Index) / 255,
		readu8(ImgBuff, Index + 1) / 255,
		readu8(ImgBuff, Index + 2) / 255
end

function Canvas:Render()
	local Canvas : EditableImage = self.__Canvas
	Canvas:WritePixelsBuffer(Vector2.zero, Canvas.Size, self.__ImageBuffer)
	return nil
end

function Canvas:Destroy()
	self.__Canvas:Destroy()
	self.__Easel:Destroy()
	setmetatable(self, nil)
	table.clear(self)
	self = nil
	return nil
end

return Canvas