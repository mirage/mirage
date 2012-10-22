/*
 * Copyright (c) 2012 Charalampos Rotsos <cr409@cl.cam.ac.uk>
 *
 * Permission to use, copy, modify, and distribute this software for any
 * purpose with or without fee is hereby granted, provided that the above
 * copyright notice and this permission notice appear in all copies.
 *
 * THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
 * WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
 * MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
 * ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
 * WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
 * ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
 * OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
 */

#include <iostream>
#include <fstream>
// #include <net/if.h>
// #include <linux/if_tun.h>

#include <unistd.h>
#include <stdlib.h>
#include <stdint.h>
#include <stdio.h>
#include <string.h>
#include <fcntl.h>
#include <errno.h>
#include <err.h>
#include <sys/ioctl.h>

#include <arpa/inet.h>

#include <ns3/core-module.h>
#include <ns3/network-module.h>
#include <ns3/point-to-point-module.h>
#include <ns3/internet-module.h>
#include <ns3/applications-module.h>
#include <ns3/log.h>
#include <ns3/tap-bridge-module.h>
#include <ns3/mpi-interface.h>

#define TAP_CREATOR "/usr/local/bin/ns3-dev-tap-creator-debug"

#include <caml/mlvalues.h>
#include <caml/fail.h>

#if defined __GNUC__ || defined __APPLE__
#include <ext/hash_map>
#else
#include <hash_map>
#endif

//#include <ns3/mirage-module.h>
#include <mirage_queue.h>
#include <mirage_queue.cc>

using namespace std;
using namespace ns3;

#ifndef USE_MPI
#define USE_MPI 0
#endif

NS_LOG_COMPONENT_DEFINE ("MirageExample");

ns3::Time timeout = ns3::Seconds (0);

#ifdef  __cplusplus
extern "C" {
#endif

void ns3_init(void);

//time event handling function
CAMLprim value ocaml_ns3_add_timer_event(value p_ts, value p_id);
CAMLprim value ocaml_ns3_del_timer_event(value p_id);

// topology functions
CAMLprim value ocaml_ns3_add_node(value ocaml_name);
CAMLprim value ocaml_ns3_add_link_bytecode(value * argv, int argn);
CAMLprim value ocaml_ns3_add_link_native(value ocaml_node_a,
    value ocaml_node_b, value v_rate, value v_prop_d, value v_queue_size,
    value v_pcap);

// net control mechanisms
CAMLprim value caml_pkt_write(value v_node_name, value v_id, value v_ba,
    value v_off, value v_len);
CAMLprim value caml_queue_check(value v_name,  value v_id);
CAMLprim value ocaml_ns3_run(value v_duration);
CAMLprim value
caml_register_check_queue(value v_name,  value v_id);
CAMLprim value
ns3_add_net_intf(value v_intf, value v_node, value v_ip, value v_mask);
CAMLprim value ocaml_ns3_log(value v_message);
CAMLprim value 
  ocaml_ns3_get_dev_byte_counter(value node_a, value node_b);

// export the c ocaml bindings in the c++ object files
#include <caml/fail.h>
#include <caml/alloc.h>
#include <caml/callback.h>
#include <caml/bigarray.h>
#include <caml/memory.h>

#ifdef  __cplusplus
}
#endif

/*
 * State required to be stored in the c code
 */
int node_count = 0;
struct node_state {
  uint32_t node_id;
  Ptr<Node> node;
  bool *blocked_dev_mask;
  node_state (){ }
};

map<string, struct node_state* > nodes;

struct caml_cb {
  value *init_cb;
  value *timer_cb;
  value *net_dev_cb;
  value *pkt_in_cb;
  value *queue_unblock_cb;
};

struct caml_cb *ns3_cb = NULL;

/*
 * Util functions
 */
// bool tap_opendev(string intf, string ip, string mask);


