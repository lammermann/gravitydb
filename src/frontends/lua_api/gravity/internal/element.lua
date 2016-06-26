--
-- basis for nodes and links
--

-- {{{ includes
local obj  = require "gravity.internal.object"
local set  = require "gravity.internal.set"
-- }}}

local e = {}

function e.new(label, props)
  local properties = props or {}
  if type(properties) ~= "table" then error("wrong init data") end
  if type(label) ~= "string" then error("wrong init data") end
  local label = label

  local elm = obj.new()
  local id  = tostring(elm)

  -- get the node id
  function elm.id()
    return id
  end

  function elm.label()
    return label
  end

  -- get or set a property
  function elm.value(name, value)
    if value then
      properties[name] = value
    end
    return properties[name]
  end
  elm.__index = function(t,v) return t.value(v) end
  elm.__newindex = function(t,k,v)
    properties[k] = v
    return v
  end

  -- does property exist
  function elm.has(property, value)
    local p = properties[property]
    if p ~= nil then
      if value ~= nil then
        if p == value then return true end
        return false
      end
      return true
    end
    return false
  end

  setmetatable(elm, elm)
  return elm
end

return e

-- vim: fdm=marker
