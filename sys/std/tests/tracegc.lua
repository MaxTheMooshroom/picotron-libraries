--[[pod_format="raw",created="2025-04-04 15:09:23",modified="2025-04-04 15:09:23",revision=0]]
-- track collections

local M = {}

-- import list
local setmetatable, stderr, collectgarbage =
         setmetatable, io.stderr, collectgarbage

_ENV = nil

local active = false


-- each time a table is collected, remark it for finalization on next
-- cycle
local mt = {}
function mt.__gc (o)
  stderr:write'.'    -- mark progress
  if active then
    setmetatable(o, mt)   -- remark object for finalization
  end
end


function M.start ()
  if not active then
    active = true
    setmetatable({}, mt)    -- create initial object
  end
end


function M.stop ()
  if active then
    active = false
    collectgarbage()   -- call finalizer for the last time
  end
end

return M
