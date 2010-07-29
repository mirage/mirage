packet ethernet {
    dest_mac: byte[6];
    src_mac: byte[6];
    length: uint16 value(offset(end_of_packet)-offset(length));
    classify (length) {
        |46..1500:"E802_2" ->
            data: byte[length];
        |0x0800:"IPv4" ->
            data: byte[remaining()];
        |0x0806:"ARP" ->
            htype: uint16 const(1);
            ptype: uint16;
            hlen: bit[8] const(6);
            plen: bit[8];
            operation: uint16 variant { |0 => Request |1 -> Reply };
            sha: byte[6];
            spa: byte[4];
            tha: byte[6];
            tpa: byte[4];
        |0x86dd:"IPv6" ->
            data: byte[remaining()];
    };
    end_of_packet: label;
}
