# Functoria

A DSL to organize functor applications.

## What is this for ?

Functoria is a DSL to describe a set of modules and functors, their types and how to apply them in order to produce a complete application. It is composed of two part:
- `Functoria`, the dsl.
- `Functoria_tool`, to generate a executable that takes a configuration file and proceed with the invocation.

The main use case is mirage. See the `mirage` repository for details.


## Internals

### Phases

Configuration is separated into phases:

1. Specialized DSL keys
   The specialized DSL's keys (along with the functoria's keys) are resolved.
2. Compilation and dynlink of the config file.
3. Registering.
   When the `register` function is called, the list of job is recorded and
   immediately transformed into a graph.
4. Switching keys and tree evaluation.
   The switching keys are the keys inside the [If].
   Those keys are resolved and the graph is simplified. At this point,
   the actual modules used are fully known.
   Note: for the `describe` command, Only _partial_ evaluation is done, which
   means decision nodes are resolved only if the value was given on the command
   line, disregarding default values.
5. Full Key resolution.
   Once the actual modules are known, we can resolve all the keys and figure out
   libraries and packages.
6. Dependency handling, configuration and code emission.

Phases 1. to 4. are also applied for the `clean` command.
