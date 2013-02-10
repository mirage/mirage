# Mirari

Mirari is a tool to create and deploy applications with Mirage.  There are
several diverse backends in Mirage that require rather specialised build steps
(from Javascript to Xen microkernels), and this compexity is wrapped up in
Mirari.

There are three stages to using Mirari:
* a *configuration* phase where OPAM package dependencies are satisfied.
* a *build* phase where the compiler and any support scripts are run.
* a *run* phase where Mirari spawns and tracks the progress of the deployment (e.g. as a UNIX process or a Xen kernel).

## Configuration files

Mirari currently uses configuration files to build Mirage applications.
Support for command line arguments should be available soon.

An example of an `app.conf`:

```
# IP configuration
ip-use-dhcp: true
# ip-address: 10.0.0.2
# ip-netmask: 255.255.0
# ip-gateway: 10.0.0.1

# Filesystem configuration
fs-static: ../files
fs-template: ../tmpl

# HTTP configuration
http-port: 80
http-address: *

# Main function
main-http: Dispatch.main
# main-ip: Ping.min

# Dependencies
depends: cohttp.syntax, uri, re, cow.syntax
packages: mirage-net, cow
```

* The main function MUST have type TODO.
* `depends` is a list of ocamlfind libraries
* `packages` is a list of OPAM packages (which contains the `depends` libraries)

We do understand there is replication between `depends` and `packages` at the
moment, but this will eventually converge as OPAM understands ocamlfind better.

In all cases, you can omit the configuration file if there is a *single* file
ending with `.conf` in your current directory, and Mirari will pick that up.

## Configuring Mirage Applications

The command:

```
$ mirari configure /path/to/app.conf
```

will configure your project. More precisely it will:
* generate `/path/to/main.ml`
* generate `/path/to/main.obuild`
* call the right OPAM commands to satisfy dependencies.
* call `cd /path/to && obuild configure`

To configure the Xen variant, do:
```
$ mirari configure /path/to/app.conf --xen
```

## Building Mirage Applications

The command:

```
$ mirari build /path/to/app.conf
```

will build your project.  To build the Xen version, just add `--xen` as with
the configuration step (you need to keep `--xen` on the command line for all
stages at the moment).

```
$ mirari build /path/to/app.conf --xen
```

## Running Mirage Applications

TODO.

### Compiling to Xen and deploying to the cloud

TODO
