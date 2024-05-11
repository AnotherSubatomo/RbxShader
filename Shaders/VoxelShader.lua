
--[=[
	VoxelShader
	Shader by @Xor on https://www.shadertoy.com/view/fstSRH
	ported to Luau, ran by my engine: RbxShader
]=]

--!native

local g = require(game.ReplicatedStorage.RbxShader.GraphicsMathLib)

local function map ( v : Vector3 , iTime : number )
	return math.sqrt(
		(v.X % 18 - 9)^2 +
			(v.Y % 18 - 9)^2 +
			(v.Z % 18 - 9)^2
	) - 9.5 + g.sin(
		v.Z * 0.3 - iTime * 0.1
	)
end

-- // Fragment shader
return {
	-- // Image buffer
	mainImage = function (
		fragColor : Vector3 ,
		fragCoords : Vector2 ,
		iTime : number ,
		iTimeDelta : number ,
		iResolution : Vector2
	)
		local cam = Vector3.new(
			g.sin(iTime*0.2+iResolution.X),
			g.sin(iTime*0.2+iResolution.Y),
			iTime
		)

		local pos = cam
		local ray = Vector3.new(
			fragCoords.X*2-iResolution.X,
			fragCoords.Y*2-iResolution.Y,
			iResolution.Y
		).Unit
		local cell = Vector3.zero

		-- // Step up to 100 voxels.
		for i = 1, 100 do
			-- // Axis distance to nearest cell (with a small bias).
			local dist = g.fract_v3(-pos * ray:Sign()) + Vector3.one * 1e-4
			-- // Alternative version (produces artifacts after a while)
			-- // vec3 dist = 1-g.fract_v3(pos * sign(ray)),
			-- // Raytraced distance to each axis.
			local leng = dist / ray:Abs()
			-- // Nearest axis' raytrace distance (as a vec3).
			local near = g.min( leng.X, g.min(leng.Y, leng.Z))

			-- // Step to the nearest voxel cell.
			pos += ray * near
			-- // Get the cell position (center of the voxel).
			cell = pos:Ceil() - Vector3.one * 0.5;
			-- // Stop if we hit a voxel.
			if map(cell, iTime) < 0 then
				break
			end
		end

		-- // Rainbow color based off the voxel cell position.
		local color = g.sin_v3(Vector3.new(0,2,4) + Vector3.one * cell.Z) * 0.5 + (Vector3.one * 0.5)
		-- // Square for gamma encoding.
		color *= color;

		-- // Compute cheap ambient occlusion from the SDF.
		local ao = g.smoothstep(-1, 1, map(pos, iTime))
		-- // Fade out to black ug.sing the distance.
		local fog = g.min(1, g.exp(1 - (pos-cam).Magnitude/8))

		-- // Output final color with ao and fog (sqrt for gamma correction).
		fragColor = g.sqrt_v3(color * ao * fog)
		return g.v3_rgb(fragColor)
	end,
}