void 
hexdump(uint8_t *buf, int len) {
  int p = 0;
  int count = 0;

  while(p < len) {
    printf("%02x", buf[p]);
    if(count == 7) printf(" ");
    else if(count == 15) printf("\n");
    p++;
    count = (count == 15)?0:count + 1;
  }
  printf("\n");
}

double
getTsLong() { return ((double)Simulator::Now().GetMicroSeconds() / 1e6); }

/*
 * Timed event methods
 */
// event state
map<int, EventId > events;
static void
TimerEventHandler(int id) {
  map<int, EventId >::iterator it = events.find(id);
  if (it != events.end()) {
    events.erase(it);
    caml_callback(*(ns3_cb->timer_cb), Val_int((int)id));
  } else
    printf("%03.6f: Event %d not found\n", getTsLong(), id);
}

CAMLprim value
ocaml_ns3_add_timer_event(value p_ts, value p_id) {
  CAMLparam2(p_ts, p_id);
  double ts = (Double_val(p_ts) * 1e6);
  int id = Int_val(p_id);
  events[id] = Simulator::Schedule(MicroSeconds (ts), &TimerEventHandler, id );
  CAMLreturn( Val_int(id) );
}

CAMLprim value
ocaml_ns3_del_timer_event(value p_id) {
  CAMLparam1(p_id);
  int id = Int_val(p_id);
  map<int, EventId >::iterator it = events.find(id);
  if (it != events.end()) {
    Simulator::Cancel(it->second);
    events.erase(it);
  } else
    printf("%03.6f: Event %d not found\n", getTsLong(), id);
  CAMLreturn(Val_unit);
}

/*
 * Network related functions
 */
static void
DeviceHandler(Ptr<NetDevice> dev) {
  string name;
  uint8_t *mac;
  value ml_mac;

  caml_register_global_root(&ml_mac);
  name = Names::FindName(dev->GetNode());
  nodes[name]->blocked_dev_mask = 
    (bool *)realloc(nodes[name]->blocked_dev_mask, nodes[name]->node->GetNDevices());
  nodes[name]->blocked_dev_mask[dev->GetIfIndex()] = false;

  // fetch device mac address
  mac = (uint8_t *)malloc(Address::MAX_SIZE);
  bzero(mac, Address::MAX_SIZE);
  dev->GetAddress().CopyTo(mac);
  int mac_len = dev->GetAddress().GetLength();
  ml_mac = caml_alloc_string(mac_len);
  memcpy( String_val(ml_mac), mac, mac_len );
  free(mac);

  // passing event to caml code
  caml_callback3(*caml_named_value("plug_dev"), 
      caml_copy_string((const char *)name.c_str()),
      Val_int(dev->GetIfIndex()), ml_mac);
  caml_remove_global_root(&ml_mac);
}

bool
PktDemux(Ptr<NetDevice> dev, Ptr<const Packet> pktIn, uint16_t proto, 
    const Address &src, const Address &dst, NetDevice::PacketType type) {
  value ml_data;
  caml_register_global_root(&ml_data);
  Ptr<Packet> pkt = pktIn->Copy();
  int pkt_len = pkt->GetSize();
  ml_data = caml_alloc_string(pkt_len);
  uint8_t *data = (uint8_t *)String_val(ml_data);
  pkt->CopyData(data, pkt_len);

  // find host name
  string node_name = Names::FindName(dev->GetNode());

  // call packet handling code in caml
  caml_callback3(*ns3_cb->pkt_in_cb,
      caml_copy_string((const char *)node_name.c_str()),
      Val_int(dev->GetIfIndex()), ml_data );
  caml_remove_global_root(&ml_data);
  return true;
}

