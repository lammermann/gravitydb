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

  context("traversal", function() -- {{{

    -- prepare the moses graph {{{
    before_each(function()
      g = gravity.new()

      moses = g.createNode({name = "moses"}, "MALE")
      aaron = g.createNode({name = "aaron"}, "MALE")
      miriam = g.createNode({name = "miriam"}, "FEMALE")

      moses.addLink(aaron, "sibling_of", '-')
      moses.addLink(miriam, "sibling_of", '-')
      miriam.addLink(aaron, "sibling_of", '-')
    end)

    after_each(function()
      g.delete()
    end)
    -- }}}

    context("aggregate steps:", function() -- {{{

      it("value", function() -- {{{
        assert.are.same("miriam", g.V("FEMALE").value("name"))
        -- is sortable
        assert.are.same({"aaron", "moses"}, g.V("MALE").value("name").sort())
        -- can be used to set values
        g.V("MALE").value("test","x")
        assert.are.same({"aaron", "moses"}, g.V().has("test","x").value("name").sort())
      end) -- }}}

      it("deleteProperty", function() -- {{{
        assert.are.same("miriam", g.filter("FEMALE").value("name"))
        g.filter("FEMALE").deleteProperty("name")
        assert.is_nil(g.filter("FEMALE").value("name"))
      end) -- }}}

    end) -- }}}

  end) -- }}}

  describe("query language frontends", function() -- {{{

    -- prepare the moses graph {{{
    setup(function()
      g = gravity.new()

      moses = g.createNode({name = "moses"}, "MALE")
      aaron = g.createNode({name = "aaron"}, "MALE")
      miriam = g.createNode({name = "miriam"}, "FEMALE")

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

        it("filter by label", function()
          assert.is.equal(miriam.id(), g.V("FEMALE").id())
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
