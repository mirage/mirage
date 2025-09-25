open Functoria.DSL

type happy_eyeballs

val happy_eyeballs : happy_eyeballs typ

val generic_happy_eyeballs :
  ?group:string ->
  ?aaaa_timeout:int64 ->
  ?connect_delay:int64 ->
  ?connect_timeout:int64 ->
  ?resolve_timeout:int64 ->
  ?resolve_retries:int ->
  ?timer_interval:int64 ->
  unit ->
  (Stack.stackv4v6 -> happy_eyeballs) impl
