# Testing gravitydb

## Folder structure

The test directory is split in subfolders:

data
:   Testing data that can be imported by tests or for manually exploring the
    APIs.

spec
:   Unit tests. They automatically form some kind of specification and parts of
    the documentation a generated out of them.

## How to run tests

You can run the Unit tests from this directory by executing the command

```bash
  /path/to/busted
```

As a dependency you need to install the
[busted](http://olivinelabs.com/busted/) lua test framework.

If you want coverage reports too just install `LuaCov` via

```bash
  luarocks install luacov
```

and run `busted -c` for unit test testing.

