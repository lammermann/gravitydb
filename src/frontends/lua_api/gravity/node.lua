-- {{{ includes
local obj  = require "gravity.internal.element"
local link = require "gravity.link"
-- }}}

local n = {}

--
-- create a new node
--
-- props
-- :    Key value pairs of properties (optional)
--
-- label
-- :    A kind of type for easier indexing. Nodes can have more than one label.
--      In that case you should insert an array of labels. (optional)
--
-- graph
-- :    The graph that holds the node. It is interesting for cleaning up all
--      pointers to a node. (optional)
function n.new(props, label, graph)
  local node = obj.new(label, props)
  if not graph then return end
  local g = graph
  local links = {}

  function node._delete() -- {{{
    -- delete the node with all its links and pointers to it
    for l,_ in pairs(links) do
      l._delete()
    end
    g:emit("DELNODE", node)
  end -- }}}

  function node.addLink(n2, label, direction, props) -- {{{
    local direction = direction or "-"
    local l
    if direction == "<" then
      l = link.new(n2, node, label, props, g)
    elseif direction == ">" then
      l = link.new(node, n2, label, props, g)
    elseif direction == "-" then
      l = link.new(node, n2, label, props, g)
      -- add automatically a second link the othe direction
      node.addLink(n2, label, "<", props)
    else
      return
    end

    if l and links[l] ~= true then
      links[l] = true
      n2._addLink(l)
    end
    return l
  end -- }}}

  -- {{{ internal functions
  function node._addLink(l)
    links[l] = true
  end

  function node._deleteLink(l)
    links[l] = nil
  end

  function node._links()
    local lks = {}
    for l,_ in pairs(links) do
      lks[l._id()] = l
    end
    return lks
  end

  function node:_getinput()
    return { n={node}, l={}, c={} }
  end
  -- }}}

  -- helper metamethods {{{
  function node.__tostring()
    return "node["..tostring(id).."]"
  end
  -- }}}

  g:emit("NEWNODE", node)
  return node
end

return n

-- vim: fdm=marker
