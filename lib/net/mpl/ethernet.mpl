packet ethernet {
    dest_mac: byte[6];
    src_mac: byte[6];
    ethertype: uint16;
    classify (ethertype) {
        |0x0800:"IPv4" ->
            data: byte[remaining()];
        |0x0806:"ARP" ->
            htype: uint16 const(1);
            ptype: uint16 variant {
                |0x0800 => IPv4
                |0x86DD -> IPv6
            };
            hlen: bit[8] const(6);
            plen: bit[8] variant { |4 => IPv4 };
            operation: uint16 variant { |1 => Request |2 -> Reply };
            sha: byte[6];
            spa: byte[4];
            tha: byte[6];
            tpa: byte[4];
        |0x86dd:"IPv6" ->
            data: byte[remaining()];
    };
    end_of_packet: label;
}
