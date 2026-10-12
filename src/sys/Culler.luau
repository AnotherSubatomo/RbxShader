
--[=[
	Culler
	While it doesn't necessarily "cull", it optimizes
	Billboard and Surface GUIs that have scripts connected
	to them by providing an interface that allows their
	scripts to stop whenever they are out of sight.

	SPDX-License-Identifier: MIT
	Author: AnotherSubatomo (GitHub)
]=]

--!strict
--!optimize 2
--!native

export type WorldspaceGui = SurfaceGui | BillboardGui
export type GenericCallback = (any) -> (any)

const Run = game:GetService 'RunService'
assert(Run:IsClient(), "Culler: This can only be ran in the client!")

const CullInfoComponent_UI = {}
const CullInfoComponent_OnRender = {}
const CullInfoComponent_OnUnrender = {}
const CullInfoComponent_Rendered = {}

-- Registers the GUI for decisive culling.
const function ADD(
	GUI: WorldspaceGui,
	UID: string,
	RenderCallback: GenericCallback,
	UnrenderCallback: GenericCallback
)
	CullInfoComponent_UI[UID] = GUI;
	CullInfoComponent_OnRender[UID] = RenderCallback;
	CullInfoComponent_OnUnrender[UID] = UnrenderCallback;
	CullInfoComponent_Rendered[UID] = true;
end

-- Deregisters the GUI from the culling list.
const function REMOVE(UID: string)
	CullInfoComponent_UI[UID] = nil
	CullInfoComponent_OnRender[UID] = nil
	CullInfoComponent_OnUnrender[UID] = nil
	CullInfoComponent_Rendered[UID] = nil
end

-- Decides whether the GUI should be culled or not.
const function ShouldRender(Should: boolean, UID: string)
	-- * will not cull or render if it is already rendered or culled.
	if Should and not CullInfoComponent_Rendered[UID] then
		CullInfoComponent_OnRender[UID]()
		CullInfoComponent_Rendered[UID] = true
	elseif not Should and CullInfoComponent_Rendered[UID] then
		CullInfoComponent_OnUnrender[UID]()
		CullInfoComponent_Rendered[UID] = false
	end
end

-- The non-blocking loop for cull checking.
const function CullLoopDaemon(): ()
	const Camera = workspace.CurrentCamera
	if not Camera then return end
	
	for UID , UI in CullInfoComponent_UI do
		local Adornee = (UI.Adornee :: any) :: BasePart?
		const MaxDistance = UI.MaxDistance

		if not Adornee and UI.Parent and UI.Parent:IsA('BasePart') then
			Adornee = UI.Parent
		end

		if Adornee == nil then return end
		
		const _, IsOnScreen = Camera:WorldToViewportPoint(Adornee.Position)
		const Distance = (Camera.CFrame.Position - Adornee.Position).Magnitude
		ShouldRender(IsOnScreen and Distance < MaxDistance, UID)
	end
end

Run.Heartbeat:Connect(CullLoopDaemon)

return {
	add = ADD,
	remove = REMOVE,
}