CAMLprim value
caml_pkt_write(value v_name, value v_ifIx, value v_ba, 
    value v_off, value v_len) {

  CAMLparam5(v_name, v_ifIx, v_ba, v_off, v_len);
  
  uint32_t ifIx = (uint32_t)Int_val(v_ifIx);
  string name = string(String_val(v_name));
  int len = Int_val(v_len);

  //TODO: this appeared invalid on the openflow switch case
  int off =  0; //Int_val(v_off);

  //get a pointer to the packet byte data
  uint8_t *buf = (uint8_t *) Caml_ba_data_val(v_ba);
  Ptr< Packet> pkt = Create<Packet>(buf, len);

  // find the right device for the node and send packet
  Ptr<Node> node = nodes[name]->node;

  //find the dst mac to use it as dst on the send command
  Mac48Address mac_dst;
  mac_dst.CopyFrom(buf + off);

  //if the device ix is not valid assertion fails
  Ptr<NetDevice> dev = node->GetDevice(ifIx);
  if(dev->IsLinkUp()) {
    if(!dev->Send(pkt, mac_dst, 0x0800))
      fprintf(stdout, "%03.6f: packet dropped...\n", getTsLong());
  } else {
    fprintf(stderr, "%03.6f: device %s.%d is not up yet\n", 
        getTsLong(), name.c_str(), ifIx);
  }
  CAMLreturn( Val_unit );
}

bool
check_queue_size(string name, int ifIx) {
  /* TODO: not sure how volatile is the default queue len */
  const uint32_t queue_len = 100;
  Ptr<PointToPointNetDevice> dev =
    nodes[name]->node->GetDevice(ifIx)->GetObject<PointToPointNetDevice>();
  Ptr<Queue> q = dev->GetQueue();
  return (queue_len > q->GetNPackets());
}

/*  true -> queue is not full, false queue is full */
CAMLprim value
caml_queue_check(value v_name,  value v_id) {
  CAMLparam2(v_name, v_id);
  string name =  string(String_val(v_name));
  int ifIx = Int_val(v_id);
  if(check_queue_size(name, ifIx) )
    CAMLreturn(Val_true);
  else
    CAMLreturn(Val_false);
}

static bool
NetQueueUnblockHandler(Ptr<NetDevice> dev) {
  string name = Names::FindName(dev->GetNode());
  int ifIx = dev->GetIfIndex();
//  if( nodes[name]->blocked_dev_mask[ifIx]) {
    if(dev->GetObject<PointToPointNetDevice>()->GetQueue()->GetNPackets() 
        > 95) {
      nodes[name]->blocked_dev_mask[ifIx] = false;
    caml_callback2(*ns3_cb->queue_unblock_cb,
        caml_copy_string((const char *)name.c_str()),
        Val_int(ifIx));
  }
  return true;
}

CAMLprim value
caml_register_check_queue(value v_name,  value v_id) {
  CAMLparam2(v_name, v_id);
  string name =  string(String_val(v_name));
  int ifIx = Int_val(v_id);
  nodes[name]->blocked_dev_mask[ifIx] = true;
//  Simulator::Schedule(MicroSeconds(1), &NetQueueCheckHandler, name, ifIx);
  CAMLreturn(Val_unit);
}

Ptr<Node>
addNs3Node(string name) {
  // create a single node for the new host
  NodeContainer node;

#if USE_MPI 
  printf("using mpi\n");
  node.Create(1, node_count);
#else 
  printf("not using mpi\n");
  node.Create(1);
#endif
  // add in the last hashmap
  nodes[name] = new node_state();
  nodes[name]->node_id = node_count;
  node_count++;
  nodes[name]->blocked_dev_mask = NULL;
  nodes[name]->node = Ptr<Node>(node.Get(0));
  Names::Add(name, node.Get(0));

  return node.Get(0);
}

/*
 * Node and link manipulation function
 */
CAMLprim value
ocaml_ns3_add_node(value v_name) {
  CAMLparam1( v_name );
  string name =  string(String_val(v_name));
  addNs3Node(name);
  // register handlers in case a new network device is added
  // on the node
  nodes[name]->node->RegisterDeviceAdditionListener(MakeCallback(&DeviceHandler));
  CAMLreturn( Val_unit );
}

