  $ export MIRAGE_DEFAULT_TARGET=unix

Describe before configure (using defaults)
  $ ./config.exe describe -t spt
  Name       describe
  Keys      
    dhcp=true (default),
    net= (default),
    service-utcp=false (default),
    target=spt

Describe before configure (no eval)
  $ ./config.exe describe --no-eval --dot -o-
  Name       describe
  Keys      
    dhcp=true (default),
    net= (default),
    service-utcp=false (default),
    target=unix (default)
  Output     -digraph G {
                ordering=out;
                1 [label="tcpv4v6_socket__1\nTcpv4v6_socket\n", shape="box"];
                2 [label="udpv4v6_socket__2\nUdpv4v6_socket\n", shape="box"];
                3 [label="tcpip_stack_socket_v4v6__3\nTcpip_stack_socket.V4V6\n", shape="box"];
                4 [label="netif__4\nNetif\n", shape="box"];
                5 [label="netif__5\nNetif\n", shape="box"];
                6 [label="If\ntarget"];
                7 [label="netif__7\nNetif\n", shape="box"];
                8 [label="netif__8\nNetif\n", shape="box"];
                9 [label="If\ntarget"];
                10 [label="netif__10\nNetif\n", shape="box"];
                11 [label="netif__11\nNetif\n", shape="box"];
                12 [label="If\ntarget"];
                13 [label="netif__13\nNetif\n", shape="box"];
                14 [label="netif__14\nNetif\n", shape="box"];
                15 [label="If\ntarget"];
                16 [label="netif__16\nNetif\n", shape="box"];
                17 [label="netif__17\nNetif\n", shape="box"];
                18 [label="If\ntarget"];
                19 [label="netif__19\nNetif\n", shape="box"];
                20 [label="netif__20\nNetif\n", shape="box"];
                21 [label="If\ntarget"];
                22 [label="netif__22\nNetif\n", shape="box"];
                23 [label="netif__23\nNetif\n", shape="box"];
                24 [label="If\ntarget"];
                25 [label="netif__25\nNetif\n", shape="box"];
                26 [label="netif__26\nNetif\n", shape="box"];
                27 [label="If\ntarget"];
                28 [label="If\ntarget"];
                29 [label="ethernet_make__29\nEthernet.Make\n", shape="box"];
                30 [label="arp_make__30\nArp.Make\n", shape="box"];
                31 [label="dhcp_ipv4_make__31\nDhcp_ipv4.Make\n", shape="box"];
                32 [label="dhcp_ipv4_proj_net__32\nDhcp_ipv4.Proj_net\n", shape="box"];
                33 [label="If\ndhcp, net,\ntarget"];
                34 [label="ipv6_make__34\nIpv6.Make\n", shape="box"];
                35 [label="qubes_db__35\nQubes.DB\n", shape="box"];
                36 [label="qubesdb_ipv4_make__36\nQubesdb_ipv4.Make\n", shape="box"];
                37 [label="dhcp_ipv4_proj_ipv4__37\nDhcp_ipv4.Proj_ipv4\n", shape="box"];
                38 [label="static_ipv4_make__38\nStatic_ipv4.Make\n", shape="box"];
                39 [label="If\ndhcp, net,\ntarget"];
                40 [label="tcpip_stack_direct_ipv4v6__40\nTcpip_stack_direct.IPV4V6\n", shape="box"];
                41 [label="utcp_mirage_make__41\nUtcp_mirage.Make\n", shape="box"];
                42 [label="tcp_flow_make__42\nTcp.Flow.Make\n", shape="box"];
                43 [label="If\nservice-utcp"];
                44 [label="udp_make__44\nUdp.Make\n", shape="box"];
                45 [label="icmpv4_make__45\nIcmpv4.Make\n", shape="box"];
                46 [label="tcpip_stack_direct_makev4v6__46\nTcpip_stack_direct.MakeV4V6\n", shape="box"];
                47 [label="If\ndhcp, net,\ntarget"];
                48 [label="app__48\nApp\n", shape="box"];
                49 [label="mirage_runtime__49\nMirage_runtime\n", shape="box"];
                50 [label="mirage_crypto_rng_mirage__50\nMirage_crypto_rng_mirage\n", shape="box"];
                51 [label="mirage_mtime__51\nMirage_mtime\n", shape="box"];
                52 [label="mirage_mtime__52\nMirage_mtime\n", shape="box"];
                53 [label="mirage_mtime__53\nMirage_mtime\n", shape="box"];
                54 [label="If\ntarget"];
                55 [label="If\ntarget"];
                56 [label="mirage_ptime__56\nMirage_ptime\n", shape="box"];
                57 [label="mirage_ptime__57\nMirage_ptime\n", shape="box"];
                58 [label="mirage_ptime__58\nMirage_ptime\n", shape="box"];
                59 [label="If\ntarget"];
                60 [label="If\ntarget"];
                61 [label="mirage_sleep__61\nMirage_sleep\n", shape="box"];
                62 [label="mirage_sleep__62\nMirage_sleep\n", shape="box"];
                63 [label="mirage_sleep__63\nMirage_sleep\n", shape="box"];
                64 [label="If\ntarget"];
                65 [label="If\ntarget"];
                66 [label="mirage_logs__66\nMirage_logs\n", shape="box"];
                67 [label="mirage_runtime__67\nMirage_runtime\n", shape="box"];
                68 [label="cmdliner_stdlib__68\nCmdliner_stdlib\n", shape="box"];
                69 [label="mirage_bootvar__69\nMirage_bootvar\n", shape="box"];
                70 [label="mirage_bootvar__70\nMirage_bootvar\n", shape="box"];
                71 [label="mirage_bootvar__71\nMirage_bootvar\n", shape="box"];
                72 [label="If\ntarget"];
                73 [label="struct_end__73\nstruct end\n", shape="box"];
                74 [label="mirage_runtime__74\nMirage_runtime\ntarget", shape="box"];
                
                3 -> 2 [style="dashed"];
                3 -> 1 [style="dashed"];
                6 -> 4 [style="dotted", headport="n"];
                6 -> 5 [style="dotted", headport="n"];
                6 -> 4 [style="bold", style="dotted", headport="n"];
                9 -> 7 [style="dotted", headport="n"];
                9 -> 8 [style="dotted", headport="n"];
                9 -> 7 [style="bold", style="dotted", headport="n"];
                12 -> 10 [style="dotted", headport="n"];
                12 -> 11 [style="dotted", headport="n"];
                12 -> 10 [style="bold", style="dotted", headport="n"];
                15 -> 13 [style="dotted", headport="n"];
                15 -> 14 [style="dotted", headport="n"];
                15 -> 13 [style="bold", style="dotted", headport="n"];
                18 -> 16 [style="dotted", headport="n"];
                18 -> 17 [style="dotted", headport="n"];
                18 -> 16 [style="bold", style="dotted", headport="n"];
                21 -> 19 [style="dotted", headport="n"];
                21 -> 20 [style="dotted", headport="n"];
                21 -> 19 [style="bold", style="dotted", headport="n"];
                24 -> 22 [style="dotted", headport="n"];
                24 -> 23 [style="dotted", headport="n"];
                24 -> 22 [style="bold", style="dotted", headport="n"];
                27 -> 25 [style="dotted", headport="n"];
                27 -> 26 [style="dotted", headport="n"];
                27 -> 25 [style="bold", style="dotted", headport="n"];
                28 -> 6 [style="dotted", headport="n"];
                28 -> 9 [style="dotted", headport="n"];
                28 -> 12 [style="dotted", headport="n"];
                28 -> 15 [style="dotted", headport="n"];
                28 -> 18 [style="dotted", headport="n"];
                28 -> 21 [style="dotted", headport="n"];
                28 -> 24 [style="dotted", headport="n"];
                28 -> 27 [style="bold", style="dotted", headport="n"];
                29 -> 28 [];
                30 -> 29 [];
                31 -> 28 [];
                31 -> 29 [];
                31 -> 30 [];
                32 -> 31 [];
                33 -> 32 [style="dotted", headport="n"];
                33 -> 28 [style="bold", style="dotted", headport="n"];
                34 -> 33 [];
                34 -> 29 [];
                36 -> 35 [];
                36 -> 29 [];
                36 -> 30 [];
                37 -> 31 [];
                38 -> 29 [];
                38 -> 30 [];
                39 -> 36 [style="dotted", headport="n"];
                39 -> 37 [style="dotted", headport="n"];
                39 -> 38 [style="bold", style="dotted", headport="n"];
                40 -> 39 [];
                40 -> 34 [];
                41 -> 40 [];
                42 -> 40 [];
                43 -> 41 [style="dotted", headport="n"];
                43 -> 42 [style="bold", style="dotted", headport="n"];
                44 -> 40 [];
                45 -> 39 [];
                46 -> 33 [];
                46 -> 29 [];
                46 -> 30 [];
                46 -> 40 [];
                46 -> 45 [];
                46 -> 44 [];
                46 -> 43 [];
                47 -> 3 [style="dotted", headport="n"];
                47 -> 46 [style="bold", style="dotted", headport="n"];
                48 -> 47 [];
                54 -> 52 [style="dotted", headport="n"];
                54 -> 53 [style="dotted", headport="n"];
                54 -> 52 [style="bold", style="dotted", headport="n"];
                55 -> 51 [style="dotted", headport="n"];
                55 -> 54 [style="dotted", headport="n"];
                55 -> 51 [style="bold", style="dotted", headport="n"];
                59 -> 57 [style="dotted", headport="n"];
                59 -> 58 [style="dotted", headport="n"];
                59 -> 57 [style="bold", style="dotted", headport="n"];
                60 -> 56 [style="dotted", headport="n"];
                60 -> 59 [style="dotted", headport="n"];
                60 -> 56 [style="bold", style="dotted", headport="n"];
                64 -> 62 [style="dotted", headport="n"];
                64 -> 63 [style="dotted", headport="n"];
                64 -> 62 [style="bold", style="dotted", headport="n"];
                65 -> 61 [style="dotted", headport="n"];
                65 -> 64 [style="dotted", headport="n"];
                65 -> 61 [style="bold", style="dotted", headport="n"];
                72 -> 69 [style="dotted", headport="n"];
                72 -> 69 [style="dotted", headport="n"];
                72 -> 70 [style="dotted", headport="n"];
                72 -> 70 [style="dotted", headport="n"];
                72 -> 70 [style="dotted", headport="n"];
                72 -> 70 [style="dotted", headport="n"];
                72 -> 70 [style="dotted", headport="n"];
                72 -> 71 [style="bold", style="dotted", headport="n"];
                73 -> 72 [style="dashed"];
                74 -> 73 [style="dashed"];
                74 -> 68 [style="dashed"];
                74 -> 67 [style="dashed"];
                74 -> 66 [style="dashed"];
                74 -> 65 [style="dashed"];
                74 -> 60 [style="dashed"];
                74 -> 55 [style="dashed"];
                74 -> 50 [style="dashed"];
                74 -> 49 [style="dashed"];
                74 -> 48 [style="dashed"];
                }

Describe after configure
  $ echo "-txen" > context
  $ ./config.exe describe --context-file=context
  Name       describe
  Keys      
    dhcp=true (default),
    net= (default),
    service-utcp=false (default),
    target=xen
