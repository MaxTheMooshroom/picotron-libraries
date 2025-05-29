--[[pod_format="raw",created="2025-04-09 04:31:33",icon=userdata("u8",16,16,"00121212121212121212120000000000001217171717171717170e1200000000001217171717171717170e0e12000000001217171717171717170e0e0e120000001217171712121212170e0e0e0e120000121717121d1d1d1d121717171712000012171717121d1d12171717171712000012171717121d1d12171717171712000012171717121d1d12171217171712000012171717121d1d12121d121717120000121717121d1d1d1d1d1d12171712000012171717121212121212171717120000121717171717171717171717171200001217171717171717171717171712000012171717171717171717171717120000121212121212121212121212121200"),modified="2025-05-29 06:49:25",revision=151]]

--- Produce a generator that iterates over the table's keys.
-- @tparam table tbl the table whose keys to iterate over
-- @treturn function the generator
function table.keys(tbl)
	if type(tbl) ~= "table" then return function() end end
	local idx = nil
	return function()
		idx = next(tbl, idx)
		return idx
	end
end

--- Produce a generator that iterates over the table's values.
-- @tparam table tbl the table whose values to iterate over
-- @treturn function the generator
function table.values(tbl)
	if type(tbl) ~= "table" then return function() end end
	local idx = nil
	return function()
		idx = next(tbl, idx)
		return tbl[idx]
	end
end

--- Pass each of a table's values (and keys) to a provided function.
--- You can also pass a generator as the `tbl` and run `fn` on each
--- of the values produced by the generator.
-- @tparam table|function tbl the table whose key-value pairs to
--         iterate over
-- @tparam function fn a function with params (value, key?)
-- @usage
-- -- prints '1' '2' '3' and '4'
-- table.foreach({1,2,3,4}, print)
-- @usage
-- -- prints 'b' 'a' 'd' and 'c'
-- table.foreach(table.keys({a=1,b=2,c=3,d=4}), print)
function table.foreach(tbl, fn)
	if type(tbl) == "table" then
		for k,v in pairs(tbl) do fn(v, k) end
	elseif type(tbl) == "function" then -- generator
		local results
		repeat
			results = {tbl()}
			if #results > 0 then fn(unpack(results)) end
		until #results == 0
	end
end

--- Iterate over a table's key-value pairs, printing
--- them as `tostr(k)..": "..tostr(v)`.
-- @tparam table tbl the table to iterate over
function table.list(tbl)
	table.foreach(tbl, function(v,k) print(tostr(k)..": "..tostr(v)) end)
end

--- Iterate over a table's key-value pairs, printing
--- them as `tostr(k)..": "..tostr(v)`.
-- @tparam table tbl the table to iterate over
function table.list_keys(tbl)
	print(table.concat(collect(table.keys(tbl)), "\n"))
end

--- Iterate over a table's values, passing them to fn(),
--- and returning the results from the generator. Is
--- intended to produce new, "transformed" tables.
-- @tparam table tbl the table whose values to iterate over
-- @tparam function fn the function to map the values with
-- @treturn table the new table with processed values
function table.map(tbl, fn)
	if type(tbl) ~= "table" and type(fn) ~= "function" then return end
	
	local result = {}
	local idx = next(tbl, nil)
	while idx ~= nil do
		result[idx] = fn(tbl[idx])
		idx = next(tbl, idx)
	end
	return result
end

--- Produce a generator that iterates over a table's values,
--- passing them to fn(), saving the changes back to tbl,
--- and returning the results from the generator. Is intended
--- to modify a table's values in-place as they're iterated
--- over.
-- @tparam table tbl the table whose values to iterate over
-- @tparam function fn the function to map the values with
-- @treturn function the generator
function table.apply(tbl, fn)
	if type(tbl) ~= "table" and type(fn) ~= "function" then return end
	
	local idx = next(tbl, nil)
	while idx ~= nil do
		tbl[idx] = fn(tbl[idx])
		idx = next(tbl, idx)
	end
end

