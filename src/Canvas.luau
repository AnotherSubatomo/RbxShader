
--[=[
	Canvas
	A simple EditableImage interface that mimics
	CanvasDraw's API design. Specifically built for RbxShader.
]=]

--!native
--!strict

local Asset = game:GetService('AssetService')
local Canvas = {}

type Parent = GuiObject | Decal | Texture | SurfaceAppearance | MeshPart
export type Canvas = typeof(Canvas)

local Resampler = Enum.ResamplerMode
local writeu8 = buffer.writeu8
local readu8 = buffer.readu8
local ceil = math.ceil

function Canvas.new(
	Parent: Parent,
	Resolution: Vector2,
	CanvasColor: Color3?,
	Blur: boolean?
) : Canvas
	-- Build the necessary objects
	local Easel = Instance.new("ImageLabel")
	Easel.Name = "FastCanvas"
	Easel.BackgroundTransparency = 1
	Easel.ClipsDescendants = true
	Easel.Size = UDim2.fromScale(1, 1)
	Easel.Position = UDim2.fromScale(0.5, 0.5)
	Easel.AnchorPoint = Vector2.new(0.5, 0.5)
	Easel.ResampleMode = Blur and Resampler.Pixelated or Resampler.Default
	Easel.Parent = Parent

	local AspectRatio = Instance.new("UIAspectRatioConstraint")
	AspectRatio.AspectRatio = Resolution.X / Resolution.Y
	AspectRatio.Parent = Easel
	
	local InternalCanvas = Asset:CreateEditableImage({ Size = Resolution })
	InternalCanvas.Parent = Easel

	-- Build the 'Canvas' object
	local self = setmetatable({}, {__index = Canvas})
	self.CanvasColor = CanvasColor or Color3.new(1, 1, 1)
	self.Resolution = Resolution
	self.__Easel = Easel
	self.__Canvas = InternalCanvas
	self.__ImageBuffer = buffer.create(Resolution.X * Resolution.Y * 4)

	-- Initialize the canvas to match the canvas color
	for X = 0, Resolution.X - 1 do
		for Y = 0, Resolution.Y - 1 do
			self:SetRGBA(
				X, Y,
				ceil(CanvasColor.R * 255) ,
				ceil(CanvasColor.G * 255) ,
				ceil(CanvasColor.B * 255) ,
				255
			)
		end
	end

	return self
end

function Canvas:__GetIndex(X: number, Y: number) : number
	return (X + (Y - 1) * self.Resolution.X) * 4 - 3
end

function Canvas:SetRGBA(X: number, Y: number, R: number, G: number, B: number, A: number)
	local Index = self:__GetIndex(X, Y)
	local ImgBuff = self.__ImageBuffer
	writeu8(ImgBuff, Index, R)
	writeu8(ImgBuff, Index + 1, G)
	writeu8(ImgBuff, Index + 2, B)
	writeu8(ImgBuff, Index + 3, A)
	return nil
end

function Canvas:GetRGB(X: number, Y: number) : (number, number, number)
	local Index = self:__GetIndex(X, Y)
	local ImgBuff = self.__ImageBuffer
	return readu8(ImgBuff, Index), readu8(ImgBuff, Index + 1), readu8(ImgBuff, Index + 2)
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