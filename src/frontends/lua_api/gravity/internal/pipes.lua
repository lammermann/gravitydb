--
-- traversal library with ideas from tinkerpop pipes
--

-- {{{ includes
local h    = require "gravity.internal.helpers"

local get_filter_func = h.get_filter_func
-- }}}

-- {{{ helper functions

-- duplicate a table
local function duptable(t)
  local out = {}
  for k,v in pairs(t) do
    if type(v) == "table" and getmetatable(t) == "duplicate" then
      -- deep copy only tables that are marked
      out[k] = duptable(v)
    else
      out[k] = v
    end
  end
  return out
end

-- go recursivly to the next step
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

local function pushresult(t)
  if #t == 0 then return end
  if #t == 1 then return t[1] end
  setmetatable(t, { __metatable = "flatten" })
  return t
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
  return inp.el.value(args.k, args.v)
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

function p.deleteP(inp, args)
  if not args.k then return end
  inp.el[args.k] = nil
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

local function adjacend(direction)
  local d1 = 1
  local d2 = 2
  if direction == ">" then
    d1 = 2
    d2 = 1
  end
  return function(inp, args, ...)
    local ff  = get_filter_func(args.f)
    local el = inp.el
    if inp.t == "l" and ff(el) then
      return nextstep({el=el.n(d1), t="n", c=inp.c}, ...)
    end

    local nds = {}
    for _,l in pairs(el._links()) do
      local v = l.n(d1)
      if ff(l) and el == l.n(d2) then
        local res = nextstep({el=v, t="n", c=inp.c}, ...)
        if res then table.insert(nds,res) end
      end
    end
    return pushresult(nds)
  end
end

p.in_ = adjacend("<")
p.out = adjacend(">")

local function adjacendL(direction)
  local d = 1
  if direction == "<" then d = 2 end
  return function(inp, args, ...)
    if inp.t ~= "n" then return end
    local ff  = get_filter_func(args.f)
    local el = inp.el
    local lks = {}
    for _,l in pairs(el._links()) do
      if ff(l) and l.n(d) == el then
        local res = nextstep({el=l, t="l", c=inp.c}, ...)
        if res then table.insert(lks,res) end
      end
    end
    return pushresult(lks)
  end
end

p.inL  = adjacendL("<")
p.outL = adjacendL(">")

function p.back(inp, args, ...)
  if not args.k then return end
  local obj = inp.c[args.k]
  if obj then
    return nextstep({ el=obj.el, t=obj.t, c=inp.c }, ...)
  end
end

-- }}}

-- {{{ sideeffect functions

function p.as(inp, args, ...)
  if not args.k then return end
  inp.c[args.k] = duptable(inp)
  return nextstep(inp, ...)
end

-- }}}

return p

-- vim: fdm=marker
