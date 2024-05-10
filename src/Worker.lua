
--[=[
	Worker
	Multithreaded script responsible for rendering
	a dictated portion of the canvas.
]=]

--!native

export type Shader = {
	mainImage : (
		ragColor : Vector3 ,
		fragCoords : Vector2 ,
		iTime : number ,
		iTimeDelta : number ,
		iResolution : Vector2	
	) -> (number, number, number)
}

-- // Dependencies
local Run = game:GetService('RunService')
local Camera = workspace.CurrentCamera
local Actor = script:GetActor()

local RbxShader = game.ReplicatedStorage:FindFirstChild('RbxShader', true)
local CanvasDraw = require(RbxShader.CanvasDraw)
local ImageDataConstructor = require(RbxShader.CanvasDraw:WaitForChild("ImageDataConstructor"))

local RenderConnection : RBXScriptConnection = nil
local Canvas : CanvasDraw = nil

Actor:BindToMessage( 'Draw' , function (
	Easel : Frame ,
	EaselSize : Vector2 ,
	EaselOffset : Vector2 ,
	CanvasSize : Vector2
)
	local Subeasel = Instance.new('Frame')
	Subeasel.Parent = Easel
	Subeasel.Size = UDim2.fromScale( EaselSize.X , EaselSize.Y )
	Subeasel.Position = UDim2.fromScale( EaselSize.X * EaselOffset.X , EaselSize.Y * EaselOffset.Y )
	Subeasel.BackgroundTransparency = 1
	
	Canvas = CanvasDraw.new( Subeasel, CanvasSize )
end)

Actor:BindToMessage( 'Run' , function (
	iResolution : Vector2 ,
	CanvasOffset : Vector2 ,
	Shader : ModuleScript ,
	InterlaceFactor : number
)
	assert( Canvas , 'GL@PARALLEL: Cannot run, personal canvas does not exist.' )
	Shader = require(Shader) :: Shader
	
	task.desynchronize()
	
	-- /* using os.clock() is smoother than os.time(), pretty sick */
	local oTime = os.clock()
	local function iTime()
		return os.clock() - oTime
	end
	
	-- // Buffer-accumulation implementation
	local ImageBuffer = ImageDataConstructor.new(
		Canvas.Resolution.X ,
		Canvas.Resolution.Y ,
		table.create(Canvas.Resolution.Y*Canvas.Resolution.X*4, 1)
	)
	
	-- // Interlacer implementation
	local Step = 1
	
	-- // Rendering
	local function PerFrame ( iTimeDelta : number )

		local iTime = iTime()
		if Step > InterlaceFactor then Step = 1 end

		for y = Step, Canvas.Resolution.Y, InterlaceFactor do
			for x = 1, Canvas.Resolution.X do
				ImageBuffer:SetRGB(x, y, Shader.mainImage(
					Vector3.new(ImageBuffer:GetRGB(x, y)),
					Vector2.new(x + CanvasOffset.X, y + CanvasOffset.Y),
					iTime,
					iTimeDelta,
					iResolution
				))
			end
		end

		Canvas:DrawImage(ImageBuffer)
		Step += 1
	end
	
	task.synchronize()

	RenderConnection = Run.PreRender:ConnectParallel( PerFrame )
end)

Actor:BindToMessage( 'Stop' , function ()
	RenderConnection:Disconnect()
end)
