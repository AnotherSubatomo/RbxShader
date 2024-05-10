
--[[
	================== RbxShader Multithreaded ===================
	
	Last updated: 10/05/2024
	Version: 1.1.0.b (44) - [Studio Only Beta Release]
	
	Learn how to use the module here: https://devforum.roblox.com/t/...
	Detailed API Documentation: https://devforum.roblox.com/t/...
	
	Copyright (c) 2024, AnotherSubatomo
	SPDX-License-Identifier: MIT
]]

--!native

-- // Types
export type EngineConfiguration = {
	InterlaceFactor : number ,
	ScreenDivision : number
}

export type Shader = ModuleScript

-- // Dependencies
local Run = game:GetService('RunService')
local Client = game.Players.LocalPlayer

-- // Defaults
local ERROR = {
	"GL: Configs.ScreenDivision must be divisible by 4 for maximum performance." ,
	"GL: Canvas size too big, it's subdivisions are greater than 1024 x 1024 (EditableImage dimension limit)." ,
	"GL: CanvasSize was unspecified." ,
	"GL: Invalid shader given." ,
	"GL: Shaders can't be ran on the server-side. I mean, just why?"
}

local DEFAULT_CONFIGURATIONS = {
	InterlaceFactor = 4 ,
	ScreenDivision = 16
}


local RbxGL = {}

-- // Run a shader
function RbxGL.new(
	Parent : LocalScript ,
	CanvasSize : Vector2 ,
	Configuration : EngineConfiguration? ,
	Shader : Shader
)
	Configuration = Configuration or DEFAULT_CONFIGURATIONS
	
	assert( Configuration.ScreenDivision % 4 == 0 , ERROR[1] )
	assert( CanvasSize , ERROR[3] )
	assert( typeof(Shader) == 'Instance' and Shader:IsA('ModuleScript') , ERROR[4] )
	
	local Subdivisions = Vector2.new(Configuration.ScreenDivision / 4, 4)
	local SubcanvasSize = CanvasSize / Subdivisions
	SubcanvasSize = Vector2.new( math.floor(SubcanvasSize.X), math.floor(SubcanvasSize.Y) )
	local SubeaselScale = SubcanvasSize / CanvasSize
	
	assert( SubcanvasSize:Max((Vector2.one*1025)) == Vector2.one*1025 , ERROR[2] )
	
	local Screen = Instance.new('ScreenGui')
	Screen.Parent = Client.PlayerGui
	Screen.IgnoreGuiInset = true
	Screen.Name = 'Screen'

	local Background = Instance.new('Frame')
	Background.Parent = Screen
	Background.Size = UDim2.fromScale(1, 1)
	Background.BackgroundColor3 = Color3.new()
	
	local Centerer = Instance.new('UIListLayout')
	Centerer.Parent = Background
	Centerer.HorizontalAlignment = 'Center'
	Centerer.VerticalAlignment = 'Center'

	local Easel = Instance.new('Frame')
	Easel.Parent = Background
	Easel.Size = UDim2.fromScale(1, 1)
	Easel.BackgroundTransparency = 1
	
	local AspectRatio = Instance.new('UIAspectRatioConstraint')
	AspectRatio.Parent = Easel
	AspectRatio.AspectRatio = CanvasSize.X / CanvasSize.Y
	
	-- // Parallelize canvas calculations
	local Workers = {}
	
	-- /* Create worker threads */
	for i = 1, Configuration.ScreenDivision do
		local Actor = Instance.new('Actor')
		script.Worker:Clone().Parent = Actor
		table.insert(Workers, Actor)
	end
	
	script.Worker:Destroy()
	
	-- /* Parent all actors under self */
	for _, Actor : Actor in Workers do
		Actor.Parent = Parent
	end
	
	task.defer( function ()
		-- /* Create the subcanvases */
		for y = 1, Subdivisions.Y do
			for x = 1, Subdivisions.X do
				local Actor = Workers[y+4*(x-1)]
				Actor.Worker.Name = 'Worker@'..y+4*(x-1)
				
				local SubeaselOffset = Vector2.new(x-1, y-1)
				Actor:SendMessage( 'Draw', Easel , SubeaselScale, SubeaselOffset, SubcanvasSize )
			end
		end
	end)
	
	task.defer( function ()
		-- /* Render parallel */
		for y = 1, Subdivisions.Y do
			for x = 1, Subdivisions.X do
				local Actor = Workers[y+4*(x-1)]
				
				local SubcanvasOffset = Vector2.new(x-1, y-1) * SubcanvasSize
				Actor:SendMessage( 'Run' , CanvasSize, SubcanvasOffset, Shader, Configuration.InterlaceFactor )
			end
		end
	end)
end

function RbxGL.stop(
	Engine : LocalScript
)
	local Workers = {}
	
	for _, Child : Instance in Engine:GetChildren() do
		if Child:IsA('Actor') then table.insert(Workers, Child) end
	end
	
	for _, Actor : Actor in Workers do
		Actor:SendMessage('Stop')
	end
end

function RbxGL:GetMathLib()
	return require(script.GraphicsMathLib)
end

assert( Run:IsClient() , ERROR[5] )

return RbxGL
