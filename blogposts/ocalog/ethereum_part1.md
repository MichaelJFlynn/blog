Ethereum is a cryptocurrency where code can be executed on the
blockchain. This capability allows "smart contracts" to be written
which execute themselves automatically. About a year ago, a smart
contract called the DAO blew up spectacularly when someone figured out
how to manipulate it into giving them what was then $41 million worth
of Eth. This caused a fracturing of the network when people decided to
"fork" the blockchain to one where the DAO attack never happened.
When I first heard about this, I thought "that sounds like so much
fun" but I haven't had time to gain a deep understanding of how it
works, until now. This is the first post in a series on the full
implementation of the Ethereum protocol from a beginner's perspective.
After this first post, I plan to write these posts in digestible
chunks so that you don't have to spend too much time reading them
every day, but over time you will gain a deeper understanding of
Ethereum.

I'm going to assume the reader has a basic understanding of Python,
git, knowledge (not expertise) of network concepts like TCP and UDP,
and no fear of working with raw bytes. Other than that I will try to
assume nothing. Today I will start with a conceptual introduction to
cryptocurrency, then set up a Python development environment, and
finally implement `ping` on the Ethereum network. Let's get started.

### The concept of cryptocurrency

A cryptocurrency is a means of storing and transferring value
electronically without a central settlement mechanism. A central
settlement mechanism keeps track of all accounts, updates them for
each transaction, and acts as a trusted third party for all
transactions. In the United States, the Federal Reserve System is the
central settlement mechanism. All banks have accounts at the Fed and
use its authority to settle transactions between accounts. Without
centralized settlement, it is hard for parties to prove to one another
that they own what they say they do - they could be lying.

Cryptocurrencies solve the settlement problem without a central
authority by having everyone keep a record of how much everyone else
owns. To keep consensus after a transaction happens, updates are
broadcast to the network along with a solved math problem and everyone
agrees to always update to the longest ledger. As long as greater than
50% of the network is playing by the rules, this strategy works
because working together solves the math problem faster than working
alone, and therefore generates the longest chain. A consensus update
to the "blockchain" is proof that a transaction was valid and actually
took place.

Therefore, to implement a cryptocurrency, we will need to figure out
how to talk to our peers, how the transactions are stored, and how to
solve the math problem with everyone else.

### Setting up a development environment

For OS, I'm using Amazon Linux, which is basically Red Hat, on an EC2
instance, but you should be able to do what I'm doing on any Linux or
OSX.

Let's make a virtual environment for this project:

    [eth ~]$ virtualenv pyeth
    New python executable in pyeth/bin/python2.7
    Also creating executable in pyeth/bin/python
    Installing setuptools, pip...done.

This will create an empty Python environment into which libraries can
be installed. This will make sure that we are all on the same page to
start.

To activate the virtual environment, use the command 

    [eth ~]$ source pyeth/bin/activate

This changes some environment variables so that the Python executable
used is the one in the virtual environment, only packages in the
virtual environment are loadable, and `pip` will install to the
virtualenv. You can check this worked by doing `which python` which
should show a path to the virtual environment:

    (pyeth)[eth ~]$ which python
    ~/pyeth/bin/python

To not have to activate the virtual environment every time I log in, I
like to add the following lines to `~/.bashrc`:

    source ~/pyeth/bin/activate

This loads whenever you start a shell. It's a nice shortcut while you
work on the project.

Note about Python versions: I'm using Python 2.7.12, and I can't
guarantee this tutorial will work the same with different versions.

    (pyeth)[eth ~]$ python --version
    Python 2.7.12

One last thing I'm going to do is set up a package skeleton with the
`cookiecutter` pip library.

    (pyeth)[eth ~]$ pip install cookiecutter

