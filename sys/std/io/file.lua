--[[pod_format="raw",created="2025-04-09 00:54:29",icon=userdata("u8",16,16,"00121212121212121212120000000000001217171717171717170e1200000000001217171717171717170e0e12000000001217171717171717170e0e0e120000001217171712121212170e0e0e0e120000121717121d1d1d1d121717171712000012171717121d1d12171717171712000012171717121d1d12171717171712000012171717121d1d12171217171712000012171717121d1d12121d121717120000121717121d1d1d1d1d1d12171712000012171717121212121212171717120000121717171717171717171717171200001217171717171717171717171712000012171717171717171717171717120000121212121212121212121212121200"),modified="2025-05-17 13:03:56",revision=2]]

local file = {}

function file:seek(whence, offset)
	whence = whence or "cur"
	offset = offset or 0
	if whence == "set" then
		if offset < 0 then return nil, "cannot set position to negative values" end
		if offset >= self.len then return nil, "cannot set position higher than length" end
		self.pos = offset
	elseif whence == "cur" then
		if self.pos + offset < 0 then return nil, "cannot set position to negative values" end
		if self.pos + offset >= self.len then return nil, "cannot set position higher than length" end
		self.pos += offset
	elseif whence == "end" then
		if self.len + offset < 0 then return nil, "cannot set position to negative values" end
		if self.len + offset >= self.len then return nil, "cannot set position higher than length" end
		self.pos = self.len + offset
	else
		return nil, "unknown 'whence' value"
	end
	return self.pos
end
