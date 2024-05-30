open Functoria
open Random
open Mclock
open Pclock

type resolver

val resolver : resolver typ

val resolver_dns :
  ?ns:string list ->
  ?mclock:mclock impl ->
  ?pclock:pclock impl ->
  ?random:random impl ->
  Stack.stackv4v6 impl ->
  resolver impl

val resolver_unix_system : resolver impl
