--
-- graph sets
--
-- These are sets of nodes and/or relations. They can be filtered to get a
-- subset. On the other hand you can aggregate and manipulate data of all
-- objects in such a set.

-- {{{ includes
local obj = require "internal.object"
local pip = require "internal.pipes"
-- }}}

local s = {}

function s.new(nodes, links, parent)
  local set = obj.new()
  local nodes = nodes or {}
  local links = links or {}
  local g     = parent or set

  function set.subset(nodes, links)
    return s.new(nodes, links, g)
  end

  -- {{{ filter functions

  function set.findByID(id)
  end

  -- returns all objects that pass function `filter`.
  --
  -- `filter` is a function that gets the arguments `object` and `index`:
  --    filter(object, index)
  function set.filter(filter)
    set._insertstep{run=pip.filter, args={f=filter}}
    return set
  end

  function set.nodes(filter)
    set._insertstep{run=pip.nodes, args={f=filter}}
    return set
  end
  set.vertices = set.nodes
  set.V        = set.nodes

  function set.links(filter)
    set._insertstep{run=pip.links, args={f=filter}}
    return set
  end
  set.connections = set.links
  set.relations   = set.links
  set.edges       = set.links
  set.E           = set.links

  -- get all incoming nodes matching the filter condition from all nodes and
  -- links
  function set.in_(filter)
    set._insertstep{run=pip.in_, args={f=filter}}
    return set
  end

  -- get all outgoing nodes matching the filter condition from all nodes and
  -- links
  function set.out(filter)
    set._insertstep{run=pip.out, args={f=filter}}
    return set
  end

  -- get all incoming links matiching the filter condition from all nodes
  -- in the set
  function set.inL(filter)
    set._insertstep{run=pip.inL, args={f=filter}}
    return set
  end

  -- get all outgoing links matiching the filter condition from all nodes
  -- in the set
  function set.outL(filter)
    set._insertstep{run=pip.outL, args={f=filter}}
    return set
  end

  function set.has(property, value)
    return set.filter(function(obj)
      if obj.has(property, value) then return true end
      return false
    end)
  end

  function set.hasNot(property, value)
    return set.filter(function(obj)
      if obj.has(property, value) then return false end
      return true
    end)
  end

  -- this will loop through a traversal until function `condition` returns
  -- `false`. The loop section is defined with the `as(name)` function.
  --
  -- `condition` gets three parameters:
  --    `obj`:   the current object
  --    `path`:  the current path
  --    `loops`: the number of times the traverser has looped through the loop
  --             section
  function set.loop(name, condition)
  end

  -- }}}

  -- {{{ aggregate or modifcation functions

  -- get the ids of all objects in a set.
  function set.id()
    set._insertstep{run=pip.id}
    return set:_runsteps()
  end

  -- get a node by his index
  function set.node(idx)
    set._insertstep{run=pip.node, args={idx=idx}}
    return set:_runsteps()
  end
  set.n = set.node

  -- get or set all values of a property in all objects in a set
  function set.value(name, value)
    set._insertstep{run=pip.value, args={k=name, v=value}}
    return set:_runsteps()
  end
  set.__index = function(t,v) return t.value(v) end
  set.__newindex = function(t,k,v) return t.value(k,v) end

  -- count all objects which can be filtered optionally
  function set.count(filter)
    set._insertstep{run=pip.count}
    return set:_runsteps()
  end

  function set.deleteProperty(name)
    set._insertstep{run=pip.deleteP, args={k=name}}
    return set:_runsteps()
  end

  -- delete all objects in a set
  function set.delete()
    for _,n in pairs(nodes) do
      n.delete()
    end
    for _,l in pairs(links) do
      l.delete()
    end
  end

  -- functional programming map function
  function set.map(mfunc)
    set._insertstep{run=pip.map, args={f=mfunc}}
    return set:_runsteps()
  end

  -- connect all nodes to a given node
  function set.link(node, label, direction, props)
    set._insertstep{run=pip.link, args={ n=node, l=label, d=direction, p=props }}
    return set:_runsteps()
  end

  -- sort all objects in a set
  -- if `rule` is a function it will be used as a sort function
  -- if `rule` is false it will be sorted decending
  -- otherwise it will be sorted ascending
  function set.sort(rule)
  end

  -- {{{ backtracking

  function set.as(name)
  end

  function set.back(name)
  end

  -- }}}

  -- {{{ except retain pattern

  -- aggregate objects in a container
  --
  -- execpt and retain are math set operations
  function set.aggregate(container)
    container = set.subset(nodes, links)
    return set
  end

  -- }}}

  -- {{{ path pattern

  function set.path(...)
  end

  -- }}}

  -- {{{ flow rank pattern

  function set.groupCount(container)
  end

  -- }}}

  -- }}}

  -- {{{ math set operations

  function set.union(s2)
    local nds = s2.nodes().map(function(n) return n end)
    local lks = s2.links().map(function(n) return n end)
    for id,n in pairs(nodes) do
      nds[id] = n
    end
    for id,l in pairs(links) do
      lks[id] = l
    end
    return set.subset(nds, lks)
  end

  function set.intersect(s2)
  end
  set.retain = set.intersect

  function set.difference(s2)
  end

  function set.complement(s2)
  end
  set.except = set.complement

  function set.cartesianProduct(s2)
  end

  -- }}}

  -- {{{ internal functions

  function set:_getinput()
    local nds = {}
    for _,n in pairs(nodes) do table.insert(nds,n) end
    local lks = {}
    for _,l in pairs(links) do table.insert(lks,l) end
    return { n=nds, l=lks, c={} }
  end

  set:addListener("NEWNODE", function(node, graph)
    local id = node.id()
    if nodes[id] and nodes[id] ~= node then
      -- TODO error cause of id colision
      return -1
    end
    nodes[id] = node -- add node
  end)

  set:addListener("DELNODE", function(node, graph)
    local id = node.id()
    if nodes[id] and nodes[id] ~= node then
      -- TODO error cause of id colision
      return -1
    end
    -- tell the node to delete all his instances and links to other nodes
    node:emit("DELTHIS", node)
    nodes[id] = nil -- delete node from index
  end)

  set:addListener("NEWLINK", function(link, graph)
    local id = link.id()
    if links[id] and links[id] ~= link then
      -- TODO error cause of id colision
      return -1
    end
    links[id] = link -- add link
  end)

  set:addListener("DELLINK", function(link, graph)
    local id = link.id()
    if links[id] and links[id] ~= link then
      -- TODO error cause of id colision
      return -1
    end
    -- tell the link to delete all his instances
    link:emit("DELTHIS", link)
    links[id] = nil -- delete link from index
  end)

  -- }}}

  local mt = {}
  mt.__add = function(s, s2) return s.union(s2) end
  setmetatable(set, mt)
  return set
end

return s

-- vim: fdm=marker
