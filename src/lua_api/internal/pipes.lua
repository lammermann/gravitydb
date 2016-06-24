--
-- traversal library with ideas from tinkerpop pipes
--

-- {{{ helper functions

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

-- }}}

local p = {}

function p.id(inp)
  local result = {}
  for _,n in ipairs(inp.n) do
    table.insert(result, n.id())
  end
  for _,l in ipairs(inp.l) do
    table.insert(result, l.id())
  end
  if #result == 0 then return end
  if #result == 1 then return result[1] end
  local mt = { sort = sortfunc(result) }
  setmetatable(result, { __index = mt })
  return result
end

function p.count(inp)
  return #inp.n + # inp.l
end

function p.value(inp, caller, args)
  if not args.k then return end
  local result = {}
  for _,n in ipairs(inp.n) do
    if n.has(args.k) then
      table.insert(result, n.value(args.k, args.v))
    end
  end
  for _,l in ipairs(inp.l) do
    if l.has(args.k) then
      table.insert(result, l.value(args.k, args.v))
    end
  end
  if #result == 0 then return end
  if #result == 1 then return result[1] end
  local mt = { sort = sortfunc(result) }
  setmetatable(result, { __index = mt })
  return result
end

function p.map(inp, caller, args)
  local result = {}
  for i,n in ipairs(inp.n) do
    table.insert(result, args.f(n, i))
  end
  for i,l in ipairs(inp.l) do
    table.insert(result, args.f(l, i))
  end
  local mt = { sort = sortfunc(result) }
  setmetatable(result, { __index = mt })
  return result
end

function p.node(inp, caller, args)
  local idx = args.idx or 1
  return inp.n[idx]
end

function p.delete(inp, caller, args)
  for _,n in ipairs(inp.n) do
    n.delete()
  end
  for _,l in ipairs(inp.l) do
    l.delete()
  end
end

return p

-- vim: fdm=marker
