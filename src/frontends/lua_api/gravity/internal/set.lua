--
-- graph sets
--
-- These are sets of nodes and/or relations. They can be filtered to get a
-- subset. On the other hand you can aggregate and manipulate data of all
-- objects in such a set.

-- {{{ includes
local obj = require "gravity.internal.object"
local pip = require "gravity.internal.pipes"
-- }}}

local s = {}

function s.new(nodes, links, parent)
  local set   = obj.new()
  local nodes = nodes or {}
  local links = links or {}
  local g     = parent or set
  if not parent then g.backend = require("gravity.backends.memory").init() end

  function set.subset(nodes, links)
    return s.new(nodes, links, g)
  end

  function set.findByID(id)
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

  -- {{{ aggregate or modifcation functions

  -- sort all objects in a set
  -- if `rule` is a function it will be used as a sort function
  -- if `rule` is false it will be sorted decending
  -- otherwise it will be sorted ascending
  function set.sort(rule)
  end

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
    local id = g.backend.createNode(node)
    if nodes[id] and nodes[id] ~= node then
      error("id colision wrong object")
    end
    nodes[id] = node -- add node
  end)

  set:addListener("DELNODE", function(node, graph)
    local id = node._id()
    g.backend.deleteNode(id)
    if nodes[id] and nodes[id] ~= node then
      error("id colision wrong object")
    end
    -- tell the node to delete all his instances and links to other nodes
    node:emit("DELTHIS", node)
    nodes[id] = nil -- delete node from index
  end)

  set:addListener("NEWLINK", function(link, graph)
    local id = g.backend.createLink(link)
    if links[id] and links[id] ~= link then
      error("id colision wrong object")
    end
    links[id] = link -- add link
  end)

  set:addListener("DELLINK", function(link, graph)
    local id = link._id()
    g.backend.deleteLink(id)
    if links[id] and links[id] ~= link then
      error("id colision wrong object")
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
