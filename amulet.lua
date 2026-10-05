rawset(_G, "amulet_license", [[Copyright (C) 2014-2020 Ian MacLarty

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.]])

rawset(_G, "_metatable_registry", {})

local function format_num(n)
	local str = string.format("%.16g", n)
	if (str == "-0") then
		return "0"
	end
	return str
end

local function format_vec(v)
	local n = #v
	local str = "vec"..n.."("
	for i = 1, n do
		str = str..format_num(v[i])
		if (i == n) then
			str = str..")"
		else
			str = str..", "
		end
	end
	return str
end

local function format_mat(m)
	local n = #m
	local rowwidth = {0, 0, 0, 0}
	for col = 1, n do
		for row = 1, n do
			local str = tostring(m[col][row])
			if (#str > rowwidth[row]) then
				rowwidth[row] = #str
			end
		end
	end
	local str = "mat"..n.."("
	for col = 1, n do
		for row = 1, n do
			local fmt = "%"..rowwidth[row].."s"
			str = str..string.format(fmt, format_num(m[col][row]))
			if (row ~= n) then
				str = str..", "
			end
		end
		if (col == n) then
			str = str..")"
		else
			str = str..",\n     "
		end
	end
	return str
end

local function format_quat(q)
	return "quat("..format_num(q.angle)..", "..tostring(q.axis)..")"
end

local function default_concat(a, b)
	return tostring(a)..tostring(b)
end

local vec_mt  = {}
local mat_mt  = {}
local quat_mt = {}

local make_vec, make_mat
local vec_add, vec_sub, vec_mul, vec_div, vec_unm, vec_len, vec_eq
local vec_distance, vec_dot, vec_cross, vec_normalize
local vec_faceforward, vec_reflect, vec_refract
local mat_add, mat_sub, mat_mul, mat_div, mat_unm, mat_eq
local quat_mul

vec_mt.__add      = function(a, b) return vec_add(a, b) end
vec_mt.__sub      = function(a, b) return vec_sub(a, b) end
vec_mt.__mul      = function(a, b) return vec_mul(a, b) end
vec_mt.__div      = function(a, b) return vec_div(a, b) end
vec_mt.__unm      = function(a)    return vec_unm(a)    end
vec_mt.__len      = function(a)    return vec_len(a)    end
vec_mt.__eq       = function(a, b) return vec_eq(a, b)  end
vec_mt.__tostring = format_vec
vec_mt.__concat   = default_concat

function vec_mt.__index(t, k)
	if (type(k) == "number") then
		return rawget(t, k)
	end
	local map = { x = 1, y = 2, z = 3, w = 4 }
	local i = map[k]
	if (i) then
		return rawget(t, i)
	end
	return vec_mt[k]
end

function vec_mt.__newindex(t, k, v)
	if (type(k) == "number") then
		rawset(t, k, v)
		return
	end
	local map = { x = 1, y = 2, z = 3, w = 4 }
	local i = map[k]
	if (i) then
		rawset(t, i, v)
	else
		rawset(t, k, v)
	end
end

function vec_mt.__call(t, ...)
	local n = #t
	local args = {...}
	for i = 1, n do
		if (args[i] ~= nil) then
			t[i] = args[i]
		end
	end
	return t
end

mat_mt.__add      = function(a, b) return mat_add(a, b) end
mat_mt.__sub      = function(a, b) return mat_sub(a, b) end
mat_mt.__mul      = function(a, b) return mat_mul(a, b) end
mat_mt.__div      = function(a, b) return mat_div(a, b) end
mat_mt.__unm      = function(a)    return mat_unm(a)    end
mat_mt.__len      = function(a)    return #a            end
mat_mt.__eq       = function(a, b) return mat_eq(a, b)  end
mat_mt.__tostring = format_mat
mat_mt.__concat   = default_concat

function mat_mt.__index(t, k)
	if (type(k) == "number") then
		return rawget(t, k)
	end
	return mat_mt[k]
end

function mat_mt.__newindex(t, k, v)
	rawset(t, k, v)
end

function mat_mt.__call(t, ...)
	local args = {...}
	local n = #t
	if (#args == n * n) then
		local idx = 1
		for col = 1, n do
			for row = 1, n do
				t[col][row] = args[idx]
				idx = idx + 1
			end
		end
	end
	return t
end

quat_mt.__mul      = function(a, b) return quat_mul(a, b) end
quat_mt.__tostring = format_quat
quat_mt.__concat   = default_concat

function quat_mt.__index(t, k)
	if (k == "angle") then
		return rawget(t, "angle")
	end
	if (k == "axis") then
		return rawget(t, "axis")
	end
	return quat_mt[k]
end

function quat_mt.__newindex(t, k, v)
	rawset(t, k, v)
end

make_vec = function(n, ...)
	local v = setmetatable({}, vec_mt)
	local args = {...}
	for i = 1, n do
		v[i] = args[i] or 0
	end
	return v
end

function vec2(...) return make_vec(2, ...) end
function vec3(...) return make_vec(3, ...) end
function vec4(...) return make_vec(4, ...) end

vec_add = function(a, b)
	local n = #a
	local r = make_vec(n)
	for i = 1, n do
		r[i] = a[i] + b[i]
	end
	return r
end

vec_sub = function(a, b)
	local n = #a
	local r = make_vec(n)
	for i = 1, n do
		r[i] = a[i] - b[i]
	end
	return r
end

vec_mul = function(a, b)
	local n = #a
	local r = make_vec(n)
	if (type(b) == "number") then
		for i = 1, n do
			r[i] = a[i] * b
		end
	else
		for i = 1, n do
			r[i] = a[i] * b[i]
		end
	end
	return r
end

vec_div = function(a, b)
	local n = #a
	local r = make_vec(n)
	if (type(b) == "number") then
		for i = 1, n do
			r[i] = a[i] / b
		end
	else
		for i = 1, n do
			r[i] = a[i] / b[i]
		end
	end
	return r
end

vec_unm = function(a)
	local n = #a
	local r = make_vec(n)
	for i = 1, n do
		r[i] = -a[i]
	end
	return r
end

vec_len = function(a)
	local n = #a
	local s = 0
	for i = 1, n do
		s = s + a[i] * a[i]
	end
	return math.sqrt(s)
end

vec_eq = function(a, b)
	local n = #a
	for i = 1, n do
		if (a[i] ~= b[i]) then
			return false
		end
	end
	return true
end

vec_distance = function(a, b)
	local n = #a
	local s = 0
	for i = 1, n do
		local d = a[i] - b[i]
		s = s + d * d
	end
	return math.sqrt(s)
end

vec_dot = function(a, b)
	local n = #a
	local s = 0
	for i = 1, n do
		s = s + a[i] * b[i]
	end
	return s
end

vec_cross = function(a, b)
	return vec3(
		a[2] * b[3] - a[3] * b[2],
		a[3] * b[1] - a[1] * b[3],
		a[1] * b[2] - a[2] * b[1]
	)
end

vec_normalize = function(a)
	local len = vec_len(a)
	if (len == 0) then
		return make_vec(#a)
	end
	return vec_div(a, len)
end

vec_faceforward = function(n, i, nref)
	local d = vec_dot(i, nref)
	if (d < 0) then
		return n
	else
		return vec_unm(n)
	end
end

vec_reflect = function(i, n)
	local d = vec_dot(n, i)
	return vec_sub(i, vec_mul(n, 2 * d))
end

vec_refract = function(i, n, eta)
	local dotNI = vec_dot(n, i)
	local k = 1 - eta * eta * (1 - dotNI * dotNI)
	if (k < 0) then
		return make_vec(#i)
	end
	return vec_sub(
		vec_mul(i, eta),
		vec_mul(n, eta * dotNI + math.sqrt(k))
	)
end

function vec_mt.length(v)               return vec_len(v)                  end
function vec_mt.distance(v, other)      return vec_distance(v, other)      end
function vec_mt.dot(v, other)           return vec_dot(v, other)           end
function vec_mt.cross(v, other)         return vec_cross(v, other)         end
function vec_mt.normalize(v)            return vec_normalize(v)            end
function vec_mt.faceforward(v, i, nref) return vec_faceforward(v, i, nref) end
function vec_mt.reflect(v, n)           return vec_reflect(v, n)           end
function vec_mt.refract(v, n, eta)      return vec_refract(v, n, eta)      end

make_mat = function(n, ...)
	local m = setmetatable({}, mat_mt)
	local args = {...}
	for col = 1, n do
		m[col] = {}
		for row = 1, n do
			m[col][row] = 0
		end
	end
	if (#args == n * n) then
		local idx = 1
		for col = 1, n do
			for row = 1, n do
				m[col][row] = args[idx]
				idx = idx + 1
			end
		end
	else
		for i = 1, n do
			m[i][i] = 1
		end
	end
	return m
end

function mat2(...) return make_mat(2, ...) end
function mat3(...) return make_mat(3, ...) end
function mat4(...) return make_mat(4, ...) end

mat_add = function(a, b)
	local n = #a
	local r = make_mat(n)
	for col = 1, n do
		for row = 1, n do
			r[col][row] = a[col][row] + b[col][row]
		end
	end
	return r
end

mat_sub = function(a, b)
	local n = #a
	local r = make_mat(n)
	for col = 1, n do
		for row = 1, n do
			r[col][row] = a[col][row] - b[col][row]
		end
	end
	return r
end

mat_mul = function(a, b)
	local n = #a
	if (type(b) == "number") then
		local r = make_mat(n)
		for col = 1, n do
			for row = 1, n do
				r[col][row] = a[col][row] * b
			end
		end
		return r
	end
	if (type(b) == "table" and #b == n and type(b[1]) == "number") then
		local r = make_vec(n)
		for row = 1, n do
			local s = 0
			for col = 1, n do
				s = s + a[col][row] * b[col]
			end
			r[row] = s
		end
		return r
	end
	local r = make_mat(n)
	for col = 1, n do
		for row = 1, n do
			local s = 0
			for k = 1, n do
				s = s + a[k][row] * b[col][k]
			end
			r[col][row] = s
		end
	end
	return r
end

mat_div = function(a, b)
	local n = #a
	local r = make_mat(n)
	if (type(b) == "number") then
		for col = 1, n do
			for row = 1, n do
				r[col][row] = a[col][row] / b
			end
		end
	else
		for col = 1, n do
			for row = 1, n do
				r[col][row] = a[col][row] / b[col][row]
			end
		end
	end
	return r
end

mat_unm = function(a)
	local n = #a
	local r = make_mat(n)
	for col = 1, n do
		for row = 1, n do
			r[col][row] = -a[col][row]
		end
	end
	return r
end

mat_eq = function(a, b)
	local n = #a
	for col = 1, n do
		for row = 1, n do
			if (a[col][row] ~= b[col][row]) then
				return false
			end
		end
	end
	return true
end

function mat_mt.set(m, ...)
	local args = {...}
	local n = #m
	if (#args == n * n) then
		local idx = 1
		for col = 1, n do
			for row = 1, n do
				m[col][row] = args[idx]
				idx = idx + 1
			end
		end
	end
	return m
end

function quat(angle, axis)
	local q = setmetatable({}, quat_mt)
	q.angle = angle or 0
	q.axis  = axis  or vec3(0, 0, 1)
	return q
end

quat_mul = function(a, b)
	local ha = a.angle * 0.5
	local hb = b.angle * 0.5
	local ca, sa = math.cos(ha), math.sin(ha)
	local cb, sb = math.cos(hb), math.sin(hb)

	local w1, x1, y1, z1 = ca, sa * a.axis[1], sa * a.axis[2], sa * a.axis[3]
	local w2, x2, y2, z2 = cb, sb * b.axis[1], sb * b.axis[2], sb * b.axis[3]

	local w = w1 * w2 - x1 * x2 - y1 * y2 - z1 * z2
	local x = w1 * x2 + x1 * w2 + y1 * z2 - z1 * y2
	local y = w1 * y2 - x1 * z2 + y1 * w2 + z1 * x2
	local z = w1 * z2 + x1 * y2 - y1 * x2 + z1 * w2

	local len = math.sqrt(w * w + x * x + y * y + z * z)
	if (len > 0) then
		w, x, y, z = w / len, x / len, y / len, z / len
	end

	local angle = 2 * math.acos(math.max(-1, math.min(1, w)))
	local sin_half = math.sqrt(1 - w * w)
	local axis
	if (sin_half < 1e-8) then
		axis = vec3(0, 0, 1)
	else
		axis = vec3(x / sin_half, y / sin_half, z / sin_half)
	end
	return quat(angle, axis)
end

rawset(_G, "vec2", vec2)
rawset(_G, "vec3", vec3)
rawset(_G, "vec4", vec4)
rawset(_G, "mat2", mat2)
rawset(_G, "mat3", mat3)
rawset(_G, "mat4", mat4)
rawset(_G, "quat", quat)

math.vec2 = vec2
math.vec3 = vec3
math.vec4 = vec4
math.mat2 = mat2
math.mat3 = mat3
math.mat4 = mat4
math.quat = quat

math.vec_length      = vec_len
math.vec_distance    = vec_distance
math.vec_dot         = vec_dot
math.vec_cross       = vec_cross
math.vec_normalize   = vec_normalize
math.vec_faceforward = vec_faceforward
math.vec_reflect     = vec_reflect
math.vec_refract     = vec_refract

math.length      = vec_len
math.distance    = vec_distance
math.dot         = vec_dot
math.cross       = vec_cross
math.normalize   = vec_normalize
math.faceforward = vec_faceforward
math.reflect     = vec_reflect
math.refract     = vec_refract

function math.clamp(v, min_v, max_v)
	if (type(v) == "number") then
		if (v < min_v) then
			return min_v
		end
		if (v > max_v) then
			return max_v
		end
		return v
	end
	local n = #v
	local r = make_vec(n)
	for i = 1, n do
		r[i] = math.clamp(v[i], min_v[i], max_v[i])
	end
	return r
end

function math.slerp(a, b, t)
	local dot = vec_dot(a, b)
	local theta = math.acos(dot)
	local sin_theta = math.sin(theta)
	if (sin_theta < 1e-8) then
		return vec_add(vec_mul(a, 1 - t), vec_mul(b, t))
	end
	local s1 = math.sin((1 - t) * theta) / sin_theta
	local s2 = math.sin(t * theta) / sin_theta
	return vec_add(vec_mul(a, s1), vec_mul(b, s2))
end

function math.perspective(fov, aspect, near, far)
	local f = 1 / math.tan(fov / 2)
	local range = near - far
	local m = mat4()
	m[1][1] = f / aspect
	m[2][2] = f
	m[3][3] = (far + near) / range
	m[4][3] = (2 * far * near) / range
	m[3][4] = -1
	m[4][4] = 0
	return m
end

function math.translate4(x, y, z)
	local m = mat4()
	if (type(x) == "table") then
		y = x[2] or 0
		z = x[3] or 0
		x = x[1] or 0
	end
	m[4][1] = x or 0
	m[4][2] = y or 0
	m[4][3] = z or 0
	return m
end

function math.scale4(x, y, z)
	local m = mat4()
	if (type(x) == "table") then
		y = x[2] or 1
		z = x[3] or 1
		x = x[1] or 1
	end
	m[1][1] = x or 1
	m[2][2] = y or 1
	m[3][3] = z or 1
	return m
end

function math.rotate4(angle, axis)
	local m = mat4()
	local c = math.cos(angle)
	local s = math.sin(angle)
	local t = 1 - c
	local ax = axis[1]
	local ay = axis[2]
	local az = axis[3]
	m[1][1] = t * ax * ax + c
	m[1][2] = t * ax * ay + s * az
	m[1][3] = t * ax * az - s * ay
	m[2][1] = t * ax * ay - s * az
	m[2][2] = t * ay * ay + c
	m[2][3] = t * ay * az + s * ax
	m[3][1] = t * ax * az + s * ay
	m[3][2] = t * ay * az - s * ax
	m[3][3] = t * az * az + c
	return m
end

function math.randvec2()
	return vec2(math.random(), math.random())
end

function math.randvec3()
	return vec3(math.random(), math.random(), math.random())
end

function math.randvec4()
	return vec4(math.random(), math.random(), math.random(), math.random())
end

function math.sign(n)
	return n > 0 and 1 or n < 0 and -1 or 0
end

_metatable_registry.vec2 = vec_mt
_metatable_registry.vec3 = vec_mt
_metatable_registry.vec4 = vec_mt
_metatable_registry.mat2 = mat_mt
_metatable_registry.mat3 = mat_mt
_metatable_registry.mat4 = mat_mt
_metatable_registry.quat = quat_mt

function table.shallow_copy(t)
	if (type(t) ~= "table") then
		error("table expected, but got a "..type(t), 2)
	end
	local copy = {}
	for k, v in pairs(t) do
		copy[k] = v
	end
	return copy
end

local function deep_copy_2(t, seen)
	local s = seen[t]
	if (s) then
		return s
	else
		s = {}
		seen[t] = s
		for k, v in pairs(t) do
			if (type(k) == "table") then
				k = deep_copy_2(k, seen)
			end
			if (type(v) == "table") then
				v = deep_copy_2(v, seen)
			end
			s[k] = v
		end
		return s
	end
end

function table.deep_copy(t)
	if (type(t) == "table") then
		return deep_copy_2(t, {})
	else
		error("table expected, but got a "..type(t), 2)
	end
end

function table.search(t, elem)
	for i = 1, #t do
		if (t[i] == elem) then
			return i
		end
	end
	return nil
end

function table.remove_all(t, val)
	for i = #t, 1, -1 do
		if (t[i] == val) then
			table.remove(t, i)
		end
	end
end

function table.append(arr1, arr2)
	local i = #arr1 + 1
	for _, v in ipairs(arr2) do
		arr1[i] = v
		i = i + 1
	end
end

function table.merge(t1, t2)
	for k, v in pairs(t2) do
		t1[k] = v
	end
end

function table.keys(t)
	local ks = {}
	local i = 1
	for k, _ in pairs(t) do
		ks[i] = k
		i = i + 1
	end
	return ks
end

function table.values(t)
	local vs = {}
	local i = 1
	for _, v in pairs(t) do
		vs[i] = v
		i = i + 1
	end
	return vs
end

function table.filter(t, f)
	local t2 = {}
	local i = 1
	for _, v in ipairs(t) do
		if (f(v)) then
			t2[i] = v
			i = i + 1
		end
	end
	return t2
end

function table.clear(t)
	for k, _ in pairs(t) do
		t[k] = nil
	end
end

function table.count(t)
	local count = 0
	for k, v in pairs(t) do
		count = count + 1
	end
	return count
end

function table.shuffle(t, r)
	if (type(t) ~= "table") then
		error("table expected, but got a "..type(t), 2)
	end

	local math_random = r or math.random

	for a = #t, 2, -1 do
		local b = math_random(a)
		t[a], t[b] = t[b], t[a]
	end
end

local function table_tostring(field, t, indent, seen, depth)
	indent = indent or 0
	local tp = type(t)
	if (tp == "table") then
		if (seen[t]) then
			error("cycle detected at field "..tostring(field), depth + 2)
		else
			seen[t] = true
		end
		local tab = "    "
		local prefix = string.rep(tab, indent)
		local str = "{\n"
		local keys = {}
		local array_test = 1
		for key, _ in pairs(t) do
			table.insert(keys, key)
			if (key ~= array_test) then
				array_test = nil
			else
				array_test = array_test + 1
			end
		end
		if (array_test) then
			for i = 1, array_test - 1 do
				str = str..prefix..tab..table_tostring(i, t[i], indent + 1, seen, depth + 1)..",\n"
			end
		else
			table.sort(keys, function(k1, k2)
				local t1 = type(k1)
				local t2 = type(k2)
				if (t1 == "string" and t2 == "string") then
					return k1 < k2
				end
				if (t1 == "number" and t2 == "number") then
					return k1 < k2
				end
				if (t1 == "string" and t2 == "number") then
					return true
				end
				if (t1 == "number" and t2 == "string") then
					return false
				end
				return tostring(k1) < tostring(k2)
			end)
			for _, key in ipairs(keys) do
				local value = t[key]
				local keystr
				if (type(key) == "string" and key:match"^[A-Za-z_][A-Za-z0-9_]*$") then
					keystr = key
				else
					keystr = "["..table_tostring("<key>", key, 0, seen, depth + 1).."]"
				end
				local valstr = table_tostring(key, value, indent + 1, seen, depth + 1)
				str = str..prefix..tab..keystr.." = "..valstr..",\n"
			end
		end
		str = str..prefix.."}"
		seen[t] = nil
		return str
	elseif (tp == "string") then
		return "\""..t:gsub("\"", "\\\""):gsub("%\n", "\\n").."\""
	else
		return tostring(t)
	end
end

table.tostring = function(t, indent)
	return table_tostring("<root>", t, indent, {}, 1)
end

local function noglobals()
	setmetatable(_G, {
		__index = function(t, k)
			error("attempt to reference missing global "..tostring(k), 2)
		end,
		__newindex = function(t, k, v)
			error("attempt to set global "..tostring(k), 2)
		end,
	})
end

rawset(_G, "noglobals", noglobals)