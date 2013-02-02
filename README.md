# Mirari

Mirari is a tool to create applications with Mirage.

## Configuration files

Mirari currently uses configuration files to set-up Mirage
applications. A support for command line arguments should be available
soon.

An example of <app.conf>:

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

## Configuring Mirage Applications

The command:

```
$ mirari configure /path/to/app.conf
```

will configure your project. More precisely it will:
* generate `/path/to/main.ml`
* generate `/path/to/main.obuild`
* call the right OPAM commands
* call `cd /path/to && obuild configure`

## Building Mirage Applications

The command:

```
$ mirari build /path/to/app.conf
```

will build your project. Alternatively you can do: `cd /path/to/ && obuild build`.

## Compiling to Xen and deploying to the cloud

TODO