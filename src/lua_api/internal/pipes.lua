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

-- aggregate functions {{{

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

function p.link(inp, caller, args)
  for _,n in ipairs(inp.n) do
    n.addLink(args.n, args.l, args.d, args.p)
  end
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

-- }}}

-- filter functions {{{

function p.filter(inp, caller, args)
  local nds = {}
  local lks = {}
  if args.f then
    local ff  = get_filter_func(args.f)
    for _,v in ipairs(inp.n) do
      if ff(v) then
        table.insert(nds,v)
      end
    end
    for _,v in ipairs(inp.l) do
      if ff(v) then
        table.insert(lks,v)
      end
    end
  else
    for _,v in ipairs(inp.n) do
      table.insert(nds,v)
    end
    for _,v in pairs(inp.l) do
      table.insert(lks,v)
    end
  end
  return { n=nds, l=lks, c=inp.c }
end

function p.nodes(inp, caller, args)
  local nds = {}
  if args.f then
    local ff  = get_filter_func(args.f)
    for _,v in ipairs(inp.n) do
      if ff(v) then
        table.insert(nds,v)
      end
    end
  else
    for _,v in ipairs(inp.n) do
      table.insert(nds,v)
    end
  end
  return { n=nds, l={}, c=inp.c }
end

function p.links(inp, caller, args)
  local lks = {}
  if args.f then
    local ff  = get_filter_func(args.f)
    for _,v in ipairs(inp.l) do
      if ff(v) then
        table.insert(lks,v)
      end
    end
  else
    for _,v in ipairs(inp.l) do
      table.insert(lks,v)
    end
  end
  return { n={}, l=lks, c=inp.c }
end

function p.in_(inp, caller, args)
  local ff  = get_filter_func(args.f)
  local nds = {}
  local lks = {}
  for _,n in ipairs(inp.n) do
    for _,l in pairs(n._links()) do
      lks[l.id()] = l
    end
  end
  for _,l in pairs(inp.l) do
    lks[l.id()] = l
  end
  for _,l in pairs(lks) do
    local n = l.n(1)
    if ff(l) then
      table.insert(nds,n)
    end
  end
  return { n=nds, l={}, c=inp.c }
end

function p.out(inp, caller, args)
  local ff  = get_filter_func(args.f)
  local nds = {}
  local lks = {}
  for _,n in ipairs(inp.n) do
    for _,l in pairs(n._links()) do
      lks[l.id()] = l
    end
  end
  for _,l in pairs(inp.l) do
    lks[l.id()] = l
  end
  for _,l in pairs(lks) do
    local n = l.n(2)
    if ff(l) then
      table.insert(nds,n)
    end
  end
  return { n=nds, l={}, c=inp.c }
end

function p.inL(inp, caller, args)
  local res = caller.subset()
  for _,n in ipairs(inp.n) do
    res = res + n.inL(args.f)
  end
  local out = res:_getinput()
  out.c = inp.c
  return out
end

function p.outL(inp, caller, args)
  local res = caller.subset()
  for _,n in ipairs(inp.n) do
    res = res + n.outL(args.f)
  end
  local out = res:_getinput()
  out.c = inp.c
  return out
end

-- }}}

return p

-- vim: fdm=marker
