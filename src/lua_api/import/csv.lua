
-- Imports {{{
local lpeg = require "lpeg"
-- }}}

-- Helper Functions {{{

local space   = lpeg.S' \t\n\v\f\r'
local field   = '"' * space^0 * lpeg.Cs(((lpeg.P(1) - (space^0 * '"')) + lpeg.P'""' / '"')^0) * space^0 * '"' +
                    space^0 * lpeg.C((1 - (space^0 * lpeg.S',\n"'))^0) * space^0

local record  = lpeg.Ct(field * (',' * field)^0)

local function split (s, sep)
  sep = lpeg.P(sep)
  local elem = lpeg.C((1 - sep)^0)
  local p = lpeg.Ct(elem * (sep * elem)^0)   -- make a table capture
  return lpeg.match(p, s)
end

local function csv (s, processor, fields)
  local fields = fields == false or fields or 1
  local lines = split(s, '\n')
  local fldnames
  if type(fields) == 'number' then -- row number of the field name record
    fldnames = lpeg.match(record, lines[fields]) -- filter out the field names
    table.remove(lines, fields) -- remove row
  elseif type(fields) == 'table' then -- a table of field names
    fldnames = fields
  else -- no field names
    fldnames = false
  end
  local tmp = {}
  for _,line in ipairs(lines) do
    if line and line:gsub("^%s*(.-)%s*$", "%1") ~= "" then
      local tmp2 = lpeg.match(record, line)
      if fldnames then
        local tmp3 = {}
        for i,f in ipairs(tmp2) do
          tmp3[fldnames[i] or 1] = f
        end
        tmp2 = tmp3
      end
      table.insert(tmp, tmp2)
      if type(processor) == "function" then
        processor(tmp2)
      end
    end
  end

  return tmp
end
-- }}}

return function(fname, ...)
  local f,e = io.open(fname, "r")
  if not f then -- when file not exists
    error(e)
  end
  local content = f:read("*all")
  f:close()
  return csv(content, ...)
end

-- vim: fdm=marker
