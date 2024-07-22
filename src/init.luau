
--[[
	================== RbxShader ===================
	
	Last updated: 19/07/2024
	Version: 1.5.2.b (106) - [Studio Only Beta Release]
	
	Learn how to use the module here: https://devforum.roblox.com/t/rbxshader-tutorial/2965555
	
	Copyright (c) 2024, AnotherSubatomo
	SPDX-License-Identifier: MIT
]]

--!native
--!strict

-- // Types
local Types = require(script.Common)
export type EngineConfiguration = Types.EngineConfiguration
export type ShaderBuffer = Types.ShaderBuffer
export type Shader = Types.Shader

-- // Dependencies
local STRegistry = game:GetService('SharedTableRegistry')
local Run = game:GetService('RunService')
local Culler = require(script.Culler)

local Client = game.Players.LocalPlayer
local Mouse = Client:GetMouse()

-- // Defaults
local ERROR = {
	"SHADER: Configs.ScreenDivision must be divisible by 4 for maximum performance." ,
	"SHADER: Canvas size too big, it's subdivisions are greater than 1024 x 1024 (EditableImage dimension limit)." ,
	"SHADER: CanvasSize was unspecified." ,
	"SHADER: Invalid shader given." ,
	"SHADER: Shaders can't be ran on the server-side. I mean, just why?" ,
	"SHADER: A ShaderID is necessary in manipulating specific shaders that run on the same script." ,
	"SHADER: ShaderID has already been used." ,
	"SHADER: Given ShaderID to fetch shader is not in use, are you sure it's typed correctly?" ,
	"SHADER: Canvas size too small, minimum size is 4 x 4." ,
	"SHADER: Given screen to display the shader in was invalid."
}

local DEFAULT_CONFIGURATIONS = {
	InterlaceFactor = 2 ,
	DualAxisInterlacing = true ,
	ScreenDivision = 16
}

local MoveConnections = {}
local ShaderIDs = {}
local RbxShader = {}

-- /* Create the environment for running the shader. */
function RbxShader.new(
	Host : Script ,
	Screen : GuiBase2d ,
	CanvasSize : Vector2 ,
	Configuration : EngineConfiguration? ,
	Shader : ModuleScript ,
	ShaderID : string
)
	-- /* Set default values */
	Configuration = Configuration or {}
	
	local BuiltConfiguration = require(Shader).CONFIGURATION
	
	for Field : string , Default : any in DEFAULT_CONFIGURATIONS do
		Configuration[Field] = Configuration[Field] or BuiltConfiguration[Field] or Default
	end
	
	-- /* Screen can only be divided into multiples-of-4 parts */
	assert( Configuration.ScreenDivision % 4 == 0 , ERROR[1] )
	assert( CanvasSize , ERROR[3] )
	assert( typeof(Shader) == 'Instance' and Shader:IsA('ModuleScript') , ERROR[4] )
	assert( CanvasSize:Min(Vector2.one*4) == Vector2.one*4 , ERROR[9] )
	
	-- /* Calculate the dimensions of each subdivisions */
	local Subdivisions = Vector2.new(Configuration.ScreenDivision / 4, 4)
	local SubcanvasSize = (CanvasSize / Subdivisions):Floor()
	local ExcessSize = CanvasSize - SubcanvasSize * Subdivisions
	
	assert( SubcanvasSize:Max((Vector2.one*1025)) == Vector2.one*1025 , ERROR[2] )
	
	-- /* Create the screen from where we'll drawn on */
	assert( Screen and Screen:IsA('GuiBase2d') , ERROR[10] )
	Screen.Name = 'SHADERSCREEN@'..Shader.Name
	
	local Background = Instance.new('Frame')
	Background.Parent = Screen
	Background.Size = UDim2.fromScale(1, 1)
	Background.BackgroundColor3 = Color3.new()
	Background.Name = 'Background'
	
	local Centerer = Instance.new('UIListLayout')
	Centerer.Parent = Background
	Centerer.HorizontalAlignment = 'Center'
	Centerer.VerticalAlignment = 'Center'

	local Easel = Instance.new('ImageButton')
	Easel.Parent = Background
	Easel.Size = UDim2.fromScale(1, 1)
	Easel.BackgroundTransparency = 1
	Easel.Name = 'Easel'
	Easel.Image = ''
	
	local AspectRatio = Instance.new('UIAspectRatioConstraint')
	AspectRatio.Parent = Easel
	AspectRatio.AspectRatio = CanvasSize.X / CanvasSize.Y

	-- /* Create shader host. */
	assert( ShaderID, ERROR[6] )
	assert( not ShaderIDs[ShaderID] , ERROR[7] )

	local Parent = Instance.new('Folder')
	Parent.Parent = Host
	Parent.Name = 'SHADER@'..ShaderID
	ShaderIDs[ShaderID] = Parent
	
	local Link = Instance.new('ObjectValue')
	Link.Parent = Parent
	Link.Value = Screen
	Link.Name = 'ScreenLink'
	
	-- /* Assume inputs are needed */
	local iMouse = SharedTable.new({ X = 1, Y = 1 })
	
	Easel.MouseButton1Down:Connect( function()
		-- # Only consider input when mouse is at the display of the shader.
		MoveConnections[ShaderID] = Mouse.Move:Connect( function ()
			SharedTable.update( iMouse, 'X', function() return Mouse.X end )
			SharedTable.update( iMouse, 'Y', function() return Mouse.Y end )
		end)
	end)

	Easel.MouseButton1Up:Connect( function ()
		if MoveConnections[ShaderID] ~= nil then
			MoveConnections[ShaderID]:Disconnect()
		end
	end)
	
	STRegistry:SetSharedTable(ShaderID..'@Mouse', iMouse)
	
	-- /* Parallelize canvas calculations */
	local Workers = {}
	
	-- # Create worker threads
	for _ = 1, Configuration.ScreenDivision do
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

				local Size : Vector2 = SubcanvasSize
				if y == Subdivisions.Y then Size += Vector2.new(0, ExcessSize.Y) end
				if y == Subdivisions.X then Size += Vector2.new(ExcessSize.X, 0) end

				local Scale : Vector2 = Size / CanvasSize

				Actor:SendMessage( 'MakeCanvas', Easel , Scale, Size , Vector2.new(x, y) )
			end
		end
		
		-- /* Set rendering context */
		for y = 1, Subdivisions.Y do
			for x = 1, Subdivisions.X do
				local Actor = Workers[y+4*(x-1)]
				Actor:SendMessage( 'Initialize' , CanvasSize, Shader, ShaderID , Configuration )
			end
		end
	end)
	
	-- # If `Screen` is a SurfaceGui or BillboardGui, then check
	--	 if the part that the Gui is adorned to is still visible
	--	 on the user viewport or is within the max distance.
	--	 If not, then stop the shader program, but keep the iTime.
	
	local WorldspaceGui = (Screen:IsA('SurfaceGui') or Screen:IsA('BillboardGui')) and Screen
		or Screen:FindFirstChildOfClass('SurfaceGui') or Screen:FindFirstChildOfClass('BillboardGui')
	
	if WorldspaceGui then
		Culler.add(WorldspaceGui, ShaderID, function ()
			for _, Actor : Actor in Workers do
				Actor:SendMessage( 'Resume' , ShaderID )
			end
		end, function ()
			for _, Actor : Actor in Workers do
				Actor:SendMessage( 'Pause' , ShaderID )
			end
		end)
	end
