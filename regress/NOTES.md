Random things I need to followup about ocamlbuild:

* Can myocamlbuild.ml be built with -annot to ease development?
* Echo doesnt mkdir_p (see XXX in myocamlbuild.ml)
* Built-in rule for output-obj to remove c&p from our plugin.
* Can we pass a command-line option to use an myocamlbuild.ml from elsewhere? This would save having to symlink the installed one into the pwd for every invocation of mir-*.
* Is there a limit to the parallel scheduling of build conjunctions? Although .exec targets parallelise, .run targets from a test suite do not.
