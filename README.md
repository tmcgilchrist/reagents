reagents — Composable lock-free data and synchronization structures
-------------------------------------------------------------------------------
%%VERSION%%

reagents is TODO

reagents is distributed under the ISC license.

Homepage: https://github.com/ocamllabs/reagents

## Installation

reagents can be installed with `opam`. You would also need to install the multicore OCaml compiler:

    $ opam switch create . 5.0.0~rc1 --repo=default,alpha=git+https://github.com/kit-ty-kate/opam-alpha-repository.git -y
    $ ???

## Documentation

The documentation and API reference is automatically generated by from
the source interfaces. It can be consulted [online][doc].

[doc]: https://ocamllabs.github.io/reagents/doc

## Sample programs

If you installed reagents with `opam` sample programs are located in
the directory `opam config var reagents:doc`.

In the distribution sample programs and tests are located in the
[`test`](test) directory of the distribution. They can be built and run
with:

    dune build @runtest