
-- Worker
-- Multithreaded script responsible for rendering a dictated portion of the canvas.

--!strict
--!optimize 2
--!native

const Run = game:GetService 'RunService'
const Actor = script:GetActor()

if not Actor then error 'Worker actor missing' end

const root = game.ReplicatedStorage:WaitForChild 'RbxShader'
const Registry = require(root.sys.Registry)
const FastCanvas = require(root.sys.Canvas)

-- * hot functions, must be localized
const FastCanvas_SetRGBA = FastCanvas.setRGBA
const FastCanvas_Render = FastCanvas.render

const EMPTY_TABLE = {}
const EMPTY_FUNCTION = function() end

const Types = require(root.common)
type GenericFragmentOperator = Types.FragmentOperator<Types.vec2 | Types.vec3>
type SharedMouse = Types.SharedMouse
type Channels = Types.Channels
type Shader = Types.Shader
type EngineConfiguration = Types.EngineConfiguration
type Canvas = FastCanvas.Canvas

------------------------------------------------------------------------------------------------

local ShaderID: string
local Shader: Shader
local MainImage: GenericFragmentOperator
local PerFrame: Types.PerFrame = EMPTY_FUNCTION
local Init: Types.ShaderInitializer = EMPTY_FUNCTION

local iResolution: Types.vec2
local Configuration: EngineConfiguration
local iMouse: SharedMouse
local iChannels: Channels
const ChannelFragOps: {GenericFragmentOperator} = {}
local CanvasCoords: Vector2
local Canvas: Canvas

Actor:BindToMessage( 'Init' , function (
	__ShaderID: string,
	ShaderModule: ModuleScript,
	Resolution: Vector2,
	Patch: EditableImage,
	X: number,
	Y: number
)
	ShaderID = __ShaderID
	Shader = require(ShaderModule) :: Shader
	Init = Shader.init or Init
	PerFrame = Shader.perFrame or PerFrame
	MainImage = Shader.mainImage
	iResolution = vector.create(Resolution.X, Resolution.Y)
	iChannels = Registry.getChannels(ShaderID)
	iMouse = Registry.getMouse(ShaderID)

	CanvasCoords = Vector2.new(X, Y)
	Canvas = FastCanvas.new(Patch)

	-- Collect the fragment operators assigned to each buffer declared (if there is any)
	local ChannelAllocations: {any} = type(Shader.CHANNELS) == 'table' and Shader.CHANNELS or EMPTY_TABLE

	for Order, Allocation in ChannelAllocations do
		if typeof(Allocation) ~= 'string' then continue end
		ChannelFragOps[Order] = Shader[Allocation]
	end
end)

------------------------------------------------------------------------------------------------

Actor:BindToMessage( 'Set' , function (Configs: EngineConfiguration)
	Configuration = Configs
	
	-- Initialize the VPM buffer to the given origin, offset, and counting direction
	const VirtualOrigin = Configuration.OriginOffset * Vector2.new(iResolution.x, iResolution.y)
	const RelativeOffset = Canvas.Resolution * (CanvasCoords - Vector2.one)
	const CountDirection = Configuration.CountDirection
	
	FastCanvas.recalculateVirtualTexelMapping(Canvas, VirtualOrigin, RelativeOffset, CountDirection)
end)

------------------------------------------------------------------------------------------------

local RenderConnection: RBXScriptConnection?

local oTime = os.clock()
local pTime = 0

const iDate = table.create(4, 0)

const function getTime(): (number)
	return os.clock() - oTime
end

const function updateDate(): ()
	const d = os.date("*t")
	const d_daysec = d.hour * 3600 + d.min * 60 + d.sec
	iDate[1] = d.year
	iDate[2] = d.month
	iDate[3] = d.day
	iDate[4] = d_daysec
end

local CanvasResolution_X: number
local CanvasResolution_Y: number
local InterlaceFactor: number
local StepX: number, StepY: number
local Frame: number

const function Renderer(iTimeDelta: number): ()
	StepY += 1
	if StepY > InterlaceFactor then StepY = 1; StepX += 1 end
	if StepX > InterlaceFactor then StepX = 1 end

	Frame += 1
	if Frame % 60 == 0 then updateDate(); Frame = 0 end

	const iTime = getTime()
	const iMouse = vector.create(iMouse.x, iMouse.y, iMouse.z)

	PerFrame(iTime, iDate, iMouse, iChannels)

	local TexelIndex = (StepY - 1) * CanvasResolution_X + StepX
	const VTMArray = Canvas.VirtualTexelMapArray

	for y = StepY, CanvasResolution_Y, InterlaceFactor do
		local TexelRowIndex = TexelIndex

		for x = StepX, CanvasResolution_X, InterlaceFactor do
			const fragCoords = VTMArray[TexelRowIndex]
			const RGB, A = MainImage(fragCoords, iResolution,
				iTime, iDate, iMouse, iChannels, iTimeDelta)
			
			FastCanvas_SetRGBA(Canvas, TexelRowIndex, RGB, A)

			TexelRowIndex += InterlaceFactor
		end

		TexelIndex += CanvasResolution_X * InterlaceFactor
	end

	task.synchronize()
	FastCanvas_Render(Canvas)
end

const function DisconnectRenderer(): ()
	if RenderConnection then
		RenderConnection:Disconnect()
	end
end

const function ConnectRenderer(): ()
	CanvasResolution_X = Canvas.Resolution.X
	CanvasResolution_Y = Canvas.Resolution.Y
	InterlaceFactor = Configuration.InterlaceFactor
	StepX, StepY = 1, 0
	Frame = 0

	Init(iResolution)

	task.wait()
	task.synchronize()

	RenderConnection = Run.PreRender:ConnectParallel(Renderer)
end

------------------------------------------------------------------------------------------------

Actor:BindToMessageParallel( 'Start' , function()
	if RenderConnection ~= nil then return end
	updateDate()
	oTime = os.clock()
	ConnectRenderer()
end)

------------------------------------------------------------------------------------------------

Actor:BindToMessage( 'Pause' , function()
	if RenderConnection == nil then return end
	-- * this prevents time skips if 'pause' is called more than once
	if pTime ~= 0 then return end
	pTime = getTime()
	DisconnectRenderer()
end)

------------------------------------------------------------------------------------------------

Actor:BindToMessageParallel( 'Resume' , function()
	if RenderConnection ~= nil then return end
	updateDate()
	oTime += getTime() - pTime
	pTime = 0
	ConnectRenderer()
end)

------------------------------------------------------------------------------------------------

Actor:BindToMessage( 'Stop' , function()
	if RenderConnection == nil then return end
	DisconnectRenderer()
end)