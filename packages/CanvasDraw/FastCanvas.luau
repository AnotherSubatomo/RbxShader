--!native

--[[
	FastCanvas is a simple, but very fast and efficent 
	drawing canvas with per pixel methods via EditableImage.
	
	This module was designed to be intergrated with CanvasDraw. 
	A real-time roblox pixel graphics engine.
	
	This can be used on normal GUI Frames AND Decals, Textures, MeshParts, etc

	Written by @Ethanthegrand14
	
	Created: 9/11/2023
	Last Updated: 18/07/2024
]]

local FastCanvas = {}

type ParentType = GuiObject | Decal | Texture | SurfaceAppearance | MeshPart

function FastCanvas.new(Width: number, Height: number, CanvasParent: ParentType, Blur: boolean?)
	local IsUiParent = CanvasParent:IsA("GuiObject")
	
	local Canvas = {} -- The canvas object
	local Grid = table.create(Width * Height * 4, 1) -- Local pixel grid containing RGBA values
	local ClearingGrid = table.clone(Grid) -- For Canvas:Clear()
	
	local Origin = Vector2.zero
	local Resolution = Vector2.new(Width, Height)
	
	-- Local functions
	local function GetGridIndex(X, Y)
		return (X + (Y - 1) * Width) * 4 - 3
	end
	
	-- Create gui objects
	
	local EditableImage = Instance.new("EditableImage")
	EditableImage.Size = Resolution
	
	local CanvasFrame
	
	if IsUiParent then
		CanvasFrame = Instance.new("ImageLabel")
		CanvasFrame.Name = "FastCanvas"
		CanvasFrame.BackgroundTransparency = 1
		CanvasFrame.ClipsDescendants = true
		CanvasFrame.Size = UDim2.fromScale(1, 1)
		CanvasFrame.Position = UDim2.fromScale(0.5, 0.5)
		CanvasFrame.AnchorPoint = Vector2.new(0.5, 0.5)
		
		if not Blur then
			CanvasFrame.ResampleMode = Enum.ResamplerMode.Pixelated
		end
		
		local AspectRatio = Instance.new("UIAspectRatioConstraint")
		AspectRatio.AspectRatio = Width / Height
		AspectRatio.Parent = CanvasFrame
		
		EditableImage.Parent = CanvasFrame
		CanvasFrame.Parent = CanvasParent
	else
		EditableImage.Parent = CanvasParent
	end
	
	-- Properties
	
	Canvas.Image = EditableImage
	Canvas.Resolution = Resolution
	
	-- Pixel methods
	
	function Canvas:SetColor3(X: number, Y: number, Colour: Color3)
		local Index = GetGridIndex(X, Y)
		Grid[Index] = Colour.R
		Grid[Index + 1] = Colour.G
		Grid[Index + 2] = Colour.B
	end
	
	function Canvas:SetRGB(X: number, Y: number, R: number, G: number, B: number)
		local Index = GetGridIndex(X, Y)
		Grid[Index] = R
		Grid[Index + 1] = G
		Grid[Index + 2] = B
	end
	
	function Canvas:SetRGBA(X: number, Y: number, R: number, G: number, B: number, A: number)
		local Index = GetGridIndex(X, Y)
		Grid[Index] = R
		Grid[Index + 1] = G
		Grid[Index + 2] = B
		Grid[Index + 3] = A or 1
	end
	
	function Canvas:SetAlpha(X: number, Y: number, Alpha: number)
		Grid[GetGridIndex(X, Y) + 3] = Alpha
	end
	
	-- Pixel fetch methods
	
	function Canvas:GetRGB(X: number, Y: number): (number, number, number)
		local Index = GetGridIndex(X, Y)

		return Grid[Index], Grid[Index + 1], Grid[Index + 2]
	end

	function Canvas:GetRGBA(X: number, Y: number): (number, number, number, number)
		local Index = GetGridIndex(X, Y)

		return Grid[Index], Grid[Index + 1], Grid[Index + 2], Grid[Index + 3]
	end
	
	function Canvas:GetColor3(X: number, Y: number): Color3
		local Index = GetGridIndex(X, Y)
		
		return Color3.new(Grid[Index], Grid[Index + 1], Grid[Index + 2])
	end
	
	function Canvas:GetAlpha(X: number, Y: number): number
		local Index = GetGridIndex(X, Y)

		return Grid[Index + 3]
	end
	
	-- Canvas methods
	
	function Canvas:SetGrid(PixelArray)
		Grid = table.clone(PixelArray)
	end

	function Canvas:GetGrid()
		return table.clone(Grid)
	end
	
	function Canvas:SetClearRGBA(R, G, B, A)
		for i = 1, Width * Height * 4, 4 do
			ClearingGrid[i] = R
			ClearingGrid[i + 1] = G
			ClearingGrid[i + 2] = B
			ClearingGrid[i + 3] = A
		end
	end
	
	function Canvas:Clear()
		Grid = table.clone(ClearingGrid)
	end
	
	function Canvas:Render()
		EditableImage:WritePixels(Origin, Resolution, Grid)
	end
	
	function Canvas:Destroy()
		if CanvasFrame then
			CanvasFrame:Destroy()
		end
		Grid = nil
		Canvas = nil
	end
	
	return Canvas
end

return FastCanvas