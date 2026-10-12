
--[[
	RbxShader
	An ergonomic, robust, and performant fragment shader engine.

	Learn more about the engine via:
	https://github.com/AnotherSubatomo/RbxShader

	Version: 3.0.0-rc.1
	SPDX-License-Identifier: MIT
	Author: @AnotherSubatomo (GitHub)
]]

--!strict
--!optimize 2
--!native

const Resampler = Enum.ResamplerMode
const Vector2 = Vector2.new
const New = Instance.new

const Asset = game:GetService 'AssetService'
const Players = game:GetService 'Players'
const Client = Players.LocalPlayer

const InputBackend = require(script:WaitForChild 'lib' .Input.backend)
const Registry = require(script:WaitForChild 'sys' .Registry)

const Types = require(script.common)
type SharedMouse = Types.SharedMouse
type Workers = {Actor}

export type EngineConfiguration = Types.EngineConfiguration
export type Shader = Types.Shader
export type ShaderContext = {
	read ID: string,
	read Configs: EngineConfiguration,
	read Workers: Workers,
	read Industry: Folder,
	read Patches: {EditableImage},
	read Resolution: Vector2
}

const VERSION = vector.create(3, 0, 0)

const EMPTY_TABLE = {}
const WORKER_TEMPLATE = script.Worker
const MIN_RESOLUTION = Vector2(32, 32)
const MAX_RESOLUTION = Vector2(1025, 1025)

const DEFAULT_CONFIGURATIONS: EngineConfiguration = {
	InterlaceFactor = 2,
	ScreenDivision = Vector2(4, 4),
	InitialColor = vector.one,
	InitialAlpha = 1,
	OriginOffset = Vector2(0, 1), --> by OpenGL convention
	CountDirection = Vector2(1, -1) --> by OpenGL convention
}

const ERR_INVALID_SHADER = 'Invalid shader module given.'
const ERR_FRAG_OP_MISS_FMT = 'There is a required but undefined fragment operator within the program, called: '
const ERR_FRAG_OP_MAIN_MISS = ERR_FRAG_OP_MISS_FMT .. 'mainImage'
const ERR_PATCH_SIZE_TOO_BIG = 'Resolution is too big; the size of its patches were greater than the EditableImage dimension limit (1024 x 1024).'

-- Returns a stable engine configuration built from two possibly conflicting configurations.
const function ReconcileConfiguration(GivenConfig: LooseEngineConfiguration?, BuiltConfig: LooseEngineConfiguration?): (EngineConfiguration)
	local Config = table.clone(DEFAULT_CONFIGURATIONS)
	local SaneGivenConfig = GivenConfig or EMPTY_TABLE :: EngineConfiguration
	local SaneBuiltConfig = BuiltConfig or EMPTY_TABLE :: EngineConfiguration
	
	for Field, Default in Config do
		Config[Field] = SaneGivenConfig[Field] or SaneBuiltConfig[Field] or Default
	end

	local CountDirection_X = Config.CountDirection.X
	local CountDirection_Y = Config.CountDirection.Y

	if CountDirection_X == 0 then
		warn 'Config.CountDirection.X is 0, which results to undefined behavior; defaulting to -1.'
		CountDirection_X = -1
	end

	if CountDirection_Y == 0 then
		warn 'Config.CountDirection.Y is 0, which results to undefined behavior; defaulting to -1.'
		CountDirection_Y = -1
	end

	Config.CountDirection = Vector2(CountDirection_X, CountDirection_Y)
	return Config :: EngineConfiguration
end

-- Requires the given shader module while ensuring that its content is formatted validly.
const function SafelyUnpackShaderModule(File: ModuleScript): (Shader)
	assert( typeof(File) == 'Instance' , ERR_INVALID_SHADER )
	assert( File:IsA('ModuleScript') , ERR_INVALID_SHADER )
	const Shader = require(File) :: any
	assert( typeof(Shader) == 'table' , ERR_INVALID_SHADER )
	assert( typeof(Shader.mainImage) == 'function' , ERR_FRAG_OP_MAIN_MISS )
	return Shader :: Shader
end

