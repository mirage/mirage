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
                30 [label="ipv6_make__30\nIpv6.Make\n", shape="box"];
                31 [label="arp_make__31\nArp.Make\n", shape="box"];
                32 [label="qubes_db__32\nQubes.DB\n", shape="box"];
                33 [label="qubesdb_ipv4_make__33\nQubesdb_ipv4.Make\n", shape="box"];
                34 [label="dhcp_ipv4_make__34\nDhcp_ipv4.Make\n", shape="box"];
                35 [label="static_ipv4_make__35\nStatic_ipv4.Make\n", shape="box"];
                36 [label="If\ndhcp, net,\ntarget"];
                37 [label="tcpip_stack_direct_ipv4v6__37\nTcpip_stack_direct.IPV4V6\n", shape="box"];
                38 [label="tcp_flow_make__38\nTcp.Flow.Make\n", shape="box"];
                39 [label="udp_make__39\nUdp.Make\n", shape="box"];
                40 [label="icmpv4_make__40\nIcmpv4.Make\n", shape="box"];
                41 [label="tcpip_stack_direct_makev4v6__41\nTcpip_stack_direct.MakeV4V6\n", shape="box"];
                42 [label="If\ndhcp, net,\ntarget"];
                43 [label="app__43\nApp\n", shape="box"];
                44 [label="mirage_runtime__44\nMirage_runtime\n", shape="box"];
                45 [label="mirage_crypto_rng_mirage__45\nMirage_crypto_rng_mirage\n", shape="box"];
                46 [label="mirage_mtime__46\nMirage_mtime\n", shape="box"];
                47 [label="mirage_mtime__47\nMirage_mtime\n", shape="box"];
                48 [label="mirage_mtime__48\nMirage_mtime\n", shape="box"];
                49 [label="If\ntarget"];
                50 [label="If\ntarget"];
                51 [label="mirage_ptime__51\nMirage_ptime\n", shape="box"];
                52 [label="mirage_ptime__52\nMirage_ptime\n", shape="box"];
                53 [label="mirage_ptime__53\nMirage_ptime\n", shape="box"];
                54 [label="If\ntarget"];
                55 [label="If\ntarget"];
                56 [label="mirage_sleep__56\nMirage_sleep\n", shape="box"];
                57 [label="mirage_sleep__57\nMirage_sleep\n", shape="box"];
                58 [label="mirage_sleep__58\nMirage_sleep\n", shape="box"];
                59 [label="If\ntarget"];
                60 [label="If\ntarget"];
                61 [label="mirage_logs__61\nMirage_logs\n", shape="box"];
                62 [label="mirage_runtime__62\nMirage_runtime\n", shape="box"];
                63 [label="cmdliner_stdlib__63\nCmdliner_stdlib\n", shape="box"];
                64 [label="mirage_bootvar__64\nMirage_bootvar\n", shape="box"];
                65 [label="mirage_bootvar__65\nMirage_bootvar\n", shape="box"];
                66 [label="mirage_bootvar__66\nMirage_bootvar\n", shape="box"];
                67 [label="If\ntarget"];
                68 [label="struct_end__68\nstruct end\n", shape="box"];
                69 [label="mirage_runtime__69\nMirage_runtime\ntarget", shape="box"];
                
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
                30 -> 28 [];
                30 -> 29 [];
                31 -> 29 [];
                33 -> 32 [];
                33 -> 29 [];
                33 -> 31 [];
                34 -> 28 [];
                34 -> 29 [];
                34 -> 31 [];
                35 -> 29 [];
                35 -> 31 [];
                36 -> 33 [style="dotted", headport="n"];
                36 -> 34 [style="dotted", headport="n"];
                36 -> 35 [style="bold", style="dotted", headport="n"];
                37 -> 36 [];
                37 -> 30 [];
                38 -> 37 [];
                39 -> 37 [];
                40 -> 36 [];
                41 -> 28 [];
                41 -> 29 [];
                41 -> 31 [];
                41 -> 37 [];
                41 -> 40 [];
                41 -> 39 [];
                41 -> 38 [];
                42 -> 3 [style="dotted", headport="n"];
                42 -> 41 [style="bold", style="dotted", headport="n"];
                43 -> 42 [];
                49 -> 47 [style="dotted", headport="n"];
                49 -> 48 [style="dotted", headport="n"];
                49 -> 47 [style="bold", style="dotted", headport="n"];
                50 -> 46 [style="dotted", headport="n"];
                50 -> 49 [style="dotted", headport="n"];
                50 -> 46 [style="bold", style="dotted", headport="n"];
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
                67 -> 64 [style="dotted", headport="n"];
                67 -> 64 [style="dotted", headport="n"];
                67 -> 65 [style="dotted", headport="n"];
                67 -> 65 [style="dotted", headport="n"];
                67 -> 65 [style="dotted", headport="n"];
                67 -> 65 [style="dotted", headport="n"];
                67 -> 65 [style="dotted", headport="n"];
                67 -> 66 [style="bold", style="dotted", headport="n"];
                68 -> 67 [style="dashed"];
                69 -> 68 [style="dashed"];
                69 -> 63 [style="dashed"];
                69 -> 62 [style="dashed"];
                69 -> 61 [style="dashed"];
                69 -> 60 [style="dashed"];
                69 -> 55 [style="dashed"];
                69 -> 50 [style="dashed"];
                69 -> 45 [style="dashed"];
                69 -> 44 [style="dashed"];
                69 -> 43 [style="dashed"];
                }

Describe after configure
  $ echo "-txen" > context
  $ ./config.exe describe --context-file=context
  Name       describe
  Keys       dhcp=false (default),
             net= (default),
             target=xen
