open Functoria
open Functoria.DSL

val run :
  ?keys:Key.Set.elt list ->
  ?init:job impl list ->
  context ->
  'a impl ->
  unit Action.t
