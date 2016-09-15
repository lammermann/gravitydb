-- make the tests standalone
require "busted.runner"()

describe("cpp header parser", function()

  -- prepare environment {{{
  setup(function()
    package.path = "../?/init.lua;"..package.path
    cppparser = require "cppHeaderParser"
    --header = cppparser.cpp_header("spec/data/TestSampleClass.h")
    header = cppparser.cpp_header("examples/SampleClass.h")
  end)

  teardown(function()
    cppparser = nil
    header = nil
  end)
  -- }}}

  describe("SampleClass", function() -- {{{

    setup(function() -- {{{
      SampleClass = header.classes.SampleClass
    end)

    teardown(function()
      SampleClass = nil
    end) -- }}}

    it("name", function()
      assert.is.equal("SampleClass", SampleClass.methods.public[1].name)
    end)

    it("Return type", function()
      assert.is.equal("void", SampleClass.methods.public[1].rtn_type)
    end)

    it("Constructor parameters", function()
      assert.are.same({}, SampleClass.methods.public[1].parameters)
    end)

    pending("Namespaces")

    pending("doxygen")

  end) -- }}}

end)

-- vim: fdm=marker
