# Testing gravitydb

## Folder structure

The test directory is split in subfolders:

data
:   Testing data that can be imported by tests or for manually exploring the
    APIs.

spec
:   Unit tests. They automatically form some kind of specification and parts of
    the documentation a generated out of them.

integration
:   Test that verify the different modules in gravitydb work smoothly together.

benchmark
:   tests to check the performance of the system when it runs with data that
    differs in size and complexity. Also tests how good the system performs for
    different kinds of queries. You can take these tests as templates when
    comes to estimate the performance for your kind of data and queries in an
    early stage of your application devellopment.

## How to run tests

TODO

### Continuos integration

The tests should be run on every commit and reports should be published
automatically. TODO to accomplish these task I would like to use
[buildbot](http://buildbot.net/) and [vagrant](https://www.vagrantup.com/).

## How to add new tests

There is a separate README file in each subfolder describing how to add that
special kind of test.
