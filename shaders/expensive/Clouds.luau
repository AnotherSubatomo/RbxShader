
--[=[
	Clouds
	Shader by @zxxuan1001 on https://www.shadertoy.com/view/tlB3zK
	Ported to Luau — ran by my engine — `RbxShader`.
	
	( Original comments are preserved. )
]=]

--!native

local g = require(game.ReplicatedStorage.RbxShader.GraphicsMathLib)
local vec2 = Vector2.new
local vec3 = Vector3.new

-- // noise function from iq: https://www.shadertoy.com/view/Msf3WH
function hash( p : Vector2 ) : Vector2
	p = vec2( p:Dot(vec2(127.1,311.7)), p:Dot(vec2(269.5,183.3)) );
	return Vector2.one * -1.0 + 2.0*g.fract_v2(g.sin_v2(p)*43758.5453123);
end

function noise( inv : { p : Vector2 } ) : number
	local K1 = 0.366025404;	-- // (sqrt(3)-1)/2;
    local K2 = 0.211324865;	-- // (3-sqrt(3))/6;

	local i : Vector2	= ( inv.p + Vector2.one * (inv.p.X+inv.p.Y)*K1 ):Floor();
    local a : Vector2	= inv.p - i + Vector2.one * (i.X+i.Y)*K2;
    local m : number	= g.step(a.Y,a.X); 
    local o : Vector2	= vec2(m,1.0-m);
    local b : Vector2	= a - o + Vector2.one * K2;
	local c : Vector2	= a - Vector2.one + Vector2.one * 2.0*K2;
    local h : Vector3	= (Vector3.one * 0.5 - vec3(a:Dot(a), b:Dot(b), c:Dot(c))):Max(Vector3.zero);	-- might cause problems
	local n : Vector3	= h*h*h*h*vec3( a:Dot(hash(i)), b:Dot(hash(i+o)), c:Dot(hash(i+Vector2.one)));
    return n:Dot(vec3(70.0));
end

local function applyMatrix( p : Vector2 ) : Vector2
	return vec2(
		1.6 * p.X + -1.2 * p.X,
		1.2 * p.Y + 1.6 * p.Y
	);
end

function fbm4( p : Vector2 ) : number
	local amp : number	= 0.5;
	local h : number	= 0;

	local inv = {p = p};
	for i = 1, 4 do
		local n : number = noise(inv);
		h += amp * n;
		amp *= 0.5;
		inv.p = applyMatrix(inv.p);
	end
	
	return 0.5 + 0.5*h;
end

-- // Fragment shader
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
		iMouse = vec2(iMouse.X, iMouse.Y);

		-- // Normalized pixel coordinates (from 0 to 1)
		local uv : Vector2	= fragCoords/iResolution;
		uv = vec2( (uv.X - 0.5) * iResolution.X/iResolution.Y, uv.Y - 0.5 );
		local mo : Vector2	= iMouse/iResolution;
		local sky : Vector3	= vec3(0.5, 0.7, 0.8);
		local col : Vector3	= vec3(0.0);

		-- // speed
    	local v : number = 0.001;

		-- // layer1
		local cloudCol : Vector3	= Vector3.one;
		uv += mo * 10;

		local uv10 : Vector2		= uv * 10;
		local scale : Vector2		= uv * 2;
		local turbulence : Vector2	= 0.008 * vec2(noise({p=uv10}), noise({p=uv10}));
		scale += turbulence;
		local n1 : number	= fbm4(vec2(scale.X - 20 * g.sin(iTime * v * 2), scale.Y - 50 * g.sin(iTime * v)));
		col = g.mix_v3( sky, cloudCol, g.smoothstep(0.5, 0.8, n1));

		-- // layer2
		scale = uv * 0.5;
		turbulence = 0.05 * vec2(noise({p=vec2(uv.X * 2.0, uv.Y * 2.1)}), noise({p=vec2(uv.X * 1.5, uv.Y * 1.2)}));
		scale += turbulence;
		local n2 : number	= fbm4(scale + Vector2.one * 20.0 * g.sin(iTime * v));
		col =  g.mix_v3( col, cloudCol, g.smoothstep(0.2, 0.9, n2));
		col = col:Min(Vector3.one);

		-- // Output to screen
		return g.v3_rgb(col)
	end
}

