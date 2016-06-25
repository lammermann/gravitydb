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

local function nextstep(inp, idx, steps, caller)
  local st = steps[idx+1]
  if st then
    return st.run(inp, st.args, idx+1, steps, caller)
  end
end

local function isdeleted(obj)
  return type(obj) == "table"
    and tostring(obj) == "deleted object"
    and getmetatable(obj) == "not accesable"
end

-- }}}

local p = {}

-- aggregate functions {{{

function p.id(inp)
  return inp.el.id()
end

function p.count(inp)
  return #inp
end

function p.value(inp, args)
  if not args.k then return end
  local el = inp.el
  if el.has(args.k) then
    return el.value(args.k, args.v)
  end
end

function p.map(inp, args)
  return args.f(inp.el, inp.c)
end

function p.link(inp, args)
  if not (args.n or args.l or args.d or inp.t == "n") then return end
  local el = inp.el
  el.addLink(args.n, args.l, args.d, args.p)
end

function p.node(inp, args)
  local idx = args.idx or 1
  local out = inp[idx]
  if not out or out.t ~= "n" then return end
  return out.el
end

function p.delete(inp, args)
  if not isdeleted(inp.el) then
    inp.el.delete()
  end
end

-- }}}

-- filter functions {{{

function p.filter(inp, args, ...)
  if args.f then
    local ff  = get_filter_func(args.f)
    if ff(inp.el) then
      return nextstep(inp, ...)
    end
  else
    return nextstep(inp, ...)
  end
end

function p.nodes(inp, args, ...)
  if inp.t ~= "n" then return end
  return p.filter(inp, args, ...)
end

function p.links(inp, args, ...)
  if inp.t ~= "l" then return end
  return p.filter(inp, args, ...)
end

function p.in_(inp, args, ...)
  local ff  = get_filter_func(args.f)
  local nds = {}
  local lks = {}
  local el = inp.el
  if inp.t == "n" then
    for _,l in pairs(el._links()) do
      lks[l.id()] = l
    end
  elseif inp.t == "l" then
    lks[el.id()] = el
  end
  for _,l in pairs(lks) do
    local v = l.n(1)
    if ff(l) then
      local res = nextstep({el=v, t="n", c=inp.c}, ...)
      if res then table.insert(nds,res) end
    end
  end
  if #nds == 0 then return end
  if #nds == 1 then return nds[1] end
  setmetatable(nds, { __metatable = "flatten" })
  return nds
end

function p.out(inp, args, ...)
  local ff  = get_filter_func(args.f)
  local nds = {}
  local lks = {}
  local el = inp.el
  if inp.t == "n" then
    for _,l in pairs(el._links()) do
      lks[l.id()] = l
    end
  elseif inp.t == "l" then
    lks[el.id()] = el
  end
  for _,l in pairs(lks) do
    local v = l.n(2)
    if ff(l) then
      local res = nextstep({el=v, t="n", c=inp.c}, ...)
      if res then table.insert(nds,res) end
    end
  end
  if #nds == 0 then return end
  if #nds == 1 then return nds[1] end
  setmetatable(nds, { __metatable = "flatten" })
  return nds
end

function p.inL(inp, args, ...)
  if inp.t ~= "n" then return end
  local ff  = get_filter_func(args.f)
  local el = inp.el
  local lks = {}
  for _,l in pairs(el._links()) do
    if ff(l) and l.n(2) == el then
      local res = nextstep({el=l, t="l", c=inp.c}, ...)
      if res then table.insert(lks,res) end
    end
  end
  if #lks == 0 then return end
  if #lks == 1 then return lks[1] end
  setmetatable(lks, { __metatable = "flatten" })
  return lks
end

function p.outL(inp, args, ...)
  if inp.t ~= "n" then return end
  local ff  = get_filter_func(args.f)
  local el = inp.el
  local lks = {}
  for _,l in pairs(el._links()) do
    if ff(l) and l.n(1) == el then
      local res = nextstep({el=l, t="l", c=inp.c}, ...)
      if res then table.insert(lks,res) end
    end
  end
  if #lks == 0 then return end
  if #lks == 1 then return lks[1] end
  setmetatable(lks, { __metatable = "flatten" })
  return lks
end

function p.back(inp, args, ...)
  local nds = {}
  local lks = {}
  local objs = inp.c[args.k]
  if objs then
    for _,n in ipairs(inp.n) do
      nd = objs[n.id()]
      table.insert(nds, nd)
    end
    for _,l in ipairs(inp.l) do
      lk = objs[l.id()]
      table.insert(lks, lk)
    end
  end
  return nextstep({ n=nds, l=lks, c=inp.c }, ...)
end

-- }}}

-- {{{ sideeffect functions

function p.as(inp, args, ...)
  local objs = {}
  for _,v in ipairs(inp.n) do
    objs[v.id()] = v
  end
  for _,v in pairs(inp.l) do
    objs[v.id()] = v
  end
  inp.c[args.k] = objs
  return nextstep(inp, ...)
end

-- }}}

return p

-- vim: fdm=marker
