
--[=[
	NaiveRaycast
	Pixelizes the game environment by naively raycasting.
	
	NOTE:
	- there is something very wrong with how I calculate
	  material reflectance
]=]

--!native

local g = require(game.ReplicatedStorage.RbxShader.GraphicsMathLib)
local Camera = workspace.CurrentCamera

-- // #defines
local SKY_COLOR = Color3.fromRGB(117, 202, 255)
local ZOOM = 6
local CANVAS_SIZE = Vector2.new(180, 120) * ZOOM

local Offset = (Camera.ViewportSize - CANVAS_SIZE) / 2

-- // Make screen size dynamically change
Camera:GetPropertyChangedSignal('ViewportSize'):Connect( function()
	Offset = (Camera.ViewportSize - CANVAS_SIZE) / 2
end)

-- // Fragment shader
return {
	CONFIGURATION = {
		InterlaceFactor = 2 ,
		ScreenDivision = 4 ,
		OriginOffset = Vector2.zero ,
		CountDirection = Vector2.one
	};
	-- // Image buffer
	mainImage = function (
		fragColor : Vector3 ,
		fragCoords : Vector2 ,
		iTime : number ,
		iTimeDelta : number ,
		iResolution : Vector2
	)
		local Raycast = Camera:ScreenPointToRay(
			Offset.X + fragCoords.X * ZOOM ,
			Offset.Y + fragCoords.Y * ZOOM
		)
		
		local RaycastResult = workspace:Raycast( Raycast.Origin, Raycast.Direction * 500 )
		
		if RaycastResult then
			if RaycastResult.Instance:IsA('Terrain') then
				fragColor = workspace.Terrain:GetMaterialColor( RaycastResult.Material )
			else
				fragColor = RaycastResult.Instance.Color
				
				if RaycastResult.Material == Enum.Material.Glass or RaycastResult.Material == Enum.Material.Metal then
					local refColor = nil
					local Reflectance = RaycastResult.Instance.Reflectance
					local Direction = g.reflect(RaycastResult.Position, RaycastResult.Normal)
					local ReflectanceResult = workspace:Raycast(RaycastResult.Position, Direction * 500)
					
					if ReflectanceResult then
						if ReflectanceResult.Instance:IsA('Terrain') then
							refColor = workspace.Terrain:GetMaterialColor( ReflectanceResult.Material )
						else
							refColor = ReflectanceResult.Instance.Color
						end
					else
						refColor = SKY_COLOR
					end
					
					-- /* Match reflectance property. */
					fragColor = Color3.new(g.c3(fragColor)):Lerp( refColor, Reflectance )
				end
			end
			
			-- /* Shadowing */
			fragColor = fragColor:Lerp( Color3.fromRGB(33, 33, 33), 1 - ((RaycastResult.Normal.Y + 1) / 2) )
			
			-- /* Motion blur */
		else
			fragColor = SKY_COLOR
		end
		
		return g.c3_rgb(fragColor)
	end,
}