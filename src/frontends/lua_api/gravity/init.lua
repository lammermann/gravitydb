-- {{{ includes
local set  = require "gravity.internal.set"
local node = require "gravity.node"
-- }}}

local gravity = {}

gravity.version = "0.1"
gravity._VERSION = gravity.version

function gravity.graph()
  local g = set.new()

  -- {{{ CRUD operations

  function g.createNode(props, label)
    return node.new(props, label, g)
  end

  -- overrides getinput and reads everything from backend
  function g:_getinput()
    local nds = g.backend.get_nodes()
    local lks = g.backend.get_links()
    return { n=nds, l=lks, c={} }
  end

  -- }}}

  -- switch the backend
  --
  -- if not called the default backend is in memory only
  function g.setBackend(name, ...)
    if g.backend then
      g.backend.unload(g)
    end
    g.backend = require("gravity.backends."..name).init(...)
  end

  g.setBackend("memory") -- default backend is memory only
  return g
end

return gravity

-- vim: fdm=marker
