Describe before configure (using defaults)
  $ ./config.exe describe -t spt
  Name       describe
  Keys      
    accept-router-advertisements=true (default),
    allocation-policy=next-fit (default),
    backtrace=true (default),
    custom-major-ratio= (default),
    custom-minor-max-size= (default),
    custom-minor-ratio= (default),
    dhcp=false (default),
    gc-verbosity= (default),
    gc-window-size= (default),
    interface=0 (default),
    interface=service (default),
    interface=tap0 (default),
    ipv4=0.0.0.0/0 (default),
    ipv4=10.0.0.2/24 (default),
    ipv4-gateway= (default),
    ipv4-only=false (default),
    ipv4-only=false (default),
    ipv6= (default),
    ipv6= (default),
    ipv6-gateway= (default),
    ipv6-only=false (default),
    ipv6-only=false (default),
    logs= (default),
    major-heap-increment= (default),
    max-space-overhead= (default),
    minor-heap-size= (default),
    net= (default),
    randomize-hashtables=true (default),
    space-overhead= (default),
    target=spt

Describe before configure (no eval)
  $ ./config.exe describe --no-eval --dot -o-
  Name       describe
  Keys      
    accept-router-advertisements=true (default),
    allocation-policy=next-fit (default),
    backtrace=true (default),
    custom-major-ratio= (default),
    custom-minor-max-size= (default),
    custom-minor-ratio= (default),
    dhcp=false (default),
    gc-verbosity= (default),
    gc-window-size= (default),
    interface=0 (default),
    interface=service (default),
    interface=tap0 (default),
    ipv4=0.0.0.0/0 (default),
    ipv4=10.0.0.2/24 (default),
    ipv4-gateway= (default),
    ipv4-only=false (default),
    ipv4-only=false (default),
    ipv6= (default),
    ipv6= (default),
    ipv6-gateway= (default),
    ipv6-only=false (default),
    ipv6-only=false (default),
    logs= (default),
    major-heap-increment= (default),
    max-space-overhead= (default),
    minor-heap-size= (default),
    net= (default),
    randomize-hashtables=true (default),
    space-overhead= (default),
    target=macosx (default)
  Output     -digraph G {
                ordering=out;
                1 [label="tcpv4v6_socket__1\nTcpv4v6_socket\nipv4-only, ipv6-only, ipv4, ipv6", shape="box"];
                2 [label="udpv4v6_socket__2\nUdpv4v6_socket\nipv4-only, ipv6-only, ipv4, ipv6", shape="box"];
                3 [label="tcpip_stack_socket_v4v6__3\nTcpip_stack_socket.V4V6\n", shape="box"];
                4 [label="mclock__4\nMclock\n", shape="box"];
                5 [label="unix_os_time__5\nUnix_os.Time\n", shape="box"];
                6 [label="xen_os_time__6\nXen_os.Time\n", shape="box"];
                7 [label="solo5_os_time__7\nSolo5_os.Time\n", shape="box"];
                8 [label="If\ntarget"];
                9 [label="mirage_crypto_rng_mirage_make__9\nMirage_crypto_rng_mirage.Make\n", shape="box"];
                10 [label="netif__10\nNetif\ninterface", shape="box"];
                11 [label="netif__11\nNetif\ninterface", shape="box"];
                12 [label="netif__12\nNetif\ninterface", shape="box"];
                13 [label="netif__13\nNetif\ninterface", shape="box"];
                14 [label="netif__14\nNetif\ninterface", shape="box"];
                15 [label="netif__15\nNetif\ninterface", shape="box"];
                16 [label="netif__16\nNetif\ninterface", shape="box"];
                17 [label="netif__17\nNetif\ninterface", shape="box"];
                18 [label="If\ntarget"];
                19 [label="ethernet_make__19\nEthernet.Make\n", shape="box"];
                20 [label="ipv6_make__20\nIpv6.Make\nipv6, ipv6-gateway, accept-router-advertisements, ipv4-only", shape="box"];
                21 [label="arp_make__21\nArp.Make\n", shape="box"];
                22 [label="qubes_db__22\nQubes.DB\n", shape="box"];
                23 [label="qubesdb_ipv4_make__23\nQubesdb_ipv4.Make\n", shape="box"];
                24 [label="dhcp_ipv4_make__24\nDhcp_ipv4.Make\n", shape="box"];
                25 [label="static_ipv4_make__25\nStatic_ipv4.Make\nipv6-only, ipv4-gateway, ipv4", shape="box"];
                26 [label="If\ndhcp, net,\ntarget"];
                27 [label="tcpip_stack_direct_ipv4v6__27\nTcpip_stack_direct.IPV4V6\nipv4-only, ipv6-only", shape="box"];
                28 [label="tcp_flow_make__28\nTcp.Flow.Make\n", shape="box"];
                29 [label="udp_make__29\nUdp.Make\n", shape="box"];
                30 [label="icmpv4_make__30\nIcmpv4.Make\n", shape="box"];
                31 [label="tcpip_stack_direct_makev4v6__31\nTcpip_stack_direct.MakeV4V6\n", shape="box"];
                32 [label="If\ndhcp, net,\ntarget"];
                33 [label="app__33\nApp\n", shape="box"];
                34 [label="pclock__34\nPclock\n", shape="box"];
                35 [label="mirage_logs_make__35\nMirage_logs.Make\nlogs", shape="box"];
                36 [label="gc__36\nGc\nallocation-policy, minor-heap-size, major-heap-increment, space-overhead, max-space-overhead, gc-verbosity, gc-window-size, custom-major-ratio, custom-minor-ratio, custom-minor-max-size", shape="box"];
                37 [label="hashtbl__37\nHashtbl\nrandomize-hashtables", shape="box"];
                38 [label="printexc__38\nPrintexc\nbacktrace", shape="box"];
                39 [label="bootvar__39\nBootvar\n", shape="box"];
                40 [label="bootvar__40\nBootvar\n", shape="box"];
                41 [label="bootvar__41\nBootvar\n", shape="box"];
                42 [label="If\ntarget"];
                43 [label="key_gen__43\nKey_gen\n", shape="box"];
                44 [label="mirage_runtime__44\nMirage_runtime\ntarget", shape="box"];
                
                3 -> 2 [style="dashed"];
                3 -> 1 [style="dashed"];
                8 -> 5 [style="dotted", headport="n"];
                8 -> 5 [style="dotted", headport="n"];
                8 -> 6 [style="dotted", headport="n"];
                8 -> 6 [style="dotted", headport="n"];
                8 -> 7 [style="dotted", headport="n"];
                8 -> 7 [style="dotted", headport="n"];
                8 -> 7 [style="dotted", headport="n"];
                8 -> 7 [style="dotted", headport="n"];
                8 -> 7 [style="dotted", headport="n"];
                8 -> 5 [style="bold", style="dotted", headport="n"];
                9 -> 8 [];
                9 -> 4 [];
                18 -> 10 [style="dotted", headport="n"];
                18 -> 11 [style="dotted", headport="n"];
                18 -> 12 [style="dotted", headport="n"];
                18 -> 13 [style="dotted", headport="n"];
                18 -> 14 [style="dotted", headport="n"];
                18 -> 15 [style="dotted", headport="n"];
                18 -> 16 [style="dotted", headport="n"];
                18 -> 17 [style="bold", style="dotted", headport="n"];
                19 -> 18 [];
                20 -> 18 [];
                20 -> 19 [];
                20 -> 9 [];
                20 -> 8 [];
                20 -> 4 [];
                21 -> 19 [];
                21 -> 8 [];
                23 -> 22 [];
                23 -> 9 [];
                23 -> 4 [];
                23 -> 19 [];
                23 -> 21 [];
                24 -> 9 [];
                24 -> 4 [];
                24 -> 8 [];
                24 -> 18 [];
                24 -> 19 [];
                24 -> 21 [];
                25 -> 9 [];
                25 -> 4 [];
                25 -> 19 [];
                25 -> 21 [];
                26 -> 23 [style="dotted", headport="n"];
                26 -> 24 [style="dotted", headport="n"];
                26 -> 25 [style="bold", style="dotted", headport="n"];
                27 -> 26 [];
                27 -> 20 [];
                28 -> 27 [];
                28 -> 8 [];
                28 -> 4 [];
                28 -> 9 [];
                29 -> 27 [];
                29 -> 9 [];
                30 -> 26 [];
                31 -> 8 [];
                31 -> 9 [];
                31 -> 18 [];
                31 -> 19 [];
                31 -> 21 [];
                31 -> 27 [];
                31 -> 30 [];
                31 -> 29 [];
                31 -> 28 [];
                32 -> 3 [style="dotted", headport="n"];
                32 -> 31 [style="bold", style="dotted", headport="n"];
                33 -> 32 [];
                35 -> 34 [];
                42 -> 39 [style="dotted", headport="n"];
                42 -> 39 [style="dotted", headport="n"];
                42 -> 40 [style="dotted", headport="n"];
                42 -> 40 [style="dotted", headport="n"];
                42 -> 40 [style="dotted", headport="n"];
                42 -> 40 [style="dotted", headport="n"];
                42 -> 40 [style="dotted", headport="n"];
                42 -> 41 [style="bold", style="dotted", headport="n"];
                43 -> 42 [style="dashed"];
                44 -> 43 [style="dashed"];
                44 -> 38 [style="dashed"];
                44 -> 37 [style="dashed"];
                44 -> 36 [style="dashed"];
                44 -> 35 [style="dashed"];
                44 -> 33 [style="dashed"];
                }

Describe after configure
  $ echo '-t\nxen' > context
  $ ./config.exe describe --context-file=context
  Name       describe
  Keys      
    accept-router-advertisements=true (default),
    allocation-policy=next-fit (default),
    backtrace=true (default),
    custom-major-ratio= (default),
    custom-minor-max-size= (default),
    custom-minor-ratio= (default),
    dhcp=false (default),
    gc-verbosity= (default),
    gc-window-size= (default),
    interface=0 (default),
    ipv4=10.0.0.2/24 (default),
    ipv4-gateway= (default),
    ipv4-only=false (default),
    ipv6= (default),
    ipv6-gateway= (default),
    ipv6-only=false (default),
    logs= (default),
    major-heap-increment= (default),
    max-space-overhead= (default),
    minor-heap-size= (default),
    net= (default),
    randomize-hashtables=true (default),
    space-overhead= (default),
    target=xen
