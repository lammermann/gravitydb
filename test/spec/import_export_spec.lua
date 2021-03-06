-- make the tests standalone
require "busted.runner"()

describe("gravity database", function()

  -- prepare environment {{{
  setup(function()
    local srcpath = "../src/frontends/lua_api/"
    package.path = srcpath.."?.lua;"..srcpath.."?/init.lua;"..package.path
    gravity = require "gravity"
  end)

  teardown(function()
    gravity = nil
  end)
  -- }}}

  context("import", function() -- {{{

    -- prepare environment {{{
    before_each(function()
      g = gravity.graph()
    end)

    after_each(function()
      g = nil
    end)
    -- }}}

    context("csv", function() -- {{{

      -- prepare environment {{{
      before_each(function()
        csv = require "gravity.import.csv"
      end)

      after_each(function()
        csv = nil
      end)
      -- }}}

      it("import", function() -- {{{
        csv("data/moses_nodes.csv", function(data)
          g.createNode({name=data.name}, data.label)
        end)
        assert.is.equal(3, g.V().count())
        csv("data/moses_links.csv", function(data)
          local n  = g.V().has("name", data.id1).n()
          local n2 = g.V().has("name", data.id2).n()
          n.addLink(n2, data.label, data.direction)
        end)
        assert.are.same(2,g.V().has("name", "aaron").outL("sibling_of").count())
      end) -- }}}

    it("fire error on non existing file", function() -- {{{
      assert.has.errors(function()
        csv("does-not-exist.csv", function(data)
          g.createNode({name=data.name}, data.label)
        end)
      end)
    end) -- }}}

    end) -- }}}

  end) -- }}}

end)

-- vim: fdm=marker
