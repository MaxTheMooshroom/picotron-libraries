--[[pod_format="raw",created="2025-03-21 18:11:52",icon=userdata("u8",16,16,"00121212121212121212120000000000001217171717171717170e1200000000001217171717171717170e0e12000000001217171717171717170e0e0e120000001217171712121212170e0e0e0e120000121717121d1d1d1d121717171712000012171717121d1d12171717171712000012171717121d1d12171717171712000012171717121d1d12171217171712000012171717121d1d12121d121717120000121717121d1d1d1d1d1d12171712000012171717121212121212171717120000121717171717171717171717171200001217171717171717171717171712000012171717171717171717171717120000121212121212121212121212121200"),modified="2025-03-29 23:59:40",revision=22]]local fmt = {}

function fmt.string_to_ord(str)
    assert(type(str) == "string", "string_to_ord() is for strings only")
    local result = {}
    for i=1,(#str+1) do
        local ochar = ord(sub(str, i, i+1))
        if not ochar then print("'"..sub(str, i, i+1).."' has no ordinal"); exit(1) end
        if ochar >= 32 and ochar <= 127 then
            add(result, ochar)
        end
    end
    return result
end

function fmt.filter_string(str)
    assert(type(str) == "string", "fmt.filter_string() is for strings only")
    local result = ""
    for ochar in ipairs(fmt.string_to_ord(str)) do
        result = result..chr(ochar)
    end
    return result
end

local function array_to_string(arr)
    if not arr[1] then return nil end
    
    local result = "[ "
    for _,v in ipairs(arr) do
        local vtype = type(v)
        if vtype == "string" then
            result = result..v
        elseif vtype == "function" then
            result = result.."<function>"
        elseif vtype == "number" or vtype == "boolean" then
            result = result..tostr(v)
        elseif vtype == "table" then
            result = result.."<table>"
        elseif vtype == "userdata" then
            result = result.."<userdata>"
        end
        result = result..", "
    end
    result = result.."]"
    return result
end

function fmt.to_string(val, depth, maxdepth)
    local vtype = type(val)

    if not val then
        return "nil"
    elseif vtype == "string" then
        return fmt.filter_string(val)
    elseif vtype == "function" then
        return "<function>"
    elseif vtype == "userdata" then
        return "<userdata>"
    elseif vtype == "number" or vtype == "boolean" then
        return tostr(val)
    elseif vtype == "table" then
        maxdepth = maxdepth or 3
        depth = depth or 0
        
        local arr_str = array_to_string(val)
        if arr_str then return arr_str end
        if depth >= maxdepth then return "<table>" end
        
        local prefix = string.rep("    ", depth)
        local result = prefix.."{\n"
        
        for k,v in pairs(val) do
            local v_str = fmt.to_string(v, depth + 1, maxdepth)
            result = result..prefix.."    ["..k.."]: "..v_str..",\n"
        end
        
        result = result..prefix.."}"
        
        return result
    end
end

return fmt