function table.zip(...)
	local gens = {}
	for value in table.values({...}) do
		if type(value) == "table" then
			add(gens, table.values(value))
		elseif type(value) == "function" then
			add(gens, value)
		end
	end
	return function()
		local values = collect(table.map(gens, function(x)
			if x then
				return x() or "<<EOF"
			else
				return "<<EOF"
			end
		end))
		for i=#values,1,-1 do
			if values[i] == "<<EOF" then
				deli(gens, i)
				deli(values, i)
			end
		end
		return unpack(values)
	end
end

--- "Reduce" a table to a single value by repeatedly
--- performing "acc = fn(acc, x)" for each of a table's
--- values, resulting in only one value at the end. Returns
--- the result of the final fn(a,b).
--- 
--- Only iterates over sequential numerical keys. By default,
--- missing keys (where the value of that key is nil) is
--- provided to the provided function, so you may receive
--- nil. If you would like to skip these values (ie continue
--- until the current key's value is not nil), provide "true"
--- for the `skip_nil` parameter.
--
-- @tparam table tbl the table to reduce
-- @tparam function fn a function that takes a and b
--         and returns the result of some operation
--         between them
-- @tparam[opt] boolean skip_nil if true, skips keys with
--              nil values
-- @treturn any the reduced value
--
-- @usage
-- function sum(tbl)
-- 	return table.reduce(tbl, function(a,b) return a+b end, true)
-- end
function table.reduce(tbl, fn, skip_nil)
	if type(tbl) ~= "table" or type(fn) ~= "function" then return end
	if #tbl == 0 then return end

	local accumulator = tbl[1]
	for i=2,#tbl do
		if tbl[i] or (not tbl[i] and not skip_nil) then
			accumulator = fn(accumulator, tbl[i])
		end
	end
	return accumulator
end

--- "Fold" a table into a value by repeatedly performing
--- "a = fn(a, b)" where b is each of a table's values,
--- resulting in only one value at the end. a is initialized
--- as `initial`, so each value in the table is applied
--- to `initial`. Returns the final result.
---
--- Unlike @see table.reduce, @see table.fold does not
--- require numerical indices, meaning the order that keys
--- are iterated over has no guarantee. As a result, operations
--- that require or expect commutativity should use
--- @see table.reduce instead.
--
-- @tparam table tbl the table to reduce
-- @tparam any initial the initial value of the accumulator
-- @tparam function fn a function that takes a and b
--         and returns the result of some operation
--         between them
-- @treturn any the folded value
function table.fold(tbl, initial, fn)
	if type(tbl) ~= "table" or type(fn) ~= "function" then return end
	if #tbl == 0 then return end

	local accumulator = initial
	for value in table.values(tbl) do
		accumulator = fn(accumulator, value)
	end
	return accumulator
end

--- "Filter" table values using a provided function
--- `fn`. `fn` should receive a table value as the
--- first parameter. `fn` should return true if the
--- value is to be in the output, and return false
--- otherwise. Filtered entries do not retain their
--- original keys.
--
-- @tparam table tbl then table to filter
-- @tparam function fn a function with signature
--         function(value) -> boolean
-- @treturn table the filtered table
function table.filter(tbl, fn)
	if type(tbl) ~= "table" or type(fn) ~= "function" then return end
	if #tbl == 0 then return end

	local results = {}
	for v in table.values(tbl) do
		local f = fn(v)
		if type(f) == "boolean" and f == true then add(results, v) end
	end
	return results
end

--- "Filter" entries in a table using a provided
--- function `fn`. `fn` should receive a table value
--- as the first parameter, and can optionally receive
--- a table index as the second parameter. `fn` should
--- return true if the entry is to be in the output,
--- and return false otherwise. Filtered entries retain
--- their original keys.
--
-- @tparam table tbl then table to filter
-- @tparam function fn a function with signature
--         function(value) -> boolean
--         OR
--         function(value, key) -> boolean
-- @treturn table the filtered table
function table.rfilter(tbl, fn)
	if type(tbl) ~= "table" or type(fn) ~= "function" then return end
	if #tbl == 0 then return end

	local results = {}
	for k,v in pairs(tbl) do
		local f = fn(v)
		if type(f) == "boolean" and f == true then results[k] = v end
	end
	return results
end

--- Get the sum of all values in a table. Assumes
--- numeric indices only.
-- @tparam table tbl a table of values that for any
--         2 values in the table, a+b is a valid
--         operation
-- @treturn any the sum of all values
function table.sum(tbl)
	return table.reduce(tbl, function(a,b) return a+b end, true)
end

--- Get the sum of all values in a table. Assumes
--- numeric indices only. Assumes numeric values only.
-- @unsafe
-- @tparam {number} tbl a table of numeric values
-- @treturn any the sum of all values
function table.fast_sum(tbl)
	local ud = userdata("f64", #tbl, 2)
	local data = ud:row(0)
	local ident = ud:row(1)

	ident += 1
	data:set(0,0, unpack(tbl))

	return data:dot(ident)
end

--- Get the product of all values in a table. Assumes
--- numeric indices only.
-- @tparam table tbl a table of values that for any
--         2 values in the table, a*b is a valid
--         operation
-- @treturn any the product of all values
function table.product(tbl)
	return table.reduce(tbl, function(a,b) return a*b end, true)
end

function table.mean(tbl)
	return table.sum(tbl) / #tbl
end

--- Get the maximum of all values in a table. Assumes
--- numeric indices only.
-- @tparam table tbl a table of values that for any
--         2 values in the table, max(a,b) is a valid
--         operation
-- @treturn any the maximum of all values
function table.max(tbl)
	return table.reduce(tbl, function(a,b) return max(a,b) end, true)
end

--- experimental function
function table._fast_max(tbl)
	local ud = userdata("f64", 1, #tbl)
	ud:set(0,0, unpack(tbl))
	ud:sort(0, true)
	return ud:get(0,0)
end

--- experimental function
function table._fast_sort(tbl)
	local ud = userdata("f64", 1, #tbl)
	ud:set(0,0, unpack(tbl))
	ud:sort(0, true)
	return {ud:get(0,0,#tbl)}
end

--- Get the maximum of all values in a table. Assumes
--- numeric indices only.
-- @tparam table tbl a table of values that for any
--         2 values in the table, max(a,b) is a valid
--         operation
-- @treturn any the maximum of all values
function table.min(tbl)
	return table.reduce(tbl, function(a,b) return min(a,b) end, true)
end

function table.any(tbl)
	return table.reduce(tbl, function(a,b) return a or b end, true)
end

function table.all(tbl)
	return table.reduce(tbl, function(a,b) return a and b end, true)
end

function table.contains(tbl, value)
	return (#table.filter(tbl, function(x) return x == value end)) > 0
end

-- separate from just checking tbl[key] because this doesn't
-- check hash values, it does direct comparison.
function table.contains_key(tbl, key)
	local keys = collect(table.keys(tbl))
	return (#table.filter(keys, function(x) return x == value end)) > 0
end

function table.sort_strings(tbl, descending)
	descending = descending or false
	local max_len = table._fast_max(table.map(tbl, function(x) return #x end))
	local ud = userdata("f64", max_len, #tbl)

	for i,v in ipairs(tbl) do
		ud:set(0, i-1, string.byte(v, 1, -1))
		print(#v..": "..string.char(ud:get(0, i-1, #v)))
	end

	--ud = ud:transpose()
	for i=1,max_len do
		print(#tbl..": "..string.char(ud:column(i-1):get(0, 0, #tbl)))
	end
	-- radixx sort
	for col=max_len,1,-1 do
		ud:sort(col-1, descending)
	end
	print("==========")

	for i=1,max_len do
		print((i-1)..": "..string.char(ud:column(i-1):get(0, 0, #tbl)))
	end

	ud = ud:convert("u8")
	local results = {}
	for i,v in ipairs(tbl) do
		results[i] = string.char(ud:get(0, i-1, #v))
	end

	return results
end

