--[[pod_format="raw",created="2025-05-01 02:53:48",icon=userdata("u8",16,16,"00121212121212121212120000000000001217171717171717170e1200000000001217171717171717170e0e12000000001217171717171717170e0e0e120000001217171712121212170e0e0e0e120000121717121d1d1d1d121717171712000012171717121d1d12171717171712000012171717121d1d12171717171712000012171717121d1d12171217171712000012171717121d1d12121d121717120000121717121d1d1d1d1d1d12171712000012171717121212121212171717120000121717171717171717171717171200001217171717171717171717171712000012171717171717171717171717120000121212121212121212121212121200"),modified="2025-05-01 07:26:56",revision=8]]-- reduced version of my better implementation because the better
-- one is for an environment that isn't yet available to picotron
local function loadfile(path, mode, _env)
	mode = mode or "bt"
	local chunkname = split(path:basename(), ".")[1]
	local contents = fetch(path)

	-- grrrr.
	-- This c-function checks the number of params
	-- passed, rather than also checking if the values
	-- are nil. So then only way to optionally provide
	-- _env to loadfile() is to have branches where
	-- env is only passed to load() when actually
	-- provided to loadfile().
	if _env then
		return load(contents, chunkname, mode, _env)
	else
		return load(contents, chunkname, mode)
	end
end

local sub_updates = {}
local sub_draws = {}

local function canon_update(...)
	for _,update in ipairs(sub_updates) do
		update(...)
	end
end

local function canon_draw(...)
	for _,draw in ipairs(sub_draws) do
		draw(...)
	end
end

-- NOTE: restore old metatable with:
-- setmetatable(_G, getmetatable(getmetatable(_G)))

if not (getmetatable(_G) or {}).submodule_hooks then
	local old_mt = getmetatable(_G) or {}
	local mt = { submodule_hooks = true }
	setmetatable(mt, { __index = old_mt })
	
	local old_index, old_newindex = old_mt.__index, old_mt.__newindex
	mt.__index = function(tbl, key)
		if key == "_update" then
			return canon_update
		elseif key == "_draw" then
			return canon_draw
		elseif old_index then
			return old_index(tbl, key)
		else
			return rawget(tbl, key)
		end
	end
	mt.__newindex = function(tbl, key, value)
		if key == "_update" then
			table.insert(sub_updates, value)
		elseif key == "_draw" then
			table.insert(sub_draws, value)
		elseif old_newindex then
			old_newindex(tbl, key, value)
		else
			rawset(tbl, key, value)
		end
	end
	setmetatable(_G, mt)
end

