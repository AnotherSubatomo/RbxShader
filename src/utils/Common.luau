
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
	Resolution : Vector2 ,
	__Canvas : EditableImage ,
	__GetIndex : (X: number, Y: number) -> number ,
	SetRGBA : ( x : number, y : number, r : number, g : number, b : number, a :number ) -> nil ,
	GetRGB : ( x : number, y : number ) -> ( number, number, number ) ,
	Render : () -> nil ,
	Destroy : () -> nil
}

return true