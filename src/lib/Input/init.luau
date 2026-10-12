
--[=[
	Input
	Reimplementation of texture and volume sampling
	functions from GLSL in Luau	such that accesses
	can be done in parallel environments.

	There are 4 types of sampleable inputs: keyboard, buffer, sampler2D, and sampler3D.
	They're all just a bunch of 2D and 3D textures, but differ in nuances.

	The keyboard refers to a specific 2D texture, such that:
		Row 0: contain the current state of the 170 keys. 
		Row 1: contains Keypress.
		Row 2: contains a toggle for every key.
		The possible keys sampleable are those found at
		Enum.KeyCode:GetEnumItems() from item 1 to 170.
		To specify this channel in the CHANNELS table, simply enter:
		`[nth_channel] = Enum.UserInputType.Keyboard`
	
	A buffer refers 2D textures that get recalculated per frame, similar
	to the `mainImage` fragment operator, hence needing a 

	Allocator types exist because we cannot immediately instanciate
	these channels at program definition as the program is unpacked in
	various thread runtimes. Doing so will cause multiple instances
	of such to exist, consuming unecessary memory. Hence, "allocator".

	EXAMPLE:
	```
	CHANNELS = {
		Enum.UserInputType.Keyboard;                       -- Keyboard
		Content.fromUri(URI);                              -- Texture asset
		`bufferA`;                                         -- Buffer
		{ flarPixelArray2D, vector.create(180, 120) };     -- 2D texture data
		{ flarPixelArray3D, vector.create(180, 120, 90) }; -- 3D texture data
	};
	```
]=]

--!strict
--!optimize 2
--!native

local common = require(script.common)

export type uint = common.uint
export type Sampler2D = common.Sampler2D
export type Sampler3D = common.Sampler3D

-- # Texel fetchers
-- * More verbose than their GLSL counterparts for better inlining.
-- * These functions can be copied and pasted directly into your shader module
--   for better inline compilation.

-- Samples data from 2D textures without interpolation, using pixel coordinates.
const function TexelFetch2D(SamplerBuffer: SharedTable, SamplerWidth: number, X: uint, Y: uint): (vector, uint)
	local RealIndex = (Y) * (SamplerWidth) + (X + 1)
	local Pixel = SamplerBuffer[RealIndex]
	return vector.create(
		-- * somehow more performant than bit32.extract
		bit32.band(Pixel, 0xFF),
		bit32.band(bit32.rshift(Pixel, 8), 0xFF),
		bit32.band(bit32.rshift(Pixel, 16), 0xFF)
	) / 255,
		bit32.band(bit32.rshift(Pixel, 24), 0xFF) / 255
end

-- Samples data from 3D textures without interpolation, using pixel coordinates.
const function TexelFetch3D(SamplerBuffer: SharedTable, SamplerWidth: number, X: uint, Y: uint, Z: uint): (vector, uint)
	local RealIndex = (Z) * (Y) * (SamplerWidth) + (X + 1)
	local Pixel = SamplerBuffer[RealIndex]
	return vector.create(
		-- * somehow more performant than bit32.extract
		bit32.band(Pixel, 0xFF),
		bit32.band(bit32.rshift(Pixel, 8), 0xFF),
		bit32.band(bit32.rshift(Pixel, 16), 0xFF)
	) / 255,
		bit32.band(bit32.rshift(Pixel, 24), 0xFF) / 255
end

-- # Texture fetchers
-- * Not implemented, and probably never will because of how infeasable
--   they would be for any practical usage that aims to be performant.

return {
	TexelFetch2D = TexelFetch2D;
	TexelFetch3D = TexelFetch3D;
	KeycodeIndex = common.KeycodeIndex;
}