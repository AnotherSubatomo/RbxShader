
-- Common types found across the scripts.

--!strict
--!optimize 2
--!native

local root = script.Parent
local Input_types = require(root:WaitForChild 'lib' .Input.common)

export type vec3 = vector
export type vec2 = vector
export type iDate = {number}

export type Channel =  Input_types.Channel
export type Channels = Input_types.Channels
export type SharedMouse = SharedTable & {x: number, y: number, z: number, Tracked: boolean}

export type FragmentOperator<vecn> = (
	fragCoord:   vecn,
	iResolution: vec2,
	iTime:       number,
	iDate:       iDate,
	iMouse:      vec2,
	iChannels:   Channels,
	iTimeDelta:  number
) -> (vec3, number)

export type PerFrame = (
	iTime:     number,
	iDate:     iDate,
	iMouse:    vec2,
	iChannels: Channels
) -> ()

export type ShaderInitializer = (iResolution: vec2) -> ()

-- [v3.0.0] You can technically name the buffer to anything now,
-- but it is still recommended to follow the conventional buffer[LETTER]
export type OperatorName = string

export type Shader = {
	read CONFIGURATION:   EngineConfiguration?,
	read CHANNELS:        {any},
	read [OperatorName]:  FragmentOperator<vector>,
	read init:            ShaderInitializer?,
	read perFrame:        PerFrame?,
	read mainImage:       FragmentOperator<vec3>
}

export type EngineConfiguration = {
	InterlaceFactor: number,
	ScreenDivision:  Vector2,
	OriginOffset:    Vector2,
	CountDirection:  Vector2
}

return true