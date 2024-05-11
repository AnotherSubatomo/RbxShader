
--[=[
	Worker
	Multithreaded script responsible for rendering
	a dictated portion of the canvas.
	
	NOTE:
	- I added a new method on CanvasDraw called `:SetRGBA`
	  to make color and alpha changing easier.
]=]

--!native

export type Shader = {
	mainImage : (
		fragColor : Vector3 ,
		fragCoords : Vector2 ,
		iTime : number ,
		iTimeDelta : number ,
		iResolution : Vector2	
	) -> (number, number, number, number)
}

-- // Dependencies
local Run = game:GetService('RunService')
local Camera = workspace.CurrentCamera
local Actor = script:GetActor()

local RbxShader = game.ReplicatedStorage:FindFirstChild('RbxShader', true)
-- ^^^ Replace this with `script.Parent` during debugging for type-checking...
local CanvasDraw = require(RbxShader.CanvasDraw)
local ImageDataConstructor = require(RbxShader.CanvasDraw:WaitForChild("ImageDataConstructor"))

local RenderConnection : RBXScriptConnection = nil
local CanvasCoords : Vector2 = nil
local Canvas : CanvasDraw = nil



Actor:BindToMessage( 'Draw' , function (
	Easel : Frame ,
	EaselSize : Vector2 ,
	CanvasSize : Vector2 ,
	__CanvasCoords : Vector2
)
	CanvasCoords = __CanvasCoords
	
	local Subeasel = Instance.new('Frame')
	Subeasel.Parent = Easel
	Subeasel.Size = UDim2.fromScale( EaselSize.X , EaselSize.Y )
	Subeasel.Position = UDim2.fromScale( EaselSize.X * (CanvasCoords.X-1) , EaselSize.Y * (CanvasCoords.Y-1) )
	Subeasel.BackgroundTransparency = 1
	
	Canvas = CanvasDraw.new( Subeasel, CanvasSize )
	Canvas.AutoRender = false
end)



local iResolution : Vector2 = nil
local Shader : Shader = nil
local InterlaceFactor : number = nil
local DualAxisInterlacing : boolean = nil



Actor:BindToMessage( 'Set' , function (
	__iResolution : Vector2 ,
	__Shader : ModuleScript ,
	__InterlaceFactor : number ,
	__DualAxisInterlacing : boolean
)
	assert( Canvas , 'SHADER@PARALLEL: Personal canvas does not exist.' )
	
	iResolution = __iResolution
	Shader = require(__Shader)
	InterlaceFactor = __InterlaceFactor
	DualAxisInterlacing = __DualAxisInterlacing
end)



Actor:BindToMessageParallel( 'Run' , function ()
	-- /* using os.clock() is smoother than os.time(), pretty sick */
	local oTime = os.clock()
	local function iTime()
		return os.clock() - oTime
	end

	-- /* Buffer-accumulation implementation */
	--	  Canvases are actually already their own
	--	  buffer, pretty neat huh! Thanks Ethan! <3

	-- /* Interlacer implementation */
	local Step = 1
	local StepX, StepY = 1, 1
	
	local Offset = Canvas.Resolution * (CanvasCoords - Vector2.one)

	-- /* Render functions */
	-- @ with dual-axis interlacing
	local function DUIRendering ( iTimeDelta : number )
		
		if StepX > InterlaceFactor then StepX = 1; StepY += 1 end
		if StepY > InterlaceFactor then StepY = 1 end
		local iTime = iTime()

		for y = StepY , Canvas.Resolution.Y, InterlaceFactor do
			for x = StepX, Canvas.Resolution.X, InterlaceFactor do
				Canvas:SetRGBA(x, y,
					Shader.mainImage(
						Vector3.new(Canvas:GetRGB(x, y)),
						Vector2.new(x + Offset.X, y + Offset.Y),
						iTime,
						iTimeDelta,
						iResolution
					)
				)
			end
		end
		
		task.synchronize()
		
		Canvas:Render()
		StepX += 1
	end
	
	-- @ without dual-axis interlacing
	local function UUIRendering ( iTimeDelta : number )

		if Step > InterlaceFactor then Step = 1 end
		local iTime = iTime()

		for y = Step , Canvas.Resolution.Y, InterlaceFactor do
			for x = 1, Canvas.Resolution.X do
				Canvas:SetRGBA(x, y,
					Shader.mainImage(
						Vector3.new(Canvas:GetRGB(x, y)),
						Vector2.new(x + Offset.X, y + Offset.Y),
						iTime,
						iTimeDelta,
						iResolution
					)
				)
			end
		end

		task.synchronize()

		Canvas:Render()
		Step += 1
	end
	
	-- /* Rendering */
	local PerFrame = DualAxisInterlacing and DUIRendering or UUIRendering

	task.synchronize()

	RenderConnection = Run.PreRender:ConnectParallel( PerFrame )
end)



Actor:BindToMessage( 'Stop' , function ()
	RenderConnection:Disconnect()
end)
