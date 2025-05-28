--[[pod_format="raw",created="2025-04-09 00:54:05",icon=userdata("u8",16,16,"00121212121212121212120000000000001217171717171717170e1200000000001217171717171717170e0e12000000001217171717171717170e0e0e120000001217171712121212170e0e0e0e120000121717121d1d1d1d121717171712000012171717121d1d12171717171712000012171717121d1d12171717171712000012171717121d1d12171217171712000012171717121d1d12121d121717120000121717121d1d1d1d1d1d12171712000012171717121212121212171717120000121717171717171717171717171200001217171717171717171717171712000012171717171717171717171717120000121212121212121212121212121200"),modified="2025-05-07 22:09:58",revision=5]]

io = io or {}

require("class")

require("sys.uuid.uuid4")
local _uuid = uuid

require("sys.buffer")

local _print = print
function print(msg, x, y, col)
	if y or get_display() or stat(315) > 0 then
		_print(msg, x, y, col)
	else
		io.stdout:write(tostring(msg))
	end
end

local file_descriptors = {}

on_event("open_connection", function(data)
	if not data.uuid or not data.secret then return end

	local uuid4 = _uuid.uuid4(data.uuid)
	if table.contains_key(file_descriptors, uuid4) then
		file_descriptors[uuid4]:set_secret(data.secret)
	end
end)

on_event("stdout", function(data)
	if not data.uuid then return end

	local uuid4 = _uuid.uuid4(data.uuid)
	if table.contains_key(file_descriptors, uuid4) then
		
	end
end)

local fildes = class("file_descriptor")

function fildes:init(prog, mode)
	self.mode = mode
	self.prog = prog
	self.uuid = uuid.uuid4()
	file_descriptors[self.uuid] = self
end

function fildes:open()
	local id = create_process(self.prog, {
		parent=pid(),
		subprocess_id=uuid.to_string(self.uuid)
	})
	todo("make a file handle from the id until a connection is opened")
end

function io.popen(prog, mode)
	return fildes(prog, mode or "r"):open()
end

local buf_in = ""  -- todo: make actual buffer (require("buffer"))
local buf_out = "" -- todo: make actual buffer (require("buffer"))
local buf_err = "" -- todo: make actual buffer (require("buffer"))

local stdin = {}
local stdout = {}
local stderr = {}

function stdin:close() end
function stdin:flush() end
function stdin:lines(...)
	local formats = {...} -- todo: use
	local lines = split(buf_in, "\n")
	buf_in = ""
	local idx = 1
	return function()
		local result = lines[idx]
		local fidx = min(idx, #formats)
		local format = formats[fidx]
		-- todo: modify result using the format
		idx += 1
		return result
	end
end
function stdin:read(...)
	local formats = {...} -- todo: use
	local result = buf_in
	buf_in = ""
	return result
end
function stdin:seek(whence, offset) end
function stdin:write() end

io.stdin = stdin
io.stdout = stdout
io.stderr = stderr








