This is part 4 of my series on implementing the full Ethereum protocol from scratch ([part 1](https://ocalog.com/post/10/), [part 2](https://ocalog.com/post/18/), [part 3](https://ocalog.com/post/20/)). By the end of this tutorial series, you will be able to crawl the Ethereum network for peers, sync and verify the blockchain, write smart contracts for the Ethereum virtual machine, and mine ether. We are currently implementing the first part, the discovery protocol. Once this is done, we can download the blockchain using a torrent-like process. Last time we decoded and verified the bootnode's `Pong` response to our `Ping`. Today we will implement the `FindNeighbors` request and the `Neighbors` response, which we will use to crawl the Ethereum network. 

This should be as simple as defining class structures for `FindNeighbors` and `Neighbors` packets, and sending them the same way we did for `PingNode` and `Pong`. However, there are requirements that need to be fulfilled before a `FindNeighbors` packet can be sent. We haven't seen these requirements in the documentation because the documentation is behind the source code. In the [go-ethereum source code](https://github.com/ethereum/go-ethereum), the discovery protocol is on version 4, while the [RLPx specification](https://github.com/ethereum/devp2p/blob/master/rlpx.md) (which we implemented) is only on version 3. There is even a [discv5](https://github.com/ethereum/go-ethereum/tree/master/p2p/discv5) module, which would indicate that `v5` is being worked on, but checking the `version` byte of `Ping`s from the bootnode indicates they are still running `v4`.

One result of the `v4` protocol is that a UDP "handshake" must occur in order to get a response to a `FindNeighbors` request. This is visible in the source code file [udp.go](https://github.com/ethereum/go-ethereum/blob/master/p2p/discover/udp.go): 

    func (req *findnode) handle(t *udp, from *net.UDPAddr, fromID NodeID, mac []byte) error {
	    if expired(req.Expiration) {
		    return errExpired
	    }
	    if t.db.node(fromID) == nil {
		    // No bond exists, we don't process the packet. This prevents
		    // an attack vector where the discovery protocol could be used
		    // to amplify traffic in a DDOS attack. A malicious actor
		    // would send a findnode request with the IP address and UDP
		    // port of the target as the source address. The recipient of
		    // the findnode packet would then send a neighbors packet
		    // (which is a much bigger packet than findnode) to the victim.
		    return errUnknownNode
	    }
To handle a `findnode` packet (the Go implementation's name for  `FindNeighbors`), first the code checks whether the source of the request, `fromID`, is in its record of known nodes. If not, it drops the request (something that continuously happend to my requests until I figured this out). 

To become a known node, first we must `ping` the bootnode. When the bootnode receives the `ping`, it will send a `pong`, then a `ping `, and will await a `pong` from us. Once we respond with a `pong`, our `nodeID` is entered into the bootnode's list of known nodes.  

Therefore, to be able to send `FindNeighbors` packets, we'll need to create `FindNeighbors` and `Neighbors` classes with the same functionality as `PingNode` and `Pong` packets.  Then we'll need to add a `Pong` response to `receive_ping` for the bootnode UDP handshake. Then we'll need to adjust `PingServer` to continuously listen for packets. Finally, we'll need to adjust our `send_ping.py` script to send a ping, allow enough time for the bootnode to respond with a `pong` and `ping`, and assuming we've implemented the `pong` response correctly after that, send a `FindNeighbors` packet and receive the `Neighbors` response. 


### Maching starting points
To match starting points, check out the `part3` branch of  the series github repository:

    git clone git@github.com:MichaelJFlynn/pyethtutorial
    cd pyethtutorial
    git checkout part3

Install all dependencies:

    pip install --upgrade pip
    pip install -r requirements.txt

Make sure that `priv_key` is saved in the source directory (also named `pyethtutorial`). If not, `cd pyethtutorial` and create the private key using Python:

    from secp256k1 import PrivateKey
    k = PrivateKey(None)
    f = open("priv_key", 'w')
    f.write(k.serialize())
    f.close()

Run `python send_ping.py`. You should see:

    sending (Ping 3 (EP 52.4.20.183 30303 30303) (EP 13.93.211.84 30303 30303) 1502910554.48)
    listening...
    received message[ ('13.93.211.84', 30303) ]:
     Verified message hash.
     Verified signature.
     received Pong
     (Pong (EP 52.4.20.183 30303 30303) <echo hash> 1502910514)

We are at the point we left off, a successful decoding of the `Pong` response.

### Creating `FindNeighbors` and `Neighbors` classes

In this section we create Python classes for `FindNeighbors` and `Neighbors` in the same we we created classes for `PingNode` and `Pong` in the previous parts of this series. For each, we create `__init__`, `__str__`, `pack`, and `unpack` methods, and add `receive_` methods in the `PingServer` class. 

For `FindNeighbors`, the packet structure from the [specification](https://github.com/ethereum/devp2p/blob/master/rlpx.md) is:

    FindNeighbours packet-type: 0x03
    struct FindNeighbours
    {
    	NodeId target; // Id of a node. The responding node will send back nodes closest to the target.
    	uint32_t timestamp;
    };

`target` is a `NodeId` type, which is a 64 byte public key. This means we can store/retrieve it as-is in the `pack` and `unpack` methods. For `__str__`, I'll use `binascii.b2a_hex` which prints the bytes in hex format. Otherwise, the code is similar to what you've seen with `PingNode` and `Pong`. So, in `discovery.py` we write:

    class FindNeighbors(object):
        packet_type = '\x03'
    
        def __init__(self, target, timestamp):
            self.target = target
            self.timestamp = timestamp
    
        def __str__(self):
            return "(FN " + binascii.b2a_hex(self.target)[:7] + "... " + str(self.ti\
    mestamp) + ")"
    
        def pack(self):
            return [
                self.target,
                struct.pack(">I", self.timestamp)
            ]
    
        @classmethod
        def unpack(cls, packed):
            timestamp = struct.unpack(">I", packed[1])[0]
            return cls(packed[0], timestamp)

For `Neighbors`, the packet structure is:

    Neighbors packet-type: 0x04
    struct Neighbours
    {
    	list nodes: struct Neighbour
    	{
    		inline Endpoint endpoint;
    		NodeId node;
    	};
    	
    	uint32_t timestamp;
    };

This requires that we define a class called `Neighbor`, which I'm going to define after this, renamed `Node`. For `Neighbors`, the only new concept is that `nodes` is a list, so we'll be using `map` to pack and unpack the data:

    class Neighbors(object):
        packet_type = '\x04'
    
        def __init__(self, nodes, timestamp):
            self.nodes = nodes
            self.timestamp = timestamp
    
        def __str__(self):
            return "(Ns [" + ", ".join(map(str, self.nodes)) + "] " + str(self.times\
    tamp) + ")"
    
        def pack(self):
            return [
                map(lambda x: x.pack(), self.nodes),
                struct.pack(">I", self.timestamp)
            ]
    
        @classmethod
        def unpack(cls, packed):
            nodes = map(lambda x: Node.unpack(x), packed[0])
            timestamp = struct.unpack(">I", packed[1])[0]
            return cls(nodes, timestamp)

For `Node`, the only new concept is that `endpoint` is packed "inline", so instead of `endpoint.pack()` becoming a individual list item, the `nodeID` is appended to its packed form:

    class Node(object):
    
        def __init__(self, endpoint, node):
            self.endpoint = endpoint
            self.node = node
    
        def __str__(self):
            return "(N " + binascii.b2a_hex(self.node)[:7] + "...)"
    
        def pack(self):
            packed  = self.endpoint.pack()
            packed.append(node)
            return packed

        @classmethod
        def unpack(cls, packed):
            endpoint = EndPoint.unpack(packed[0:3])
            return cls(endpoint, packed[3])



For the new packet classes, let's define new `PingServer` methods for receiving the packets, leaving them simple for now:

    def receive_find_neighbors(self, payload):
        print " received FindNeighbors"
        print "", FindNeighbors.unpack(rlp.decode(payload))

    def receive_neighbors(self, payload):
        print " received Neighbors"
        print "", Neighbors.unpack(rlp.decode(payload))

Let's also adjust the `response_types` dispatch table in `PingServer` method `receive`: 

    response_types = {
        PingNode.packet_type : self.receive_ping,
        Pong.packet_type : self.receive_pong,
        FindNeighbors.packet_type : self.receive_find_neighbors,
        Neighbors.packet_type : self.receive_neighbors
    }



### Making the server listen continuously

There are several items to tackle in order to make the server listen to packets continuously:

- Now that there is more general functionality demanded from `PingServer`, let's rename it to `Server`. 
- Let's make the server socket non-blocking by setting `self.sock.setblocking(0)`.
- Let's move all code above `#verify hash` from `receive` to a new `listen` method, and add a `data` parameter to `receive`.  This new `listen` function runs a loop to wait for packets to arrive with `select` and responds to them with `receive`. The `select` function waits for a resource to become available, with an optional timeout.
- Let's increase the number of bytes we read from the socket to 2048, since some Ethereum packets are larget than 1024 bytes long. 
- Let's replace `udp_listen`  with `listen_thread`, which in addition to returning the thread object, sets its `daemon` field to `True`, which means the process will end even if the listen thread is still running (before it would cause the shell to hang). 

The final states of the relevant code sections are below:

    ...
    import select
    ...
    class Server(object):
    
        def __init__(self, my_endpoint):
            ...
            ## set socket non-blocking mode
            self.sock.setblocking(0)

        ...
        def receive(self, data):
            ## verify hash
            msg_hash = data[:32]
            ...

        ...
        def listen(self):
            print "listening..."
            while True:
                ready = select.select([self.sock], [], [], 1.0)
                if ready[0]:
                    data, addr = self.sock.recvfrom(2048)
                    print "received message[", addr, "]:"
                    self.receive(data)

        ...
        def listen_thread(self):
            thread = threading.Thread(target = self.listen)
            thread.daemon = True
            return thread


### Responding to pings

We must modify the `receive_ping` method of the `Server` class to respond with a `Pong`. This will also require that we replace the `Server` method `ping` with a more general function `send`.  Where `ping` created a `PingNode` object and sent it, `send` takes a `packet` as a new argument, prepares it for sending, and sends it. 


    def receive_ping(self, payload, msg_hash):
        print " received Ping"
        ping = PingNode.unpack(rlp.decode(payload))
        pong = Pong(ping.endpoint_from, msg_hash, time.time() + 60)
        print "  sending Pong response: " + str(pong)
        self.send(pong, pong.to)
    ...

    def send(self, packet, endpoint):
        message = self.wrap_packet(packet)
        print "sending " + str(packet)
        self.sock.sendto(message, (endpoint.address.exploded, endpoint.udpPort))


Notice that there is a new `msg_hash` parameter to `receive_ping`. This needs to be put in the `dispatch` call in the `Server` method `receive ` and all the other `receive_` functions. 

    def receive_pong(self, payload, msg_hash):
    ...
    def receive_find_neighbors(self, payload, msg_hash):
    ...
    def receive_neighbors(self, payload, msg_hash):
    ...
    def receive(self, data):
        ## verify hash
        msg_hash = data[:32]
        ...
        dispatch(payload, msg_hash)

### Miscellaneous fixes 

Since the  bootnodes are using the `v4` version of the RLPx protocol, while the specification and our implementation is `v3`,  we need to comment out the assertion that `packed[0]==cls.version` for the `PingNode` `unpack` method. I'm reluctant to change the actual version  of the class until I can find centralized documentation on the new version. In previous articles, I also forgot to  include the unpacked `timestamp` in the params to `cls`, so make sure your `unpack` method looks like below:

    @classmethod
    def unpack(cls, packed):
        ## assert(packed[0] == cls.version)
        endpoint_from = EndPoint.unpack(packed[1])
        endpoint_to = EndPoint.unpack(packed[2])
        timestamp = struct.unpack(">I", packed[3])[0]
        return cls(endpoint_from, endpoint_to, timestamp)

Another change that happened in `v4` is that the second argument to the encoding of `EndPoint` is optional, and so you need to account for that in the `unpack` method. If it is missing, you set `tcpPort` equal to `udpPort`.

    @classmethod
    def unpack(cls, packed):
        udpPort = struct.unpack(">H", packed[1])[0]
        if packed[2] == '':
            tcpPort = udpPort
        else:
            tcpPort = struct.unpack(">H", packed[2])[0]
        return cls(packed[0], udpPort, tcpPort)

One last fix is that in previous versions of this code, `Pong`'s `pack` method had a typo, where `timestamp` was referenced instead of `self.timestamp`. The problem wasn't found because we never sent a `Pong` message. Fixed below:

    def pack(self):
        return [
            self.to.pack(),
            self.echo,
            struct.pack(">I", self.timestamp)]


### Modifying `send_ping.py`

We must rewrite `send_ping.py` to account for the new sending process:

    from discovery import EndPoint, PingNode, Server, FindNeighbors, Node
    import time
    import binascii

    bootnode_key = "3f1d12044546b76342d59d4a05532c14b85aa669704bfe1f864fe079415aa2c02d743e03218e57a33fb94523adb54032871a6c51b2cc5514cb7c7e35b3ed0a99"

    bootnode_endpoint = EndPoint(u'13.93.211.84',
                        30303,
                        30303)

    bootnode = Node(bootnode_endpoint,
                    binascii.a2b_hex(bootnode_key))

    my_endpoint = EndPoint(u'52.4.20.183', 30303, 30303)    
    server = Server(my_endpoint)
    
    listen_thread = server.listen_thread()
    listen_thread.start()

    fn = FindNeighbors(bootnode.node, time.time() + 60)
    ping = PingNode(my_endpoint, bootnode.endpoint, time.time() + 60)
    
    ## introduce self
    server.send(ping, bootnode.endpoint)
    ## wait for pong-ping-pong
    time.sleep(3)
    ## ask for neighbors
    server.send(fn, bootnode.endpoint)
    ## wait for response
    time.sleep(3)

First we create a `Node` object from the bootnode we've been using as a first contact, grabbing the key from [params/bootnodes.go](https://github.com/ethereum/go-ethereum/blob/ff2c966e7f0550f4c0cb2b482d1af3064e6db0fe/params/bootnodes.go). We then create a server, start  a listen thread, and create `PingNode` and `FindNeighbors` packets. Then we `ping` the bootnode, for which we should receive a `pong`, then a `ping`, as part of the handshake process. We'll respond with a `pong` to become a recongnized node. Finally, we can send the `fn` packet. The bootnode should respond with a `Neighbors` response. 

Run `python send_ping.py`. You should see something like:

    (pyeth)[eth pyethtutorial]$ python send_ping.py
    sending (Ping 3 (EP 52.4.20.183 30303 30303) (EP 13.93.211.84 30303 30303) 1502819202.25)
    listening...
    received message[ ('13.93.211.84', 30303) ]:
     Verified message hash.
     Verified signature.
     received Pong
     (Pong (EP 52.4.20.183 30303 30303) <echo hash> 1502819162)
    received message[ ('13.93.211.84', 30303) ]:
     Verified message hash.
     Verified signature.
     received Ping
       sending Pong response: (Pong (EP 13.93.211.84 30303 30303) <echo hash> 1502819202.34)
    sending (Pong (EP 13.93.211.84 30303 30303) <echo hash> 1502819202.34)
    sending (FN 3f1d120... 1502983026.6)
    received message[ ('13.93.211.84', 30303) ]:
     Verified message hash.
     Verified signature.
     received Neighbors
     (Ns [(N 9e44f97...), (N 112917b...), (N ebf683d...), (N 2232e47...), (N f6ff826...), (N 7524431...), (N 804613e...), (N 78e5ce9...), (N c6dd88f...), (N 1dbf854...), (N 48a80a9...), (N 8b6c265...)] 1502982991)
    received message[ ('13.93.211.84', 30303) ]:
     Verified message hash.
     Verified signature.
     received Neighbors
     (Ns [(N 8567bc4...), (N bf48f6a...), (N f8cb486...), (N 8e7e82e...)] 1502982991)

The bootnode has responded to us with  16 neighbors, divided into 2 packets. 

Next time, we will build a process of crawling these neighbors until we have sufficient peers to sync the blockchain.

**Do you like writing in-depth articles? Do you have a podcast you're having trouble monetizing? Are you an artist that's been overlooked by Patreon?
 Ocalog is a platform to help you get paid. Consider joining!**
