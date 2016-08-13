-- {{{ includes
local obj  = require "gravity.internal.element"
-- }}}

local l = {}

function l.new(n1, n2, label, props, graph)
  -- check input parameters
  if not n1 or not n2 then return end
  local n1 = n1
  local n2 = n2
  if not graph then return end
  local g = graph

  local link = obj.new(label, props, graph)

  function link._n(idx) -- {{{
    if idx == 1 then return n1 end
    if idx == 2 then return n2 end
  end -- }}}

  function link._delete() -- {{{
    -- delete the link with all pointers to it
    n1._deleteLink(link)
    n2._deleteLink(link)
    g:emit("DELLINK", link)
  end -- }}}

  -- {{{ internal functions
  function link:_getinput()
    return { n={}, l={link}, c={} }
  end
  -- }}}

  function link.__tostring() -- {{{
    local out = {
      "link[",tostring(id),"][",tostring(n1._id()),
      "-",label,"->",tostring(n2._id()),"]"
    }
    return table.concat(out)
  end -- }}}

  g:emit("NEWLINK", link)
  return link
end

return l

-- vim: fdm=marker
