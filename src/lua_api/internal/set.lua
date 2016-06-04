--
-- graph sets
--
-- These are sets of nodes and/or relations. They can be filtered to get a
-- subset. On the other hand you can aggregate and manipulate data of all
-- objects in such a set.

-- {{{ includes
local obj  = require "internal.object"
-- }}}

local s = {}

function s.new(nodes, links)
  local set = obj.new()
  local nodes = nodes or {}
  local links = links or {}

  -- {{{ filter functions

  -- {{{ helper functions

  local function get_filter_func(filter)
    if type(filter) == "string" then
      return function(obj) return obj.label() == filter end
    elseif type(filter) == "function" then
      return filter
    end
    return function() return true end
  end

  -- }}}

  function set.findByID(id)
  end

  -- returns all objects that pass function `filter`.
  --
  -- `filter` is a function that gets the arguments `object` and `index`:
  --    filter(object, index)
  function set.filter(filter)
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
    return s.new(subnodes)
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
    return s.new(nil, sublinks)
  end
  set.connections = set.links
  set.relations   = set.links
  set.edges       = set.links
  set.E           = set.links

  -- get all incoming nodes matching the filter condition from all nodes and
  -- links
  function set.in_(filter)
  end

  -- get all outgoing nodes matching the filter condition from all nodes and
  -- links
  function set.out(filter)
  end

  -- get all incoming links matiching the filter condition from all nodes
  -- in the set
  function set.inL(filter)
  end

  -- get all outgoing links matiching the filter condition from all nodes
  -- in the set
  function set.outL(filter)
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
    local result = {}
    for _,n in pairs(nodes) do
      table.insert(result, n.id())
    end
    for _,l in pairs(links) do
      table.insert(result, l.id())
    end
    if #result == 0 then return end
    if #result == 1 then return result[1] end
    return result
  end

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

  -- connect all nodes to a given node
  function set.link(node, label, direction, props)
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
    container = s.new(nodes, links)
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

  return set
end

return s

-- vim: fdm=marker
