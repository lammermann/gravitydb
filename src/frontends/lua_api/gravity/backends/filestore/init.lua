--
-- generic filestore storage backend
--

-- {{{ includes
local be   = require "gravity.internal.backend"
local lfs  = require "lfs"
local uuid = require "uuid"
-- }}}

local filestore = {}

function filestore.init(params)
  local fs = be.new(params)
  fs.name = "filestore"
  local path = nil

  function fs.status()
    if type(path) ~= "string" then return be.st.UNCONFIGURED end
    return be.st.RUNNING
  end

  function fs.features()
    return be.feat.PERSISTANT
  end

  function fs.param(key, value)
    if key == "path" then
      local p = lfs.attributes(value)
      if p then
        if p.mode == "directory" then
          path = value
        else
          error("file " .. value .. "is not a directory")
        end
      else
        path, err = lfs.mkdir(value)
        if not path then error(err) end
      end
      return path
    end
  end

  function wr_node(n, id, fpath)
    local fp = assert(io.open(fpath, "w"))
    -- TODO write all links and params in a list (maybe use msgpack)
    assert(fp:close())
    n._setid(id)
    return id
  end

  function wr_link(l, id, fpath)
    local fp = assert(io.open(fpath, "w"))
    -- TODO write all links and params in a list (maybe use msgpack)
    assert(fp:close())
    l._setid(id)
    return id
  end

  function fs.createNode(n, id)
    local id = id or uuid.new()
    id = "n"..tostring(id)
    local fpath = path.."/"..id
    if lfs.attributes(fpath) then error("id collision. id: '"..id.."' already exists") end
    return wr_node(n, id, fpath)
  end

  function fs.readNode(n, id)
  end

  function fs.writeNode(n)
    local id = tostring(n._id())
    local fpath = path.."/"..id
    return wr_node(n, id, fpath)
  end

  function fs.deleteNode(id)
    local id = tostring(id)
    local fpath = path.."/"..id
    if not lfs.attributes(fpath) then error("id: '"..id.."' does not exist") end
    assert(os.remove(fpath))
  end

  function fs.createLink(l, id)
    local id = id or uuid.new()
    id = "l"..tostring(id)
    local fpath = path.."/"..id
    if lfs.attributes(fpath) then error("id collision. id: '"..id.."' already exists") end
    return wr_link(l, id, fpath)
  end

  function fs.readLink(l, id)
  end

  function fs.writeLink(l)
    local id = tostring(l._id())
    local fpath = path.."/"..id
    return wr_link(l, id, fpath)
  end

  fs.deleteLink = fs.deleteNode -- equal implementation

  function fs.get_nodes(filter, index)
    local nds = {}
    for id in lfs.dir(path) do
      if string.sub(id,1,1) == "n" then
        local n = node.new()
        fs.readNode(n, id)
        table.insert(nds, n)
      end
    end
    return nds
  end

  function fs.get_links(filter, index)
    local lks = {}
    for id in lfs.dir(path) do
      if string.sub(id,1,1) == "l" then
        local l = link.new()
        fs.readLink(l, id)
        table.insert(lks, l)
      end
    end
    return lks
  end

  return fs
end

return filestore

-- vim: fdm=marker
