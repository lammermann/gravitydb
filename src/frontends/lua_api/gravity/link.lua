-- {{{ includes
local obj  = require "gravity.internal.element"
local set  = require "gravity.internal.set"
-- }}}

local l = {}

function l.new(n1, n2, label, props, graph)
  -- check input parameters
  if not n1 or not n2 then return end
  local n1 = n1
  local n2 = n2
  if not graph then return end
  local g = graph

  local link = obj.new(label, props)

  -- read out parameters {{{

  function link.n(idx)
    if idx == 1 then return n1 end
    if idx == 2 then return n2 end
  end

  -- }}}

  -- delete the link with all pointers to it
  function link.delete()
    n1._deleteLink(link)
    n2._deleteLink(link)
    g:emit("DELLINK", link)
  end

  -- {{{ internal functions
  function link:_getinput()
    return { n={}, l={link}, c={} }
  end
  -- }}}

  -- helper metamethods {{{
  function link.__tostring()
    local out = {
      "link[",tostring(id),"][",tostring(n1.id()),
      "-",label,"->",tostring(n2.id()),"]"
    }
    return table.concat(out)
  end
  -- }}}

  g:emit("NEWLINK", link)
  return link
end

return l

-- vim: fdm=marker