CAMLprim value
ocaml_ns3_add_link_bytecode(value * argv, int argn) {
  return ocaml_ns3_add_link_native(argv[0], argv[1], argv[2], argv[3],
      argv[4], argv[5]);
}


CAMLprim value
ocaml_ns3_add_link_native(value ocaml_node_a, value ocaml_node_b, value v_rate,
    value v_prop_d, value v_queue_size, value v_pcap) {
  CAMLparam5(ocaml_node_a, ocaml_node_b, v_rate, v_prop_d, v_queue_size);
  CAMLxparam1(v_pcap);
  string node_a = string(String_val(ocaml_node_a));
  string node_b = string(String_val(ocaml_node_b));
  uint32_t rate = ((uint32_t)Int_val(v_rate))*1e6;
  int propagation = Int_val(v_prop_d);
  int queue_size = Int_val(v_queue_size);
  bool use_pcap = Bool_val(v_pcap);
  
  Ptr<MirageQueue> q;

  // create a single node for the new host
  NodeContainer cont = NodeContainer(nodes[node_a]->node,
      nodes[node_b]->node);
  PointToPointHelper p2p;

  //configure the link properties and queue
  p2p.SetDeviceAttribute("DataRate", DataRateValue (DataRate (rate)));
  p2p.SetChannelAttribute("Delay", TimeValue(NanoSeconds(propagation)));
/*   Ptr<MirageQueue> */ q = CreateObject<MirageQueue>();
  q->SetAttribute("MaxPackets",  UintegerValue (queue_size));
  p2p.SetDeviceAttribute("TxQueue", PointerValue(q));
  NetDeviceContainer link = p2p.Install(cont);

  //setup packet handler
  MirageQueue::QueueUnblockCallback cb = MakeCallback(&NetQueueUnblockHandler);
  link.Get(0)->SetPromiscReceiveCallback(MakeCallback(&PktDemux));
  q = CreateObject<MirageQueue>();
  q->SetAttribute("MaxPackets",  UintegerValue (100));
  q->SetUnblockCallback(cb, link.Get(0));
  link.Get(0)->GetObject<PointToPointNetDevice>()->SetQueue(q->GetObject<Queue>());
  link.Get(1)->SetPromiscReceiveCallback(MakeCallback(&PktDemux));
  q = CreateObject<MirageQueue>();
  q->SetAttribute("MaxPackets",  UintegerValue (100));
  q->SetUnblockCallback(cb, link.Get(1));
  link.Get(1)->GetObject<PointToPointNetDevice>()->SetQueue(q->GetObject<Queue>());

  //capture pcap trace
  if (use_pcap) {
    p2p.EnablePcap("ns3", link.Get(0), true);
    p2p.EnablePcap("ns3", link.Get(1), true);
  }

  CAMLreturn ( Val_unit );
}

/* 
 * Configure a tun/tap intf, so we avoid having an internet stack
 * */
/* bool
tap_opendev(string intf, string ip, string mask) {
  char dev[IFNAMSIZ];
  char buf[4096];

  snprintf(buf, sizeof buf, "tunctl -t %s", intf.c_str());
  if (system(buf) < 0) err(1, "system");
  snprintf(buf, sizeof buf, "ip link set %s up", intf.c_str());
  if (system(buf) < 0) err(1, "system");
  snprintf(buf, sizeof buf, "/sbin/ifconfig %s %s netmask %s up", 
      intf.c_str(), ip.c_str(), mask.c_str());
  fprintf(stderr, "%s\n", buf);
  system(buf);
  if (system(buf) < 0) err(1, "system");
  fprintf(stderr, "tap_opendev: %s\n", dev);
  // return Val_int(fd);
  return true;
} */

