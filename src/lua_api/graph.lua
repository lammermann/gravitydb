-- {{{ includes
local set  = require "internal.set"
local node = require "node"
-- }}}

local graph = {}

graph.version = "0.1"
graph._VERSION = graph.version

function graph.new()
  local g = set.new()

  -- {{{ CRUD operations

  function g.createNode(props, label)
    return node.new(props, label, g)
  end

  function g.deleteNode(node)
    -- TODO delete all links to other nodes
    g:emit("DELNODE", node)
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

return graph

-- vim: fdm=marker
