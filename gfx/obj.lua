--[[pod_format="raw",created="2025-04-12 23:44:43",modified="2025-04-13 04:13:41",revision=11]]

require("sys.table")

require("gfx.model") -- defines gfx

local obj = {}
gfx.obj = obj

--- loads a @see gfx.model by parsing the source
--- of a wavefront obj file.
-- @tparam string str the source to parse
-- @treturn gfx.model the constructed model
-- @treturn nil,string an error has occurred, the error message
function obj.load_source(str)
	local vertices = {}
	local normals = {}
	local tex_coords = {}
	local tris = {}

	local mat_libs = {}
	local mats = {}

	local errors = {}

	local words
	local cmd
	local current_mat = "default"

	for i,line in ipairs(split(str, "\n")) do
		words = split(line, " ")
		cmd = deli(words, 1)

		if line[1] == "#" or cmd[1] == "#" then
			goto line_continue
		elseif cmd == "v" then -- vertex
			if not (#words == 3 or #words == 4) then
				add(errors, "line "..i..": vertices must consist of 3 or 4 values")
				goto line_continue
			end
			add(vertices, {
				tonum(words[1]),
				tonum(words[2]),
				tonum(words[3]),
				tonum(words[4]) or 1
			})
		elseif cmd == "vt" then -- texture coord
			if not (#words >= 1 and #words <= 3) then
				add(errors, "line "..i..": tex coords must consist of 1, 2, or 3 values")
				goto line_continue
			end
			add(tex_coords, {
				tonum(words[1]),
				tonum(words[2]) or 0,
				tonum(words[3]) or 0
			})
		elseif cmd == "vn" then -- texture normal
			if #words ~= 3 then
				add(errors, "line "..i..": vertex normals must consist of 3 values")
				goto line_continue
			end
			add(normals, {
				tonum(words[1]),
				tonum(words[2]),
				tonum(words[3]),
			})
		elseif cmd == "vp" then -- parameter-space vertex
			add(errors, "line "..i..": parameter-space vertices not supported")
			goto line_continue
		elseif cmd == "f" then -- polygonal face
			if #words ~= 3 then
				add(errors, "line "..i..": faces must consist of 3 vertices (only tris are supported)")
				goto line_continue
			end
			add(mats, current_mat)
			add(tris, {
				[1]=words[1],
				[2]=words[2],
				[3]=words[3]
			})
		elseif cmd == "l" then -- line for polyline
			add(errors, "line "..i..": parameter-space vertices not supported")
			goto line_continue
		elseif cmd == "mtllib" then
			if #words > 1 then
				add(errors, "line "..i..": mtllib has more than one argument?")
				goto line_continue
			end
			add(mat_libs, words[1])
		elseif cmd == "usemtl" then
			if #words > 1 then
				add(errors, "line "..i..": usemtl has more than one argument?")
				goto line_continue
			end
			current_mat = words[1]
		else
			add(errors, "line "..i..": unknown command '"..cmd.."'")
		end
		
		::line_continue::
	end

	local update_tbl = {}
	update_tbl.vertices = vertices
	update_tbl.normals = normals
	update_tbl.tex_coords = tex_coords
	update_tbl.mats = mats
	update_tbl.tris = tris

	local m = gfx.model()
	m:update_from_table(update_tbl)
	return m, errors
end

--- loads a @see gfx.model by parsing the source
--- of a wavefront obj file.
-- @tparam string path the filepath of the source
--         to parse
-- @treturn gfx.model the constructed model
-- @treturn nil an error has occurred
function obj.load_file(path)
	if path:ext() ~= "obj" then return nil end
	if not fstat(fullpath(path)) then return nil end

	local source = fetch(path)
	if not source then return nil end -- todo: report error?
	return obj.load_source(source)
end