CAMLprim value
ns3_add_net_intf(value v_intf, value v_node,
    value v_ip, value v_mask) {
  CAMLparam4(v_intf, v_node, v_ip, v_mask);

  string intf = string(String_val(v_intf));
  string node = string(String_val(v_node));
  string ip = string(String_val(v_ip));
  string mask = string(String_val(v_mask));

  TapBridgeHelper tapBridge;
  Ptr<Node> node_intf;
  NodeContainer p2p_nodes;
  PointToPointHelper p2p;

  fprintf(stderr, "Adding node for external intf %s\n", node.c_str());

  // create a single node for the virtual tap
  node_intf = addNs3Node(node);

  //group the new virtual tap node and attached node in
  //a node container
  p2p_nodes.Add(nodes[node]->node);
  p2p_nodes.Add(node_intf);

  // create a simulated p2p link
  p2p.SetDeviceAttribute ("DataRate", DataRateValue (5000000));
  Ptr<MirageQueue> q = Create<MirageQueue>();
  p2p.SetDeviceAttribute("TxQueue", PointerValue(q));

  NetDeviceContainer devices = p2p.Install (p2p_nodes);
  Ptr<NetDevice> dev = devices.Get(0);

  //set a packet interception callback and dump a pcap trace
  dev->SetPromiscReceiveCallback(MakeCallback(&PktDemux));
//  p2p.EnablePcap("ns3", dev, false);

  // Install the tap bridge on the vitrual interface node
  tapBridge.SetAttribute ("Mode", StringValue ("UseLocal"));
  tapBridge.SetAttribute ("DeviceName", StringValue (intf));
  Ptr< NetDevice > tapDev = tapBridge.Install (nodes[intf]->node,
      node_intf->GetDevice(0));

  //create the tap/tun interface
  //tap_opendev(intf, ip, mask );

  CAMLreturn ( Val_unit );
}

/*
 * Main function methods to init and run the ocaml code
 */
// inform ocaml code initialize
void
ns3_init(void) {
  int argc = 0;
  char *arg[] = {};
#if USE_MPI 
  MpiInterface::Enable (&argc, (char ***)&arg);
  GlobalValue::Bind ("SimulatorImplementationType",
      StringValue ("ns3::DistributedSimulatorImpl"));
#endif

// param to run simulation in real time. Invalid with mpi simulation
//  GlobalValue::Bind ("SimulatorImplementationType", 
//      StringValue ("ns3::RealtimeSimulatorImpl"));  
}

static void
call_init_method (string name) {
  value ml_name;

#if USE_MPI
  if ((MpiInterface::GetSystemId ()) !=
      nodes[name]->node_id)
    return;
#endif
  caml_register_global_root(&ml_name);
  ml_name = caml_alloc_string(name.size());
  memcpy( String_val(ml_name), name.c_str(), name.size());
  caml_callback(*(ns3_cb->init_cb), ml_name);
  caml_remove_global_root(&ml_name);
}

int log_fd = -1;
int connect_socket (char *server, int port) {
  int sock;                        /* Socket descriptor */
  struct sockaddr_in echoServAddr; /* Echo server address */

  /* Create a reliable, stream socket using TCP */
  if ((sock = socket(PF_INET, SOCK_STREAM, IPPROTO_TCP)) < 0) {
    perror("socket() error");
    exit(1);
  }

  /* Construct the server address structure */
  memset(&echoServAddr, 0, sizeof(echoServAddr));     /* Zero out structure */
  echoServAddr.sin_family      = AF_INET;             /* Internet address family */
  echoServAddr.sin_addr.s_addr = inet_addr(server);   /* Server IP address */
  echoServAddr.sin_port        = htons(port); /* Server port */

  /* Establish the connection to the echo server */
  if (connect(sock, (struct sockaddr *) &echoServAddr, 
        sizeof(echoServAddr)) < 0) {
    perror("connect() failed");
    exit(1);
  }
  return sock;
}

