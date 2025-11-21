This is part 2 of this series on implementing the full Ethereum protocol from scratch. Part 1 is available [here](https://ocalog.com/post/10/).  We are currently  implementing the "discovery" protocol of Ethereum so that we can find other nodes on the network. The discovery protocol is the UDP piece of the [RLPx](https://github.com/ethereum/devp2p/blob/master/rlpx.md) protocol, which specifies four messages: `PingNode`, `Pong`, `FindNeighbors`, and `Neighbors`. 

We left off with the ability to send a `PingNode` message to ourselves. Today we're going to try to ping a node on the Ethereum network. 

### Retracing our steps

To get the code from the end of the last post, clone the git repo and checkout the `part1` branch:

    git clone git@github.com:MichaelJFlynn/pyethtutorial
    cd pyethtutorial
    git checkout part1

Make sure all your packages are up to date:

    pip install --upgrade pip
    pip install -r requirements.txt

Now do

    cd pyethtutorial
    python send_ping.py

You should see something like

    sending ping.
    listening...
    received message[ ('127.0.0.1', 53042) ]

This is where we left off. 

### Trying to ping another node

A good set of candidates to direct our ping messages are the "bootstrap" nodes of the network. On the [Connecting to the network](https://github.com/ethereum/go-ethereum/wiki/Connecting-to-the-network) wiki page, it states:

>  In order to get going initially, geth uses a set of bootstrap nodes whose endpoints are recorded in the source code.

`geth` is the Go implementation of Ethereum, listed on Github as [go-ethereum](https://github.com/ethereum/go-ethereum). In that repository, the file [params/bootnodes.go](https://github.com/ethereum/go-ethereum/blob/ff2c966e7f0550f4c0cb2b482d1af3064e6db0fe/params/bootnodes.go) contains  lists of bootnodes for the different networks: "MainnetBootnodes", "TestnetBootnodes", "RinkebyBootnodes", and so on. All these nodes are listed in the [Ethereum enode format](https://github.com/ethereum/wiki/wiki/enode-url-format):

**public_key_hex@ip_address:port**

The main net nodes are listed below, hexes abbreviated as [..pub_key..] :

    var MainnetBootnodes = []string{
    
    	// Ethereum Foundation Go Bootnodes
    	"enode://[..pub_key..]@52.16.188.185:30303", // IE
    	"enode://[..pub_key..]@13.93.211.84:30303",  // US-WEST
    	"enode://[..pub_key..]@191.235.84.50:30303", // BR
    	"enode://[..pub_key..]@13.75.154.138:30303", // AU
    	"enode://[..pub_key..]@52.74.57.123:30303",  // SG
    
    	// Ethereum Foundation Cpp Bootnodes
    	"enode://[..pub_key..]@5.1.83.226:30303", // DE
    
    }

I'm going to pick the "US-WEST" address since I'm in the US.  The only code change is for `their_endpoint` in `send_ping.py` to use that IP address. 

    their_endpoint = EndPoint(u'13.93.211.84', 30303, 30303)

Here is `send_ping.py` now :

    from discovery import EndPoint, PingNode, PingServer
    
    my_endpoint = EndPoint(u'52.4.20.183', 30303, 30303)
    their_endpoint = EndPoint(u'13.93.211.84', 30303, 30303)
    
    server = PingServer(my_endpoint)
    
    listen_thread = server.udp_listen()
    listen_thread.start()
    
    server.ping(their_endpoint)

Let's try it out: 

    [eth pyethtutorial]$ python send_ping.py
    sending ping.
    listening...

It just hangs. What went wrong?

### The solution

It turns out that Ethereum nodes use the return address from the UDP header and not the `PingNode` "from" field to address return packets, and our UDP headers are not sending the correct return address.

Remember the printout for the received message in the "Retracing our steps" section? 

    received message[ ('127.0.0.1', 53042) ]

53042 is the port from the UDP header. The socket is sending the packet with that header because it isn't bound to any port beforehand.  I've annotated the problems with `PingServer` below:

    56    def udp_listen(self):
    57        ## socket created and bound to 30303
    58        sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
    59        sock.bind(('0.0.0.0', self.endpoint.udpPort))
    60
    61        def receive_ping():
    62            print "listening..."
    63            data, addr = sock.recvfrom(1024)
    64            print "received message[", addr, "]"
    65
    66        return threading.Thread(target = receive_ping)
    67
    68    def ping(self, endpoint):
    69        ## new socket: bad!
    70        sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
    71        ping = PingNode(self.endpoint, endpoint)
    72        message = self.wrap_packet(ping)
    73        print "sending ping."
    74        sock.sendto(message, (endpoint.address.exploded, endpoint.udpPort))

The problem is that `udp_listen` and `ping` use different sockets (created on lines 58 and 70), and the one used by `ping` is not bound to port 30303, so it uses an arbitrary port.

To fix this I need to create the port during the`__init__` method of the server. The final result looks something like this:

    class PingServer(object):
        def __init__(self, my_endpoint):
            self.endpoint = my_endpoint
    
            ## get private key
            priv_key_file = open('priv_key', 'r')
            priv_key_serialized = priv_key_file.read()
            priv_key_file.close()
            self.priv_key = PrivateKey()
            self.priv_key.deserialize(priv_key_serialized)
    
            ## init socket
            self.sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
            self.sock.bind(('0.0.0.0', self.endpoint.udpPort))
    
        def wrap_packet(self, packet):
            payload = packet.packet_type + rlp.encode(packet.pack())
            sig = self.priv_key.ecdsa_sign_recoverable(keccak256(payload), 
                                                       raw = True)
            sig_serialized = self.priv_key.ecdsa_recoverable_serialize(sig)
            payload = sig_serialized[0] + chr(sig_serialized[1]) + payload
    
            payload_hash = keccak256(payload)
            return payload_hash + payload
    
        def udp_listen(self):
            def receive_ping():
                print "listening..."
                data, addr = self.sock.recvfrom(1024)
                print "received message[", addr, "]"
    
            return threading.Thread(target = receive_ping)
    
        def ping(self, endpoint):
            ping = PingNode(self.endpoint, endpoint)
            message = self.wrap_packet(ping)
            print "sending ping."
            self.sock.sendto(message, (endpoint.address.exploded, endpoint.udpPort))

The socket is initialized in `__init__` and referenced in `udp_listen` and `ping`. 

Now let's try `send_ping.py`:

    [eth pyethtutorial]$ python send_ping.py
    sending ping.
    listening...
    received message[ ('13.93.211.84', 30303) ]

We got a message back from the bootstrap node! Great. 

That's it for today. Next post will be on decoding the responses. For the Part 2 code, check out the `part2` branch of the git repo:

    git clone git@github.com:MichaelJFlynn/pyethtutorial
    cd pyethtutorial
    git checkout part2

Thanks for reading.

**Do you like writing in-depth articles? Ocalog is a platform to help you get paid for it so you can afford to spend time doing it. Consider joining!**
