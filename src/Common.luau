
-- [=[ Common types found across the scripts. ]=]

export type ShaderBuffer = (
	fragColor : Vector3 ,
	fragCoords : Vector2 ,
	iTime : number ,
	iTimeDelta : number ,
	iResolution : Vector2	
) -> (number, number, number, number)

export type Shader = {
	mainImage : ShaderBuffer
}

export type EngineConfiguration = {
	InterlaceFactor : number ,
	DualAxisInterlacing : boolean ,
	ScreenDivision : number ,
	CanvasColor : Color3? ,
	IsBlurred : boolean
}

export type FastCanvas = {
	Image : EditableImage ,
	SetRGBA : ( x : number, y : number, r : number, g : number, b : number, a :number ) -> nil ,
	GetRGBA : ( x : number, y : number ) -> ( number, number, number, number ) ,
	SetGrid : ( pixelArray : {number} ) -> nil ,
	GetGrid : () -> {number} ,
	Render : () -> nil ,
	Clear : () -> nil ,
	Destroy : () -> nil
}

return true