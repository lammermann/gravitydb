--
-- Parse C++ header files and generate a data structure
-- representing the class
--
-- This is heavily inspired by the similar python project.
-- see: http://senexcanis.com/open-source/cppheaderparser/
--

local lpeg = require "lpeg"
