(* empty *)

open Functoria

type mimic

val mimic : mimic typ

val mimic_happy_eyeballs :
  (Stack.stackv4v6 -> Dns.dns_client -> Happy_eyeballs.happy_eyeballs -> mimic)
  impl
