Initialize a git repository:

  $ git init --quiet

And set a user name for future commits:

  $ git config user.email "noreply@mirage.io"
  $ git config user.name "Camelus Dromedarius"

And set its "origin" remote to something:

  $ git remote add origin https://github.com/notifications/invalid-repo.git
  $ git remote show -n
  origin
  $ git branch

Make an empty commit and rename it to main. Otherwise we don't have any branches.

  $ git commit --quiet --allow-empty -m 'Hello Mirage World'
  $ git branch -m main
  $ git branch
  * main

Configure the project for Unix:

  $ mirage configure -t unix
  Successfully configured the unikernel. Now run 'make' (or more fine-grained steps: 'make all', 'make depends', or 'make lock').

Check the source url of the generated opam package

  $ cat mirage/random-unix.opam | grep "^url"
  url { src: "git+https://github.com/notifications/invalid-repo.git#main" }

Now, let's use a remote with ssh transport:

  $ git remote set-url origin git@github.com:notifications/invalid-repo.git

Configure the project again for Unix:

  $ mirage configure -t unix
  Successfully configured the unikernel. Now run 'make' (or more fine-grained steps: 'make all', 'make depends', or 'make lock').

Check the source url of the generated opam package

  $ cat mirage/random-unix.opam | grep "^url"
  url { src: "git+https://github.com/notifications/invalid-repo.git#main" }
