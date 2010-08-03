packet udp {
    source_port: uint16;
    dest_port: uint16;
    length: uint16 min(8) value(offset(total_length));
    checksum: uint16 default(0);
    data: byte[length - offset(checksum)];
    total_length: label;
}