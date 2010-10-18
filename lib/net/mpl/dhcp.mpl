packet dhcp {
    op: byte variant { |1 -> BootRequest |2-> BootReply };
    htype: byte const(1);
    hlen: byte const(6);
    hops: byte default(0);
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
    cookie: uint32 const(0x63825363);
    options: byte[remaining()];
}
