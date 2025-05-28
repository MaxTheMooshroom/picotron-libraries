--[[pod_format="raw",created="2025-03-26 05:34:29",icon=userdata("u8",16,16,"00121212121212121212120000000000001217171717171717170e1200000000001217171717171717170e0e12000000001217171717171717170e0e0e120000001217171712121212170e0e0e0e120000121717121d1d1d1d121717171712000012171717121d1d12171717171712000012171717121d1d12171717171712000012171717121d1d12171217171712000012171717121d1d12121d121717120000121717121d1d1d1d1d1d12171712000012171717121212121212171717120000121717171717171717171717171200001217171717171717171717171712000012171717171717171717171717120000121212121212121212121212121200"),modified="2025-04-12 22:03:28",revision=33]]

local _debug = debug

function report_error(title, ...)
    local messages = {...}
    send_message(3, {event="report_error", content="*"..title})
    for i=1,#messages do
        send_message(3, {event="report_error", content=messages[i]})
    end
    exit(1)
end

function todo(msg)
    report_error(
        "todo: not yet implemented!",
        msg,
        "==========",
        _debug.traceback(nil, 2)
    )
    exit(2)
end

function unimplemented()
    report_error(
        "unimplemented!",
        "(and probably never will be)",
        "==========",
        _debug.traceback(nil, 2)
    )
    exit(2)
end

--- Checks if table `value` is a @see class object.
-- @tparam table value the table to check
-- @treturn boolean whether it's a class object
function isclass(value)
	return value.name and getmetatable(value).instanceOf
end

--- Checks if table `value` is an instance of a
--- @see class object.
-- @tparam table value the table to check
-- @treturn boolean whether it's a class instance
function isclassinstance(value)
	return value.class and getmetatable(value).instanceOf
end

--- Checks if `value` is the type described by `compare`.
-- @tparam any value the value to check the type of
-- @tparam string|table compare the type to check against.
--         Can be either a string or a class object.
-- @treturn boolean whether `value` is `compare`
function istype(value, compare)
	local vtype = type(value)
	local ctype = type(compare)
	local isclassi = isclassinstance(value)
	local cisclassi = ctype == "table" and isclass(compare) or false
	local cisclass = isclassinstance(compare)

	if vtype ~= "table" and ctype == "string" then
		return vtype == compare
	elseif vtype ~= "table" then
		return false
	elseif ctype == "string" and compare == "table" then
		return true
	elseif ctype == "string" and isclassi then
		return value.class.name == compare
	elseif cisclassi and isclassi then
		return value:instanceOf(com_type)
	else
		return false
	end
end

--- Checks if `value` is any of the types described by
--- `compare`.
-- @tparam any value the value to check the type of
-- @tparam {string|table} compare the type to check against.
--         Can be either a string or a class object.
-- @treturn boolean whether `value` is any of the `compare`
--          values
function istypes(value, compares)
	if type(compares) ~= "table" then return istype(value, compares) end
	for compare in table.values(compares) do
		if istype(value, compare) then return true end
	end
	return false
end

function expect_type(value, compare)
	if not istype(value, compare) then
		error("expected type '"..tostring(compare)
			.."', but got type '"..tostring(value).."'")
	end
end

function expect_types(value, com_types)
	if type(compares) ~= "table" then return expect_type(value, compares) end
end

--- Gets the type of a value. If `value` is an
--- instance of a @see class then it returns that
--- class. If is a class object itself, return the nameElse returns the result of type(value)
-- @tparam any value the value to get the type of
-- @treturn string|table the type of `value`
function typeof(value)
	local vtype = type(value)
	if vtype == "table" then
		if isclass(value) then return value.name end
		if isclassinstance(value) then return value.class end
	end
	return vtype
end

function skip(generator, skip_count)
	skip_count = skip_count or 1
	for i=1,skip_count do generator() end
end

function exhaust(generator)
	if type(generator) ~= "function" then
		error("only functions may be provided to exhaust()!")
	end
	while generator() do end
end

function collect(generator)
	if type(generator) ~= "function" then
		error("only functions may be provided to collect()!")
	end
	local result = {}
	local item
	repeat
		item = generator()
		result[#result + 1] = item
	until not item
	return result
end

function enumerate(generator)
	if type(generator) ~= "function" then
		error("only functions may be provided to collect()!")
	end
	local idx = 0
	return function()
		idx += 1
		local item = generator()
		if item then return idx, item end
		return nil
	end
end










