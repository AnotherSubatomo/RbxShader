
--[=[
	Worker
	Multithreaded script responsible for rendering
	a dictated portion of the canvas.
]=]

--!native

-- // Dependencies
local Run = game:GetService('RunService')
local Actor = script:GetActor()

local root = game.ReplicatedStorage:WaitForChild('RbxShader')
local FastCanvas = require(root.Canvas)
local argue = require(root.utils.Argue):at('runtime')

local STRegistry = game:GetService('SharedTableRegistry')

local ERROR = {
	'Shader never had a `mainImage` function.' ,
	'Different shader buffers cannot not share the same letter.'
}

-- * Every type changes will have to be manually synced, unfortunately
local Types = require(root.utils.Common)
type ShaderBuffer = Types.ShaderBuffer
type Shader = Types.Shader
type EngineConfiguration = Types.EngineConfiguration
type FastCanvas = FastCanvas.Canvas

----------------------------------------------------------------------------------

local ShaderID : string = nil
local Shader : Shader = nil
local iResolution : Vector2 = nil
local CanvasCoords : Vector2 = nil
local Configuration : EngineConfiguration = nil

Actor:BindToMessage( 'SetContext' , function (
	__ShaderID : string ,
	__Shader : ModuleScript ,
	__iResolution : Vector2 ,
	__CanvasCoords : Vector2 ,
	__Configuration : EngineConfiguration
)
	ShaderID = __ShaderID
	Shader = require(__Shader)
	iResolution = __iResolution
	CanvasCoords = __CanvasCoords
	Configuration = __Configuration
end)

----------------------------------------------------------------------------------

local Canvas : FastCanvas = nil

Actor:BindToMessage( 'MakeCanvas' , function (
	Easel : Frame ,
	EaselSize : Vector2 ,
	CanvasSize : Vector2
)
	local Subeasel = Instance.new('Frame')
	Subeasel.Parent = Easel
	Subeasel.Size = UDim2.fromScale( EaselSize.X , EaselSize.Y )
	Subeasel.Position = UDim2.fromScale( EaselSize.X * (CanvasCoords.X-1) , EaselSize.Y * (CanvasCoords.Y-1) )
	Subeasel.BackgroundTransparency = 1

	Canvas = FastCanvas.new(Subeasel, CanvasSize, Configuration.IsBlurred)
	-- Initialize the image buffer to the given initial color and alpha
	Canvas:Fill(Configuration.InitialColor, Configuration.InitialAlpha)
	-- Initialize the VPM buffer to the given origin, offset, and counting direction
	local VirtualOrigin = Configuration.OriginOffset * iResolution
	local RelativeOffset = Canvas.Resolution * (CanvasCoords - Vector2.one)
	local CountDirection = Configuration.CountDirection
	Canvas:RecalculateVirtualPixelMapping(VirtualOrigin, RelativeOffset, CountDirection)
end)

----------------------------------------------------------------------------------

Actor:BindToMessage( 'Set' , function (
	NewConfiguration : EngineConfiguration
)
	-- # Do necessary updates
	-- @ Update resample mode
	if NewConfiguration.IsBlurred ~= Configuration.IsBlurred then
		local Resampler = Enum.ResamplerMode
		Canvas.__Easel.ResampleMode = NewConfiguration.IsBlurred and Resampler.Default or Resampler.Pixelated
	end
	-- @ Update pixel coordinate mapping
	if NewConfiguration.OriginOffset ~= Configuration.OriginOffset or
	NewConfiguration.CountDirection ~= Configuration.CountDirection then
		local VirtualOrigin = NewConfiguration.OriginOffset * iResolution
		local RelativeOffset = Canvas.Resolution * (CanvasCoords - Vector2.one)
		local CountDirection = NewConfiguration.CountDirection
		Canvas:RecalculateVirtualPixelMapping(VirtualOrigin, RelativeOffset, CountDirection)
	end
	Configuration = NewConfiguration
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
	-- # Fundamental variables
	local Buffers = {} --> collection of shader buffers
	local iMouse = STRegistry:GetSharedTable(ShaderID..'@Mouse') --> mouse position
	local InterlaceFactor = Configuration.InterlaceFactor
	local DualAxisInterlacing = Configuration.DualAxisInterlacing

	-- # Buffer implementation
	for Step : string , Buffer : ShaderBuffer in Shader do
		if type(Step) ~= "string" or Step:sub(1, 6) ~= 'buffer' then continue end
		local Order = Step:sub(7, 7):upper():byte() - 64
		argue( Buffers[Order] , ERROR[2] )
		Buffers[Order] = Buffer
	end

	-- Buffer sequence re-ordering
	-- * because some people may have accidentally skipped some letters
	local ReorderedBuffers = {}
	for _ : number , Buffer : ShaderBuffer in Buffers do
		table.insert(ReorderedBuffers, Buffer)
	end

	Buffers = ReorderedBuffers

	argue( Shader.mainImage , ERROR[1] )
	table.insert(Buffers, Shader.mainImage)

	-- # Interlacer implementation
	local Step = 1
	local StepX, StepY = 1, 1

	-- # Render functions
	-- @ with dual-axis interlacing
	local function DUIRendering ( iTimeDelta : number )

		if StepX > InterlaceFactor then StepX = 1; StepY += 1 end
		if StepY > InterlaceFactor then StepY = 1 end
		local iTime = iTime()
		local iDate = iDate()

		for __ , ShaderBuffer: ShaderBuffer in Buffers do
			for y = StepY , Canvas.Resolution.Y, InterlaceFactor do
				for x = StepX, Canvas.Resolution.X, InterlaceFactor do
					local fragColor = Vector3.new(Canvas:GetRGB(x, y))
					local fragCoords = Vector2.new(Canvas:GetVirtualPosition(x, y))

					Canvas:SetRGBA(x, y,
						ShaderBuffer(
							fragColor,
							fragCoords,
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

		for __ , ShaderBuffer: ShaderBuffer in Buffers do
			for y = Step , Canvas.Resolution.Y, InterlaceFactor do
				for x = 1, Canvas.Resolution.X do
					local fragColor = Vector3.new(Canvas:GetRGB(x, y))
					local fragCoords = Vector2.new(Canvas:GetVirtualPosition(x, y))

					Canvas:SetRGBA(x, y,
						ShaderBuffer(
							fragColor,
							fragCoords,
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
	local Renderer = DualAxisInterlacing and DUIRendering or UUIRendering

	task.synchronize()

	RenderConnection = Run.PreRender:ConnectParallel(Renderer)
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