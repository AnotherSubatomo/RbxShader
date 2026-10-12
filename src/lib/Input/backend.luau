
-- Part of the Input library that should not be accessed by external users.
--!strict
--!optimize 2
--!native

local Asset = game:GetService('AssetService')
local UserInput = game:GetService('UserInputService')
local STRegistry = game:GetService('SharedTableRegistry')
local common = require(script.Parent.common)
local stalloc = SharedTable.new
local talloc = table.create

type uint = common.uint
type Sampler2D = common.Sampler2D
type Sampler3D = common.Sampler3D
type Channel = common.Channel

local KEYBOARD_REF = 'RbxShader@Keyboard'
local KEYBOARD_INPUT_TYPE = Enum.UserInputType.Keyboard
local LAST_KEYCODE = common.MaxKeycodeIndex
local KeycodeIndex = common.KeycodeIndex

local KEY_STATE_MASK = 0xff
local KEY_STATE_INV_MASK = bit32.bnot(KEY_STATE_MASK)
local KEY_PRESS_MASK = 0xff00
local KEY_PRESS_INV_MASK = bit32.bnot(KEY_PRESS_MASK)
local KEY_TOGGLE_MASK = 0xff0000

const function FetchKeyboardSampler(): (Sampler2D)
	local Keyboard = STRegistry:GetSharedTable(KEYBOARD_REF) :: Sampler2D

	if Keyboard.Buffer == nil then
		local X = LAST_KEYCODE
		Keyboard = (stalloc { Buffer = talloc(X, 0), X = X, Y = 1 }) :: Sampler2D

		local Buffer = Keyboard.Buffer :: SharedTable

		UserInput.InputBegan:Connect( function(input, processed)
			if processed or input.UserInputType ~= KEYBOARD_INPUT_TYPE then return end
			local Index = KeycodeIndex[input.KeyCode]
			local RGBA = Buffer[Index]

			RGBA = bit32.bor(RGBA, KEY_STATE_MASK, KEY_PRESS_MASK)
			RGBA = bit32.bxor(RGBA, KEY_TOGGLE_MASK)
			Buffer[Index] = RGBA

			-- * four frame delay
			task.wait(3/60)

			RGBA = bit32.band(RGBA, KEY_PRESS_INV_MASK)
			Buffer[Index] = RGBA
		end)

		UserInput.InputEnded:Connect( function (input, processed)
			if processed or input.UserInputType ~= KEYBOARD_INPUT_TYPE then return end
			local Index = KeycodeIndex[input.KeyCode]
			local RGBA = Buffer[Index]
			RGBA = bit32.band(RGBA, KEY_STATE_INV_MASK)
			Buffer[Index] = RGBA
		end)

		STRegistry:SetSharedTable(KEYBOARD_REF, Keyboard)
	end

	return Keyboard
end

function Sampler2D(X: uint, Y: uint): (Sampler2D)
	local SamplerBuff = talloc(X * Y, 0)
	return (stalloc({ Buffer = SamplerBuff, X = X, Y = Y }) :: any) :: Sampler2D
end

function Sampler2D_fromImage(ImageID: Content): (Sampler2D)
	local Image = Asset:CreateEditableImageAsync(ImageID)
	local ImageSize = Image.Size
	local Sampler = Sampler2D(ImageSize.X, ImageSize.Y)
	local SamplerBuff = Sampler.Buffer :: {number}
	local ImgBuff = Image:ReadPixelsBuffer(Vector2.zero, ImageSize)

	for i = 1, ImageSize.X * ImageSize.Y do
		SamplerBuff[i] = buffer.readu32(ImgBuff, (i - 1) * 4)
	end

	Image:Destroy()
	return Sampler
end

function AllocateChannel(Allocator: any, Resolution: Vector2): (Channel?)
	local AllocType = typeof(Allocator)

	if Allocator == Enum.UserInputType.Keyboard then
		return FetchKeyboardSampler()
		
	elseif AllocType == 'Content' then
		if Allocator.Uri == nil then return warn '' end
		return Sampler2D_fromImage(Allocator)

	elseif AllocType == 'table' then
		local Buffer = (Allocator :: {any})[1] :: common.PixelArray
		local Dimension = vector.max((Allocator :: {any})[2] :: vector, vector.one)
		local N = Dimension.x * Dimension.y * Dimension.z

		assert(#Buffer == N, 'What the fuck')
		
		local Sampler = stalloc {
			Buffer = Buffer,
			X = Dimension.x,
			Y = Dimension.y,
			Z = Dimension.z
		} :: Channel
		
		return Sampler

	elseif AllocType == 'string' then
		return Sampler2D(Resolution.X, Resolution.Y)

	else return end
end

return {
	AllocateChannel = AllocateChannel
}