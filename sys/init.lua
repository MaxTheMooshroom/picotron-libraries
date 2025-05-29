--[[pod_format="raw",created="2025-03-26 05:27:27",icon=userdata("u8",16,16,"00121212121212121212120000000000001217171717171717170e1200000000001217171717171717170e0e12000000001217171717171717170e0e0e120000001217171712121212170e0e0e0e120000121717121d1d1d1d121717171712000012171717121d1d12171717171712000012171717121d1d12171717171712000012171717121d1d12171217171712000012171717121d1d12121d121717120000121717121d1d1d1d1d1d12171712000012171717121212121212171717120000121717171717171717171717171200001217171717171717171717171712000012171717171717171717171717120000121212121212121212121212121200"),modified="2025-05-28 10:37:02",revision=74]]
lib_settings = fetch("/lib/settings.pod") or {}

include "/lib/sys/p8tron-plus.lua"

function loadfile(path, mode, _env)
	mode = mode or "bt"

	local file -- = io.stdin
	if path then
		local fmode = "r"
		if mode == "b" or mode == "bt" then
			fmode = "rb"
		end
		-- todo: use io lib
		-- file = io.open(path, fmode)
		file = {}
		function file:read() return fetch(path) end
	else
		todo("io not yet implemented; needs io.stdin\nloadfile() must be provided a path")
		-- todo: use io lib
		-- file = io.stdin
	end

	local chunkname = "<stdin>"
	if path then chunkname = path:stem() end

	local contents = file:read()
	if _env then
		return load(contents, chunkname, mode, _env)
	else
		-- grrrr.
		-- This c-function checks the number of params
		-- passed, rather than also checking if the values
		-- are nil. So then only way to optionally provide
		-- _env to loadfile() is to have branches where
		-- env is only passed to load() when actually
		-- provided to loadfile().
		return load(contents, chunkname, mode)
	end
end

function dofile(path) return loadfile(path)() end

local _error = _error or error
local _pcall = _pcall or pcall
local _pcall_depth = _pcall_depth or 0
local _exit = _exit or exit

function error(msg, level)
	if _pcall_depth == 0 then
		print(msg)
		report_error(msg)
	end
	_error(msg, (level or 1) + 2)
end

function pcall(fn, ...)
	_pcall_depth += 1
	local results = {_pcall(fn, ...)}
	_pcall_depth -= 1
	local ok = deli(results, 1)
	if not results[1] then
		return false, unpack(results)
	end
	return true, unpack(results)
end

function xpcall(fn, err_handle, ...)
	local results = {pcall(fn, ...)}
	local ok = deli(results, 1)
	if not ok then
		return false, err_handle(unpack(results))
	end
	return true, unpack(results)
end

function exit(code)
	if env().immortal then return end
	local codes = fetch("/ram/system/exit_codes.pod") or {}
	add(codes, {id=pid(),code=code})
	store("/ram/system/exit_codes.pod", codes)
	_exit(code)
end

include "/lib/sys/string.lua"
include "/lib/sys/std/module.lua"

require("class")

require("sys.buffer")

--require("std.io")
require("sys.std.os")

