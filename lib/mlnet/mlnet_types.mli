module Ethernet :
  sig
    type mac
    val mac_of_bytes : string -> mac
    val mac_of_string : string -> mac option
    val mac_to_string : mac -> string
  end
module IPv4 :
  sig
    type addr
    val addr_of_bytes : string -> addr
    val addr_of_tuple : (int * int * int * int) -> addr
    val addr_of_string : string -> addr option
    val addr_to_string : addr -> string
  end
