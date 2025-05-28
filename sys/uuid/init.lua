--[[pod_format="raw",created="2025-04-09 01:28:01",icon=userdata("u8",16,16,"00121212121212121212120000000000001217171717171717170e1200000000001217171717171717170e0e12000000001217171717171717170e0e0e120000001217171712121212170e0e0e0e120000121717121d1d1d1d121717171712000012171717121d1d12171717171712000012171717121d1d12171717171712000012171717121d1d12171217171712000012171717121d1d12121d121717120000121717121d1d1d1d1d1d12171712000012171717121212121212171717120000121717171717171717171717171200001217171717171717171717171712000012171717171717171717171717120000121212121212121212121212121200"),modified="2025-05-07 21:33:48",revision=16]]

require("sys.table")

uuid = {}

local uuid_fstring_from = "(%x%x)(%x%x)(%x%x)(%x%x)-?"
								.."(%x%x)(%x%x)-?(%x%x)(%x%x)-?(%x%x)(%x%x)-?"
								.."(%x%x)(%x%x)(%x%x)(%x%x)(%x%x)(%x%x)"
function uuid._uuid_from_str(ud, str, version, variants)
	variants = variants or {}
	local bytes = {str:match(uuid_fstring_from)}
	assert(#bytes == 16, "invalid uuid string: pattern")
	assert(bytes[7][1] == version, "invalid uuid string: version: "..bytes[7][1])
	--assert(table.any(table.map(variants, function(x)
	--		tonumber(bytes[9][1], 16) & 
	--	end)),
	--	"invalid uuid string: variant: "..
	--)

	table.apply(bytes, function(x) return tonumber(x, 16) end)

	ud:set(0, table.unpack(bytes))
end

local uuid_fstring_to = 	"%x%x%x%x-"
							..	"%x%x-%x%x-%x%x-"
							..	"%x%x%x%x%x%x"
function uuid.tostring(ud)
	return uuid_fstring_to:format(ud:get(0, 16))
end
