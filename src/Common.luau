
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
	ScreenDivision : number
}

return true