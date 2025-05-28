--[[pod_format="raw",created="2025-05-17 13:07:02",icon=userdata("u8",16,16,"00121212121212121212120000000000001217171717171717170e1200000000001217171717171717170e0e12000000001217171717171717170e0e0e120000001217171712121212170e0e0e0e120000121717121d1d1d1d121717171712000012171717121d1d12171717171712000012171717121d1d12171717171712000012171717121d1d12171217171712000012171717121d1d12121d121717120000121717121d1d1d1d1d1d12171712000012171717121212121212171717120000121717171717171717171717171200001217171717171717171717171712000012171717171717171717171717120000121212121212121212121212121200"),modified="2025-05-28 08:50:24",revision=4]]require("class")

require("sys.uuid.uuid4")
require("sys.table")

event = class("event")

function event.__newindex(tbl, key, value)
	tbl.data[key] = value
end

function event:init(_type, _from)
	if not _type then error("cannot make an event with no type") end

	rawset(self, "subscribe", nil)
	rawset(self, "unsubscribe", nil)

	rawset(self, "data", _from or {})
	self.event = _type
end

function event:submit(...)
	local pids = {...}
	for _pid in table.values(pids) do
		send_message(_pid, self.data)
	end
end

event_handles = {}
event_types = {}

local function event_dispatch(event)
    local _type = event.event
    for id in table.values(event_types) do
    	event_handles[id](event)
    end
end

function event.subscribe(_type, fn)
	local id = uuid.tostring(uuid.uuid4())

	-- VERY unlikely to ever run twice, let alone thrice
	while event_handles[id] do id = uuid.tostring(uuid.uuid4()) end

	if not event_types[_type] then
		event_types[_type] = {id}
		on_event(_type, event_dispatch)
	else
		table.insert(event_types, id)
	end

	event_handles[id] = fn
	return id
end

function event.unsubscribe(id)
	if not event_handles[id] then return end
	event_handles[id] = nil

	for e in table.keys(event_types) do
		for i=#e,1,-1 do
			if e[i] == id then
				table.remove(e, i)
			end
		end
	end
end
