-- make the tests standalone
require "busted.runner"()

describe("gravity database", function()

  -- prepare environment {{{
  setup(function()
    local srcpath = "../src/frontends/lua_api/"
    package.path = srcpath.."?.lua;"..srcpath.."?/init.lua;"..package.path
    package.cpath = "../bin/release/libs/?.so;"..package.cpath
    gravity = require "gravity"
    be      = require "gravity.internal.backend"
  end)

  teardown(function()
    gravity = nil
    be      = nil
  end)
  -- }}}

  context("filestore", function() -- {{{

    -- prepare environment {{{
    before_each(function()
      g = gravity.graph()
      g.setBackend("filestore")
    end)

    after_each(function()
      g = nil
    end)
    -- }}}

    it("needs path before it is accessable", function() -- {{{
      assert.is.equal(be.st.UNCONFIGURED, g.backend.status())
      g.backend.param("path", "data/samplefilestore")
      assert.is.equal(be.st.RUNNING, g.backend.status())
    end) -- }}}

  end) -- }}}

end)

-- vim: fdm=marker
