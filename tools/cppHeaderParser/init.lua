--
-- Parse C++ header files and generate a data structure
-- representing the class
--
-- This is heavily inspired by the similar python project.
-- see: http://senexcanis.com/open-source/cppheaderparser/
--

-- prepare environment {{{
local lpeg = require "lpeg"

local P, R, S, V, C, Cg, Cb, Cmt, Cc, Ct, B, Cs, Cp =
  lpeg.P, lpeg.R, lpeg.S, lpeg.V, lpeg.C, lpeg.Cg, lpeg.Cb,
  lpeg.Cmt, lpeg.Cc, lpeg.Ct, lpeg.B, lpeg.Cs, lpeg.Cp
-- }}}

local M = {}

-- helper functions {{{

local function error_print(msg, line)
  local line = line or "?"
  error( "Parsing error at line " .. tostring(line) .. ":\n\t"
    .. tostring(msg) )
end

local function warning_print(msg, line)
  local line = line or "?"
  print( "warning at line " .. tostring(line) .. ":\n\t"
    .. tostring(msg) )
end

local function debug_print(msg, line)
  local line = line or "?"
  print( "debug at line " .. tostring(line) .. ":\n\t"
    .. tostring(msg) )
end

local function parse_with(f)
  return function(...) return M[f](...) end
end

-- }}}

-- lpeg parser {{{

-- generic
local period       = P(".")
local lparent      = P("(")
local rparent      = P(")")
local lbracket     = P("[")
local rbracket     = P("]")
local lbrace       = P("{")
local rbrace       = P("}")
local colon        = P(":")
local semicolon    = P(";")
local exclamation  = P("!")
local slash        = P("/")

local spacechar    = S(" \t")

local any          = P(1)
local fail         = any - 1
local always       = P("")
local eof          = - any

local newline      = P("\r\n") + P("\n") + P("\r")
local linechar     = P(1 - newline)
local line         = linechar^0 * newline
                     + linechar^1 * eof
local optspace     = (spacechar + newline)^0
local spaces       = (spacechar + newline)^1

local digit        = R("09")
local hexdigit     = R("09","af","AF")
local letter       = R("AZ","az")
local alphanumeric = R("AZ","az","09")

local access       = C(letter * alphanumeric^0) * colon * optspace / parse_with("cpp_access")
local ty_number    = C(digit^1 + (P("0x" * hexdigit^1)))
local ty_floatnum  = C(S("+-")^-1 * digit^1 * period * digit^0
                     * ( S("eE") * S("+-")^-1 * digit^1 )^-1 )
local name         = ( S("<>_~") + letter ) * ( alphanumeric + P"_" )^0
local cpp_type     = name * (spacechar + newline)
                     * (optspace * (name + P("*")^1) * (spacechar + newline))^0

-- cpp constructs
local comment_singleline = Cs(((optspace * P("//")) / "" * line)^1)
local comment_multiline = P("/*")
                          * Cs(((spacechar^0 * newline * spacechar^0) / "\n"
                            + (any - P("*/")))^0)
                          * P("*/")
local comment      = (comment_singleline + comment_multiline) / parse_with("doxygen")

local function balanced(p1, p2)
  local p1 = P(p1)
  local p2 = P(p2)
  return P{ p1 * ((any - (p1 + p2)) + V(1))^0 * p2 }
end
local function entity(s_pat, f)
  return Ct( P(s_pat) * optspace
         * Cg( Cs(balanced(lbrace, rbrace)), "content") ) / parse_with(f)
         * optspace
end
local property     = Ct( Cg((comment * optspace)^0, "doxygen") * Cg(cpp_type, "type")
                     * Cg(name, "name")
                     * optspace * semicolon ) / parse_with("cpp_property")
local meth_def     = Ct( Cg((comment * optspace)^0, "doxygen") * Cg(cpp_type, "rtn_type")
                     * Cg(name, "name") * optspace
                     * C(balanced(lparent, rparent))
                     * optspace * semicolon ) / parse_with("cpp_method")
local meth_inline  = entity( Cg((comment * optspace)^0, "doxygen") * Cg(cpp_type, "rtn_type")
                     * Cg(name, "name") * optspace
                     * C(balanced(lparent, rparent))
                     * optspace
                     , "cpp_method")
                     * semicolon^-1
local method       = meth_def + meth_inline
local class        = entity(P("class") * spacechar^1 * Cg(name, "name")
                     , "cpp_class")
                     * semicolon^-1
local namespace    = entity(P("namespace") * spacechar^1 * Cg(name, "name")
                     , "cpp_namespace")
                     * semicolon^-1
local union        = entity("union",    "cpp_union")
local struct       = entity("struct",   "cpp_struct")
local enum         = entity("enum",     "cpp_enum")

local define       = P("#define") * spacechar^1
                     * C(linechar^1) / parse_with("define") * newline
local include      = P("#include") * spacechar^1
                     * C(
                       ('"' * (any-'"')^1 * '"')
                       + ("<" * (any-">")^1 * ">")
                     ) / parse_with("include")
                     * spacechar^0 * newline

local header = {
  "entities",
  entities         = optspace
                     * ( define
                       + include
                       + namespace
                       + class
                       + union
                       + struct
                       + enum
                       + method
                       + property
                       + spaces -- ignore spaces
                       + C(any-eof) * Cp() / warning_print
                       )^0
                     * eof
}
-- }}}

