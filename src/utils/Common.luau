
-- [=[ Common types found across the scripts. ]=]
--!native

export type ShaderBuffer = (
	fragColor : Vector3 ,
	fragCoords : Vector2 ,
	iTime : number ,
	iTimeDelta : number ,
	iResolution : Vector2 ,
	iMouse : SharedTable ,
	iDate : {number}
) -> (number, number, number, number)

-- a few buffer name examples
export type BufferName = 'bufferA' | 'bufferB' | 'bufferC' | 'bufferD' | 'bufferE'

export type Shader = {
	CONFIGURATION : EngineConfiguration ,
	[BufferName] : ShaderBuffer ,
	mainImage : ShaderBuffer
}

export type EngineConfiguration = {
	InterlaceFactor : number ,
	DualAxisInterlacing : boolean ,
	ScreenDivision : number ,
	InitialColor : Color3? ,
	InitialAlpha : number? ,
	IsBlurred : boolean? ,
	OriginOffset : Vector2 ,
	CountDirection : Vector2
}

return true