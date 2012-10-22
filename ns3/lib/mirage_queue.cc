/*
 * Copyright (c) 2007 University of Washington
 * Copyright (c) 2012 Charalmpos Rotsos <cr409@cl.cam.ac.uk>
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

/* 
 * An ns3 net device queue to generate queue empty events and propagate them
 * to applications in order to avoid constant queue poling.
 * */
#include <ns3/enum.h>
#include <ns3/uinteger.h>
#include <mirage_queue.h>

// NS_LOG_COMPONENT_DEFINE ("MirageQueue");

namespace ns3 {

NS_OBJECT_ENSURE_REGISTERED (MirageQueue);

TypeId MirageQueue::GetTypeId (void) 
{
  static TypeId tid = TypeId ("ns3::MirageQueue")
    .SetParent<Queue> ()
    .AddConstructor<MirageQueue> ()
    .AddAttribute ("Mode", 
                   "Whether to use bytes (see MaxBytes) or packets (see MaxPackets) as the maximum queue size metric.",
                   EnumValue (QUEUE_MODE_PACKETS),
                   MakeEnumAccessor (&MirageQueue::SetMode),
                   MakeEnumChecker (QUEUE_MODE_BYTES, "QUEUE_MODE_BYTES",
                                    QUEUE_MODE_PACKETS, "QUEUE_MODE_PACKETS"))
    .AddAttribute ("MaxPackets", 
                   "The maximum number of packets accepted by this MirageQueue.",
                   UintegerValue (100),
                   MakeUintegerAccessor (&MirageQueue::m_maxPackets),
                   MakeUintegerChecker<uint32_t> ())
    .AddAttribute ("MaxBytes", 
                   "The maximum number of bytes accepted by this MirageQueue.",
                   UintegerValue (100 * 65535),
                   MakeUintegerAccessor (&MirageQueue::m_maxBytes),
                   MakeUintegerChecker<uint32_t> ())
  ;

  return tid;
}

MirageQueue::MirageQueue () :
  Queue (),
  m_packets (),
  m_bytesInQueue (0)
{
  NS_LOG_FUNCTION_NOARGS ();
}

MirageQueue::~MirageQueue ()
{
  NS_LOG_FUNCTION_NOARGS ();
}

void
MirageQueue::SetMode (MirageQueue::QueueMode mode)
{
  NS_LOG_FUNCTION (mode);
  m_mode = mode;
}

MirageQueue::QueueMode
MirageQueue::GetMode (void)
{
  NS_LOG_FUNCTION_NOARGS ();
  return m_mode;
}

bool 
MirageQueue::DoEnqueue (Ptr<Packet> p)
{
  NS_LOG_FUNCTION (this << p);

  if (m_mode == QUEUE_MODE_PACKETS && (m_packets.size () >= m_maxPackets))
    {
      NS_LOG_LOGIC ("Queue full (at max packets) -- droppping pkt");
      Drop (p);
      return false;
    }

  if (m_mode == QUEUE_MODE_BYTES && (m_bytesInQueue + p->GetSize () >= m_maxBytes))
    {
      NS_LOG_LOGIC ("Queue full (packet would exceed max bytes) -- droppping pkt");
      Drop (p);
      return false;
    }

  m_bytesInQueue += p->GetSize ();
  m_packets.push (p);

  NS_LOG_LOGIC ("Number packets " << m_packets.size ());
  NS_LOG_LOGIC ("Number bytes " << m_bytesInQueue);

  return true;
}

Ptr<Packet>
MirageQueue::DoDequeue (void)
{
  NS_LOG_FUNCTION (this);

  if (m_packets.empty ())
    {
      NS_LOG_LOGIC ("Queue empty");
      return 0;
    }

  Ptr<Packet> p = m_packets.front ();
  m_packets.pop ();
  m_bytesInQueue -= p->GetSize ();

  NS_LOG_LOGIC ("Popped " << p);

  NS_LOG_LOGIC ("Number packets " << m_packets.size ());
  NS_LOG_LOGIC ("Number bytes " << m_bytesInQueue);

  if (!this->m_unblockCallback.IsNull ()) {
     Simulator::ScheduleNow(&MirageQueue::NotifyQueueEmpty, this);
  }
  return p;
}

void
MirageQueue::NotifyQueueEmpty() {
  this->m_unblockCallback(this->m_device);
}

Ptr<const Packet>
MirageQueue::DoPeek (void) const
{
  NS_LOG_FUNCTION (this);

  if (m_packets.empty ())
    {
      NS_LOG_LOGIC ("Queue empty");
      return 0;
    }

  Ptr<Packet> p = m_packets.front ();

  NS_LOG_LOGIC ("Number packets " << m_packets.size ());
  NS_LOG_LOGIC ("Number bytes " << m_bytesInQueue);

  return p;
}

void 
MirageQueue::SetUnblockCallback(QueueUnblockCallback cb, Ptr<NetDevice> dev) {
  this->m_unblockCallback = cb;
  this->m_device = dev;
}

} // namespace ns3
