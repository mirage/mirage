packet dns_rr {
    name: dns_label_comp;
    atype: uint16;
    aclass: uint16 variant {|1 => IN |2 -> CSNET
        |3 -> CHAOS |4 -> HS };
    ttl: uint32;
    rdlength: uint16 value(offset(end_of_answers) - offset(start_of_answers));
    start_of_answers: label;
    classify (atype) {
    |1:"A" ->
       ip: uint32;
    |2:"NS" ->
       hostname: dns_label_comp;
    |3:"MD" ->
       madname: dns_label;
    |4:"MF" ->
       madname: dns_label;
    |5:"CNAME" ->
       cname: dns_label;
    |6:"SOA" ->
       primary_ns: dns_label_comp;
       admin_mb: dns_label_comp;
       serial: uint32;
       refresh: uint32;
       retry: uint32;
       expiration: uint32;
       minttl: uint32;
    |7:"MB" ->
       madname: dns_label;
    |8:"MG" ->
       mgmname: dns_label;
    |9:"MR" ->
       newname: dns_label;
    |10:"NULL" ->
       data: byte[rdlength];
    |11:"WKS" ->
       address: uint32;
       protocol: byte;
       bitmap: byte[rdlength - 5];
    |12:"PTR" ->
       ptrdname: dns_label_comp;
    |13:"HINFO" ->
       cpu: string8;
       os: string8;
    |14:"MINFO" ->
       rmailbox: dns_label_comp;
       emailbox: dns_label_comp;
    |15:"MX" ->
       preference: uint16;
       hostname: dns_label_comp;
    |16:"TXT" ->
       data: string8;
       misc: byte[rdlength - offset(data) + offset(start_of_answers)];
    |17:"RP" -> /* rfc 1183 */
       mbox_dname: dns_label;
       txt_dname: dns_label;
    |18:"AFSDB" -> /* rfc 1183 */
       subtype: uint16;
       hostname: dns_label;
    |19:"X25" -> /* rfc 1183 */
       psdn_address: string8;
    |20:"ISDN" -> /* rfc 1183 */
       data: string8;
    |21:"RT" -> /* rfc 1183 */
       preference: uint16;
       intermediate_host: dns_label;
    |25:"KEY" -> /* rfc 2535 */
       /* complex, needs classification */
       data: byte[rdlength];
    |27:"GPOS" -> /* rfc 1712 */       
      longitude: string8;
      latitude: string8;
      altitude: string8;
    |28:"AAAA" -> /* rfc 3596 */
       ip: byte[16];
    |29:"LOC" -> /* rfc 1876 */
       version: byte const(0);
       size: byte;
       horiz_pre: byte;
       vert_pre: byte;
       latitude: uint32; 
       longitude: uint32;
       altitude: uint32;
    |33:"SRV" -> /* rfc 2782 */
       priority: uint16;
       weight: uint16;
       port: uint16;
       target: dns_label;
    |36:"A6" -> /* rfc 2874 */
       /* this format is insane, needs a custom type */
       data: byte[rdlength];
    |39:"DNAME" -> /* rfc 2672 */
       target: dns_label;
    |43:"DS" -> /* rfc 3658 */
       key_tag: uint16;
       algorithm: byte;
       digest_type: byte;
       classify (digest_type) {
       |1:"SHA1" ->
          digest: byte[20];
       };
    |103:"UNSPEC" -> /* Deprecated BIND4 type, for testing */
       data: byte[rdlength];
    |999:"UNKNOWN" ->  /* until default matching works */
        data: byte[rdlength];
    };
    end_of_answers: label;
}
