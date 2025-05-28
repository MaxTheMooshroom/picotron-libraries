--[[pod_format="raw",created="2025-04-07 20:06:34",icon=userdata("u8",16,16,"00121212121212121212120000000000001217171717171717170e1200000000001217171717171717170e0e12000000001217171717171717170e0e0e120000001217171712121212170e0e0e0e120000121717121d1d1d1d121717171712000012171717121d1d12171717171712000012171717121d1d12171717171712000012171717121d1d12171217171712000012171717121d1d12121d121717120000121717121d1d1d1d1d1d12171712000012171717121212121212171717120000121717171717171717171717171200001217171717171717171717171712000012171717171717171717171717120000121212121212121212121212121200"),modified="2025-04-08 06:48:23",revision=11]]

require("sys.p8tron-plus")
require("std.module")
require("std.os")
require("std.io")

term = {}

function term.init()
	local _path = fetch("/appdata/system/pods/path.pod")
	if not _path then
		_path = {
			"/system/util",
			"/system/apps",
			"/appdata/system/util",
			"/apps"
		}
		store("/appdata/system/pods/path.pod", _path)
	end
	os.setenv("PATH", table.concat(_path, ":"))

	local _locale = fetch("/appdata/system/pods/locale.pod")
	if not _locale then
		_locale = {
			lang      = "en_US.UTF-8",
			all       = nil,
			collate   = "C", -- default sorting order (binary, fast, consistent)
			ctype     = "en_US.UTF-8", -- character classification and case conversion
			messages  = "en_US.UTF-8", -- language used for system messages
			monetary  = "en_US.UTF-8", -- currency and monetary formatting
			numeric   = "en_US.UTF-8",
			time      = "en_US.UTF-8" -- date and time formatting
		}
		store("/appdata/system/pods/locale.pod", _locale)
	end
	os.setenv("LC_ALL", _locale.all)
	os.setenv("LC_COLLATE", _locale.collate)
	os.setenv("LC_CTYPE", _locale.ctype)
	os.setenv("LC_MESSAGES", _locale.messages)
	os.setenv("LC_MONETARY", _locale.monetary)
	os.setenv("LC_NUMERIC", _locale.numeric)
	os.setenv("LC_TIME", _locale.time)
	os.setenv("LANG", _locale.lang)

end

term.commands = {}

function term.commands.cd(argv)
	local err_msg = cd(argv[1])
	if err_msg then
		io.stderr:write(err_msg)
		io.stderr:flush()
		return false
	end
	return true
end

function term.commands.exit(argv) exit(0); return false end
function term.commands.cls(argv) return true end
function term.commands.reset(argv) reset(); return true end
function term.commands.resume(argv) return true end

function term.resolve_path(name)
	local path = os.getenv("PATH")
	todo("need to check path variable")
end

function term.fallback_shell(command, _env)
	local argv0 = split(command, " ")
	local argv = {}
	for _,v in ipairs(argv0) do if v ~= "" then add(argv, v) end end
	local cmd = deli(argv, 1)
	if term.commands[cmd] then
		if term.commands[cmd](argv) then
			return todo()
		else
			return todo()
		end
	else
		local prog = term.resolve_path(cmd)
		if prog then
			todo()
		else
			-- try running as lua
			todo()
		end
	end
end

function term.run(command, shell, _env)
	local id
	if not shell then
		id = term.fallback_shell(command, _env)
	else
		id = create_process(shell, {path=pwd(),argv={command},vars=_env})
	end

	os.sleep(0)
end

