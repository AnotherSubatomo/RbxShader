
--[[
	================== RbxShader ===================
	
	Last updated: 12/05/2024
	Version: 1.3.0.b (63) - [Studio Only Beta Release]
	
	Learn how to use the module here: https://devforum.roblox.com/t/rbxshader-tutorial/2965555
	
	Copyright (c) 2024, AnotherSubatomo
	SPDX-License-Identifier: MIT
]]

--!native

-- // Types
export type EngineConfiguration = {
	InterlaceFactor : number ,
	DualAxisInterlacing : boolean ,
	ScreenDivision : number
}

-- // Dependencies
local Run = game:GetService('RunService')
local Client = game.Players.LocalPlayer

-- // Defaults
local ERROR = {
	"SHADER: Configs.ScreenDivision must be divisible by 4 for maximum performance." ,
	"SHADER: Canvas size too big, it's subdivisions are greater than 1024 x 1024 (EditableImage dimension limit)." ,
	"SHADER: CanvasSize was unspecified." ,
	"SHADER: Invalid shader given." ,
	"SHADER: Shaders can't be ran on the server-side. I mean, just why?"
}

local DEFAULT_CONFIGURATIONS = {
	InterlaceFactor = 2 ,
	DualAxisInterlacing = true ,
	ScreenDivision = 16
}

local function GetWorkers ( Engine : LocalScript )
	local Workers = {}

	for _, Child : Instance in Engine:GetChildren() do
		if Child:IsA('Actor') then table.insert(Workers, Child) end
	end

	return Workers
end

local RbxShader = {}

-- /* Create the environment for running the shader. */
function RbxShader.new(
	Parent : LocalScript ,
	CanvasSize : Vector2 ,
	Configuration : EngineConfiguration? ,
	Shader : ModuleScript
)
	-- /* Set default values */
	Configuration = Configuration or require(Shader).CONFIGURATION or DEFAULT_CONFIGURATIONS
	
	-- /* Screen can only be divided into multiples-of-4 parts */
	assert( Configuration.ScreenDivision % 4 == 0 , ERROR[1] )
	assert( CanvasSize , ERROR[3] )
	assert( typeof(Shader) == 'Instance' and Shader:IsA('ModuleScript') , ERROR[4] )
	
	-- /* Calculate the dimensions of each subdivisions */
	local Subdivisions = Vector2.new(Configuration.ScreenDivision / 4, 4)
	local SubcanvasSize = CanvasSize / Subdivisions
		  SubcanvasSize = Vector2.new( math.floor(SubcanvasSize.X), math.floor(SubcanvasSize.Y) )
	local SubeaselScale = SubcanvasSize / CanvasSize
	
	assert( SubcanvasSize:Max((Vector2.one*1025)) == Vector2.one*1025 , ERROR[2] )
	
	-- /* Create the screen from where we'll drawn on */
	local Screen = Instance.new('ScreenGui')
	Screen.Parent = Client.PlayerGui
	Screen.IgnoreGuiInset = true
	Screen.ResetOnSpawn = false
	Screen.Name = 'Screen@'..Shader.Name

	local Background = Instance.new('Frame')
	Background.Parent = Screen
	Background.Size = UDim2.fromScale(1, 1)
	Background.BackgroundColor3 = Color3.new()
	Background.Name = 'Background'
	
	local Centerer = Instance.new('UIListLayout')
	Centerer.Parent = Background
	Centerer.HorizontalAlignment = 'Center'
	Centerer.VerticalAlignment = 'Center'

	local Easel = Instance.new('Frame')
	Easel.Parent = Background
	Easel.Size = UDim2.fromScale(1, 1)
	Easel.BackgroundTransparency = 1
	Easel.Name = 'Easel'
	
	local AspectRatio = Instance.new('UIAspectRatioConstraint')
	AspectRatio.Parent = Easel
	AspectRatio.AspectRatio = CanvasSize.X / CanvasSize.Y
	
	-- /* Parallelize canvas calculations */
	local Workers = {}
	
	-- # Create worker threads
	for i = 1, Configuration.ScreenDivision do
		local Actor = Instance.new('Actor')
		script.Worker:Clone().Parent = Actor
		table.insert(Workers, Actor)
	end
	
	script.Worker:Destroy()
	
	-- # Parent all actors under self
	for _, Actor : Actor in Workers do
		Actor.Parent = Parent
	end
	
	task.defer( function ()
		-- /* Create the subcanvases */
		for y = 1, Subdivisions.Y do
			for x = 1, Subdivisions.X do
				local Actor = Workers[y+4*(x-1)]
				Actor.Worker.Name = 'Worker@'..y+4*(x-1)
				
				Actor:SendMessage( 'Draw', Easel , SubeaselScale, SubcanvasSize , Vector2.new(x, y) )
			end
		end
		
		-- /* Set rendering context */
		for y = 1, Subdivisions.Y do
			for x = 1, Subdivisions.X do
				local Actor = Workers[y+4*(x-1)]
				Actor:SendMessage(
					'Set' , CanvasSize, Shader,
					Configuration.InterlaceFactor ,
					Configuration.DualAxisInterlacing
				)
			end
		end
	end)
end



-- /* Halts a shader from running. */
function RbxShader.stop(
	Engine : LocalScript
)
	local Workers = GetWorkers( Engine )
	
	for _, Actor : Actor in Workers do
		Actor:SendMessage('Stop')
	end
end



-- /* Runs a shader. (Not a resume function) */
function RbxShader.run(
	Engine : LocalScript
)
	local Workers = GetWorkers( Engine )

	task.defer( function ()
		for _, Actor : Actor in Workers do
			Actor:SendMessage('Run')
		end
	end)
end



-- /* Retrieve the graphics-specific math library. */
function RbxShader:GetMathLib()
	return require(script.GraphicsMathLib)
end



assert( Run:IsClient() , ERROR[5] )

return RbxShader
