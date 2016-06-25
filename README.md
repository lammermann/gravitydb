The Gravity Database
====================

Just as gravity connects the universe it now connects data invisibly.

Gravity is a graph database trying to make the traversal as easy as possible
for complex data. There are several goals it tries to archive:

* provide an elegant way to traverse
* be scalable
* can be easily split, distributed, shared and merged

How to build
------------
Gravity is meant as a library which can be embedded in a project. The easiest
way to include it in a [JUCE](http://www.juce.com/) based project is to use the
[JUCE module](/examples/juce-modules/gravity) in the examples folder.

Nonetheless there is a standalone server in the [examples folder](/examples)
(along with some other projects build on gravity) and here is how to build it:

First make sure you have installed the build dependencies.

* [lua](https://www.lua.org/)
* [lpeg](http://www.inf.puc-rio.br/~roberto/lpeg/) optional for usage of some
  frontends and importers.

Download the latest version of the code from
[github](https://github.com/lammermann/gravitydb/archive/master.zip) or clone
the git repository:

```bash
git clone https://github.com/lammermann/gravitydb.git
```

TODO

Getting started
---------------
TODO

You can get used to the concepts of graph data handling by following the
[tutorial](/doc/tutorial.md) or by examining the exemplary use case
[recepies](/doc/recepies).

For further information please read the [user guide](/doc/userguide.md).

Hacking the code
----------------
You can help improving the project in different ways:

* blog about it or link to it
* add to the documentation
* test and file issues
* submit patches

For some of these point you need to know the project and folder structure
better.

[doc](/doc)
:   It holds information about the concepts of the library and the API. There
    is also a user guide for the software projects shipped with the examples.

[src](/src)
:   The source code of the library.

[examples](/examples)
:   Programs and other software projects build around the gravity library.

[test](/test)
:   Unit tests and so on.

[tools](/tools)
:   Some tools that are useful for building, testing and deploying the
    software.

Pull Requests are always welcome but please check if they are aligned with the
[Styling Rules](/STYLE.md). If you found a bug its bests if you describe how to
reproduce it or even better if you write a test case for it directly.
