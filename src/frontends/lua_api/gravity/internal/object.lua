--
-- the basic db object
--
-- event listeners can be added to
-- * force type schemas
-- * update indexes
-- * index objects, that should be updated in the storage backend
-- * etc.

-- {{{ includes
local pip = require "gravity.internal.pipes"
-- }}}

local o = {}

-- {{{ helper functions

local function deleted()
  error("This is a deleted object. It can not be used any more")
end

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

local function flatten(t, out)
  local out = out or {}
  for _,v in ipairs(t) do
    if type(v) == "table" and getmetatable(v) == "flatten" then
      -- flatten only tables that arent classes
      flatten(v, out)
    else
      table.insert(out, v)
    end
  end
  return out
end

-- }}}

function o.new()
  local obj = {}
  local listeners = {}
  local steps = {}

  -- {{{ aggregate functions

  -- get the ids of all objects in a obj.
  function obj.id()
    obj._insertstep{run=pip.id}
    return obj:_runsteps()
  end

  -- count all objects which can be filtered optionally
  function obj.count(filter)
    obj._insertstep{run=function() return 1 end}
    return obj:_runsteps{run=pip.count}
  end

  -- get or obj all values of a property in all objects in a obj
  function obj.value(name, value)
    obj._insertstep{run=pip.value, args={k=name, v=value}}
    return obj:_runsteps()
  end

  -- functional programming map function
  function obj.map(mfunc)
    obj._insertstep{run=pip.map, args={f=mfunc}}
    return obj:_runsteps()
  end

  -- connect all nodes to a given node
  function obj.link(node, label, direction, props)
    obj._insertstep{run=pip.link, args={ n=node, l=label, d=direction, p=props }}
    return obj:_runsteps()
  end

  -- get a node by his index
  function obj.node(idx)
    obj._insertstep{run=function(...) return ... end}
    return obj:_runsteps{run=pip.node, args={idx=idx}}
  end
  obj.n = obj.node

  function obj.deleteProperty(name)
    obj._insertstep{run=pip.deleteP, args={k=name}}
    return obj:_runsteps()
  end

  -- delete all objects in a obj
  function obj.delete()
    obj._insertstep{run=pip.delete}
    return obj:_runsteps()
  end

  -- }}}

  -- {{{ filter functions

  -- returns all objects that pass function `filter`.
  --
  -- `filter` is a function that gets the arguments `object` and `index`:
  --    filter(object, index)
  function obj.filter(filter)
    obj._insertstep{run=pip.filter, args={f=filter}}
    return obj
  end

  function obj.nodes(filter)
    obj._insertstep{run=pip.nodes, args={f=filter}}
    return obj
  end
  obj.vertices = obj.nodes
  obj.V        = obj.nodes

  function obj.links(filter)
    obj._insertstep{run=pip.links, args={f=filter}}
    return obj
  end
  obj.connections = obj.links
  obj.relations   = obj.links
  obj.edges       = obj.links
  obj.E           = obj.links

  function obj.has(property, value)
    return obj.filter(function(obj)
      if obj._has(property, value) then return true end
      return false
    end)
  end

  function obj.hasNot(property, value)
    return obj.filter(function(obj)
      if obj._has(property, value) then return false end
      return true
    end)
  end

  -- get all incoming nodes matching the filter condition from all nodes and
  -- links
  function obj.in_(filter)
    obj._insertstep{run=pip.in_, args={f=filter}}
    return obj
  end

  -- get all outgoing nodes matching the filter condition from all nodes and
  -- links
  function obj.out(filter)
    obj._insertstep{run=pip.out, args={f=filter}}
    return obj
  end

  -- get all incoming links matiching the filter condition from all nodes
  -- in the obj
  function obj.inL(filter)
    obj._insertstep{run=pip.inL, args={f=filter}}
    return obj
  end

  -- get all outgoing links matiching the filter condition from all nodes
  -- in the obj
  function obj.outL(filter)
    obj._insertstep{run=pip.outL, args={f=filter}}
    return obj
  end

  function obj.back(name)
    obj._insertstep{run=pip.back, args={k=name}}
    return obj
  end

  -- }}}

  -- {{{ sideeffect functions

  function obj.as(name)
    obj._insertstep{run=pip.as, args={k=name}}
    return obj
  end

  -- }}}

  -- {{{ insert and run steps

  function obj._insertstep(st)
    table.insert(steps, st)
  end

  function obj:_runsteps(reduce)
    -- should I do pipe optimation before?
    local input = self:_getinput()
    local result = {}
    if #steps > 0 then
      local st = steps[1]
      for _,v in ipairs(input.n) do
        local r = st.run({el=v, t="n", c=input.c}, st.args, 1, steps, self)
        if r then table.insert(result, r) end
      end
      for _,v in ipairs(input.l) do
        local r = st.run({el=v, t="l", c=input.c}, st.args, 1, steps, self)
        if r then table.insert(result, r) end
      end
    end
    steps = {}
    result = flatten(result)
    if reduce then return reduce.run(result, reduce.args, self) end
    if #result == 0 then return end
    if #result == 1 then return result[1] end
    local mt = { sort = sortfunc(result) }
    setmetatable(result, { __index = mt })
    return result
  end

  -- }}}

  -- TODO there needs to be some parameter checking and error handling
  -- this could be done more efficiently in c++

  -- {{{ listener handling

  function obj:addListener(name, listener)
    local container = listeners[name] or {}
    for i,l in ipairs(container) do
      -- don't allow a listener twice
      if listener == l then
        return error("same listener isn't permitted twice")
      end
    end
    container[#container + 1] = listener
    listeners[name] = container
  end

  function obj:removeListener(name, listener)
    local container = listeners[name]
    if not container then return end
    for i,l in ipairs(container) do
      if listener == l then
        table.remove(container, i)
        return
      end
    end
  end

  -- send an event to all listeners
  function obj:emit(name, evt)
    local container = listeners[name]
    if not container then return end
    for _,listener in ipairs(container) do
      listener(evt, self, name)
    end
  end

  -- {{{ internal cleanup functions

  obj:addListener("DELTHIS", function()
    for k,_ in pairs(obj) do
      obj[k] = nil
    end
    setmetatable(obj, {
      __index     = deleted,
      __newindex  = deleted,
      __metatable = "not accesable",
      __tostring  = function() return "deleted object" end
    })
  end)

  -- }}}

  -- }}}

  return obj
end

return o

-- vim: fdm=marker
