--
-- graph sets
--
-- These are sets of nodes and/or relations. They can be filtered to get a
-- subset. On the other hand you can aggregate and manipulate data of all
-- objects in such a set.

-- {{{ includes
local obj = require "internal.object"
local h   = require "internal.helpers"

local get_filter_func = h.get_filter_func
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
    local subnodes = {}
    local sublinks = {}
    if filter then
      local ff  = get_filter_func(filter)
      for k,v in pairs(nodes) do
        if ff(v) then
          subnodes[k] = v
        end
      end
      for k,v in pairs(links) do
        if ff(v) then
          sublinks[k] = v
        end
      end
    else
      for k,v in pairs(nodes) do
        subnodes[k] = v
      end
      for k,v in pairs(links) do
        sublinks[k] = v
      end
    end
    return set.subset(subnodes, sublinks)
  end

  function set.nodes(filter)
    local subnodes = {}
    if filter then
      local ff  = get_filter_func(filter)
      for k,v in pairs(nodes) do
        if ff(v) then
          subnodes[k] = v
        end
      end
    else
      for k,v in pairs(nodes) do
        subnodes[k] = v
      end
    end
    return set.subset(subnodes)
  end
  set.vertices = set.nodes
  set.V        = set.nodes

  function set.links(filter)
    local sublinks = {}
    if filter then
      local ff  = get_filter_func(filter)
      for k,v in pairs(links) do
        if ff(v) then
          sublinks[k] = v
        end
      end
    else
      for k,v in pairs(links) do
        sublinks[k] = v
      end
    end
    return set.subset(nil, sublinks)
  end
  set.connections = set.links
  set.relations   = set.links
  set.edges       = set.links
  set.E           = set.links

  -- get all incoming nodes matching the filter condition from all nodes and
  -- links
  function set.in_(filter)
    local ff  = get_filter_func(filter)
    local nds = {}
    for _,l in pairs(links) do
      local n = l.n(1)
      if ff(l) then
        nds[n.id()] = n
      end
    end
    return set.subset(nds)
  end

  -- get all outgoing nodes matching the filter condition from all nodes and
  -- links
  function set.out(filter)
    local ff  = get_filter_func(filter)
    local nds = {}
    for _,l in pairs(links) do
      local n = l.n(2)
      if ff(l) then
        nds[n.id()] = n
      end
    end
    return set.subset(nds)
  end

  -- get all incoming links matiching the filter condition from all nodes
  -- in the set
  function set.inL(filter)
    local res = set.subset()
    for _,n in pairs(nodes) do
      res = res + n.inL(filter)
    end
    return res
  end

  -- get all outgoing links matiching the filter condition from all nodes
  -- in the set
  function set.outL(filter)
    local res = set.subset()
    for _,n in pairs(nodes) do
      res = res + n.outL(filter)
    end
    return res
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

  -- {{{ helper functions

  local function sortfunc(t)
    return function(sorter)
      if sorter == false then
        table.sort(t, function(a,b) return a>b end)
      elseif type(sorter) == "function" then
        table.sort(t, sorter)
      else
        table.sort(t)
      end
      return t
    end
  end

  -- }}}

  -- get the ids of all objects in a set.
  function set.id()
    local result = {}
    for _,n in pairs(nodes) do
      table.insert(result, n.id())
    end
    for _,l in pairs(links) do
      table.insert(result, l.id())
    end
    if #result == 0 then return end
    if #result == 1 then return result[1] end
    local mt = { sort = sortfunc(result) }
    setmetatable(result, { __index = mt })
    return result
  end

  -- get a node by his index
  function set.node(idx)
    local idx = idx or 1
    local i = 1
    for _,n in pairs(nodes) do
      if i == idx then return n end
      i = i + 1
    end
  end
  set.n = set.node

  -- get or set all values of a property in all objects in a set
  function set.value(name, value)
    if not name then return end
    local result = {}
    for _,n in pairs(nodes) do
      if n.has(name) then
        table.insert(result, n.value(name, value))
      end
    end
    for _,l in pairs(links) do
      if l.has(name) then
        table.insert(result, l.value(name, value))
      end
    end
    if #result == 0 then return end
    if #result == 1 then return result[1] end
    local mt = { sort = sortfunc(result) }
    setmetatable(result, { __index = mt })
    return result
  end
  set.__index = function(t,v) return t.value(v) end
  set.__newindex = function(t,k,v) return t.value(k,v) end

  -- count all objects which can be filtered optionally
  function set.count(filter)
    count = 0
    for _ in pairs(links) do count = count + 1 end
    for _ in pairs(nodes) do count = count + 1 end
    return count
  end

  function set.deleteProperty(name)
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
    local result = {}
    local i = 0
    for _,n in pairs(nodes) do
      table.insert(result, mfunc(n, i))
      i = i + 1
    end
    i = 0
    for _,l in pairs(links) do
      table.insert(result, mfunc(l, i))
      i = i + 1
    end
    local mt = { sort = sortfunc(result) }
    setmetatable(result, { __index = mt })
    return result
  end

  -- connect all nodes to a given node
  function set.link(node, label, direction, props)
    for _,n in pairs(nodes) do
      n.addLink(node, label, direction, props)
    end
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
