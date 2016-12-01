---
-- Premake 5.x build configuration script
-- Use this script to configure the project with Premake5.
---

--
-- Remember my location; I will need it to locate sub-scripts later.
--

local corePath = _SCRIPT_DIR

-- supporting actions {{{

newaction {
  trigger = "embed",
  description = "Embed scripts in scripts.c; required before release builds",
  execute = function ()
    include (path.join(corePath, "tools/embed.lua"))
  end
}

newaction {
  trigger = "bindings",
  description = "Create lua bindings for cpp header files",
  execute = function ()
    include (path.join(corePath, "tools/create_lua_bindings.lua"))
  end
}

newaction {
  trigger = "package",
  description = "Creates source and binary packages",
  execute = function ()
    include (path.join(corePath, "tools/package.lua"))
  end
}

-- }}}

-- options {{{

newoption {
  trigger = "to",
  value   = "path",
  description = "Set the output location for the generated files"
}

newoption {
  trigger = "lua-dir",
  value   = "path",
  description = "The location of the lua files to build the modules",
}

-- }}}

--
-- Define the project. Put the release configuration first so it will be the
-- default when folks build using the makefile. That way they don't have to
-- worry about the -scripts argument and all that.
--

solution "GravityDB"
  configurations { "release", "debug" }
  location       ( _OPTIONS["to"] )
  flags          { "No64BitChecks", "ExtraWarnings", "StaticRuntime" }
  targetdir      "bin/%{cfg.buildcfg}"

  configuration "debug"
    defines     "_DEBUG"
    symbols     "On"

  configuration "release"
    defines     "NDEBUG"
    flags       { "OptimizeSize" }

  --project "GravityServer"
  --  targetname  "gravity"
  --  language    "C++"
  --  kind        "ConsoleApp"
  --  includedirs { "src/dependencies/lua-5.1.4/src" }
  --  links       { "liblua" }

  --  files
  --  {
  --    "src/**.h", "src/**.cpp",
  --  }

  --  excludes
  --  {
  --    "src/dependencies/**.c",
  --  }

  project "sophia_backend"
    targetname  "sophia"
    targetprefix ""
    language    "C"
    kind        "SharedLib"
    targetdir   "bin/%{cfg.buildcfg}/libs/gravity/backend"
    includedirs {
      "src/backends",
      "src/dependencies/sophia"
    }
    links       { "lua", "sophia" }

    files { "src/backends/sophia/backend.c" }

    configuration "linux"
      includedirs { _OPTIONS["lua-dir"] }
      libdirs { _OPTIONS["lua-dir"] }

  -- tools {{{

  --project "builddocs"
  --  targetname  "builddocs"
  --  language    "C"
  --  kind        "ConsoleApp"
  --  includedirs { "src/dependencies/uuid" }
  --  links       { "liblua" }

  --  files { "src/dependencies/uuid/luuid.c" }

  --  configuration "windows"
  --    files { "src/dependencies/uuid/wuuid.c" }

  --  configuration "linux"
  --    links { "uuid" }

  -- }}}

  -- dependencies {{{

  project "luauuid"
    targetname  "uuid"
    targetprefix ""
    language    "C"
    kind        "SharedLib"
    targetdir   "bin/%{cfg.buildcfg}/libs"
    includedirs { "src/dependencies/uuid" }
    links       { "lua" }

    files { "src/dependencies/uuid/luuid.c" }

    configuration "windows"
      files { "src/dependencies/uuid/wuuid.c" }

    configuration "linux"
      includedirs { _OPTIONS["lua-dir"] }
      libdirs { _OPTIONS["lua-dir"] }
      links { "uuid" }

  project "lpeg"
    targetname  "lpeg"
    targetprefix ""
    language    "C"
    kind        "SharedLib"
    targetdir   "bin/%{cfg.buildcfg}/libs"
    includedirs { "src/dependencies/lpeg/" }
    links       { "lua" }
    undefines   { "NDEBUG" }

    files { "src/dependencies/lpeg/*.c" }

    configuration "linux"
      includedirs { _OPTIONS["lua-dir"] }
      libdirs { _OPTIONS["lua-dir"] }

  project "sophia"
    targetname  "sophia"
    language    "C"
    kind        "StaticLib"
    targetdir   "bin/%{cfg.buildcfg}/libs"
    includedirs { "src/dependencies/sophia" }
    flags       { "C99" }

    files { "src/dependencies/sophia/sophia.c" }

  --[[
  project "libtomcrypt"
    targetname  "tomcrypt"
    language    "C"
    kind        "StaticLib"
    includedirs
    {
      "src/dependencies/libtomcrypt/src/headers/",
      "src/dependencies/libtommath/",
    }

    files { "src/dependencies/libtomcrypt/src/**.c" }
    excludes { "src/dependencies/libtomcrypt/src/pk/ecc/ltc_ecc_mulmod_timing.c" }
    links { "libtommath" }

  project "libtommath"
    targetname  "tommath"
    language    "C"
    kind        "StaticLib"
    includedirs { "src/dependencies/libtommath/" }

    files { "src/dependencies/libtommath/*.c" }
  --]]

  project "liblua"
    targetname  "lua"
    language    "C"
    kind        "StaticLib"
    includedirs { "src/dependencies/lua-5.3.3/src" }
    files       { "src/dependencies/lua-5.3.3/src/*.c" }

    excludes
    {
      "src/dependencies/lua-5.3.3/src/lua.c",
      "src/dependencies/lua-5.3.3/src/luac.c",
    }

    configuration "vs*"
      defines     { "_CRT_SECURE_NO_WARNINGS" }

    configuration "vs2005"
      defines {"_CRT_SECURE_NO_DEPRECATE" }

    configuration "windows"
      links { "ole32" }

    configuration "linux or bsd or hurd"
      defines     { "LUA_USE_POSIX", "LUA_USE_DLOPEN" }
      links       { "m" }
      linkoptions { "-rdynamic" }

    configuration "linux or hurd"
      links       { "dl" }

    configuration "macosx"
      defines     { "LUA_USE_MACOSX" }
      links       { "CoreServices.framework" }

    configuration { "macosx", "gmake" }
      toolset "clang"
      buildoptions { "-mmacosx-version-min=10.4" }
      linkoptions  { "-mmacosx-version-min=10.4" }

    configuration { "solaris" }
      linkoptions { "-Wl,--export-dynamic" }

    configuration "aix"
      defines     { "LUA_USE_POSIX", "LUA_USE_DLOPEN" }
      links       { "m" }
  -- }}}

--
-- A more thorough cleanup.
--

if _ACTION == "clean" then
  os.rmdir("bin")
  os.rmdir("build")
end

-- vim: fdm=marker
