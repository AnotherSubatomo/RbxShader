
--[=[
	BismuthCrystals
	Shader by @jarble on https://www.shadertoy.com/view/NdsXzl
	Ported to Luau — ran by my engine — `RbxShader`.
	
	( Original comments are preserved. )
]=]

--!native

local g = require(game.ReplicatedStorage.RbxShader.GraphicsMathLib)
local vec2 = Vector2.new
local vec3 = Vector3.new

-- // #defines
local ITERS = 12

-- // Pixel shader
return {
	CONFIGURATION = {
		InterlaceFactor = 2 ,
		ScreenDivision = 4
	};
	-- // Image buffer
	mainImage = function (
		fragColor : Vector3 ,
		fragCoords : Vector2 ,
		iTime : number ,
		iTimeDelta : number ,
		iResolution : Vector2 ,
		iMouse : Vector2
	)
		fragColor = Vector3.zero;
		local col : Vector3		= Vector3.zero;
		local colPrev : Vector3	= Vector3.zero;
		local t : number		= 0;
		local uv : Vector2		= (fragCoords*10 - iResolution) / iResolution.Y / 15;
		uv = vec2(uv.X, uv.Y + iTime / 25);

		for c = 1, ITERS do
			local scale : number	= 2.1;
			local scale1 : number	= 1.13;
			local s1 : number		= scale1*scale;
			colPrev = col;
			
			for i = 1, ITERS do
				uv = g.fract_v2((-uv) - vec2(
					uv.X/scale - uv.Y/scale1,
					uv.Y/scale - uv.X/scale1
				) / scale) / scale1;
				uv = vec2(uv.X * scale1, uv.Y);
				uv = g.fract_v2(g.yx(-uv)/s1)*s1;

				uv = vec2(uv.X, uv.Y / -scale1);
				-- // scale1 += (uv.X*(.0005*g.fract(uv.X+iTime/4)));
			end
			col = vec3(col.X, g.abs(g.fract(uv.Y)-g.fract(uv.X)), col.Z);
			--//			  g.fract((uv.Y)-(uv.X));
			col = (col+g.yzx(colPrev)) / 2.125;
		end
		
		return g.v3_rgb(col*3);
	end
}