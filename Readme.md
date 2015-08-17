# Functoria

A DSL to organize functor applications.

## What is this for ?

Functoria is a DSL to describe a set of modules and functors, their types and how to apply them in order to produce a complete application. It is composed of two part:
- `Functoria`, the dsl.
- `Functoria_tool`, to generate a executable that takes a configuration file and proceed with the invocation.

The main use case is mirage. See the `mirage` repository for details.
