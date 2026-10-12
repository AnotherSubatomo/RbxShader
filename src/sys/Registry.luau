
--[=[
	Registry
	Where structured tables shared across scripts of
	different execution environment are accessed or set.
]=]

--!strict
--!optimize 2
--!native

const common = require(script.Parent.Parent.common)
const STRegistry = game:GetService('SharedTableRegistry')

const MOUSE_REF = '@Mouse'
const CHANNELS_REF = '@Channels'

type SharedMouse = common.SharedMouse
type Channels = common.Channels

const function SetMouse(ShaderID: string, Shared: SharedMouse?): ()
	STRegistry:SetSharedTable(ShaderID..MOUSE_REF, Shared)
end

const function SetChannels(ShaderID: string, Shared: Channels?): ()
	STRegistry:SetSharedTable(ShaderID..CHANNELS_REF, Shared :: SharedTable?)
end

const function GetMouse(ShaderID: string): (SharedMouse)
	return STRegistry:GetSharedTable(ShaderID..MOUSE_REF) :: SharedMouse
end

const function GetChannels(ShaderID: string): (Channels)
	return STRegistry:GetSharedTable(ShaderID..CHANNELS_REF)
end


return {
	setMouse = SetMouse,
	setChannels = SetChannels,
	getMouse = GetMouse,
	getChannels = GetChannels,
}