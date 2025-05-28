--[[pod_format="raw",created="2025-03-26 05:49:10",icon=userdata("u8",16,16,"00121212121212121212120000000000001217171717171717170e1200000000001217171717171717170e0e12000000001217171717171717170e0e0e120000001217171712121212170e0e0e0e120000121717121d1d1d1d121717171712000012171717121d1d12171717171712000012171717121d1d12171717171712000012171717121d1d12171217171712000012171717121d1d12121d121717120000121717121d1d1d1d1d1d12171712000012171717121212121212171717120000121717171717171717171717171200001217171717171717171717171712000012171717171717171717171717120000121212121212121212121212121200"),modified="2025-04-23 02:27:13",revision=67]]
function string:stem()
    return split(self:basename(), ".")[1]
end

function print_mat(mat, one_d)
	local w,h,tt,d = mat:attribs()
	local contents = ""
	for x=0,w-1 do
		local values
		if one_d and one_d == true then
			values = {mat:get(x,h)}
		else
			values = {mat:get(x,0,h)}
		end
		contents = contents.."["..table.concat(values, ",").."]"
	end
	print("["..tt.."]["..w.."]["..h.."]{"..contents.."}")
end

local MAX_VEC_CMP_SIZE = 128
local DATA1 = userdata("u8", MAX_VEC_CMP_SIZE)
local DATA2 = userdata("u8", MAX_VEC_CMP_SIZE)

local function _strcmp(self, other)
	local size = #self

	DATA1:set(0, 0, ord(self, 1, size))
	DATA2:set(0, 0, ord(other, 1, size))

	local diff = (DATA1 - DATA2)
	local sum = diff:add(true, 1, 0, 1, 1, 0, #diff)[0]
	DATA1 *= 0
	DATA2 *= 0

	return sum == 0
end

local function _strcmp_long(self, other)
	local size = #self
	local bc = size // MAX_VEC_CMP_SIZE -- batch count
	local sum

	for i=1,bc do
		DATA1:set(0, 0, ord(self, 1, MAX_VEC_CMP_SIZE))
		DATA2:set(0, 0, ord(other, 1, MAX_VEC_CMP_SIZE))

		self = sub(self, MAX_VEC_CMP_SIZE + 1)
		other = sub(other, MAX_VEC_CMP_SIZE + 1)

		sum = (DATA1 - DATA2):convert("f64"):dot(ONES)
		if sum ~= 0 then
			DATA1 *= 0
			DATA2 *= 0
			return false
		end
	end

	-- if there's a partial comparison left over
	if size % MAX_VEC_CMP_SIZE ~= 0 then
		DATA1 *= 0
		DATA2 *= 0

		DATA1:set(0, 0, ord(self, 1, MAX_VEC_CMP_SIZE))
		DATA2:set(0, 0, ord(other, 1, MAX_VEC_CMP_SIZE))

		sum = (DATA1 - DATA2):convert("f64"):dot(ONES)

		DATA1 *= 0
		DATA2 *= 0

		return sum == 0
	else
		return true
	end
end

function strcmp_unsized(self, other)
	local size = #self
	if #other ~= size then return false end

	local ones = userdata("f64", size, 1)
	local s = userdata("u8", size, 1)
	local o = userdata("u8", size, 1)

	s:set(0, 0, ord(self, 1, size))
	o:set(0, 0, ord(other, 1, size))
	ones += 1

	local diff = (s - o):convert("f64")
	local sum = diff:dot(ones)

	return sum == 0
end

function strcmp(self, other)
	local size = #self
	if #other ~= size then return false end
	if size > MAX_VEC_CMP_SIZE then
		return _strcmp_long(self, other)
	else
		return _strcmp(self, other)
	end
end
