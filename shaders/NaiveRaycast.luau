
--[=[
	NaiveRaycast
	Pixelizes the game environment by naively raycasting.
	
	NOTE:
	- there is something very wrong with how I calculate material reflectance
]=]

--!strict
--!optimize 2
--!native

type vec3 = vector
type vec2 = vector

const function reflect(i: Vector3, n: Vector3): (Vector3)
	return i - 2 * vector.dot(n :: any, i :: any) * n
end

const SKY_COLOR = Color3.fromRGB(117, 202, 255)
const SHADOW_COLOR = Color3.fromRGB(33, 33, 33)
const GLASS = Enum.Material.Glass
const METAL = Enum.Material.Metal
const ZOOM = 6

local CANVAS_SIZE: Vector2 = Vector2.zero
local Offset: Vector2 = Vector2.zero

local rawRBXmemberGet: (any, string) -> (any)
xpcall(function() return game[""] end, function() rawRBXmemberGet = debug.info(2, "f") end)

const Raycast: (
	self: Workspace,
	origin: Vector3,
	direction: Vector3,
	raycastParams: RaycastParams?
) -> (RaycastResult) = rawRBXmemberGet(workspace, 'Raycast')

const Terrain = rawRBXmemberGet(workspace, 'Terrain')

const GetMaterialColor: (
	self: Terrain,
	material: Enum.Material
) -> (Color3) = rawRBXmemberGet(Terrain, 'GetMaterialColor')

const Color3Lerp: (
	self: Color3,
	color: Color3,
	alpha: number
) -> (Color3) = SKY_COLOR.Lerp

const Camera = rawRBXmemberGet(workspace, 'CurrentCamera') :: Camera

-- Make screen size dynamically change
Camera:GetPropertyChangedSignal('ViewportSize'):Connect( function()
	Offset = (rawRBXmemberGet(Camera, 'ViewportSize') :: Vector2 - CANVAS_SIZE) / 2
end)

const ScreenPointToRay: (
	self: Camera,
	x: number,
	y: number,
	depth: number?
) -> (Ray) = rawRBXmemberGet(Camera, 'ScreenPointToRay')

const IsA: (
	self: Instance,
	class: string
) -> (Ray) = rawRBXmemberGet(Camera, 'IsA')

-- Shader program
return {
	CONFIGURATION = {
		OriginOffset = Vector2.zero;
		CountDirection = Vector2.one;
		InterlaceFactor = 2;
		ScreenDivision = Vector2.new(4, 2);
	};
	
	init = function (iResolution: vec2): ()
		CANVAS_SIZE = Vector2.new(iResolution.x * ZOOM, iResolution.y * ZOOM)
		Offset = (rawRBXmemberGet(Camera, 'ViewportSize') :: Vector2 - CANVAS_SIZE) / 2
	end;

	mainImage = function (fragCoords: vec2, _, iTime: number): (vec3, number)
		local fragColor: Color3

		const Ray = ScreenPointToRay( Camera,
			Offset.X + fragCoords.x * ZOOM,
			Offset.Y + fragCoords.y * ZOOM
		)
		
		const RaycastResult = Raycast( workspace, Ray.Origin, Ray.Direction * 500 )

		if RaycastResult then
			if IsA( RaycastResult.Instance, 'Terrain' ) then
				fragColor = GetMaterialColor( Terrain, RaycastResult.Material )
			else
				fragColor = RaycastResult.Instance.Color

				if RaycastResult.Material == GLASS or RaycastResult.Material == METAL then
					local refColor = nil
					const Reflectance = RaycastResult.Instance.Reflectance
					const Direction = reflect( RaycastResult.Position, RaycastResult.Normal )
					const ReflectanceResult = Raycast( workspace, RaycastResult.Position, Direction * 500 )
					
					if ReflectanceResult then
						if IsA( ReflectanceResult.Instance, 'Terrain' ) then
							refColor = GetMaterialColor( Terrain, ReflectanceResult.Material )
						else
							refColor = ReflectanceResult.Instance.Color
						end
					else
						refColor = SKY_COLOR
					end
					
					-- Match reflectance property
					fragColor = Color3Lerp( fragColor, refColor, Reflectance )
				end
			end
			
			-- Shadowing
			fragColor = Color3Lerp( fragColor, SHADOW_COLOR, 1 - ((RaycastResult.Normal.Y + 1) / 2) )
		else
			fragColor = SKY_COLOR
		end
		
		return vector.create(fragColor.R, fragColor.G, fragColor.B), 1;
	end;
}