packet tcp {
  source_port: uint16;
  dest_port: uint16;
  sequence: uint32;
  ack_number: uint32;
  offset: bit[4] value(offset(header_end) / 4);
  reserved: bit[4] const(0);
  cwr: bit[1] default(0);
  ece: bit[1] default(0);
  urg: bit[1] default(0);
  ack: bit[1] default(0);
  psh: bit[1] default(0);
  rst: bit[1] default(0);
  syn: bit[1] default(0);
  fin: bit[1] default(0);
  window: uint16;
  checksum: uint16;
  urgent: uint16 default(0);
  header_end: label;
  options: byte[(offset * 4) - offset(header_end)] align(32);
  data: byte[remaining()];
}
