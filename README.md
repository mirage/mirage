Mirage is a unikernel for constructing secure, high-performance network
applications across a variety of cloud computing and mobile platforms. Code can
be developed on a normal OS such as Linux or MacOS X, and then compiled into a
fully-standalone, specialised microkernel that runs under the Xen hypervisor.
Since Xen powers most public cloud computing infrastructure such as Amazon EC2,
this lets your servers run more cheaply, securely and finer control than with a
full software stack.

Mirage is based around the OCaml language, with syntax extensions and libraries
which provide networking, storage and concurrency support that are easy to use
during development, and map directly into operating system constructs when
being compiled for production deployment. The framework is fully event-driven,
with no support for preemptive threading.

This contains the OS bindings for the Mirage operating system, primarily
through an `OS` OCaml module. The following backends are available:

* Unix: maps POSIX resources and executes Mirage apps as normal binaries.

* Xen: a microkernel backend that can run against Xen3+

For documentation, visit <http://openmirage.org>.

The older "unified" tree is also present for historical reasons into the
`old-master` branch.
