
--[=[
	Worker
	Multithreaded script responsible for rendering
	a dictated portion of the canvas.
	
	NOTE:
	- I added a new method on CanvasDraw called `:SetRGBA`
	  to make color and alpha changing easier.
]=]

--!native

-- // Dependencies
local Run = game:GetService('RunService')
local Actor = script:GetActor()

local RbxShader = game.ReplicatedStorage:FindFirstChild('RbxShader', true)
-- ^^^ Replace this with `script.Parent` during debugging for type-checking...
local CanvasDraw = require(RbxShader.CanvasDraw)
local Types = require(RbxShader.Common)

local STRegistry = game:GetService('SharedTableRegistry')

local ERROR = {
	'SHADER@RUN: Personal canvas does not exist.' ,
	'SHADER@RUN: Shader never had a `mainImage` function.' ,
	'SHADER@RUN: Buffers should not share the same letter.' ,
	'SHADER@RUN: Buffer amount should not exceed 26. (A-Z)'
}

----------------------------------------------------------------------------------

local CanvasCoords : Vector2 = nil
local Canvas : typeof(CanvasDraw) | Types.FastCanvas = nil

Actor:BindToMessage( 'MakeCanvas' , function (
	Easel : Frame ,
	EaselSize : Vector2 ,
	CanvasSize : Vector2 ,
	__CanvasCoords : Vector2 ,
	CanvasColor : Color3? ,
	IsBlurred : boolean?
)
	CanvasCoords = __CanvasCoords
	
	local Subeasel = Instance.new('Frame')
	Subeasel.Parent = Easel
	Subeasel.Size = UDim2.fromScale( EaselSize.X , EaselSize.Y )
	Subeasel.Position = UDim2.fromScale( EaselSize.X * (CanvasCoords.X-1) , EaselSize.Y * (CanvasCoords.Y-1) )
	Subeasel.BackgroundTransparency = 1
	
	Canvas = CanvasDraw.new( Subeasel, CanvasSize, CanvasColor, IsBlurred )
	Canvas.AutoRender = false
	Canvas = Canvas.InternalCanvas
end)

----------------------------------------------------------------------------------

local iResolution : Vector2 = nil
local Shader : Types.Shader = nil
local ShaderID : string = nil
local InterlaceFactor : number = nil
local DualAxisInterlacing : boolean = nil

local function SetConfigurations( Configuration : Types.EngineConfiguration )
	InterlaceFactor = Configuration.InterlaceFactor
	DualAxisInterlacing = Configuration.DualAxisInterlacing
end

Actor:BindToMessage( 'Initialize' , function (
	__iResolution : Vector2 ,
	__Shader : ModuleScript ,
	__ShaderID : string ,
	Configuration : Types.EngineConfiguration
)
	assert( Canvas , ERROR[1] )
	
	iResolution = __iResolution
	Shader = require(__Shader)
	ShaderID = __ShaderID
	SetConfigurations( Configuration )
end)

----------------------------------------------------------------------------------

Actor:BindToMessage( 'Set' , function (
	Configuration : Types.EngineConfiguration
)
	SetConfigurations( Configuration )
end)

----------------------------------------------------------------------------------

local RenderConnection : RBXScriptConnection = nil

-- # using os.clock() is smoother than os.time(), pretty sick
local oTime = os.clock()
local pTime = 0

-- /* Program runtime getter */
local function iTime()
	return os.clock() - oTime
end

-- /* Program runner */
local function RunProgram()
	-- /* Buffer implementation */
	local Buffers = {}

	for Step : string , Buffer : Types.ShaderBuffer in Shader do
		if Step:sub(1, 6) ~= 'buffer' then continue end
		local Order = Step:sub(7, 7):upper():byte() - 64
		assert( Buffers[Order] , ERROR[3] )
		Buffers[Order] = Buffer
	end

	-- # Buffer sequence re-ordering
	-- * because some people may have accidentally skipped
	--	 some letters (really a nano-optimization)
	local ReorderedBuffers = {}

	for Index : string , Buffer : Types.ShaderBuffer in Buffers do
		table.insert(Index, Buffer)
	end

	Buffers = ReorderedBuffers

	assert( Shader.mainImage , ERROR[2] )
	table.insert(Buffers, Shader.mainImage)
	
	-- /* Fetch inputs */
	local iMouse = STRegistry:GetSharedTable(ShaderID..'@Mouse')

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

		for __ , Buffer : Types.ShaderBuffer in Buffers do
			for y = StepY , Canvas.Resolution.Y, InterlaceFactor do
				for x = StepX, Canvas.Resolution.X, InterlaceFactor do
					Canvas:SetRGBA(x, y,
						Buffer(
							Vector3.new(Canvas:GetRGB(x, y)),
							Vector2.new(x + Offset.X, y + Offset.Y),
							iTime,
							iTimeDelta,
							iResolution,
							iMouse
						)
					)
				end
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

		for __ , Buffer : Types.ShaderBuffer in Buffers do
			for y = Step , Canvas.Resolution.Y, InterlaceFactor do
				for x = 1, Canvas.Resolution.X do
					Canvas:SetRGBA(x, y,
						Buffer(
							Vector3.new(Canvas:GetRGB(x, y)),
							Vector2.new(x + Offset.X, y + Offset.Y),
							iTime,
							iTimeDelta,
							iResolution,
							iMouse
						)
					)
				end
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
end

----------------------------------------------------------------------------------

Actor:BindToMessageParallel( 'Run' , function ()
	-- /* Reset runtime. */
	oTime = os.clock()
	RunProgram()
end)

----------------------------------------------------------------------------------

Actor:BindToMessage( 'Pause' , function()
	pTime = iTime()
	if RenderConnection ~= nil then
		RenderConnection:Disconnect()
	end
end)

----------------------------------------------------------------------------------

Actor:BindToMessageParallel( 'Resume' , function()
	oTime += iTime() - pTime
	RunProgram()
end)

----------------------------------------------------------------------------------

Actor:BindToMessage( 'Stop' , function ()
	if RenderConnection ~= nil then
		RenderConnection:Disconnect()
	end
end)