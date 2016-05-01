--
-- the basic db object
--
-- event listeners can be added to
-- * force type schemas
-- * update indexes
-- * index objects, that should be updated in the storage backend
-- * etc.

local o = {}

local function deleted()
  error("This is a deleted object. It can not be used any more")
end

function o.new(listeners)
  local obj = {}
  local listeners = {}

  -- TODO there needs to be some parameter checking and error handling
  -- this could be done more efficiently in c++

  function obj:addListener(name, listener)
    local container = listeners[name] or {}
    for i,l in ipairs(container) do
      -- don't allow a listener twice
      if listener == l then return end
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
      -- TODO error cause of id colision
      return -1
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
