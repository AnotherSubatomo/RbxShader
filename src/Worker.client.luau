
--[=[
	Worker
	Multithreaded script responsible for rendering
	a dictated portion of the canvas.
]=]

--!native

-- // Dependencies
local Run = game:GetService('RunService')
local Actor = script:GetActor()

--local root = script.Parent // enable during development
local root = game.ReplicatedStorage:WaitForChild('RbxShader')
local FastCanvas = require(root.Canvas)
local argue = require(root.utils.Argue):at('run')

local STRegistry = game:GetService('SharedTableRegistry')

local ERROR = {
	'Personal canvas does not exist.' ,
	'Shader never had a `mainImage` function.' ,
	'Buffers should not share the same letter.' ,
	'Buffer amount should not exceed 26. (A-Z)'
}

-- * Every type changes will have to be manually synced, unfortunately
export type ShaderBuffer = (
	fragColor : Vector3 ,
	fragCoords : Vector2 ,
	iTime : number ,
	iTimeDelta : number ,
	iResolution : Vector2	
) -> (number, number, number, number)

export type Shader = {
	mainImage : ShaderBuffer
}

export type EngineConfiguration = {
	InterlaceFactor : number ,
	DualAxisInterlacing : boolean ,
	ScreenDivision : number ,
	CanvasColor : Color3? ,
	IsBlurred : boolean
}

export type FastCanvas = {
	Resolution : Vector2 ,
	__Canvas : EditableImage ,
	__GetIndex : (X: number, Y: number) -> number ,
	SetRGBA : ( x : number, y : number, r : number, g : number, b : number, a :number ) -> nil ,
	GetRGB : ( x : number, y : number ) -> ( number, number, number ) ,
	Render : () -> nil ,
	Destroy : () -> nil
}

----------------------------------------------------------------------------------

local CanvasCoords : Vector2 = nil
local Canvas : FastCanvas = nil

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
	
	Canvas = FastCanvas.new( Subeasel, CanvasSize, CanvasColor, IsBlurred )
end)

----------------------------------------------------------------------------------

local iResolution : Vector2 = nil
local Shader : Shader = nil
local ShaderID : string = nil
local InterlaceFactor : number = nil
local DualAxisInterlacing : boolean = nil

local function SetConfigurations( Configuration : EngineConfiguration )
	InterlaceFactor = Configuration.InterlaceFactor
	DualAxisInterlacing = Configuration.DualAxisInterlacing
end

Actor:BindToMessage( 'Initialize' , function (
	__iResolution : Vector2 ,
	__Shader : ModuleScript ,
	__ShaderID : string ,
	Configuration : EngineConfiguration
)
	argue( Canvas , ERROR[1] )
	
	iResolution = __iResolution
	Shader = require(__Shader)
	ShaderID = __ShaderID
	SetConfigurations( Configuration )
end)

----------------------------------------------------------------------------------

Actor:BindToMessage( 'Set' , function (
	Configuration : EngineConfiguration
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

-- /* Date getter */
local function iDate()
	local gt = os.date("%Y|%m|%d|%X"):split('|')
	local t = gt[4]:split(':')
	gt[4] = t[1] * 3600 + t[2] * 60 + t[3] + select(2, math.modf(os.clock()))

	for k, v in gt do
		gt[k] = tonumber(v)
	end

	return gt
end

-- /* Program runner */
local function RunProgram()
	-- /* Buffer implementation */
	local Buffers = {}

	for Step : string , Buffer : ShaderBuffer in Shader do
		if Step:sub(1, 6) ~= 'buffer' then continue end
		local Order = Step:sub(7, 7):upper():byte() - 64
		argue( Buffers[Order] , ERROR[3] )
		Buffers[Order] = Buffer
	end

	-- # Buffer sequence re-ordering
	-- * because some people may have accidentally skipped
	--	 some letters (really a nano-optimization)
	local ReorderedBuffers = {}

	for Index : string , Buffer : ShaderBuffer in Buffers do
		table.insert(Index, Buffer)
	end

	Buffers = ReorderedBuffers

	argue( Shader.mainImage , ERROR[2] )
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
		local iDate = iDate()

		for __ , Buffer : ShaderBuffer in Buffers do
			for y = StepY , Canvas.Resolution.Y, InterlaceFactor do
				for x = StepX, Canvas.Resolution.X, InterlaceFactor do
					Canvas:SetRGBA(x, y,
						Buffer(
							Vector3.new(Canvas:GetRGB(x, y)),
							Vector2.new(x + Offset.X, y + Offset.Y),
							iTime,
							iTimeDelta,
							iResolution,
							iMouse,
							iDate
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
		local iDate = iDate()

		for __ , Buffer : ShaderBuffer in Buffers do
			for y = Step , Canvas.Resolution.Y, InterlaceFactor do
				for x = 1, Canvas.Resolution.X do
					Canvas:SetRGBA(x, y,
						Buffer(
							Vector3.new(Canvas:GetRGB(x, y)),
							Vector2.new(x + Offset.X, y + Offset.Y),
							iTime,
							iTimeDelta,
							iResolution,
							iMouse,
							iDate
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