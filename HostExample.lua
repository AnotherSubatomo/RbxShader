
--[=[
	Host
	A sample script on how you would
  run a shader.
]=]

--!native

-- // Dependencies
local RbxShader = require(game.ReplicatedStorage.RbxShader)

-- // Configurations
local CONFIGURATIONS = {
	InterlaceFactor = 2 ,
	DualAxisInterlacing = true ,
	ScreenDivision = 16
}

local CANVAS_SIZE = Vector2.new(180, 120)
local SHADER = script.GravitySucks

RbxShader.new( script , CANVAS_SIZE , CONFIGURATIONS , SHADER )
RbxShader.run( script )

task.wait(5)

RbxShader.stop( script )

task.wait(5)

RbxShader.run( script )
