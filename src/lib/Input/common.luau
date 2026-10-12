
-- Where types and enums used by Input library's frontend and backend are located.

--!strict
--!optimize 2
--!native

-- Specified primitive types
export type u32 = number
export type uint = u32
export type vec2 = vector
export type vec3 = vector

-- Stuct types
-- A (shared) flat array of u32's such that each item
-- represents the entire RGBA value of a pixel.
export type PixelArray = SharedTable & {[u32]: u32}

-- All types of Samplers are static, meaning that their values
-- are assigned once and never again. ShaderBuffers are similar
-- in definition (such	that their underlying datatype is a buffer)
-- but instead are dynamic, meaning their values change every frame.
export type Sampler2D = SharedTable & {Buffer: PixelArray, X: uint, Y: uint}
export type Sampler3D = SharedTable & {Buffer: PixelArray, X: uint, Y: uint, Z: uint}
export type ShaderBuffer = Sampler2D
export type Channel = Sampler2D | Sampler3D
export type Channels = {Channel}

-- Reverse enum of the KeyCode Enum such that they're
-- spaced next to each other and can fit in a uint8.
local KeycodeIndex: {[Enum.KeyCode]: number} = {}
local Keycodes = Enum.KeyCode:GetEnumItems()
local MaxKeycodeIndex = #Keycodes

for Index, Keycode in Keycodes do
	KeycodeIndex[Keycode] = Index
end

return {
	MaxKeycodeIndex = MaxKeycodeIndex;
	KeycodeIndex = KeycodeIndex;
}