--
-- the basic db object
--
-- event listeners can be added to
-- * force type schemas
-- * update indexes
-- * index objects, that should be updated in the storage backend
-- * etc.

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

  -- TODO there needs to be some parameter checking and error handling
  -- this could be done more efficiently in c++

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

  obj:addListener("DELTHIS", function(o)
    if o ~= obj then
      error("id colision wrong object")
    end
    for k,_ in pairs(o) do
      o[k] = nil
    end
    setmetatable(o, {
      __index     = deleted,
      __newindex  = deleted,
      __metatable = "not accesable",
      __tostring  = function() return "deleted object" end
    })
  end)

  -- }}}

  return obj
end

return o

-- vim: fdm=marker
