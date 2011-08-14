type operation =
    Debug
  | Directory
  | Read
  | Getperms
  | Watch
  | Unwatch
  | Transaction_start
  | Transaction_end
  | Introduce
  | Release
  | Getdomainpath
  | Write
  | Mkdir
  | Rm
  | Setperms
  | Watchevent
  | Error
  | Isintroduced
  | Resume
  | Set_target
  | Restrict
val operation_c_mapping : operation array
val size : int
external get_internal_offset : unit -> int = "stub_get_internal_offset"
val offset_pq : int
val operation_c_mapping_pq : operation array
val size_pq : int
val array_search : 'a -> 'a array -> int
val of_cval : int -> operation
val to_cval : operation -> int
val to_string : operation -> string
