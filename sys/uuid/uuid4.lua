--[[pod_format="raw",created="2025-04-09 09:05:01",icon=userdata("u8",16,16,"00121212121212121212120000000000001217171717171717170e1200000000001217171717171717170e0e12000000001217171717171717170e0e0e120000001217171712121212170e0e0e0e120000121717121d1d1d1d121717171712000012171717121d1d12171717171712000012171717121d1d12171717171712000012171717121d1d12171217171712000012171717121d1d12121d121717120000121717121d1d1d1d1d1d12171712000012171717121212121212171717120000121717171717171717171717171200001217171717171717171717171712000012171717171717171717171717120000121212121212121212121212121200"),modified="2025-05-29 05:57:46",revision=10]]

require("sys.uuid")

local function uuid4(ud)
	-- fill with random bytes
	ud:mutate("i64")
	ud:set(0,
		math.random(0, math.maxinteger),
		math.random(0, math.maxinteger)
	)
	ud:mutate("u8")

	-- set version (high nibble of byte 6) to 4
	ud:band(0x0f, true, nil, 6, 1)		-- clear high nibble
	ud:bor(0x40, true, nil, 6, 1)		-- set version bits

	-- set variant (two highest bits of byte 8) to 10
	ud:band(0x3f, true, nil, 8, 1)		-- clear two highest bits
	ud:bor(0x80, true, nil, 8, 1)		-- set variant
end

function uuid.uuid4(from)
	local ud = userdata("u8", 16)
	if type(from) == "string" then
		uuid._uuid_from_str(ud, from, "4")
	else
		uuid4(ud)
	end
	return ud
end
