/* http://tools.ietf.org/id/draft-ietf-hybi-thewebsocketprotocol-01.html */

packet websocket {
    more: bit[1] variant {
      | 0 -> Final
      | 1 -> Fragment
    };
    rsv1: bit[1] const(0);
    rsv2: bit[1] const(0);
    rsv3: bit[1] const(0);
    opcode: bit[4] variant {
      | 0 -> Continuation
      | 1 -> Close
      | 2 -> Ping
      | 3 -> Pong
      | 4 -> Text
      | 5 -> Binary
    };
/*  rsv4: bit[1] const(0); length-header: bit[7]; */
	length_header: byte;
    classify(length_header) {
      | 0..126:"Length7" ->
	      length: label value(length_header);
          data: byte[length];
      | 126:"Length32" when (size(data) >= 126 && size(data) <= 65535) ->
          length: uint16 value(sizeof(data));
          data: byte[length];
      | 127:"Length63" when size(data) > 65535->
          length: uint64 value(sizeof(data));
          data: byte[length];

     };
}