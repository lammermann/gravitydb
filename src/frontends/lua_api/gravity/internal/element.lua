--
-- basis for nodes and links
--

-- {{{ includes
local obj  = require "gravity.internal.object"
local set  = require "gravity.internal.set"
-- }}}

local e = {}

function e.new(label, props, graph, id)
  local properties = props or {}
  if type(properties) ~= "table" then error("wrong init data") end
  if type(label) ~= "string" then error("wrong init data") end
  local label = label
  local g = graph

  local elm = obj.new()
  local id  = id or tostring(elm)

  -- get the node id
  function elm._id()
    return id
  end

  function elm.label()
    return label
  end

  -- get available property keys
  function elm._propKeys()
    local kys = {}
    for k,_ in pairs(properties) do
      table.insert(kys,k)
    end
    return kys
  end

  -- get or set a property
  function elm._value(name, value)
    if value then
      properties[name] = value
      g:emit("UPDATEPROP", elm)
    end
    return properties[name]
  end

  -- delete a value
  elm._delvalue = function(k)
    g:emit("UPDATEPROP", elm)
    properties[k] = nil
  end

  -- does property exist
  function elm._has(property, value)
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