-- parsing processors {{{
function M.define(d)
  local def = {
    _type = "define",
    content = d
  }
  return def
end

function M.include(d)
  local inc = {
    _type = "include",
    content = d
  }
  return inc
end

local allowed_access = {
  private = true,
  public = true,
  protected = true
}
function M.cpp_access(d)
  local ac = {
    _type = "access",
    level = d
  }
  if not allowed_access[d] then ac.level = "private" end
  return ac
end

-- Parses doxygen documentation from comments
function M.doxygen(comment)
  return comment
end

function M.cpp_property(prop)
  prop._type = "property"
  return prop
end

-- Takes a name stack and turns it into a class
function M.cpp_class(name, content, context)
  local content = name.content
  local name = name.name
  local cl = {
    _type = "class",
    name = name, -- Name of the class
    doxygen = "", -- Doxygen comments associated with the class if they exist
    inherits = {}, --[[ List of Classes that this one inherits where the values
        are of the form {"access": Anything in supportedAccessSpecifier
                                  "class": Name of the class
        --]]
    classes = {}, -- List of subclasses
    methods = {}, --[[ Dictionary where keys are from supportedAccessSpecifier
        and values are a lists of CppMethod's
    --]]
    properties = {}, --[[ Dictionary where keys are from supportedAccessSpecifier
        and values are lists of CppVariable's
        --]]
    enums = {}, --[[ Dictionary where keys are from supportedAccessSpecifier and
        values are lists of CppEnum's
        --]]
    structs = {}, --[[ Dictionary where keys are from supportedAccessSpecifier and
        values are lists of nested Struct's
        --]]
  }
  for k,_ in pairs(allowed_access) do
    for _,v in ipairs{"classes", "methods", "properties"} do
      cl[v][k] = {}
    end
  end

  local syntax = optspace * lbrace * optspace
            * Ct( access^-1
                  * ( class
                    + Ct( Cg(Cc(""), "rtn_type") * Cg(P(name), "name") * optspace -- constructor
                      * C(balanced(lparent, rparent))
                      * optspace * semicolon ) / parse_with("cpp_method")
                    + method
                    + property
                    + access
                    + spaces
                    + C(any-rbrace) * Cp() / warning_print
                    )^1
              )
            * rbrace
  local ast = assert(lpeg.match(syntax, content))

  cur_access = "private"
  for _,e in ipairs(ast) do
    if e._type == "class" then
      cl.classes[e.name] = e
      table.insert(cl.classes, e)
    elseif e._type == "method" then
      cl.methods[cur_access][e.name] = e
      table.insert(cl.methods[cur_access], e)
    elseif e._type == "property" then
      cl.properties[cur_access][e.name] = e
      table.insert(cl.properties[cur_access], e)
    elseif e._type == "access" then
      cur_access = e.level
    elseif e._type == "struct" then
      cl.structs[e.name] = e
      table.insert(cl.structs, e)
    end
  end

  return cl
end

-- Takes a name stack and turns it into a union
function M.cpp_union(name_stack, cur_template)
  local un = M.cpp_class(name_stack, cur_template)
  un._type = "union"

  return un
end

function M.cpp_method(d)
  local meth = {
    _type = "method",
    name = d.name, -- Name of the method
    rtn_type = d.rtn_type, -- Return type of the method
    doxygen = d.doxygen, -- Doxygen comments associated with the method if they exist
    parameters = {}, -- List of cpp variables
  }

  return meth
end

function M.cpp_namespace(ns)
  local syntax = lbrace * Ct(header) --* rbrace
  local ast = assert(lpeg.match(syntax, ns.content))
  ast._type = "namespace"
  ast.name = ns.name
  return ast
end

-- Parsed C++ class header
function M.cpp_header(header_file_name, arg_type, args)
  local arg_type = arg_type or "file"
  local hd = {
    classes = {},
    structs = {},
    functions = {}, -- functions that aren't part of a class
    pragmas = {},
    defines = {},
    includes = {},
    enums = {},
    variable = {},
    global_enums = {},
  }

  if arg_type == "file" then
    hd.header_file_name = header_file_name
    hd.main_class       = header_file_name -- TODO split off prefix and suffix
    local f = assert(io.open(hd.header_file_name, "r"))
    hd.content          = f:read("*all")
    f:close()
  elseif arg_type == "string" then
    hd.header_file_name = ""
    hd.main_class       = "???"
    hd.content          = header_file_name
  else
    error("arg_type must be either file or string")
  end

  local syntax = Ct(header)
  local ast = assert(lpeg.match(syntax, hd.content))

  local cur_line = 0
  local cur_char = 0
  local cur_ns
  local function process(ast, ns, linenum, charnum)
    for _,e in ipairs(ast) do
      if e._type == "class" then
        e.namespace = ns
        hd.classes[e.name] = e
        table.insert(hd.classes, e)
      elseif e._type == "struct" then
        hd.structs[e.name] = e
        table.insert(hd.structs, e)
      elseif e._type == "method" then
        hd.functions[e.name] = e
        table.insert(hd.functions, e)
      elseif e._type == "include" then
        table.insert(hd.includes, e.content)
      elseif e._type == "define" then
        table.insert(hd.defines, e.content)
      elseif e._type == "namespace" then
        local newns = tostring(e.name)
        if ns then newns = ns .. "::" .. newns end
        process(e, newns, linenum, charnum)
      end
    end
    return ast
  end
  process(ast, cur_ns, cur_line, cur_char)

  return hd
end
-- }}}

-- auxillary functions {{{

function M.filter(container, filter, processor)
  local filter = filter or function() return true end
  local processor = processor or function(d) return d end
  local out = {}
  for k,v in pairs(container) do
    if filter(v,k) then
      table.insert(out, processor(v,k))
    end
  end
  return out
end

-- }}}

return M

-- vim: fdm=marker
