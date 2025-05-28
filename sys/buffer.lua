--[[pod_format="raw",created="2025-03-26 21:56:12",icon=userdata("u8",16,16,"00121212121212121212120000000000001217171717171717170e1200000000001217171717171717170e0e12000000001217171717171717170e0e0e120000001217171712121212170e0e0e0e120000121717121d1d1d1d121717171712000012171717121d1d12171717171712000012171717121d1d12171717171712000012171717121d1d12171217171712000012171717121d1d12121d121717120000121717121d1d1d1d1d1d12171712000012171717121212121212171717120000121717171717171717171717171200001217171717171717171717171712000012171717171717171717171717120000121212121212121212121212121200"),modified="2025-05-07 10:27:27",revision=9]]
--- Buffer Module
-- @module buffer
-- a fixed-size circular buffer of bytes (u8) using USERDATA

-- @type buffer
-- @field _buf userdata internal byte storage (u8)
-- @field _cap number maximum capacity in bytes
-- @field _head number next write index (0-based)
-- @field _tail number next read index (0-based)
-- @field _count number current number of stored bytes
buffer = class("buffer")

--- create a new buffer.
-- @tparam integer capacity the number of bytes the buffer can hold
-- @treturn buffer instance
function buffer:init(capacity)
	assert(
		type(capacity) == "number" and math.type(capacity) == "integer",
		"capacity must be an integer!"
	)
	assert(capacity > 0, "capacity must be at least 1!")
	self._buf = userdata("u8", capacity)
	self._cap = capacity
	self._head = 0
	self._count = 0
end

-- compute tail index based on head and count
local function tail_index(self)
	return (self._head - self._count % self._cap + self._cap) % self._cap
end

--- push a byte into the buffer.
-- @tparam integer val Byte value (0-255)
-- @treturn boolean true if pushed, false if buffer full
function buffer:push(val)
	assert(
		type(val) == "number" and math.type(val) == "integer",
		"val must be an integer!"
	)
	assert(val >= 0 and val < 256, "value must be 0-255")
	if self._count == self._cap then return false end
	self._buf:set(self._head, val)
	self._head = (self._head + 1) % self._cap
	self._count = self._count + 1
	return true
end

--- push multiple bytes into the buffer.
-- @tparam integer,... vararg list of byte values
-- @treturn integer number of bytes actually pushed
function buffer:push_many(...)
	local vals = {...}
	local n = #vals
	if n == 0 then return 0 end
	local space = self._cap - self._count
	local to_push = math.min(n, space)
	local start = self._head
	local first = math.min(to_push, self._cap - start)
	if first > 0 then
		self._buf:set(start, table.unpack(vals, 1, first))
	end
	local second = to_push - first
	if second > 0 then
		self._buf:set(0, table.unpack(vals, first+1, first+second))
	end
	self._head = (start + to_push) % self._cap
	self._count = self._count + to_push
	return to_push
end

--- pop bytes from the buffer.
-- @tparam[opt] integer n number of bytes to pop (default 1)
-- @treturn integer count number of bytes popped (0 if empty)
-- @treturn[1] integer,... popped values
function buffer:pop(n)
	if self._count == 0 then return 0 end
	local num = (type(n) == "number" and n > 0) and math.min(n, self._count) or 1
	local tail = tail_index(self)
	if num == 1 then
		local val = self._buf:get(tail)
		self._count = self._count - 1
		return 1, val
	end
	local out = {}
	local first = math.min(num, self._cap - tail)
	for i = 0, first-1 do
		out[#out+1] = self._buf:get((tail + i) % self._cap)
	end
	local second = num - first
	for i = 0, second-1 do
		out[#out+1] = self._buf:get(i)
	end
	self._count = self._count - num
	return num, table.unpack(out)
end

--- peek at an element without removing it from the buffer.
-- @tparam[opt] integer idx Index (0 = oldest)
-- @treturn number Byte value at the position
function buffer:peek(idx)
	local i = idx or 0
	assert(i >= 0 and i < self._count, "index out of range")
	local pos = (tail_index(self) + i) % self._cap
	return self._buf:get(pos)
end

--- get current number of stored bytes.
-- @treturn number byte count
function buffer:size()
	return self._count
end

--- get maximum buffer capacity.
-- @treturn number capacity in bytes
function buffer:capacity()
	return self._cap
end

--- check if buffer is empty.
-- @treturn boolean
function buffer:is_empty()
	return self._count == 0
end

--- check if buffer is full.
-- @treturn boolean
function buffer:is_full()
	return self._count == self._cap
end

--- clear buffer contents.
function buffer:clear()
	self._head = 0
	self._tail = 0
	self._count = 0
end
