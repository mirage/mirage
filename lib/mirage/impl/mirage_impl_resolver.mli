type resolver

open Functoria
open Mirage_impl_random
open Mirage_impl_mclock
open Mirage_impl_pclock
open Mirage_impl_time

val resolver : resolver typ

val resolver_dns :
  ?ns:string list ->
  ?time:time impl ->
  ?mclock:mclock impl ->
  ?pclock:pclock impl ->
  ?random:random impl ->
  Mirage_impl_stack.stackv4v6 impl ->
  resolver impl

val resolver_unix_system : resolver Functoria.impl
