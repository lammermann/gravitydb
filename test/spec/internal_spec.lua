-- make the tests standalone
require "busted.runner"()

describe("gravity database core", function()

  -- prepare environment {{{
  setup(function()
    package.path = "../src/lua_api/?.lua;"..package.path
    obj  = require "internal.object"
    set  = require "internal.set"
    link = require "link"
    node = require "node"
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
        assert.is.same("-", l2.direction())
      end) -- }}}

      it("get deleted if one of there connected nodes gets deleted", function() -- {{{
        pending("TODO")
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

end)

-- vim: fdm=marker