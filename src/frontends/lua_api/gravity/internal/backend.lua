--
-- storage backend interface
--

-- {{{ includes
local obj  = require "gravity.internal.object"
-- }}}

local backend = {}

backend.st = {
  RUNNING      = 0,
  UNCONFIGURED = 1,
  UNLOADED     = 2,
}

backend.feat = {
  PERSISTANT = 0x1,
  ACID       = 0x2,
  SYNC       = 0x4,
}

function backend.new(params)
  local b  = obj.new()
  local txid = nil -- no transaction yet

  -- get the current backend status
  function b.status()
    return be.st.RUNNING
  end

  -- get the backend features
  -- features can be:
  --    ACID transactional api
  --    sync api
  --    etc.
  function b.features()
    return 0 -- in memory only storage
  end

  -- remove the storage backend
  function b.unload()
  end

  -- get or set configuration params {{{
  --
  -- this should throw an exeption when called after the first (explecit or
  -- implezit) transaction is started. Although this is the default case it's
  -- up to the backend implementation if it allowes hot configuration or not.
  function b.param(key, value)
  end
  -- }}}

  -- CRUD operations {{{

  --
  -- create a new node in the backend
  --
  -- n
  -- :    The node object. The backend will grab all information from it and
  --      store it. Than it will assign an id to the node.
  --
  -- id
  -- :    The id of the new node (optional). Most backends will ignore
  --      this and generate ids on their own.
  --
  -- return
  -- :    The id of the newly created node.
  function b.createNode(n, id)
  end

  --
  -- read a node from the backend
  --
  -- Can be used to init a new node or to update an outdated node.
  --
  -- n
  -- :    The node object to update
  --
  -- id
  -- :    The id is used as a key for the backend storage.
  function b.readNode(n, id)
  end

  function b.writeNode(n)
  end

  function b.deleteNode(id)
  end

  function b.createLink(l, id)
  end

  function b.readLink(l, id)
  end

  function b.writeLink(l)
  end

  function b.deleteLink(id)
  end

  -- get a list off all (filtered) nodes from the backend
  --
  -- filter
  -- :    Can be a label or a list of labels or a filter
  --      function (optional)
  --
  -- index
  -- :    If filter is a function this variable provides
  --      the name of the index that is used to limit the
  --      filtered set
  function b.get_nodes(filter, index)
  end
  
  -- get a list off all (filtered) nodes from the backend
  --
  -- filter
  -- :    Can be a label or a list of labels or a filter
  --      function (optional)
  --
  -- index
  -- :    If filter is a function this variable provides
  --      the name of the index that is used to limit the
  --      filtered set
  function b.get_links(filter, index)
  end
  -- }}}

  -- transaction functions {{{

  -- start a new transaction and set the transaction id
  function b.tx()
    if txid then error("allready in transaction "..tostring(txid)) end
    txid = b._tx()
    return b
  end

  function b.commit()
    b._commit()
    txid = nil
  end

  function b.rollback()
    b._rollback()
    txid = nil
  end

  function b._tx()
  end

  function b._commit()
  end

  function b._rollback()
  end
  -- }}}

  -- sync functions {{{

  -- diff two nodes
  --
  -- can show differences in links and properties.
  -- n1: the first node
  -- n2: the second node
  -- origin: the latest state of the node that both nodes share in comon
  --         (optional). This can be used to see which changes are old and
  --         which should be apllied.
  -- return 1st: a table with the keys of all links and properties that are
  --             different. The values of that table are two value arrays where
  --             the first is the value of `n1` and the second is the value of
  --             `n2` (nil is possible if something was deleted).
  -- return 2nd: if `origin` was provided it returns a table showing only those
  --             keys where both differ from `origin` and thus could not be
  --             determined which one is newer (or right). The values are there
  --             arrays with three values: first that of `origin`, second that
  --             of `n1` and third that of `n2`.
  --             There is also a second table provided in that case with all
  --             the keys where the soloution is resolvable and all the values
  --             from the table that differs from `origin` for that very key.
  function b.diffNode(n1,n2,origin)
  end

  -- currently links can only be added or deleted but never changed. So
  -- implementing this makes no sense right now
  function b.diffLink(l1,l2,origin)
  end

  -- diff two graph versions
  function b.diffGraph(g1,g2,origin)
  end

  function b.mergeNode(n1,n2,origin)
  end

  function b.mergeGraph(g1,g2,origin)
  end

  -- if there where conflicts in the merge they have to be resolved before a
  -- new version could be commited. This command markes for the database, that
  -- all conflicts are resolved and the current state should be taken as the
  -- new version.
  function b.conflictResolved()
  end

  -- finds the last version of an entity that is shared in the history of both
  -- incoming entities (nodes, links or graphs).
  -- If there is no shared origin point returns nil.
  function b.lastCommonAncestor(e1,e2)
  end

  -- }}}

  return b
end

return backend

-- vim: fdm=marker