-- Generates actors: instances which enable code to run on multiple threads simultaneously.
const function GenerateWorkers(Amount: number): (Workers)
	const Workers = table.create(Amount) :: Workers

	for Order = 1, Amount do
		const Actor = New 'Actor'
		const Worker = Instance.fromExisting(WORKER_TEMPLATE)
		Worker.Name = 'Worker@' .. Order
		Worker.Parent = Actor
		Workers[Order] = Actor
	end

	return Workers
end

-- Sends the same message throughout the given list of actors.
const function MessageEachWorker(Workers: Workers, Topic: string, ...: any): ()
	for _, Actor in Workers do Actor:SendMessage(Topic, ...) end
end

-- Distributes the shader program's context to all workers.
const function InitializeWorkers(
	Workers: Workers, Patches: {EditableImage}, ShaderID: string, ShaderModule: ModuleScript,
	Configs: EngineConfiguration, Resolution: Vector2, Division_Y: number
): ()
	for Index, Actor in Workers do
		-- Fetch their respectively assigned patches
		local Patch = Patches[Index]
		local X = ((Index - 1) // Division_Y) + 1
		local Y = ((Index - 1) % Division_Y) + 1
		Actor:SendMessage('Init', ShaderID, ShaderModule, Resolution, Patch, X, Y)
		Actor:SendMessage('Set', Configs)
	end
end

-- Creates and initializes the runtime context and
-- environment for the given shader to run on.
const function NEW(
	ShaderModule: ModuleScript,
	Host: Script,
	Resolution: Vector2,
	GivenConfiguration: LooseEngineConfiguration?
): (ShaderContext)
	assert( typeof(Resolution) == 'Vector2' , 'Resolution was unspecified.' )
	assert( Resolution:Min(MIN_RESOLUTION) == MIN_RESOLUTION , 'Resolution is too small; minimum resolution is 32 by 32.' )

	-- Temporarily unpack the module here
	local Shader = SafelyUnpackShaderModule(ShaderModule)
	
	local Configs = ReconcileConfiguration(GivenConfiguration, Shader.CONFIGURATION)
	local ShaderID = string.sub(tostring(Configs), 8)

	-- Initialize the allocated input channels
	local ChannelAllocations: {any} = type(Shader.CHANNELS) == 'table' and Shader.CHANNELS or EMPTY_TABLE
	local Channels = SharedTable.new(table.create(#ChannelAllocations, 0))
	
	for Order, Allocation in ChannelAllocations do
		if typeof(Allocation) == 'string' then
			local FragOpName = Allocation
			assert( typeof(Shader[FragOpName]) == 'function' , ERR_FRAG_OP_MISS_FMT .. FragOpName )
		end
		SharedTable.update(Channels, Order, function()
			return InputBackend.AllocateChannel(Allocation, Resolution)
		end)
	end

	-- Representation of the mouse position that is shared across parallel scripts.
	local SharedMouse = SharedTable.new { x = 0, y = 0, z = 0 } :: SharedMouse
	Registry.setMouse(ShaderID, SharedMouse)
	Registry.setChannels(ShaderID, Channels :: any)
	
	-- Calculate the dimensions of each subdivisions
	-- These subdivisions are called a 'subcanvas' or 'patch' of a canvas
	local ScreenDivision = Configs.ScreenDivision:Floor()
	local WorkerAmount = ScreenDivision.X * ScreenDivision.Y
	assert ( WorkerAmount % 2 == 0 , 'The product of the components of `ScreenDivision` must be an even number for maximum performance.' )
	
	local MeanPatchSize = (Resolution / ScreenDivision):Floor()
	local ExcessSize = Resolution - MeanPatchSize * ScreenDivision

	assert( MeanPatchSize:Max(MAX_RESOLUTION) == MAX_RESOLUTION , ERR_PATCH_SIZE_TOO_BIG )
	assert( (MeanPatchSize + ExcessSize):Max(MAX_RESOLUTION) == MAX_RESOLUTION , ERR_PATCH_SIZE_TOO_BIG )
	
	-- Set-up parallelized shader daemons that work on a designated patch
	local Workers = GenerateWorkers(WorkerAmount)
	local Industry = New 'Folder'
	Industry.Name = 'SHADER@' .. ShaderID
	Industry.Parent = Host
	-- * Set parents at last priority, otherwise it won't work
	for _, Actor in Workers do
		Actor.Parent = Industry
	end
	
	-- Create the patches
	local Patches = table.create(WorkerAmount) :: {EditableImage}
	local Division_X, Division_Y = ScreenDivision.X, ScreenDivision.Y
	local MeanPatchSize_X, MeanPatchSize_Y = MeanPatchSize.X, MeanPatchSize.Y
	local Excess_X, Excess_Y = ExcessSize.X, ExcessSize.Y

	for Y = 1, Division_Y do
		for X = 1, Division_X do
			local Index = Y + Division_Y * (X - 1)
			local Size_X, Size_Y = MeanPatchSize_X, MeanPatchSize_Y
			if Y == Division_Y then Size_Y += Excess_Y end
			if X == Division_X then Size_X += Excess_X end

			local PatchSize = Vector2(Size_X, Size_Y)
			local Patch = Asset:CreateEditableImage { Size = PatchSize }
			Patches[Index] = Patch
		end
	end

	task.defer(InitializeWorkers,
		Workers, Patches, ShaderID, ShaderModule,
		Configs, Resolution, Division_Y)
	
	Patches = table.freeze(Patches)

	return table.freeze {
		ID = ShaderID,
		Configs = Configs,
		Workers = Workers,
		Industry = Industry,
		Patches = Patches,
		Resolution = Resolution
	}
end

const function deferTopic(Action: string, Workers: Workers, ...: any): ()
	task.defer(MessageEachWorker, Workers, Action, ...)
end

-- Halts a shader from running.
const function STOP(Context: ShaderContext): ()
	deferTopic('Stop', Context.Workers)
end

-- Runs a shader. (Not a resume function)
const function START(Context: ShaderContext): ()
	deferTopic('Start', Context.Workers)
end

-- Pauses the shader.
const function PAUSE(Context: ShaderContext): ()
	deferTopic('Pause', Context.Workers)
end

-- Resumes the shader.
const function RESUME(Context: ShaderContext): ()
	deferTopic('Resume', Context.Workers)
end

-- Sets the configuration of the shader to something else.
const function SET(Context: ShaderContext, GivenConfiguration: LooseEngineConfiguration): ()
	local Workers = Context.Workers
	local NewConfigs = ReconcileConfiguration(GivenConfiguration, Context.Configs)

	deferTopic('Pause', Workers)
	MessageEachWorker(Workers, 'Set', NewConfigs)
	deferTopic('Resume', Workers)
end

const function CREATE_DISPLAY(Context: ShaderContext, IsBlurred: boolean?): (ImageButton)
	local Configs = Context.Configs
	local Resolution = Context.Resolution

	local ScreenDivision = Configs.ScreenDivision
	local Division_X, Division_Y = math.floor(ScreenDivision.X), math.floor(ScreenDivision.Y)
	local WorkerAmount = Division_X * Division_Y

	if WorkerAmount % 2 == 1 then
		error 'The product of the components of screen division must be an even number for maximum performance.'
	end
	
	-- Initialize the easel where our subcanvases will be placed
	const Easel = New 'ImageButton' do
		Easel.Name = Context.Industry.Name .. '/Easel'
		Easel.Size = UDim2.fromScale(1, 1)
		Easel.BackgroundTransparency = 1
		Easel.ImageContent = Content.none

		const Blur = not not IsBlurred

		for Y = 0, Division_Y - 1 do
			for X = 0, Division_X - 1 do
				const Index = (Y + 1) + Division_Y * X
				const Patch = Context.Patches[Index]

				const SubeaselSize_X = Patch.Size.X / Resolution.X
				const SubeaselSize_Y = Patch.Size.Y / Resolution.Y
				const Subeasel = Instance.new('ImageLabel')
				Subeasel.Name = '[' .. X .. ', ' .. Y .. ']'
				Subeasel.Size = UDim2.fromScale(SubeaselSize_X, SubeaselSize_Y)
				Subeasel.Position = UDim2.fromScale(SubeaselSize_X * X, SubeaselSize_Y * Y)
				Subeasel.BackgroundTransparency = 1
				Subeasel.BorderSizePixel = 0
				Subeasel.ClipsDescendants = true
				Subeasel.ImageContent = Content.fromObject(Patch)
				Subeasel.Parent = Easel

				Subeasel.ResampleMode = if Blur then Resampler.Default else Resampler.Pixelated
			end
		end
	end

	return Easel
end

const function TRACK_MOUSE_INPUTS(Context: ShaderContext, Easel: GuiButton): (() -> ())
	const Configs = Context.Configs
	const Resolution = Context.Resolution
	const OriginOffset = Configs.OriginOffset
	const CountDirection = Configs.CountDirection

	const Mouse = Client:GetMouse()
	const SharedMouse = Registry.getMouse(Context.ID) :: SharedMouse

	if SharedMouse.Tracked then
		error 'The mouse of the given shader context is already being tracked.'
	end
	
	SharedMouse.Tracked = true

	local MouseHasBeenClicked = false

	const function MouseUpdater(): ()
		const vs = workspace.CurrentCamera.ViewportSize --@ viewport pixel size
		const eas = Easel.AbsoluteSize                  --@ easel absolute pixel size
		const e = vs - eas                              --@ excess viewport space

		const mpx = Mouse.X + Easel.AbsolutePosition.X
		const mpy = Mouse.Y + 48 + e.Y / 2
		const mp = Vector2(mpx, mpy)

		const rmp = mp - e                              --@ relative mouse position (to easel)
		const prc = (rmp / eas * Resolution):Ceil()     --@ mouse position relative to canvas size

		-- * account for the pixel mapping
		const vo = OriginOffset * Resolution            --@ virtual origin
		const vp = vo + CountDirection * prc            --@ (the fragCoord the mouse is at)
		
		SharedMouse.x = vp.X
		SharedMouse.y = vp.Y

		if MouseHasBeenClicked then
			SharedMouse.z = -1
		end
	end

	local MoveConnection: RBXScriptConnection? = nil

	const function ConnectMoveConnection(): ()
		MouseUpdater()
		MoveConnection = Mouse.Move:Connect(MouseUpdater)
		SharedMouse.z = 1
		
		task.wait()
		MouseHasBeenClicked = true
	end
	
	const function DisconnectMoveConnection(): ()
		if not MoveConnection then return end
		MoveConnection:Disconnect()
		MoveConnection = nil
		SharedMouse.z = 0
		MouseHasBeenClicked = false
	end

	-- Only consider input when mouse is at the display (i.e. easel).
	const MouseButton1DownConnection = Easel.MouseButton1Down:Connect(ConnectMoveConnection)
	const MouseButton1UpConnection = Easel.MouseButton1Up:Connect(DisconnectMoveConnection)
	const MouseLeaveConnection = Easel.MouseLeave:Connect(DisconnectMoveConnection)
	const DestroyingConnection = Easel.Destroying:Connect(DisconnectMoveConnection)

	return function(): ()
		MouseButton1DownConnection:Disconnect()
		MouseButton1UpConnection:Disconnect()
		MouseLeaveConnection:Disconnect()
		DestroyingConnection:Disconnect()
	end
end

-- Destroys the shader context and halts all dependent operations.
const function DESTROY(Context: ShaderContext): ()
	for _, Actor in Context.Workers do
		Actor:SendMessage('Stop')
	end

	for _, Patch in Context.Patches do
		Patch:Destroy()
	end

	const ShaderID = Context.ID
	Registry.setMouse(ShaderID, nil)
	Registry.setChannels(ShaderID, nil)

	Context.Industry:Destroy()
	table.clear(Context)
end

return {
	VERSION = VERSION;

	new     = NEW;
	destroy = DESTROY;

	stop    = STOP;
	start   = START;
	pause   = PAUSE;
	resume  = RESUME;
	set     = SET;

	createDisplay = CREATE_DISPLAY;
	trackMouseInputs = TRACK_MOUSE_INPUTS;
}