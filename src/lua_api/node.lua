-- {{{ includes
local obj  = require "internal.object"
local set  = require "internal.set"
local link  = require "link"
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
  local node = obj.new()
  local properties = props or {}
  local id    = tostring(node)
  local label = label
  local links = {}
  local g = graph

  -- get the node id
  function node.id()
    return id
  end

  function node.label()
    return label
  end

  -- {{{ add and delete functions

  -- delete the node with all its links and pointers to it
  function node.delete()
    for l,_ in pairs(links) do
      l.delete()
    end
    if g then
      g:emit("DELNODE", node)
    else
      node:emit("DELNODE", node)
    end
  end

  function node.addLink(n2, label, direction, props)
    local l = link.new(node, n2, label, direction, props, g)

    if l and links[l] ~= true then
      links[l] = true
      n2._addLink(l)
    end
    return l
  end

  function node.deleteLink(l)
    l.delete()
  end

  -- {{{ internal functions
  function node._addLink(l)
    links[l] = true
  end

  function node._deleteLink(l)
    links[l] = nil
  end
  -- }}}

  -- get or set a property
  function node.value(name, value)
    if value then
      properties[name] = value
    end
    return properties[name]
  end
  node.__index = function(t,v) return t.value(v) end
  node.__newindex = function(t,k,v)
    properties[k] = v
    return v
  end

  -- }}}

  -- {{{ filter functions

  -- does property exist
  function node.has(property, value)
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

  -- {{{ filter relations

  -- return all conected nodes
  function node.both(filter)
    local nds = {}
    for l,_ in pairs(links) do
      if l.n(1) == node then
        table.insert(nds, l.n(2))
      else
        table.insert(nds, l.n(1))
      end
    end
    return set.new(nds)
  end

  -- return all conected relations
  function node.bothL(filter)
  end

  -- return outgoing nodes
  function node.out(filter)
    local nds = {}
    for l,_ in pairs(links) do
      if l.n(1) == node then
        table.insert(nds, l.n(2))
      elseif l.direction() == '-' then
        table.insert(nds, l.n(1))
      end
    end
    return set.new(nds)
  end

  -- return outgoing relations
  function node.outL(filter)
    local lks = {}
    for l,_ in pairs(links) do
      if l.n(1) == node or l.direction() == '-' then
        table.insert(lks, l)
      end
    end
    return set.new(lks)
  end

  -- return incoming nodes
  function node.in_(filter)
    local nds = {}
    for l,_ in pairs(links) do
      if l.n(2) == node then
        table.insert(nds, l.n(1))
      elseif l.direction() == '-' then
        table.insert(nds, l.n(2))
      end
    end
    return set.new(nds)
  end

  -- return incoming relations
  function node.inL(filter)
    local lks = {}
    for l,_ in pairs(links) do
      if l.n(2) == node or l.direction() == '-' then
        table.insert(lks, l)
      end
    end
    return set.new(lks)
  end

  -- }}}

  -- }}}

  -- helper metamethods {{{
  function node.__tostring()
    return "node["..tostring(id).."]"
  end
  -- }}}

  setmetatable(node, node)
  if g then g:emit("NEWNODE", node) end
  return node
end

return n

-- vim: fdm=marker
