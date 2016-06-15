-- make the tests standalone
require "busted.runner"()

describe("The gravity graph database", function()

  -- prepare environment {{{
  setup(function()
    package.path = "../src/?.lua;../src/lua_api/?.lua;"..package.path
    --gravity = require "gravity"
    gravity = require "graph"
  end)

  teardown(function()
    gravity = nil
  end)

  local contexts

  -- }}}

  context("The gravity module", function() -- {{{
    it("should have a 'version' member", function()
      assert.are.equal("string", type(gravity.version))
    end)
    it("should have a '_VERSION' member", function()
      assert.are.equal("string", type(gravity._VERSION))
    end)
  end) -- }}}

  describe("query language frontends", function() -- {{{

    -- prepare the moses graph {{{
    setup(function()
      g = gravity.new()

      moses = g.createNode({name = "moses"}, "PERSON")
      aaron = g.createNode({name = "aaron"}, "PERSON")
      miriam = g.createNode({name = "miriam"}, "PERSON")

      moses.addLink(aaron, "sibling_of", '-')
      moses.addLink(miriam, "sibling_of", '-')
      miriam.addLink(aaron, "sibling_of", '-')
    end)
    -- }}}

    describe("gremlinish", function() -- {{{

      describe("queries:", function()

        it("find vertex by name", function()
          assert.is.equal(moses.id(), g.V().has("name", "moses").id())
        end)

        it("Who are the siblings of aaron?", function()
          local siblings = aaron.out("sibling_of").value("name")
          assert.is.equal("table",type(siblings))
          table.sort(siblings)
          assert.are.same({"miriam","moses"},siblings)
        end)

      end)
    end) -- }}}

  end) -- }}}

end)

-- vim: fdm=marker
