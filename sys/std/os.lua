--[[pod_format="raw",created="2025-03-26 05:36:29",icon=userdata("u8",16,16,"00121212121212121212120000000000001217171717171717170e1200000000001217171717171717170e0e12000000001217171717171717170e0e0e120000001217171712121212170e0e0e0e120000121717121d1d1d1d121717171712000012171717121d1d12171717171712000012171717121d1d12171717171712000012171717121d1d12171217171712000012171717121d1d12121d121717120000121717121d1d1d1d1d1d12171712000012171717121212121212171717120000121717171717171717171717171200001217171717171717171717171712000012171717171717171717171717120000121212121212121212121212121200"),modified="2025-05-29 06:52:23",revision=78]]

os = {}

-- todo: when exactly should
-- /appdata/system/pods/vars.pod
-- be loaded?
local vars = env().vars or {}

local start_time -- initialized after os.now() is defined
function os.clock()
	return (os.now() - start_time) // 1000
end

os.date = date

function os.difftime(t2, t1) return t2 - t1 end

function os.execute(command)
	require("sys.term")
	return term.run(command, vars["SHELL"], vars)
end

function os.exit(code) exit(code) end

function os.getenv(name) return vars[name] end

function os.remove(filename) rm(filename) end

function os.rename(oldname, newname) mv(oldname, newname) end

function os.setlocale(locale, category)
	category = category or "all"
	if type(category) ~= "string" then return nil end
	category = category:lower()
	if category == "all" then
		if not locale then return os.getenv("LC_ALL") end
		if locale == "" then locale = nil end
		os.setenv("LC_ALL", locale)
		return locale
	elseif category == "collate" then
		if not locale then return os.getenv("LC_ALL") or os.getenv("LC_COLLATE") end
		if locale == "" then locale = "C" end
		os.setenv("LC_COLLATE", locale)
		return locale
	elseif category == "ctype" then
		if not locale then return os.getenv("LC_ALL") or os.getenv("LC_CTYPE") end
		if locale == "" then locale = "en_US.UTF-8" end
		os.setenv("LC_CTYPE", locale)
		return locale
	elseif category == "messages" then
		if not locale then return os.getenv("LC_ALL") or os.getenv("LC_MESSAGES") end
		if locale == "" then locale = "en_US.UTF-8" end
		os.setenv("LC_MESSAGES", locale)
		return locale
	elseif category == "monetary" then
		if not locale then return os.getenv("LC_ALL") or os.getenv("LC_MONETARY") end
		if locale == "" then locale = "en_US.UTF-8" end
		os.setenv("LC_MONETARY", locale)
		return locale
	elseif category == "numeric" then
		if not locale then return os.getenv("LC_ALL") or os.getenv("LC_NUMERIC") end
		if locale == "" then locale = "en_US.UTF-8" end
		os.setenv("LC_NUMERIC", locale)
		return locale
	elseif category == "time" then
		if not locale then return os.getenv("LC_ALL") or os.getenv("LC_TIME") end
		if locale == "" then locale = "en_US.UTF-8" end
		os.setenv("LC_TIME", locale)
		return locale
	else
		return nil
	end
end

function os.time(tbl)
	if type(tbl) == "table" then
		local tz_local = os.setlocale(nil, "time")
		todo()
		return dt:posix()
	elseif not tbl then
		return math.tointeger(os.now())
	end
end

function os.tmpname()
	if not fstat("/ram/tmp/") then mkdir("/ram/tmp/") end
	local proto = "/ram/tmp/"..pid()
	local result = proto
	local i = 0
	while fstat(result) do
		result = proto.."_"..i
		i = i + 1
	end
	return result
end

-- =======================================
--         NON-STANDARD FUNCTIONS
-- =======================================

function os.joinpaths(...)
	local sep = split(package.config, "\n")[1]
	local paths = {...}
	for i=1,#paths do
		if paths[i][#paths[i]] == sep then
			paths[i] = sub(paths[i], 1, -2)
		end
	end
	for i=2,#paths do
		if paths[i][1] == sep then
			paths[i] = sub(paths[i], 2)
		end
	end
	return table.concat(paths, sep)
end

function os.setenv(varname, value)
	vars[tostring(varname)] = tostring(value)
end

-- expected to be called during an "interrupt"
-- while the main process is paused. So you
-- would do something like:
-- ```lua
-- on_message("wake", function() os.resume() end)
-- -- ...
-- 
-- ```
function os.resume()
	poke(0x547f, peek(0x547f) & ~0x4)
end

-- generally speaking, this function is unsafe
-- because it assumes an external process will
-- send an 'unpause' event, or that os.resume()
-- will be called by one of its own event
-- callbacks.
function os.yield()
	poke(0x547f, peek(0x547f) | 0x4)
	flip(0x4)
end

-- yield out of the process for a given number of seconds.
-- events are still handled while sleeping.
function os.sleep(secs)
	if not secs or secs == 0 then flip(); return end
	send_message(pid(), {event="unpause", _delay=secs})
	os.yield()
end

-- current time as unix timestamp in ms instead of secs
function os.now(ms)
	return math.tointeger(stat(86) * 1000 + stat(987))
end
start_time = os.now()







