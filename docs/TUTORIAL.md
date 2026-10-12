
## Shader Programming

A *shader program* for RbxShader is some Luau code at a `ModuleScript`, whose content is — at its simplest form — is defined in the following format:
```lua
-- this is the "shader program"
return {
	mainImage = function (
		fragColor: Vector3,
		fragCoords: Vector2,
		iTime: number,
		iTimeDelta: number,
		iResolution: Vector2,
		iMouse: Vector2,
		
	)
		-- do some calculations onto `fragColor`...
		-- then return the individual RGBA colors
		-- * if the alpha is missing, it is assumed to be 1.
		return fragColor.X, fragColor.Y, fragColor.Z;
	end
}
```

Please bear in mind that our definition of a *shader program* does not fit the traditional definition of one; rather, this is somewhat a glorified [fragment shader](https://stackoverflow.com/questions/4421261/vertex-shader-vs-fragment-shader).

If you ever need the functions offered by the two aforementioned built-in libraries, you can do so by requiring their respective paths. Since these libraries are often referenced frequently, it is recommended to shorthand the names of their variables for convenience.

```lua
-- chances are, you're gonna need this library 98% of the time
local g = require(game.ReplicatedStorage.RbxShader.lib.GraphicsMath)
-- (OMITTABLE) you'll only ever need this if you need to
-- sample textures or volumes, have buffers, etc.
local i = require(game.ReplicatedStorage.RbxShader.lib.Input)
```

If you want to enforce default configuration values that are specific to the program, you can do so by providing a `CONFIGURATION` field to the program.
```lua
-- ...
return {
	CONFIGURATION = {
		InterlaceFactor = 2 ,
		ScreenDivision = 4
	};
-- ...
```

If your program ever needs to sample textures, volumes, keyboard input, and/or buffers, you can do so by providing a `CHANNELS` field to the program. This is simply an array of channels.
```lua
-- ...
	-- (OMITTABLE) you'll only ever need this for the same 
	-- reasons you need to require the Input library
	CHANNELS = {
		i.Texture "rbxassetid://112541002499578" ,
		i.Keyboard
	}
-- ...
```