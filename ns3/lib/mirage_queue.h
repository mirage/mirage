/* -*- Mode:C++; c-file-style:"gnu"; indent-tabs-mode:nil; -*- */
/*
 * Copyright (c) 2007 University of Washington
 * Copyright (c) 2012 Charalmpos Rotsos <cr409@cl.cam.ac.uk>
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License version 2 as
 * published by the Free Software Foundation;
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
 */

// The queue base class does not have any limit based on the number
// of packets or number of bytes. It is, conceptually, infinite 
// by default. Only subclasses define limitations.
// The base class implements tracing and basic statistics calculations.

#ifndef MIRAGE_QUEUE_H
#define MIRAGE_QUEUE_H

#include <queue>
#include <ns3/packet.h>
#include <ns3/queue.h>
#include <ns3/net-device.h>
#include <ns3/log.h>

namespace ns3 {

class TraceContainer;

/**
 * \ingroup queue
 *
 * \brief A FIFO packet queue that drops tail-end packets on overflow
 */
class MirageQueue : public Queue {

public:
  enum QueueMode
  {
    QUEUE_MODE_PACKETS,     /**< Use number of packets for maximum queue size */
    QUEUE_MODE_BYTES,       /**< Use number of bytes for maximum queue size */
  };


  typedef Callback< bool, Ptr<NetDevice> > QueueUnblockCallback;

  static TypeId GetTypeId (void);
  /**
   * \brief MirageQueue Constructor
   *
   * Creates a droptail queue with a maximum size of 100 packets by default
   */
  MirageQueue ();

  virtual ~MirageQueue();

  /**
   * Set the operating mode of this device.
   *
   * \param mode The operating mode of this device.
   *
   */
  void SetMode (MirageQueue::QueueMode mode);

  /**
   * Get the encapsulation mode of this device.
   *
   * \returns The encapsulation mode of this device.
   */
  MirageQueue::QueueMode GetMode (void);

  void SetUnblockCallback(QueueUnblockCallback cb, Ptr<NetDevice> dev);

private:
  virtual bool DoEnqueue (Ptr<Packet> p);
  virtual Ptr<Packet> DoDequeue (void);
  virtual Ptr<const Packet> DoPeek (void) const;
  void NotifyQueueEmpty(void);

  std::queue<Ptr<Packet> > m_packets;
  uint32_t m_maxPackets;
  uint32_t m_maxBytes;
  uint32_t m_bytesInQueue;
  QueueMode m_mode;
  MirageQueue::QueueUnblockCallback m_unblockCallback;
  Ptr<NetDevice> m_device;
};

} // namespace ns3

#endif /* MIRAGE_QUEUE_H */
