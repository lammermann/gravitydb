-- {{{ includes
local obj  = require "internal.object"
local set  = require "internal.set"
-- }}}

local l = {}

function l.new(n1, n2, label, direction, props, graph)
  -- check input parameters
  local direction  = direction or "-"
  if direction ~= "-" and direction ~= "<" and direction ~= ">" then return end
  local properties = props or {}
  if type(properties) ~= "table" then return end
  if not n1 or not n2 then return end
  local n1   = n1
  local n2   = n2
  if type(label) ~= "string" then return end
  local label = label
  local g = graph

  local link = obj.new()
  local id   = tostring(link)

  -- read out parameters {{{

  -- get the link id
  function link.id()
    return id
  end

  -- get the link direction
  function link.direction()
    return direction
  end

  -- get the link label
  function link.label()
    return label
  end

  function link.n(idx)
    if idx == 1 then return n1 end
    if idx == 2 then return n2 end
  end

  -- }}}

  -- delete the link with all pointers to it
  function link.delete()
    n1._deleteLink(link)
    n2._deleteLink(link)
    if g then
      g:emit("DELLINK", link)
    else
      link:emit("DELTHIS", link)
    end
  end

  -- get or set a property
  function link.value(name, value)
    if value then
      properties[name] = value
    end
    return properties[name]
  end
  link.__index = function(t,v) return t.value(v) end
  link.__newindex = function(t,k,v)
    properties[k] = v
    return v
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

  -- helper metamethods {{{
  function link.__tostring()
    local out = {"link[",tostring(id),"][",tostring(n1.id())}
    if direction == "<" or direction == "-" then
      table.insert(out,"<-")
    else
      table.insert(out,"-")
    end
    table.insert(out,label)
    if direction == ">" or direction == "-" then
      table.insert(out,"->")
    else
      table.insert(out,"-")
    end
    table.insert(out,tostring(n2.id()),"]")
    return table.concat(out)
  end
  -- }}}

  setmetatable(link, link)
  if g then g:emit("NEWLINK", link) end
  return link
end

return l

-- vim: fdm=marker
