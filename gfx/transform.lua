--[[pod_format="raw",created="2025-04-12 22:18:54",modified="2025-04-13 01:05:38",revision=4]]

require("class")

gfx = gfx or {}
transform = class("transform")

function transform:init(pos, rot, scale)
	if type(pos) == "table" and #pos == 3 then
		self.pos = {pos[1], pos[2], pos[3]}
	elseif type(pos) == "userdata" and pos:width() == 3 then
		self.pos = pos
	else
		self.pos = vec(1,1,1)
	end

	if type(rot) == "table" and (#rot == 3) or (#rot == 4) then
		self.rot = {rot[1], rot[2], rot[3], rot[4]}
	elseif type(rot) == "userdata" and (rot:width() == 3 or rot:width() == 4) then
		self.rot = rot
	else
		self.rot = vec(0,0,0)
	end

	if type(scale) == "table" or #scale == 3 then
		self.scale = {scale[1], scale[2], scale[3]}
	elseif type(scale) == "userdata" and scale:width() == 3 then
		self.scale = scale
	else
		self.scale = vec(1,1,1)
	end
end

