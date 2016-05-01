-- {{{ includes
local obj  = require "internal.object"
local set  = require "internal.set"
-- }}}

local l = {}

function l.new(n1, n2, label, props, graph)
  local link = obj.new()
  local properties = props or {}
  local id   = tostring(link)
  local n1   = n1
  local n2   = n2
  local label = label
  local g = graph

  -- get the link id
  function link.id()
    return id
  end

  -- delete the link with all pointers to it
  function link.delete()
    n1._deleteLink(link)
    n2._deleteLink(link)
    g:emit("DELLINK", link)
  end

  -- get or set a property
  function link.value(name, value)
    if value then
      properties[name] = value
    end
    return properties[name]
  end

  -- does property exist
  function link.has(property, value)
    local p = properties[property]
    if p then
      if value then
        if p == value then return true end
        return false
      end
      return true
    end
    return false
  end

  function link.n(idx)
    if idx == 1 then return n1 end
    if idx == 2 then return n2 end
  end

  if g then g:emit("NEWLINK", link) end
  return link
end

return l

-- vim: fdm=marker
