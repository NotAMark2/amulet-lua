-- Copyright (C) 2014-2020 Ian MacLarty

-- Permission is hereby granted, free of charge, to any person obtaining a copy
-- of this software and associated documentation files (the "Software"), to deal
-- in the Software without restriction, including without limitation the rights
-- to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
-- copies of the Software, and to permit persons to whom the Software is
-- furnished to do so, subject to the following conditions:

-- The above copyright notice and this permission notice shall be included in all
-- copies or substantial portions of the Software.

-- THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
-- IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
-- FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
-- AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
-- LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
-- OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
-- SOFTWARE.



-- ============================================================
--  Pure Lua implementation of Amulet's math
--  Replaces am_math.cpp / am_mathv.cpp
--  Compatible with Lua 5.1+ and LuaJIT 2.1
-- ============================================================



-- Vector metatable (vec2 / vec3 / vec4)

local vec_mt = {}
vec_mt.__index = vec_mt

function vec_mt.__add(a, b)
	return vec_add(a, b)
end

function vec_mt.__sub(a, b)
	return vec_sub(a, b)
end

function vec_mt.__mul(a, b)
	return vec_mul(a, b)
end

function vec_mt.__div(a, b)
	return vec_div(a, b)
end

function vec_mt.__unm(a)
	return vec_unm(a)
end

function vec_mt.__len(a)
	return vec_len(a)
end

function vec_mt.__eq(a, b)
	return vec_eq(a, b)
end

-- Assumes format_vec and default_concat are defined externally

vec_mt.__tostring = format_vec
vec_mt.__concat   = default_concat

-- Index access: v[1], v.x, v.y, v.z, v.w

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

-- Vector constructors

local function make_vec(n, ...)
	local v = setmetatable({}, vec_mt)
	local args = {...}
	for i = 1, n do
		v[i] = args[i] or 0
	end
	return v
end

function vec2(...)
	return make_vec(2, ...)
end

function vec3(...)
	return make_vec(3, ...)
end

function vec4(...)
	return make_vec(4, ...)
end

-- Vector operations

local function vec_add(a, b)
	local n = #a
	local r = make_vec(n)
	for i = 1, n do
		r[i] = a[i] + b[i]
	end
	return r
end

local function vec_sub(a, b)
	local n = #a
	local r = make_vec(n)
	for i = 1, n do
		r[i] = a[i] - b[i]
	end
	return r
end

local function vec_mul(a, b)
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

local function vec_div(a, b)
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

local function vec_unm(a)
	local n = #a
	local r = make_vec(n)
	for i = 1, n do
		r[i] = -a[i]
	end
	return r
end

local function vec_len(a)
	local n = #a
	local s = 0
	for i = 1, n do
		s = s + a[i] * a[i]
	end
	return math.sqrt(s)
end

local function vec_eq(a, b)
	local n = #a
	for i = 1, n do
		if (a[i] ~= b[i]) then
			return false
		end
	end
	return true
end

local function vec_length(a)
	return vec_len(a)
end

local function vec_distance(a, b)
	local n = #a
	local s = 0
	for i = 1, n do
		local d = a[i] - b[i]
		s = s + d * d
	end
	return math.sqrt(s)
end

local function vec_dot(a, b)
	local n = #a
	local s = 0
	for i = 1, n do
		s = s + a[i] * b[i]
	end
	return s
end

local function vec_cross(a, b)
	return vec3(
		a[2] * b[3] - a[3] * b[2],
		a[3] * b[1] - a[1] * b[3],
		a[1] * b[2] - a[2] * b[1]
	)
end

local function vec_normalize(a)
	local len = vec_len(a)
	if (len == 0) then
		return make_vec(#a)
	end
	return vec_div(a, len)
end

local function vec_faceforward(n, i, nref)
	local d = vec_dot(i, nref)
	if (d < 0) then
		return n
	else
		return vec_unm(n)
	end
end

local function vec_reflect(i, n)
	local d = vec_dot(n, i)
	return vec_sub(i, vec_mul(n, 2 * d))
end

local function vec_refract(i, n, eta)
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

function vec_mt.length(v)
	return vec_len(v)
end

function vec_mt.distance(v, other)
	return vec_distance(v, other)
end

function vec_mt.dot(v, other)
	return vec_dot(v, other)
end

function vec_mt.cross(v, other)
	return vec_cross(v, other)
end

function vec_mt.normalize(v)
	return vec_normalize(v)
end

function vec_mt.faceforward(v, i, nref)
	return vec_faceforward(v, i, nref)
end

function vec_mt.reflect(v, n)
	return vec_reflect(v, n)
end

function vec_mt.refract(v, n, eta)
	return vec_refract(v, n, eta)
end

-- Matrix metatable (mat2 / mat3 / mat4)

local mat_mt = {}
mat_mt.__index = mat_mt

function mat_mt.__add(a, b)
	return mat_add(a, b)
end

function mat_mt.__sub(a, b)
	return mat_sub(a, b)
end

function mat_mt.__mul(a, b)
	return mat_mul(a, b)
end

function mat_mt.__div(a, b)
	return mat_div(a, b)
end

function mat_mt.__unm(a)
	return mat_unm(a)
end

function mat_mt.__len(a)
	return #a
end

function mat_mt.__eq(a, b)
	return mat_eq(a, b)
end

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

-- Matrix constructors

local function make_mat(n, ...)
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

function mat2(...)
	return make_mat(2, ...)
end

function mat3(...)
	return make_mat(3, ...)
end

function mat4(...)
	return make_mat(4, ...)
end

-- Matrix operations

local function mat_add(a, b)
	local n = #a
	local r = make_mat(n)
	for col = 1, n do
		for row = 1, n do
			r[col][row] = a[col][row] + b[col][row]
		end
	end
	return r
end

local function mat_sub(a, b)
	local n = #a
	local r = make_mat(n)
	for col = 1, n do
		for row = 1, n do
			r[col][row] = a[col][row] - b[col][row]
		end
	end
	return r
end

local function mat_mul(a, b)
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

local function mat_div(a, b)
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

local function mat_unm(a)
	local n = #a
	local r = make_mat(n)
	for col = 1, n do
		for row = 1, n do
			r[col][row] = -a[col][row]
		end
	end
	return r
end

local function mat_eq(a, b)
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

-- Quaternion (quat)

local quat_mt = {}
quat_mt.__index = quat_mt

function quat_mt.__mul(a, b)
	return quat_mul(a, b)
end

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

function quat(angle, axis)
	local q = setmetatable({}, quat_mt)
	q.angle = angle or 0
	q.axis  = axis  or vec3(0, 0, 1)
	return q
end

local function quat_mul(a, b)
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

-- Register globals and math functions

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

math.vec_length      = vec_length
math.vec_distance    = vec_distance
math.vec_dot         = vec_dot
math.vec_cross       = vec_cross
math.vec_normalize   = vec_normalize
math.vec_faceforward = vec_faceforward
math.vec_reflect     = vec_reflect
math.vec_refract     = vec_refract