packet ipv4 {
    version: bit[4] const(4);
    ihl: bit[4] min(5) value(offset(options) / 4);
    tos_precedence: bit[3] variant {
        |0 => Routine |1 -> Priority
        |2 -> Immediate |3 -> Flash
        |4 -> Flash_override |5 -> ECP
        |6 -> Internetwork_control |7 -> Network_control
    };
    tos_delay: bit[1] variant {|0 => Normal |1 -> Low};
    tos_throughput: bit[1] variant {|0 => Normal |1 -> Low};
    tos_reliability: bit[1] variant {|0 => Normal |1 -> Low};
    tos_reserved: bit[2] const(0);
    length: uint16 value(offset(data));
    id: uint16;
    reserved: bit[1] const(0);
    dont_fragment: bit[1] default(0);
    can_fragment: bit[1] default(0);
    frag_offset: bit[13] default(0);
    ttl: byte;
    protocol: byte variant {|1->ICMP |2->IGMP |6->TCP |17->UDP};
    checksum: uint16;
    src: uint32;
    dest: uint32;
    options: byte[(ihl * 4) - offset(dest)] align(32);
    header_end: label;
    data: byte[length-(ihl*4)];
}
