
--[=[ Basically an assertion with format. ]=]

--!native
--!strict

local argue = setmetatable({}, {
	__call = function (
		t : {} ,
		cond : any ,
		msg : string
	)
		msg = msg or 'Assertion failed!'
		local location = t.at or debug.info(2, "n")
		if not cond then return error( `@RbxShader/{location}: {msg}` ) end
	end
})

function argue:at( at : string )
	if typeof(at) ~= "string" then return argue end
	return setmetatable({ at = at }, getmetatable(argue))
end

return argue