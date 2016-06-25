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
      miriam = g.createNode({name = "miriam", a = 1}, "FEMALE")
      amram = g.createNode({name = "amram"}, "MALE")
      jochebed = g.createNode({name = "jochebed"}, "FEMALE")

      moses.addLink(aaron,  "sibling_of", '>', { b = 1 })
      moses.addLink(miriam, "sibling_of", '>', { b = 2 })
      miriam.addLink(aaron, "sibling_of", '>', { b = 3 })
      moses.addLink(aaron,  "sibling_of", '<')
      moses.addLink(miriam, "sibling_of", '<')
      miriam.addLink(aaron, "sibling_of", '<')
      amram.addLink(moses,  "parent_of",  '>')
      amram.addLink(aaron,  "parent_of",  '>')
      amram.addLink(miriam, "parent_of",  '>')
      jochebed.addLink(moses,  "parent_of",  '>')
      jochebed.addLink(aaron,  "parent_of",  '>')
      jochebed.addLink(miriam, "parent_of",  '>')
    end)

    after_each(function()
      g.delete()
    end)
    -- }}}

    context("filter steps:", function() -- {{{

      it("filter", function() -- {{{
        assert.are.same({"jochebed", "miriam"},
          g.filter("FEMALE").value("name").sort()
        )
      end) -- }}}

      it("nodes", function() -- {{{
        assert.are.same({"jochebed", "miriam"},
          g.V("FEMALE").value("name").sort()
        )
      end) -- }}}

      it("links", function() -- {{{
        assert.are.same(6,
          g.E("parent_of").count()
        )
      end) -- }}}

      it("has", function() -- {{{
        assert.are.same(3,
          g.E("sibling_of").has("b").count()
        )
        assert.are.same(1,
          g.E("sibling_of").has("b", 3).count()
        )
      end) -- }}}

      it("hasNot", function() -- {{{
        assert.are.same(1,
          g.V("FEMALE").hasNot("a").count()
        )
        assert.are.same(5,
          g.E("sibling_of").hasNot("b", 3).count()
        )
      end) -- }}}

      it("in", function() -- {{{
        assert.are.same({"amram", "amram", "jochebed", "jochebed"},
          g.V().has("name", "moses")
            .in_("sibling_of")
            .in_("parent_of")
            .value("name").sort()
        )
      end) -- }}}

      it("out", function() -- {{{
        assert.are.same({"aaron", "moses"}, g.V().has("name", "miriam")
          .out("sibling_of")
          .value("name").sort()
        )
        assert.are.same({"aaron", "miriam", "moses", "moses"},
          g.V().has("name", "moses")
            .out("sibling_of")
            .out("sibling_of")
            .value("name").sort()
        )
        -- can also be used from links
        assert.are.same({"aaron", "miriam"},
          g.V().has("name", "moses")
            .outL("sibling_of")
            .out()
            .value("name").sort()
        )
      end) -- }}}

      it("inL", function() -- {{{
        assert.are.same(2, g.V().has("name", "aaron")
          .inL("sibling_of")
          .count()
        )
        assert.are.same({1,3}, g.V().has("name", "aaron")
          .inL("sibling_of")
          .value("b")
          .sort()
        )
      end) -- }}}

      it("outL", function() -- {{{
        assert.are.same(0, g.V().has("name", "aaron")
          .outL("sibling_of")
          .has("b")
          .count()
        )
        assert.are.same({1,2}, g.V().has("name", "moses")
          .outL("sibling_of")
          .value("b")
          .sort()
        )
      end) -- }}}

      it("back", function() -- {{{
        -- Who are the siblings of moses siblings that have a sister?
        assert.are.same({"miriam", "moses"},
          moses.out("sibling_of").as("s")
            .out("sibling_of")
            .filter("FEMALE").back("s")
            .out("sibling_of")
            .value("name")
            .sort()
        )
      end) -- }}}

    end) -- }}}

    context("sideeffect steps:", function() -- {{{

      it("as", function() -- {{{
        assert.are.same({"aaron amram", "miriam amram", "moses amram"},
          g.V("MALE").as("x")
            .out("parent_of").map(function(el, c)
              local x = c["x"].el
              return el.value("name") .. " " .. x.value("name")
            end).sort()
        )
      end) -- }}}

    end) -- }}}

    context("aggregate steps:", function() -- {{{

      it("id", function() -- {{{
        assert.are.same(moses.id(), g.V().has("name", "moses").id())
      end) -- }}}

      it("count", function() -- {{{
        assert.are.same(3, g.V("MALE").count())
      end) -- }}}

      it("value", function() -- {{{
        assert.are.same("miriam", g.V().has("name","miriam").value("name"))
        -- is sortable
        assert.are.same({"aaron", "amram", "moses"}, g.V("MALE").value("name").sort())
        -- can be used to set values
        g.V("MALE").value("test","x")
        assert.are.same({"aaron", "amram", "moses"}, g.V().has("test","x").value("name").sort())
      end) -- }}}

      it("map", function() -- {{{
        assert.are.same({"aaron 5", "amram 5", "jochebed 8", "miriam 6", "moses 5"},
          g.V().map(function(el)
            return el.value("name") .. " " .. tostring(#el.value("name"))
          end).sort()
        )
      end) -- }}}

      it("link", function() -- {{{
        local gershom = g.createNode({name = "gershom"}, "MALE")
        g.V().has("name","moses").in_("parent_of").link(gershom, "gparent_of", ">")
        assert.are.same({"amram", "jochebed"},
          gershom.in_("gparent_of").value("name").sort()
        )
      end) -- }}}

      it("node", function() -- {{{
        assert.is.equal(moses, g.V().has("name","moses").n())
      end) -- }}}

      it("deleteProperty", function() -- {{{
        assert.are.same("miriam", g.has("a", 1).value("name"))
        g.has("a", 1).deleteProperty("name")
        assert.is_nil(g.has("a", 1).value("name"))
      end) -- }}}

      it("delete", function() -- {{{
        g.V().has("name","moses").delete()
        assert.are.same("aaron", g.V().has("name","miriam").out("sibling_of").value("name"))
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
