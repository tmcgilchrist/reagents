(lang dune 3.0)
(name reagents)

(generate_opam_files true)
(formatting disabled)

(license BSD-3-clause)
(maintainers "KC Sivaramakrishnan <sk826@cl.cam.ac.uk>")
(authors "KC Sivaramakrishnan <sk826@cl.cam.ac.uk>" )
(source (github ocaml-multicore/reagents))
(documentation "https://ocaml-multicore.github.io/reagents/")

(package
 (name reagents)
 (depends
  (ocaml (>= 5.0))
  (lockfree (>= 0.3.0))
  domainslib
  (kcas (>= 0.1.5))
  alcotest)
 (synopsis "Composable lock-free data and synchronization structures")
 (description "Reagents - Composable lock-free data and synchronization structures"))