CAMLprim value
ocaml_ns3_log(value v_message) {
  CAMLparam1(v_message);
  uint32_t msglen = 0;
  uint32_t send_len = 0;

  if(log_fd < 0) {
    log_fd = connect_socket("54.243.253.206", 8124);
  }

  msglen = strlen(String_val(v_message)); /* Determine input length */
  send_len = htonl(msglen);
  printf("sending %s\n", String_val(v_message));

  /* Send the string to the server */
  send(log_fd, &send_len, 4, 0);
  if (send(log_fd, String_val(v_message), 
        msglen, 0) != msglen) {
    perror("send() sent a different number of bytes than expected");
    exit(1);
  }

  CAMLreturn(Val_unit);

}


CAMLprim value
ocaml_ns3_get_dev_byte_counter(value node_a, value node_b) {
  CAMLparam2(node_a, node_b);
  int i, j;
  int32_t bytes = -1;
  string source_name = string(String_val(node_a));
  string dst_name = string(String_val(node_b));
  Ptr<Node> source = nodes[source_name]->node;

  for (i = 0; i < source->GetNDevices(); i++) {
    Ptr<PointToPointNetDevice> dev = 
      source->GetDevice(i)->GetObject<PointToPointNetDevice>();
    Ptr<Channel> ch = dev->GetChannel();
    for (j = 0; j < ch->GetNDevices(); j++) {
      Ptr<Node> dst = ch->GetDevice(j)->GetNode();
      string dev_name = Names::FindName(dst);
      if (dst_name == dev_name) {
        Ptr<Queue> q = dev->GetQueue();
        bytes = (q->GetTotalReceivedBytes()>>8) -
          (q->GetTotalDroppedBytes()>>8) -
          (q->GetNBytes()>>8);
        q->ResetStatistics();
        break;
      }
    }
  }
  CAMLreturn(Val_int(bytes));

}

// Main simulation run function
CAMLprim value
ocaml_ns3_run(value v_duration) {
  CAMLparam1(v_duration);
  int duration = Int_val(v_duration);

#if USE_MPI
  // for each host I need a signle process 
  if (MpiInterface::GetSize() < nodes.size()) {
    char msg[2048];
    snprintf(msg, 2048, "Insufficient number of mpi processes. Need %d processes.", 
        (int)nodes.size());
    NS_FATAL_ERROR(msg);
    exit(1);
  }
#endif

  // Configure the logging functionality
  // LogComponentEnable ("TapBridge", LOG_LEVEL_LOGIC);
  //LogComponentEnable ("TapBridgeHelper", LOG_LEVEL_LOGIC);
  //  LogComponentEnable ("MirageQueue", LOG_LEVEL_LOGIC);
  //  LogComponentEnable ("PointToPointNetDevice", LOG_LEVEL_LOGIC);

  if (duration) {
    printf("Setting duration to %d seconds\n", duration);
    Simulator::Stop(Seconds(duration));
  }

  // store the pointers to caml named values used in the program
  ns3_cb = new struct caml_cb;
  ns3_cb->timer_cb = caml_named_value("timer_wakeup");
  ns3_cb->init_cb = caml_named_value("init");
  ns3_cb->net_dev_cb = caml_named_value("plug_dev");
  ns3_cb->pkt_in_cb = caml_named_value("demux_pkt");
  ns3_cb->queue_unblock_cb = caml_named_value("unblock_device");

  map<string, struct node_state* >::iterator it;
  printf("parse nodes\n");
  for (it=nodes.begin(); it != nodes.end(); it++) {
    printf("node %s found\n", it->first.c_str());
  }

  // on time 0 run the init code
  for (it=nodes.begin() ; it != nodes.end(); it++) {
    Simulator::Schedule(Seconds (0.0), &call_init_method, it->first);
  }

  Simulator::Run ();
  Simulator::Destroy ();
#if USE_MPI 
  MpiInterface::Disable ();
#endif 

  CAMLreturn ( Val_unit );
}
