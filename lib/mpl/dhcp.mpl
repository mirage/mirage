packet dhcp {
    op: byte variant { |1 -> BootRequest |2-> BootReply };
    htype: byte variant { |1 -> Ethernet };
    hlen: byte value(sizeof(chaddr));
    hops: byte;
    xid: uint32;
    secs: uint16;
	broadcast: bit[1];
	reserved: bit[15] const(0);
    ciaddr: uint32;
    yiaddr: uint32;
    siaddr: uint32;
    giaddr: uint32;
    chaddr: byte[16];
    sname: byte[64];
    file: byte[128];
    options: byte[remaining()];
}

packet dhcp_option {
	code: byte;
	classify (code) {
	|0:"Pad" -> ();
	|1:"SubnetMask" ->
		olen: byte const(4);
		mask: uint32;
	|2:"TimeOffset" ->
		olen: byte const(4);
		offset: uint32; /* XXX two's complement, not uint32 */
	|3:"Router" ->
		olen: byte value(sizeof(routers));
		routers: byte[olen];  /* XXX list of 32-bit IP addresses */
	|4:"TimeServer" ->
		olen: byte value(sizeof(timeserver));
		timeserver: byte[olen];  /* XXX list of 32-bit IP addresses */
	|5:"NameServer" ->
		olen: byte value(sizeof(nameserver));
		nameserver: byte[olen];  /* XXX list of 32-bit IP addresses */
	|6:"DNSServer" ->
		olen: byte value(sizeof(nameserver));
		nameserver: byte[olen];  /* XXX list of 32-bit IP addresses */
	|12:"HostName" ->
		olen: byte value(sizeof(hostname));
		hostname: byte[olen];
	|15:"DomainName" ->
		olen: byte value(sizeof(name)) min(1);
		name: byte[olen];
	|50:"RequestedIP" ->
		olen: byte const(4);
		ip: uint32;
	|51:"LeaseTime" ->
		olen: byte const(4);
		time: uint32;
	|53:"MessageType" ->
		olen: byte const(1);
		mtype: byte variant {
			|1 -> Discover |2 -> Offer |3 -> Request |4 -> Decline
			|5 -> Ack |6 -> Nak |7 -> Release |8 -> Inform };
	|54:"ServerIdentifier" ->
		olen: byte const(4);
		id: uint32;
	|55:"ParameterRequest" ->
		olen: byte value(sizeof(params));
		params: byte[olen];
	|61:"ClientID" ->
		olen: byte value(sizeof(id)+1);
		htype: byte;
		id: byte[olen-1];
	|57:"MaxSize" ->
		olen: byte const(2);
		size: uint16 min(576);
	|255:"End" -> ();
	};
}