end

--==============================
--[=[ SHADER PROGRAM ACTIONS ]=]
--==============================

local function GetWorkers ( Engine : LocalScript )
	local Workers = {}

	for _, Child : Instance in Engine:GetChildren() do
		if Child:IsA('Actor') then
			table.insert(Workers, Child)
		end
	end

	return Workers
end

local function CallAction(
	Action : string ,
	ShaderID : string
)
	assert( ShaderID, ERROR[6] )
	assert( ShaderIDs[ShaderID], ERROR[8] )

	local Workers = GetWorkers( ShaderIDs[ShaderID] )
	
	task.defer( function ()
		for _, Actor : Actor in Workers do
			Actor:SendMessage( Action )
		end
	end)
end

-- /* Halts a shader from running. */
function RbxShader.stop( ShaderID : string )
	CallAction( 'Stop', ShaderID )
end

-- /* Runs a shader. (Not a resume function) */
function RbxShader.run( ShaderID : string )
	CallAction( 'Run' , ShaderID )
end

-- /* Pauses the shader. */
function RbxShader.pause( ShaderID : string )
	CallAction( 'Pause', ShaderID )
end

-- /* Resumes the shader. */
function RbxShader.resume( ShaderID : string )
	CallAction( 'Resume', ShaderID )
end

-- /* Halts and terminates a shader program. */
function RbxShader.clear( ShaderID : string )
	assert( ShaderID, ERROR[6] )
	assert( ShaderIDs[ShaderID], ERROR[8] )

	local Host = ShaderIDs[ShaderID]
	local Workers = GetWorkers( Host )

	for _, Actor : Actor in Workers do
		Actor:SendMessage( 'Stop' )
	end
	
	Host.ScreenLink.Value:Destroy()
	Host:ClearAllChildren()
	Host:Destroy()
end

-- /* Sets the configuration of the shader to something else. */
function RbxShader.set(
	ShaderID : string ,
	Configuration : EngineConfiguration
)
	assert( ShaderID, ERROR[6] )
	assert( ShaderIDs[ShaderID], ERROR[8] )
	
	local Workers = GetWorkers( ShaderIDs[ShaderID] )
	
	for Field : string , Default : any in DEFAULT_CONFIGURATIONS do
		Configuration[Field] = Configuration[Field] or Default
	end
	
	RbxShader.pause( ShaderID )
	
	for _, Actor : Actor in Workers do
		Actor:SendMessage( 'Set' , Configuration )
	end

	RbxShader.resume( ShaderID )
end



--================================
--[=[ SHADER UTILITY LIBRARIES ]=]
--================================

-- /* Retrieve the graphics-specific math library. */
function RbxShader:GetMathLib()
	return require(script.GraphicsMathLib)
end

-- /* Retrieve the input handling library. */
-- * ADDME: The input library....
function RbxShader:GetInputLib()
	return require(script.InputLib)
end

assert( Run:IsClient() , ERROR[5] )

return RbxShader