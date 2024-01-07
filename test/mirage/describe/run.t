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
                4 [label="mclock__4\nMclock\n", shape="box"];
                5 [label="unix_os_time__5\nUnix_os.Time\n", shape="box"];
                6 [label="xen_os_time__6\nXen_os.Time\n", shape="box"];
                7 [label="solo5_os_time__7\nSolo5_os.Time\n", shape="box"];
                8 [label="If\ntarget"];
                9 [label="mirage_crypto_rng_mirage_make__9\nMirage_crypto_rng_mirage.Make\n", shape="box"];
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
                28 [label="netif__28\nNetif\n", shape="box"];
                29 [label="netif__29\nNetif\n", shape="box"];
                30 [label="If\ntarget"];
                31 [label="netif__31\nNetif\n", shape="box"];
                32 [label="netif__32\nNetif\n", shape="box"];
                33 [label="If\ntarget"];
                34 [label="If\ntarget"];
                35 [label="ethernet_make__35\nEthernet.Make\n", shape="box"];
                36 [label="ipv6_make__36\nIpv6.Make\n", shape="box"];
                37 [label="arp_make__37\nArp.Make\n", shape="box"];
                38 [label="qubes_db__38\nQubes.DB\n", shape="box"];
                39 [label="qubesdb_ipv4_make__39\nQubesdb_ipv4.Make\n", shape="box"];
                40 [label="dhcp_ipv4_make__40\nDhcp_ipv4.Make\n", shape="box"];
                41 [label="static_ipv4_make__41\nStatic_ipv4.Make\n", shape="box"];
                42 [label="If\ndhcp, net,\ntarget"];
                43 [label="tcpip_stack_direct_ipv4v6__43\nTcpip_stack_direct.IPV4V6\n", shape="box"];
                44 [label="tcp_flow_make__44\nTcp.Flow.Make\n", shape="box"];
                45 [label="udp_make__45\nUdp.Make\n", shape="box"];
                46 [label="icmpv4_make__46\nIcmpv4.Make\n", shape="box"];
                47 [label="tcpip_stack_direct_makev4v6__47\nTcpip_stack_direct.MakeV4V6\n", shape="box"];
                48 [label="If\ndhcp, net,\ntarget"];
                49 [label="app__49\nApp\n", shape="box"];
                50 [label="pclock__50\nPclock\n", shape="box"];
                51 [label="mirage_logs_make__51\nMirage_logs.Make\n", shape="box"];
                52 [label="mirage_runtime__52\nMirage_runtime\n", shape="box"];
                53 [label="gc__53\nGc\n", shape="box"];
                54 [label="hashtbl__54\nHashtbl\n", shape="box"];
                55 [label="printexc__55\nPrintexc\n", shape="box"];
                56 [label="bootvar__56\nBootvar\n", shape="box"];
                57 [label="bootvar__57\nBootvar\n", shape="box"];
                58 [label="bootvar__58\nBootvar\n", shape="box"];
                59 [label="If\ntarget"];
                60 [label="key_gen__60\nKey_gen\n", shape="box"];
                61 [label="mirage_runtime__61\nMirage_runtime\ntarget", shape="box"];
                
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
                30 -> 28 [style="dotted", headport="n"];
                30 -> 29 [style="dotted", headport="n"];
                30 -> 28 [style="bold", style="dotted", headport="n"];
                33 -> 31 [style="dotted", headport="n"];
                33 -> 32 [style="dotted", headport="n"];
                33 -> 31 [style="bold", style="dotted", headport="n"];
                34 -> 12 [style="dotted", headport="n"];
                34 -> 15 [style="dotted", headport="n"];
                34 -> 18 [style="dotted", headport="n"];
                34 -> 21 [style="dotted", headport="n"];
                34 -> 24 [style="dotted", headport="n"];
                34 -> 27 [style="dotted", headport="n"];
                34 -> 30 [style="dotted", headport="n"];
                34 -> 33 [style="bold", style="dotted", headport="n"];
                35 -> 34 [];
                36 -> 34 [];
                36 -> 35 [];
                36 -> 9 [];
                36 -> 8 [];
                36 -> 4 [];
                37 -> 35 [];
                37 -> 8 [];
                39 -> 38 [];
                39 -> 9 [];
                39 -> 4 [];
                39 -> 35 [];
                39 -> 37 [];
                40 -> 9 [];
                40 -> 4 [];
                40 -> 8 [];
                40 -> 34 [];
                40 -> 35 [];
                40 -> 37 [];
                41 -> 9 [];
                41 -> 4 [];
                41 -> 35 [];
                41 -> 37 [];
                42 -> 39 [style="dotted", headport="n"];
                42 -> 40 [style="dotted", headport="n"];
                42 -> 41 [style="bold", style="dotted", headport="n"];
                43 -> 42 [];
                43 -> 36 [];
                44 -> 43 [];
                44 -> 8 [];
                44 -> 4 [];
                44 -> 9 [];
                45 -> 43 [];
                45 -> 9 [];
                46 -> 42 [];
                47 -> 8 [];
                47 -> 9 [];
                47 -> 34 [];
                47 -> 35 [];
                47 -> 37 [];
                47 -> 43 [];
                47 -> 46 [];
                47 -> 45 [];
                47 -> 44 [];
                48 -> 3 [style="dotted", headport="n"];
                48 -> 47 [style="bold", style="dotted", headport="n"];
                49 -> 48 [];
                51 -> 50 [];
                59 -> 56 [style="dotted", headport="n"];
                59 -> 56 [style="dotted", headport="n"];
                59 -> 57 [style="dotted", headport="n"];
                59 -> 57 [style="dotted", headport="n"];
                59 -> 57 [style="dotted", headport="n"];
                59 -> 57 [style="dotted", headport="n"];
                59 -> 57 [style="dotted", headport="n"];
                59 -> 58 [style="bold", style="dotted", headport="n"];
                60 -> 59 [style="dashed"];
                61 -> 60 [style="dashed"];
                61 -> 55 [style="dashed"];
                61 -> 54 [style="dashed"];
                61 -> 53 [style="dashed"];
                61 -> 52 [style="dashed"];
                61 -> 51 [style="dashed"];
                61 -> 49 [style="dashed"];
                }

Describe after configure
  $ echo "-txen" > context
  $ ./config.exe describe --context-file=context
  Name       describe
  Keys       dhcp=false (default),
             net= (default),
             target=xen
