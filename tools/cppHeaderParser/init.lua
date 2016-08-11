--
-- Parse C++ header files and generate a data structure
-- representing the class
--
-- This is heavily inspired by the similar python project.
-- see: http://senexcanis.com/open-source/cppheaderparser/
--

local lpeg = require "lpeg"

local P, R, S, V, C, Cg, Cb, Cmt, Cc, Ct, B, Cs =
  lpeg.P, lpeg.R, lpeg.S, lpeg.V, lpeg.C, lpeg.Cg, lpeg.Cb,
  lpeg.Cmt, lpeg.Cc, lpeg.Ct, lpeg.B, lpeg.Cs

local M = {}

-- Takes a name stack and turns it into a class
function M.cpp_class(name-stack, cur_template)
  local cl = {}
  
  return cl
end
