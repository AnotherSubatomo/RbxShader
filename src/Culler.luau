
--[=[
	Culler
	While it doesn't necessarily "cull", it optimizes
	Billboard and Surface GUIs that have scripts connected
	to them by providing an interface that allows their
	scripts to stop whenever they are out of sight.

	Author: AnotherSubatomo (GitHub)
	SPDX-License-Identifier: MIT
]=]

--!native

type CullInfo = {
	UI : SurfaceGui | BillboardGui ,
	OnRender : () -> any ,
	OnUnrender : () -> any ,
	Rendered : boolean
}

local Run = game:GetService('RunService')
local Camera = workspace.CurrentCamera

local CullInfoMap : { [string] : CullInfo } = {}
local Culler = {}

-- /* Adds a GUI to the bucket of GUI's
--	  that will be decisively culled. */
function Culler.add(
	GUI : BillboardGui | SurfaceGui ,
	UID : string ,
	RenderCallback : () -> any ,
	UnrenderCallback : () -> any
)
	CullInfoMap[UID] = {
		UI = GUI;
		OnRender = RenderCallback;
		OnUnrender = UnrenderCallback;
		Rendered = true;
	}
end

-- /* Removes a GUI from the bucket. */
function Culler.remove( UID : string )
	local CullInfo = CullInfoMap[UID]
	table.clear(CullInfo)
	CullInfoMap[UID] = nil
end


-- /* Decides whether the GUI should be culled or not. */
local function ShouldRender( Should : boolean , CullInfo : CullInfo )
	-- # Will not cull or render if it is already rendered or culled.
	if Should and not CullInfo.Rendered then
		CullInfo.OnRender()
		CullInfo.Rendered = true
	elseif not Should and CullInfo.Rendered then
		CullInfo.OnUnrender()
		CullInfo.Rendered = false
	end
end

-- /* Cull loop */
Run.Heartbeat:Connect( function ()
	for _ , CullInfo : CullInfo in CullInfoMap do
		local UI = CullInfo.UI
		local Adornee = UI.Adornee
		local MaxDistance = UI.MaxDistance

		if not Adornee and UI:IsA('SurfaceGui') then
			Adornee = UI.Parent:IsA('BasePart') and UI.Parent or nil
		end

		if Adornee == nil then return end
		
		local _, IsOnScreen = workspace.CurrentCamera:WorldToViewportPoint(Adornee.Position)
		local Distance = (Camera.CFrame.Position - (Adornee :: BasePart).Position).Magnitude
		ShouldRender(IsOnScreen and Distance < MaxDistance, CullInfo)
	end
end)

assert( Run:IsClient() )
return Culler