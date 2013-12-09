# Mirage

Mirage is a unikernel for constructing secure, high-performance network
applications across a variety of cloud computing and mobile platforms. Code can
be developed on a normal OS such as Linux or MacOS X, and then compiled into a
fully-standalone, specialised microkernel that runs under the Xen hypervisor.
Since Xen powers most public cloud computing infrastructure such as Amazon EC2,
this lets your servers run more cheaply, securely and finer control than with a
full software stack.

This repository includes a commmand-line tool to create and deploy applications
with Mirage.  There are several diverse backends in Mirage that require rather
specialised build steps (from Javascript to Xen microkernels), and this
compexity is wrapped up in the tool.

There are three stages to using `mirage`:

* a *configuration* phase where OPAM package dependencies are
  satisfied.

* a *build* phase where the compiler and any support scripts are run.

* a *run* phase where `mirage` spawns and tracks the progress of the
  deployment (e.g. as a UNIX process or a Xen kernel).

## Configuration files

`mirage` currently uses a configuration file to build a Mirage unikernel.
Support for command line arguments should be available soon.

An example of an `app.conf`:

```
# IP configuration

# This will use DHCP for configuring the unikernel's network interfaces

ip-use-dhcp: true

# This will manually set an IPv4 to the unikernel's network
# interfaces. For now, this technique only works when a unikernel has
# only one network interface.

# ip-address: 10.0.0.2
# ip-netmask: 255.255.255.0
# ip-gateway: 10.0.0.1

# Filesystem configuration. Directories can be specified here, and
# they will be compiled into a "filesystem" where each file will be
# presented to the unikernel via a key value interface. For example
# here, there will be two databases, named respectively "static" and
# "template", presenting the content of dir "../files" and "../templ"
# respectively.

fs-static: ../files
fs-template: ../tmpl

# HTTP configuration
http-port: 80
http-address: *

# Main function

# If your main is a Dispatch function for cohttp
main-http: Dispatch.main

# If Ping.min has signature Net.Manager.t -> Net.Manager.interface -> Net.Manager.id -> 'a Lwt.t
# main-ip: Ping.min

# Noip.main must have signature unit -> 'a Lwt.t (do not use networking)
# main-noip: Noip.main

# Dependencies

depends: cohttp.syntax, uri, re, cow.syntax
packages: mirage-net, cow

# Target (Select a target compiler: takes precedence over --xen or
# --unix switch on the command line)

compiler: 4.01.0dev+mirage-xen

# XL parameters. They will be used for creating the xl config file
# when doing a ``mirage` run --xen`.

xl-memory: 32
xl-on_crash: preserve
xl-vif: [ 'mac=00:16:3E:74:34:32' ]

```

* `depends` is a list of ocamlfind libraries
* `packages` is a list of OPAM packages (which contains the `depends` libraries)
* `compiler` is a OPAM compiler selector (see `opam switch`)

We do understand there is replication between `depends` and `packages` at the
moment, but this will eventually converge as OPAM understands ocamlfind better.

## Configuring Mirage Applications

Provided that one and only one file of name `<foo>.conf` (where
`<foo>` can be any string) is present in the current working
directory, the command:

```
$ `mirage` configure
```

will configure your project. It will:

* generate `main.ml`
* generate `main.obuild`
* call the right OPAM commands to satisfy dependencies.
* call `obuild configure`

To build for the unix-direct target (using tap interfaces), do:

```
$ `mirage` configure --unix
```

To build for the xen target, do:

```
$ `mirage` configure --xen
```

## Building Mirage Applications

The command:

```
$ `mirage` build
```

will build your project. Likewise, you can use the `--unix` or `--xen`
switches to build for a particular target.

## Running Mirage Applications

The command:

```
$ `mirage` run (--unix or --xen)
```

will run the unikernel on the selected backend.

* Under the unix-socket backend, it just executes the unikernel.

* Under the unix-direct backend (`--unix`), `mirage` sets up a virtual
  interface (tap) is passes its fd to the unikernel that will use it to
  perform networking operations.

* Under the xen backend (`--xen`), `mirage` creates a xl configuration
  file and uses `xl` to run the unikernel locally. Xen has to be
  installed and running on the machine.

### Compiling to Xen and deploying to the cloud

In order to deploy a Mirage unikernel to Amazon EC2, you need to
install the AWS tools on your machine, build a unikernel with the
`--xen` option and then use the `ec2.sh` script (in directory
`script`) in order to register you kernel with AWS. Then you can start
your kernel with the web interface to AWS or any other mean AWS
provides to start EC2 instances.
