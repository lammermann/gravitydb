--
-- helper utils for internal use
--
-- This is a collection of functions and objects that could be useful for
-- various modules.
--

local h = {}

function h.get_filter_func(filter)
  if type(filter) == "string" then
    return function(obj) return obj.label() == filter end
  elseif type(filter) == "function" then
    return filter
  end
  return function() return true end
end

return h

-- vim: fdm=marker
