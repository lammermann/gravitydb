--
-- generic memory only storage
--

local be   = require "gravity.internal.backend"

local mem = {}

function mem.init()
  local nodes = {}
  local links = {}
  local m = be.new()

  function m.createNode(n)
    nodes[n._id()] = n
    return n._id()
  end

  function m.deleteNode(id)
    nodes[id] = nil
  end

  function m.createLink(l)
    links[l._id()] = l
    return l._id()
  end

  function m.deleteLink(id)
    links[id] = nil
  end

  function m.get_nodes(filter, index)
    local nds = {}
     for _,n in pairs(nodes) do table.insert(nds,n) end
     return nds
  end

  function m.get_links(filter, index)
    local lks = {}
    for _,l in pairs(links) do table.insert(lks,l) end
    return lks
  end

  return m
end

return mem
