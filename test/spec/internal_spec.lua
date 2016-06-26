-- make the tests standalone
require "busted.runner"()

describe("gravity database core", function()

  -- prepare environment {{{
  setup(function()
    local srcpath = "../src/frontends/lua_api/"
    package.path = srcpath.."?.lua;"..srcpath.."?/init.lua;"..package.path
    obj  = require "gravity.internal.object"
    set  = require "gravity.internal.set"
    link = require "gravity.link"
    node = require "gravity.node"
  end)

  teardown(function()
    obj = nil
    set = nil
    node = nil
    link = nil
  end)
  -- }}}

  context("nodes", function() -- {{{

    -- prepare environment {{{
    before_each(function()
      s = set.new()
      n = node.new(nil, "test", s)
    end)

    after_each(function()
      n = nil
    end)
    -- }}}

    it("should have an id", function() -- {{{
      assert.is.truthy(n.id())
    end) -- }}}

    it("can have properties", function() -- {{{
      assert.is.equal(nil, n.value("key"))
      n.value("key", "val")
      assert.is.equal("val", n.value("key"))
      assert.is.equal("val", n["key"]) -- make sure alias also works
      n["key"] = nil
      assert.is.equal(nil, n.value("key"))
    end) -- }}}

  end) -- }}}

    context("links", function() -- {{{

    -- prepare environment {{{
    before_each(function()
      s  = set.new()
      n  = node.new(nil, "test", s)
      n2 = node.new(nil, "test", s)
      l  = n.addLink(n2, "test_link", "-")
    end)

    after_each(function()
      s, n, n2, l = nil
    end)
    -- }}}

    it("should have an id", function() -- {{{
      assert.is.truthy(l.id())
    end) -- }}}

      it("always connect two nodes", function() -- {{{
        local l2  = n.addLink(nil, "label") -- try to create a dangling link
        assert.is_nil(l2)
      end) -- }}}

      it("must have a direction", function() -- {{{
        local l2  = n.addLink(n2, "wrong_direction", "") -- invalid string
        assert.is_nil(l2)
        l2  = n.addLink(n2, "wrong_direction", 1) -- number is a wrong type
        assert.is_nil(l2)
        -- no argument is implicit for both directions
        l2  = n.addLink(n2, "implicit")
        assert.is.same(1, n.outL("implicit").count())
        assert.is.same(1, n.inL("implicit").count())
      end) -- }}}

      it("between two connected nodes must have a opposite direction for both of them", function() -- {{{
        n.addLink(n2, "->", ">")
        n.addLink(n2, "<-", "<")
        assert.is.same(n2.id(), n.out("->").id())
        assert.is.same(n.id(), n2.in_("->").id())
        assert.is.same(n.id(), n2.out("<-").id())
        assert.is.same(n2.id(), n.in_("<-").id())
      end) -- }}}

      it("get deleted if one of there connected nodes gets deleted", function() -- {{{
        assert.are.same(1, n2.outL("test_link").count())
        n.delete()
        assert.are.same(0, n2.outL("test_link").count())
      end) -- }}}

      it("must have a label", function() -- {{{
        local l2  = n.addLink(n2) -- no label
        assert.is_nil(l2)
        l2  = n.addLink(n2, {"label1","label2"}) -- only one label possible
        assert.is_nil(l2)
        l2  = n.addLink(n2, "mylabel")
        assert.is.same("mylabel", l2.label())
      end) -- }}}

    it("can have properties", function() -- {{{
      assert.is.equal(nil, l.value("key"))
      l.value("key", "val")
      assert.is.equal("val", l.value("key"))
      assert.is.equal("val", l["key"]) -- make sure alias also works
      l["key"] = nil
      assert.is.equal(nil, l.value("key"))
    end) -- }}}

    end) -- }}}

  context("objects", function() -- {{{

    -- prepare environment {{{
    before_each(function()
      s = set.new()
      n = node.new(nil, "test", s)
      n2 = node.new(nil, "test", s)
      l  = n.addLink(n2, "test_link", "-")
    end)

    after_each(function()
      s, n, n2, l = nil
    end)
    -- }}}

    it("can not be acsessed after deletion", function() -- {{{
      l.delete()
      assert.has_error(function() l.id() end, "This is a deleted object. It can not be used any more")
      assert.has_error(function() return l.id end, "This is a deleted object. It can not be used any more") -- not even indexing is possible
      n.delete()
      assert.has_error(function() n.id() end, "This is a deleted object. It can not be used any more")
      assert.has_error(function() return n.id end, "This is a deleted object. It can not be used any more")
    end) -- }}}

    it("can add listeners", function() -- {{{
      local var = {x=1}
      n:emit("test", var)
      assert.are.same(1, var.x)
      n:addListener("test", function(v) v.x = v.x + 1 end)
      n:emit("test", var)
      assert.are.same(2, var.x)
    end) -- }}}

  end) -- }}}

end)

-- vim: fdm=marker
