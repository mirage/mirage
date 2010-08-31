packet dns {
    id: uint16;
    qr: bit[1] variant { |0 -> Query |1 -> Answer };
    opcode: bit[4] variant { |0 -> Query |1 -> IQuery |2 -> Status 
        |3 -> Reserved  |4 -> Notify |5 -> Update };
    authoritative: bit[1];
    truncation: bit[1];
    rd: bit[1];
    ra: bit[1];
    zv: bit[3] const(0);
    rcode: bit[4] variant {|0 => NoError |1 -> FormErr
        |2 -> ServFail |3 -> NXDomain |4 -> NotImp |5 -> Refused
        |6 -> YXDomain |7 -> YXRRSet  |8 -> NXRRSet |9 -> NotAuth
        |10 -> NotZone |16 -> BadVers |17 -> BadKey |18 -> BadTime
        |19 -> BadMode |20 -> BadName |21 -> BadAlg};
    qdcount: uint16 value(array_length(questions));
    ancount: uint16 value(array_length(answers));
    nscount: uint16 value(array_length(authority));
    arcount: uint16 value(array_length(additional));
    questions: array (qdcount) {
        qname: dns_label;
        qtype: uint16 variant {|1 -> A |2 -> NS |3 -> MD |4 -> MF
            |5-> CNAME |6-> SOA  |7 -> MB |8 -> MG |9 -> MR
            |10 -> NULL |11 -> WKS |12 -> PTR |13 -> HINFO
            |14 -> MINFO |15 -> MX |16 -> TXT |17 -> RP
            |18 -> AFSDB |19 -> X25 |20 -> ISDN |21 -> RT
            |22 -> NSAP |23 -> NSAP_PTR |24 -> SIG |25 -> KEY
            |26 -> PX |27 -> GPOS |28 -> AAAA |29 -> LOC
            |30 -> NXT |31 -> EID |32 -> NIMLOC |33 -> SRV 
            |34 -> ATMA |35 -> NAPTR |36 -> KM |37 -> CERT 
            |38 -> A6 |39 -> DNAME |40 -> SINK |41 -> OPT 
            |42 -> APL |43 -> DS |44 -> SSHFP |45 -> IPSECKEY 
            |46 -> RRSIG |47 -> NSEC |48 -> DNSKEY 
            |99 -> SPF |100 -> UINFO |101 -> UID |102 -> GID 
            |103 -> UNSPEC
            |252 -> AXFR |253 -> MAILB |254 -> MAILA |255 -> ANY 
            |32768 -> TA |32769 -> DLV};
        qclass: uint16 variant {|1 => IN |2 -> CSNET
            |3 -> CHAOS |4 -> HS |254 -> NONE |255 -> ANY};
    };
    answers: array (ancount) {
         rr: packet dns_rr();
    };
    authority: array (nscount) {
         rr: packet dns_rr();
    };
    additional: array (arcount) {
         rr: packet dns_rr();
    };
}
