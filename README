# Mirari

Mirari is a tool to create applications with Mirage.

## Writing configuration files

Mirari currently uses configuration files to set-up Mirage
applications. A support for command line arguments is planned in the
future.

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
```

The main function have type TODO.

## Building applications

Then, you need to ask Mirari to generate the boiler-plate code to run your application.

```
$ mirari /path/to/app.conf
```

This will:
* generate `/path/to/main.ml`
* call `obuild configure` and `obuild build` [currently, this needs
  `/path/to/app.obuild` to exists, but next step is to generate that
  build file]
* create `mir-app`

## Compiling to Xen and deploying to the cloud

TODO