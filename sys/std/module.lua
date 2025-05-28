--[[pod_format="raw",created="2025-03-26 06:56:26",icon=userdata("u8",16,16,"00121212121212121212120000000000001217171717171717170e1200000000001217171717171717170e0e12000000001217171717171717170e0e0e120000001217171712121212170e0e0e0e120000121717121d1d1d1d121717171712000012171717121d1d12171717171712000012171717121d1d12171717171712000012171717121d1d12171217171712000012171717121d1d12121d121717120000121717121d1d1d1d1d1d12171712000012171717121212121212171717120000121717171717171717171717171200001217171717171717171717171712000012171717171717171717171717120000121212121212121212121212121200"),modified="2025-05-07 20:55:13",revision=145]]

package = {}

local default_config = table.concat({
	"/", -- dir seperator
	";", -- path seperator
	"?", -- sub marker
	"!", -- marker for replace with env().argv[0]
	"-", -- n/a - present for compat
}, "\n")

local _config = fetch("/appdata/system/pods/pconfig.pod")
if not _config then
	package.config = default_config
	store("/appdata/system/pods/pconfig.pod", default_config)
elseif type(_config) == "string" then
	if #_config ~= 9 then
		package.config = default_config
		store("/appdata/system/pods/pconfig.pod", default_config)
	end
elseif type(_config) == "table" then
	if #_config ~= 5 then
		package.config = default_config
		store("/appdata/system/pods/pconfig.pod", default_config)
	end
else
	package.config = default_config
	store("/appdata/system/pods/pconfig.pod", default_config)
end

if not package.config then package.config = _config end

local function dirsep() return split(package.config, "\n")[1] end
local function pathsep() return split(package.config, "\n")[2] end

package.cpath = "<no-c>" -- compat

package.loaded = {
	sys = {},
	["sys.string"] = {},
	["std.module"] = {},
}
package.preload = {} -- compat
package.searchers = {}

-- compat stub
function package.loadlib(libname, funcname) end

if not env().vars or not env().vars.LUA_PATH then
	local lpath = fetch("/appdata/system/pods/lpath.pod")
	if not lpath then
		lpath = {
			"/system/util/?.lua",
			"/appdata/system/util/?.lua",
			"/appdata/system/util/?/init.lua",
			"/lib/?.lua",
			"/lib/?/init.lua",
			"?.lua",
			"?/init.lua",
		}
		store("/appdata/system/pods/lpath.pod", lpath)
	end
	package.path = table.concat(lpath, pathsep())
else
	package.path = env().vars.LUA_PATH
end

function package.searchpath(modname, lpath, sep, rep)
	sep = sep or "%."
	rep = rep or dirsep()
	modname = modname:gsub(sep, rep)

	errs = {}
	for _,path in pairs(split(lpath, ";")) do
		local fpath = path:gsub("?", modname)
		if fstat(fpath) == "file" then
			return fpath, nil
		end
		add(errs, "\tno file '"..fpath.."'")
	end
	
	local all_errs = table.concat(errs, "\n")
	print("all: "..all_errs)
	return nil, all_errs
end

function package.searchers.default(modname)
	local path, errmsg = package.searchpath(modname, package.path)
	if not path then
		return nil, errmsg
	end
	local fn, errmsg = loadfile(path)
	if not fn then
		return nil, errmsg
	end
	return fn, path
end

local function run_searchers(modname)
	local errs = {"\tno field package.preload['"..modname.."']"}
	for k,searcher in pairs(package.searchers) do
		local fn, args = searcher(modname)
		if fn then
			package.loaded[modname] = {fn(args)}
			return
		else
			add(errs, args)
		end
	end

	error(
		"module '"..modname.."' not found\n"
		..table.concat(errs, "\n").."\n"
		..debug.traceback(nil, 1),
		1
	)
end

function require(modname)
	if package.loaded[modname] then return unpack(package.loaded[modname]) end
	run_searchers(modname)
	return table.unpack(package.loaded[modname] or {})
end

function unrequire(...)
	for _,modname in ipairs({...}) do
		if package.loaded[modname] then
			print("Unloading "..modname)
			package.loaded[modname] = nil
		end
	end
end







