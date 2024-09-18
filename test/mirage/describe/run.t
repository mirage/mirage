  $ export MIRAGE_DEFAULT_TARGET=unix

Describe before configure (using defaults)
  $ ./config.exe describe -t spt
  Name       describe
  Keys       dhcp=false (default),
             net= (default),
             target=spt

Describe before configure (no eval)
  $ ./config.exe describe --no-eval --dot -o-
  Name       describe
  Keys       dhcp=false (default),
             net= (default),
             target=unix (default)
  Output     -digraph G {
                ordering=out;
                1 [label="tcpv4v6_socket__1\nTcpv4v6_socket\n", shape="box"];
                2 [label="udpv4v6_socket__2\nUdpv4v6_socket\n", shape="box"];
                3 [label="tcpip_stack_socket_v4v6__3\nTcpip_stack_socket.V4V6\n", shape="box"];
                4 [label="mirage_time__4\nMirage_time\n", shape="box"];
                5 [label="mirage_time__5\nMirage_time\n", shape="box"];
                6 [label="If\ntarget"];
                7 [label="mclock__7\nMclock\n", shape="box"];
                8 [label="mirage_crypto_rng_mirage_make__8\nMirage_crypto_rng_mirage.Make\n", shape="box"];
                9 [label="netif__9\nNetif\n", shape="box"];
                10 [label="netif__10\nNetif\n", shape="box"];
                11 [label="If\ntarget"];
                12 [label="netif__12\nNetif\n", shape="box"];
                13 [label="netif__13\nNetif\n", shape="box"];
                14 [label="If\ntarget"];
                15 [label="netif__15\nNetif\n", shape="box"];
                16 [label="netif__16\nNetif\n", shape="box"];
                17 [label="If\ntarget"];
                18 [label="netif__18\nNetif\n", shape="box"];
                19 [label="netif__19\nNetif\n", shape="box"];
                20 [label="If\ntarget"];
                21 [label="netif__21\nNetif\n", shape="box"];
                22 [label="netif__22\nNetif\n", shape="box"];
                23 [label="If\ntarget"];
                24 [label="netif__24\nNetif\n", shape="box"];
                25 [label="netif__25\nNetif\n", shape="box"];
                26 [label="If\ntarget"];
                27 [label="netif__27\nNetif\n", shape="box"];
                28 [label="netif__28\nNetif\n", shape="box"];
                29 [label="If\ntarget"];
                30 [label="netif__30\nNetif\n", shape="box"];
                31 [label="netif__31\nNetif\n", shape="box"];
                32 [label="If\ntarget"];
                33 [label="If\ntarget"];
                34 [label="ethernet_make__34\nEthernet.Make\n", shape="box"];
                35 [label="ipv6_make__35\nIpv6.Make\n", shape="box"];
                36 [label="arp_make__36\nArp.Make\n", shape="box"];
                37 [label="qubes_db__37\nQubes.DB\n", shape="box"];
                38 [label="qubesdb_ipv4_make__38\nQubesdb_ipv4.Make\n", shape="box"];
                39 [label="dhcp_ipv4_make__39\nDhcp_ipv4.Make\n", shape="box"];
                40 [label="static_ipv4_make__40\nStatic_ipv4.Make\n", shape="box"];
                41 [label="If\ndhcp, net,\ntarget"];
                42 [label="tcpip_stack_direct_ipv4v6__42\nTcpip_stack_direct.IPV4V6\n", shape="box"];
                43 [label="tcp_flow_make__43\nTcp.Flow.Make\n", shape="box"];
                44 [label="udp_make__44\nUdp.Make\n", shape="box"];
                45 [label="icmpv4_make__45\nIcmpv4.Make\n", shape="box"];
                46 [label="tcpip_stack_direct_makev4v6__46\nTcpip_stack_direct.MakeV4V6\n", shape="box"];
                47 [label="If\ndhcp, net,\ntarget"];
                48 [label="app__48\nApp\n", shape="box"];
                49 [label="pclock__49\nPclock\n", shape="box"];
                50 [label="mirage_logs_make__50\nMirage_logs.Make\n", shape="box"];
                51 [label="mirage_runtime__51\nMirage_runtime\n", shape="box"];
                52 [label="gc__52\nGc\n", shape="box"];
                53 [label="hashtbl__53\nHashtbl\n", shape="box"];
                54 [label="printexc__54\nPrintexc\n", shape="box"];
                55 [label="mirage_bootvar__55\nMirage_bootvar\n", shape="box"];
                56 [label="mirage_bootvar__56\nMirage_bootvar\n", shape="box"];
                57 [label="mirage_bootvar__57\nMirage_bootvar\n", shape="box"];
                58 [label="If\ntarget"];
                59 [label="struct_end__59\nstruct end\n", shape="box"];
                60 [label="mirage_runtime__60\nMirage_runtime\ntarget", shape="box"];
                
                3 -> 2 [style="dashed"];
                3 -> 1 [style="dashed"];
                6 -> 4 [style="dotted", headport="n"];
                6 -> 4 [style="dotted", headport="n"];
                6 -> 5 [style="dotted", headport="n"];
                6 -> 5 [style="dotted", headport="n"];
                6 -> 5 [style="dotted", headport="n"];
                6 -> 5 [style="dotted", headport="n"];
                6 -> 5 [style="dotted", headport="n"];
                6 -> 5 [style="dotted", headport="n"];
                6 -> 5 [style="dotted", headport="n"];
                6 -> 4 [style="bold", style="dotted", headport="n"];
                8 -> 7 [];
                8 -> 6 [style="dashed"];
                11 -> 9 [style="dotted", headport="n"];
                11 -> 10 [style="dotted", headport="n"];
                11 -> 9 [style="bold", style="dotted", headport="n"];
                14 -> 12 [style="dotted", headport="n"];
                14 -> 13 [style="dotted", headport="n"];
                14 -> 12 [style="bold", style="dotted", headport="n"];
                17 -> 15 [style="dotted", headport="n"];
                17 -> 16 [style="dotted", headport="n"];
                17 -> 15 [style="bold", style="dotted", headport="n"];
                20 -> 18 [style="dotted", headport="n"];
                20 -> 19 [style="dotted", headport="n"];
                20 -> 18 [style="bold", style="dotted", headport="n"];
                23 -> 21 [style="dotted", headport="n"];
                23 -> 22 [style="dotted", headport="n"];
                23 -> 21 [style="bold", style="dotted", headport="n"];
                26 -> 24 [style="dotted", headport="n"];
                26 -> 25 [style="dotted", headport="n"];
                26 -> 24 [style="bold", style="dotted", headport="n"];
                29 -> 27 [style="dotted", headport="n"];
                29 -> 28 [style="dotted", headport="n"];
                29 -> 27 [style="bold", style="dotted", headport="n"];
                32 -> 30 [style="dotted", headport="n"];
                32 -> 31 [style="dotted", headport="n"];
                32 -> 30 [style="bold", style="dotted", headport="n"];
                33 -> 11 [style="dotted", headport="n"];
                33 -> 14 [style="dotted", headport="n"];
                33 -> 17 [style="dotted", headport="n"];
                33 -> 20 [style="dotted", headport="n"];
                33 -> 23 [style="dotted", headport="n"];
                33 -> 26 [style="dotted", headport="n"];
                33 -> 29 [style="dotted", headport="n"];
                33 -> 32 [style="bold", style="dotted", headport="n"];
                34 -> 33 [];
                35 -> 33 [];
                35 -> 34 [];
                35 -> 8 [];
                35 -> 7 [];
                35 -> 6 [style="dashed"];
                36 -> 34 [];
                36 -> 6 [style="dashed"];
                38 -> 37 [];
                38 -> 8 [];
                38 -> 7 [];
                38 -> 34 [];
                38 -> 36 [];
                39 -> 8 [];
                39 -> 7 [];
                39 -> 33 [];
                39 -> 34 [];
                39 -> 36 [];
                39 -> 6 [style="dashed"];
                40 -> 8 [];
                40 -> 7 [];
                40 -> 34 [];
                40 -> 36 [];
                41 -> 38 [style="dotted", headport="n"];
                41 -> 39 [style="dotted", headport="n"];
                41 -> 40 [style="bold", style="dotted", headport="n"];
                42 -> 41 [];
                42 -> 35 [];
                43 -> 42 [];
                43 -> 7 [];
                43 -> 8 [];
                43 -> 6 [style="dashed"];
                44 -> 42 [];
                44 -> 8 [];
                45 -> 41 [];
                46 -> 8 [];
                46 -> 33 [];
                46 -> 34 [];
                46 -> 36 [];
                46 -> 42 [];
                46 -> 45 [];
                46 -> 44 [];
                46 -> 43 [];
                46 -> 6 [style="dashed"];
                47 -> 3 [style="dotted", headport="n"];
                47 -> 46 [style="bold", style="dotted", headport="n"];
                48 -> 47 [];
                50 -> 49 [];
                51 -> 6 [style="dashed"];
                58 -> 55 [style="dotted", headport="n"];
                58 -> 55 [style="dotted", headport="n"];
                58 -> 56 [style="dotted", headport="n"];
                58 -> 56 [style="dotted", headport="n"];
                58 -> 56 [style="dotted", headport="n"];
                58 -> 56 [style="dotted", headport="n"];
                58 -> 56 [style="dotted", headport="n"];
                58 -> 57 [style="bold", style="dotted", headport="n"];
                59 -> 58 [style="dashed"];
                60 -> 59 [style="dashed"];
                60 -> 54 [style="dashed"];
                60 -> 53 [style="dashed"];
                60 -> 52 [style="dashed"];
                60 -> 51 [style="dashed"];
                60 -> 50 [style="dashed"];
                60 -> 48 [style="dashed"];
                }

Describe after configure
  $ echo "-txen" > context
  $ ./config.exe describe --context-file=context
  Name       describe
  Keys       dhcp=false (default),
             net= (default),
             target=xen
