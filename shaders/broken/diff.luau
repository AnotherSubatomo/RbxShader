
-- * somehow faster than clamp, according to compiler remarks
const function f1(v, l, u): (number)
	return math.min(u, math.max(v, l))
end

const function f2(v, l, u): (number)
	return math.clamp(v, l, u)
end

const function f3(v, l, u): (number)
	return if v <= l then l elseif v >= u then u else v
end

const function v1(v, l, u): (vector)
	return vector.min(u, vector.max(v, l))
end

const function v2(v, l, u): (vector)
	return vector.clamp(v, l, u)
end

f1()
f2()
f3()

v1()
v2()