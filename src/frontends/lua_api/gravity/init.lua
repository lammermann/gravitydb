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

  -- }}}

  -- {{{ import export functions

  function g.import(data, format)
  end

  function g.export(format)
    return
  end

  -- }}}

  return g
end

return gravity

-- vim: fdm=marker
