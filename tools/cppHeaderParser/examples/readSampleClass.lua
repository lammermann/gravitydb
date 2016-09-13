#!/usr/bin/lua

package.path = "../../?/init.lua;"..package.path
local cppparser = require "cppHeaderParser"

header = cppparser.cpp_header("SampleClass.h")

print("CppHeaderParser view of", header)

sampleClass = header.classes["SampleClass"]
print("Number of public methods", #sampleClass.methods.public)
print("Number of private properties", #sampleClass.properties.private)
meth3 = cppparser.filter(sampleClass["methods"]["public"],
          function(m) return m["name"] == "meth3" end
        )[1] -- get meth3
meth3ParamTypes = cppparser.filter(meth3["parameters"],
                    function(d) return d end,
                    function(t) return t["type"] end
                  ) -- get meth3s parameters
print("Parameter Types for public method meth3", meth3ParamTypes)

print("\nReturn type for meth1:")
print(header.classes.SampleClass.methods.public[2].rtn_type)

print("\nDoxygen for meth2:")
print(header.classes.SampleClass.methods.public[3].doxygen)

print("\nParameters for meth3:")
print(header.classes.SampleClass.methods.public[4].parameters)

print("\nDoxygen for meth4:")
print(header.classes.SampleClass.methods.public[5].doxygen)

print("\nReturn type for meth5:")
print(header.classes.SampleClass.methods.private[1].rtn_type)

print("\nDoxygen type for prop1:")
print(header.classes.SampleClass.properties.private[1].doxygen)

print("\nType for prop5:")
print(header.classes.SampleClass.properties.private[2]["type"])

print("\nNamespace for AlphaClass is:")
print(header.classes.AlphaClass.namespace)

print("\nReturn type for alphaMethod is:")
print(header.classes.AlphaClass.methods.public[2].rtn_type)

print("\nNamespace for OmegaClass is:")
print(header.classes.OmegaClass.namespace)

print("\nType for omegaString is:")
print(header.classes.AlphaClass.properties.public[1]["type"])

print("\nFree functions are:")
for _,func in ipairs(header.functions) do
  print(" ", func["name"])
end

print("\n#includes are:")
for _,incl in ipairs(header.includes) do
  print(" ", incl)
end

print("\n#defines are:")
for _,define in ipairs(header.defines) do
  print(" ", define)
end
