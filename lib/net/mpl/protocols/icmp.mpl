packet icmp {
	ptype: byte;
	code: byte default(0);
	checksum: uint16 default(0);
	classify (ptype) {
	|0:"EchoReply" ->
		identifier: uint16;
		sequence: uint16;
		data: byte[remaining()];
	|3:"DestinationUnreachable" ->
		reserved: uint32 const(0);
		ip_header: byte[remaining()];
	|4:"SourceQuench" ->
		reserved: uint32 const(0);
		ip_header: byte[remaining()];
	|5:"Redirect" ->
		gateway_ip: uint32;
		ip_header: byte[remaining()];
	|8:"EchoRequest" ->
		identifier: uint16;
		sequence: uint16;
		data: byte[remaining()];
	|9:"RouterAdvertisement" -> ();
	|10:"RouterSolicitation" -> ();
	|11:"TimeExceeded" ->
		reserved: uint32 const(0);
		ip_header: byte[remaining()];
	|13:"TimestampRequest" ->
		identifier: uint16;
		sequence: uint16;
		origin_timestamp: uint32;
		receive_timestamp: uint32;
		transmit_timestamp: uint32;
	};
}