I'm going to be using
a
[minimal skeleton](https://github.com/wdm0006/cookiecutter-pipproject)
that enables pip publishing and testing.

    (pyeth)[eth pyeth]$ cookiecutter gh:wdm0006/cookiecutter-pipproject

This line should prompt you to answer some questions. I called my
project `pyethtutorial`. After this was done, I set up git to track my
project [here](https://github.com/MichaelJFlynn/PyEthTutorial).

Let's also install the `nose` package for tests:

    (pyeth)[eth pyeth]$ pip install nose

Now let's see if the test cases work. In `pyethtutorial/tests` there
is one test, which is set up to pass:

    def test_pass():
            assert True, "dummy sample test"

To run all tests, use the `nosetests` command in the package directory:

    (pyeth)[eth pyethtutorial]$ nosetests
    .
    ----------------------------------------------------------------------
    Ran 1 test in 0.003s
    
    OK

Alright, I think we're ready to go.

### Starting the implementation

We want to figure out how to talk to the other nodes. Googling, I've
found documentation on
the
[Ethereum Wire Protocol](https://github.com/ethereum/wiki/wiki/Ethereum-Wire-Protocol):

> Peer-to-peer communications between nodes running Ethereum clients run using the underlying [ÐΞVp2p Wire Protocol](https://github.com/ethereum/wiki/wiki/%C3%90%CE%9EVp2p-Wire-Protocol).
>### **Basic Chain Syncing**
>- Two peers connect & say Hello and send their Status message. Status includes the Total Difficulty(TD) & hash of their best block.

which leads me to
the
[devp2p wire protocol docs](https://github.com/ethereum/wiki/wiki/%C3%90%CE%9EVp2p-Wire-Protocol):

> ÐΞVp2p nodes communicate by sending messages using RLPx, an encrypted
> and authenticated transport protocol. Peers are free to advertise and
> accept connections on any TCP ports they wish, however, a default port
> on which the connection may be listened and made will be 30303. Though
> TCP provides a connection-oriented medium, ÐΞVp2p nodes communicate in
> terms of packets. RLPx provides facilities to send and receive
> packets. For more information about RLPx, refer to the [protocol
> specification](https://github.com/ethereum/devp2p/tree/master/rlpx.md).
> 
> ÐΞVp2p nodes find peers through the RLPx discovery protocol DHT. Peer
> connections can also be initiated by supplying the endpoint of a peer
> to a client-specific RPC API.

So we're sending packets, by default over port 30303, using this RLPx
protocol. The `devp2p` protocol has 2 different modes: the main
protocol which uses TCP, and the discovery protocol which uses UDP. I
just want to figure out how to "find peers" using the discovery
protocol "DHT"
today. DHT
[stands](https://www.maketecheasier.com/how-bittorrent-dht-peer-discovery-works/) for
"Distributed Hash Table". You connect to designated servers called
"bootstrap nodes" (for BitTorrent those servers are
`router.bittorrent.com` and `router.utorrent.com`) who give you a
small list of peers to connect to. Once you have those peers, you can
connect to them and they'll share their peers with you and so on until
you have a full list of peers on the network.

Sounds simple enough, but let's keep it even simpler. In
the
[RLPx specification](https://github.com/ethereum/devp2p/tree/master/rlpx.md) referenced
in the last blockquote, there is a section called "Node Discovery". It
lays out how the messages are sent over UDP port 30303 and specifies
the following packet structure:

    hash || signature || packet-type || packet-data
	    hash: sha3(signature || packet-type || packet-data)	// used to verify integrity of datagram
	    signature: sign(privkey, sha3(packet-type || packet-data))
	    signature: sign(privkey, sha3(pubkey || packet-type || packet-data)) // implementation w/MCD
	    packet-type: single byte < 2**7 // valid values are [1,4]
	    packet-data: RLP encoded list. Packet properties are serialized in the order in which they're defined. See packet-data below.

and the different types of packets:

    All data structures are RLP encoded.
    Total payload of packet (excluding IP headers) must be no greater than 1280 bytes.
    NodeId: The node's public key.
    inline: Properties are appened to current list instead of encoded as list.
    Maximum byte size of packet is noted for reference.
    timestamp: When packet was created (number of seconds since epoch).
    
    PingNode packet-type: 0x01
    struct PingNode
    {
    	h256 version = 0x3;
    	Endpoint from;
    	Endpoint to;
    	uint32_t timestamp;
    };
    
    Pong packet-type: 0x02
    struct Pong
    {
    	Endpoint to;
    	h256 echo;
    	uint32_t timestamp;
    };
    
    FindNeighbours packet-type: 0x03
    struct FindNeighbours
    {
    	NodeId target; // Id of a node. The responding node will send back nodes closest to the target.
    	uint32_t timestamp;
    };
    
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
    
    struct Endpoint
    {
    	bytes address; // BE encoded 4-byte or 16-byte address (size determines ipv4 vs ipv6)
    	uint16_t udpPort; // BE encoded 16-bit unsigned
    	uint16_t tcpPort; // BE encoded 16-bit unsigned
    }

The message types are represented by C-like structs of data. The
simplest thing we could do today is implementing `PingNode`, which is
composed of a `version`, two `EndPoint` objects, and a
`timestamp`. The `EndPoint` objects are composed of an IP address, and
two integers representing the UDP and TCP ports, respectively.

To send these over the wire, these structs are put into "RLP",
"recursive length prefix" encoding. In
the [docs](https://github.com/ethereum/wiki/wiki/RLP), it states:

> The RLP encoding function takes in an item. An item is defined as follows:
> 
> - A string (ie. byte array) is an item
> - A list of items is an item
>
> RLP encoding is defined as follows:
>
> - For a single byte whose value is in the `[0x00, 0x7f]` range, that byte is its own RLP encoding.
> - Otherwise, if a string is 0-55 bytes long, the RLP encoding consists of a single byte with value `0x80` plus the length of the string followed by the string. The range of the first byte is thus `[0x80, 0xb7]`.
> - If a string is more than 55 bytes long, the RLP encoding consists of a single byte with value `0xb7` plus the length in bytes of the length of the string in binary form, followed by the length of the string, followed by the string. For example, a length-1024 string would be encoded as `\xb9\x04\x00` followed by the string. The range of the first byte is thus `[0xb8, 0xbf]`.
> - If the total payload of a list (i.e. the combined length of all its items) is 0-55 bytes long, the RLP encoding consists of a single byte with value 0xc0 plus the length of the list followed by the concatenation of the RLP encodings of the items. The range of the first byte is thus `[0xc0, 0xf7]`.
> - If the total payload of a list is more than 55 bytes long, the RLP encoding consists of a single byte with value `0xf7` plus the length in bytes of the length of the payload in binary form, followed by the length of the payload, followed by the concatenation of the RLP encodings of the items. The range of the first byte is thus `[0xf8, 0xff]`.

Before anything can be converted to RLP-encoding, first you need to
convert the struct into an "item": either a string or a list of items
(the definition is recursive). The output is then of the form
&lt;LENGTH&gt;&lt;BYTES&gt;, thus the name "recursive length prefix".
As it says in the docs, RLP just encodes "structure", and leaves the
interpretation of the "BYTES" to the higher-order protocol.

Since I'd rather get going on implementing the protocol itself, I'm
going to use the `rlp` library, with its functions `encode` and
`decode`, to do the RLP encoding. Use `pip install rlp` to get it in
your local package.

We have everything we need to send a `PingNode` packet. In the Python
program coming up, we will make a `PingNode`, pack it, and send it to
ourselves. To pack the data, we'll start with the RLP-encoded value of
the struct, add a byte to denote the type of the struct, append the
cryptographic signature, and finally add a hash to verify the packet
integrity. Let's write our python program.

In `pyethtutorial/discovery.py`:

    import socket
    import threading
    import time
    import struct
    import rlp
    from crypto import keccak256
    from secp256k1 import PrivateKey
    from ipaddress import ip_address
    
    class EndPoint(object):
        def __init__(self, address, udpPort, tcpPort):
            self.address = ip_address(address)
            self.udpPort = udpPort
            self.tcpPort = tcpPort
    
        def pack(self):
            return [self.address.packed,
                    struct.pack(">H", self.udpPort),
                    struct.pack(">H", self.tcpPort)]
    
The first class is an `EndPoint` class according to the
specification. The ports are expected to be integers and the address
is expected to be in the "dot" format "127.0.0.1". The address is
passed to the `ipaddress` library so we can use its utility functions,
for example converting the "dot" representation to binary format,
which is what I do in the `pack` method. Use `pip install ipaddress`
to install this package. The `pack` method prepares the object to be
consumed by `rlp.encode`, converting it to a list of strings. In the
`EndPoint` specification, it demands the "BE encoded 4-byte" address,
which is exactly what's outputted by `self.address.packed`. For the
ports, the RLP specification page demands "Ethereum integers must be
represented in big endian binary form with no leading zeroes", and the
`Endpoint` specification lists their datatypes as `uint16_t`, or
unsigned 16-bit integers. So, I use the `struck.pack` method with the
format string `>H`, which means "big-endian unsigned 16-bit integer"
according to
the
[documentation page](https://docs.python.org/2/library/struct.html).

    class PingNode(object):
        packet_type = '\x01';
        version = '\x03';
        def __init__(self, endpoint_from, endpoint_to):
            self.endpoint_from = endpoint_from
            self.endpoint_to = endpoint_to
    
        def pack(self):
            return [self.version,
                    self.endpoint_from.pack(),
                    self.endpoint_to.pack(),
                    struct.pack(">I", time.time() + 60)]

The next class is the `PingNode` struct.  Instead of converting later,
I decided to enter in the raw byte values for `packet_type` and
`version` as constant fields. In the constructor, you need to pass in
the "from" and "to" endpoints, as listed in the specification. For the
`pack` method, we can use the raw value of `version`, since it's
already in bytes. For the endpoints, we can use their `pack` methods,
and for the timestamp, since its type is listed as `uint32_t`, or
"unsigned 32-bit integer", I'll use `struct.pack` with the format
string `>I` for "big endian unsigned 32-bit integer". I added 60 to
the time stamp to give an extra 60 seconds for this packet to arrive
at the destination (specification says that packets received with
timestamps in the past are dropped to
prevent
[replay attacks]( https://en.wikipedia.org/wiki/Replay_attack)).
    
    class PingServer(object):
        def __init__(self, my_endpoint):
            self.endpoint = my_endpoint
    
            ## get private key
            priv_key_file = open('priv_key', 'r')
            priv_key_serialized = priv_key_file.read()
            priv_key_file.close()
            self.priv_key = PrivateKey()
            self.priv_key.deserialize(priv_key_serialized)

    
        def wrap_packet(self, packet):
            payload = packet.packet_type + rlp.encode(packet.pack())
            sig = self.priv_key.ecdsa_sign_recoverable(keccak256(payload), raw = True)
            sig_serialized = self.priv_key.ecdsa_recoverable_serialize(sig)
            payload = sig_serialized[0] + chr(sig_serialized[1]) + payload
    
            payload_hash = keccak256(payload)
            return payload_hash + payload
    
        def udp_listen(self):
            sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
            sock.bind(('0.0.0.0', self.endpoint.udpPort))
    
            def receive_ping():
                print "listening..."
                data, addr = sock.recvfrom(1024)
                print "received message[", addr, "]"
    
            return threading.Thread(target = receive_ping)
    
        def ping(self, endpoint):
            sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
            ping = PingNode(self.endpoint, endpoint)
            message = self.wrap_packet(ping)
            print "sending ping."
            sock.sendto(message, (endpoint.address.exploded, endpoint.udpPort))

The last class is `PingServer`. This class opens the sockets, signs,
and hashes the messages, and sends them to other servers. The
constructor takes an `EndPoint` object, which is "itself" in the
network space. The server will use this as a "from" address when
sending packets. The other thing that happens when a server is created
is that the server's private key is loaded - which we need to create
for the first time!

Ethereum uses [secp256k1](https://en.bitcoin.it/wiki/Secp256k1), an
elliptic curve, for asymmetric encryption. The Python library that
implements it
is [secp256k1-py]( https://github.com/ludbb/secp256k1-py). You can
install the library with `pip install secp256k1`.

To generate a private key, call the `PrivateKey` constructor with
`None` as an argument and then write the `serialize()` output to a
file:

    >>> from secp256k1 import PrivateKey
    >>> k = PrivateKey(None)
    >>> f = open("priv_key", 'w')
    >>> f.write(k.serialize())
    >>> f.close()

I do this in the same directory as the source files for now. Make sure
you add this file to `.gitignore` if you are using git so you don't
accidentally publish it.

The `wrap_packet` method encodes the packet:

> hash || signature || packet-type || packet-data

The first thing to do is append the packet type to the RLP encoding of
the packet data. Then the hashed payload is signed using the private
key's `ecdsa_sign_recoverable` function. The `raw` parameter is set to
`True` because we've done the hashing ourselves (otherwise the
function would have used its own hash function). Then we serialize the
signature and append it to the front of the payload. The serialized
signature is a tuple with two parts, and the second needs to be
converted to a string using `chr` (this tripped me up in the
beginning). Finally, the entire payload is hashed, and that hash is
appended to the front and the packet is ready to be sent.

You might have noticed we haven't defined the `keccak256` function
yet. Ethereum uses
a
[non-standard sha3 algorithm called keccak-256](https://ethereum.stackexchange.com/questions/550/which-cryptographic-hash-function-does-ethereum-use). The
Python library `pysha3` implements it. Use `pip install pysha3` to
install.

In `pyethtutorial/crypto.py`, we define `keccak256`:
    
    import hashlib
    import sha3
    
    ## Ethereum uses the keccak-256 hash algorithm
    def keccak256(s):
        k = sha3.keccak_256()
        k.update(s)
        return k.digest()

This function is pretty straightforward. 

Back to `PingServer`. The next function, `udp_listen`, listens for
incoming transmissions. It creates a `socket` object that binds to the
server endpoint's UDP port. I then define a function called
`receive_ping` that listens at the socket for incoming data, prints
out the receipt of a transmission, and then returns. The method
returns a `Thread` object that will run `receive_ping`, so we can send
pings at the same time.

The last method `ping` takes a destination endpoint as input, creates a
`PingNode` object to that endpoint, creates a message using
`wrap_packet` and sends it using UDP.

Now we can set up a script that will send some packets. In the file
`send_ping.py`:

    from discovery import EndPoint, PingNode, PingServer
    
    my_endpoint = EndPoint(u'52.4.20.183', 30303, 30303)
    their_endpoint = EndPoint(u'127.0.0.1', 30303, 30303)
    
    server = PingServer(my_endpoint)
    
    listen_thread = server.udp_listen()
    listen_thread.start()
    
    server.ping(their_endpoint)

When I run this code I get the following output:

    (pyeth)[eth pyethtutorial]$ python send_ping.py
    sending ping
    listening...
    received message[ ('127.0.0.1', 41948) ]

I've successfully pinged myself. I have not connected to any of the
bootstrap nodes, that is the plan for the next post. Stay tuned for
the next part in this series!

**Do you like writing in-depth articles? Ocalog is a platform to help
you get paid for it, so you can afford to spend the time doing
it. Consider joining!**
