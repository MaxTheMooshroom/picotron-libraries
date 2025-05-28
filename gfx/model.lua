--[[pod_format="raw",created="2025-04-12 21:33:51",modified="2025-04-13 04:13:59",revision=18]]

require("sys.table")
require("sys.p8tron-plus")

require("gfx.transform") -- defines gfx

local model = class("model")
gfx.model = model

function model:init(vertex_count, tri_count)
	--self.transform = gfx.transform()
	self.material_libs = {}
	self.material_lookup = {}
end

function model:resize_verts(vert_count)
	self.vertex_buffer = userdata("f64", 4, vert_count)
	self.vertex_buffer:column(3) += 1
end

function model:resize_normals(norm_count)
	self.normal_buffer = userdata("f64", 4, norm_count)
	self.normal_buffer:column(3) += 1
end

function model:resize_tris(tri_count)
	self.index_buffer = userdata("u16", 3, tri_count)
	self.mat_buffer = userdata("u8", tri_count)
	self.tex_coord_buffer = userdata("f64", 3, tri_count)
end

function model:set_vert(n, x, y, z, w)
	self.vertex_buffer:set(0, n, x, y, z, w or 1)
end

function model:update_from_table(tbl)
	if tbl.vertices and type(tbl.vertices) == "table" and #tbl.vertices > 0 then
		self:resize_verts(#tbl.vertices)
		local s = tbl.vertices.start or 0
		for n,vertex in ipairs(tbl.vertices) do
			self.vertex_buffer:set(s + (n * 3), vertex[1], vertex[2], vertex[3], vertex[4] or 1)
		end
	end

	if tbl.normals and type(tbl.normals) == "table" and #tbl.normals > 0 then
		self:resize_normals(#tbl.normals)
		local s = tbl.normals.start or 0
		for n,normal in ipairs(tbl.normals) do
			self.normal_buffer:set(s + (n * 3), normal[1], normal[2], normal[3])
		end
	end

	if tbl.tris and type(tbl.tris) == "table" and #tbl.tris > 0 then
		self:resize_tris(#tbl.tris)
		local do_tc = tbl.tex_coords and type(tbl.tex_coords) == "table" and #tbl.tex_coords == #tbl.tris
		local do_mats = tbl.mats and type(tbl.mats) == "table" and #tbl.mats == #tbl.tris

		local to_gen = {tbl.tris}
		if do_tc then add(to_gen, tbl.tex_coords) end
		if do_mats then add(to_gen, tbl.mats) end

		local s = tbl.tris.start or 0
		local tc
		local mat
		for n,vertex,v2,v3 in enumerate(table.zip(unpack(to_gen))) do
			if do_mat and do_mat then
				tc = v2
				mat = v3
			elseif do_mat then
				mat = v2
			end
				
			self.index_buffer:set(s + (n * 3), vertex[1], vertex[2], vertex[3])
			if do_tc then self.tex_coord_buffer:set(s + (n * 3), tc[1], tc[2], tc[3]) end
			if do_mat then self.mat_buffer:set(s + (n * 3), mat) end
		end
	end
end
