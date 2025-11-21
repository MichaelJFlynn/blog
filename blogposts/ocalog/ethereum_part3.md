This is the third part of my series on implementing the full Ethereum protocol from scrach ([part 1](https://ocalog.com/post/10/), [part 2](https://ocalog.com/post/18/)). We're currently implementing Ethereum's discovery protocol: the algorithms used to find other nodes to sync the blockchain with. We left off able to ping a bootnode: a node that is written into the source code as a starting point to find other nodes. It responded with a message, but we did not decode it. Today we will decode the bootnode's response.

### Retracing our steps

To match my starting point, checkout the `part2` branch of the series github repo:

    git clone git@github.com:MichaelJFlynn/pyethtutorial
    cd pyethtutorial/
    git checkout part2

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

    sending ping.
    listening...
    received message[ ('13.93.211.84', 30303) ]


We are where we left off: a successful ping of a bootnode, with a response.

### Unpacking data

In this section, we will write methods to unpack RLP encoded `PingNode` and `Pong` messages into Python objects. These methods will be used to read in the message data after the message hash and signature have been verified. We've already defined a class for `PingNode`, so I'll start with `Pong`. 

A `Pong` message is defined in the [RLPx specification](https://github.com/ethereum/devp2p/blob/master/rlpx.md) as:

    Pong packet-type: 0x02
    struct Pong
    {
        Endpoint to;
        h256 echo;
        uint32_t timestamp;
    };

Let's write a class that corresponds to this structure in `discovery.py`: 

    class Pong(object):
        packet_type = '\x02'
    
        def __init__(self, to, echo, timestamp):
            self.to = to
            self.echo = echo
            self.timestamp = timestamp
    
        def __str__(self):
            return "(Pong " + str(self.to) + " <echo hash> " + str(self.timestamp) + ")"
    
        def pack(self):
            return [
                self.to.pack(),
                self.echo,
                struct.pack(">I", timestamp)]
    
        @classmethod
        def unpack(cls, packed):
            to = EndPoint.unpack(packed[0])
            echo = packed[1]
            timestamp = struct.unpack(">I", packed[2])[0]
            return cls(to, echo, timestamp)

The class encodes the packet structure as a Python object, with `packet_type` as a class field and passing `to`, `echo`, and `timestamp` passed in via the `__init__` constructor.
I've added a `__str__` method to print the object, which requires that `to`, an `EndPoint` object, also has a `__str__` method. Let's define that:

    class EndPoint(object):
        ...    
        def __str__(self):
            return "(EP " + self.address.exploded + " " + str(self.udpPort) + " " +  str(self.tcpPort)  + ")"
        ...

This method prints the "exploded" format of the IP address  (127.0.0.1) , as well as the integer UDP and TCP ports. 

Back to the `Pong` class. As described in [Part 1](https://ocalog.com/post/10/)  and the RLP [specification](https://github.com/ethereum/wiki/wiki/RLP),  the `pack` method puts the object in `item` format, where `item` is a binary string or a list of `item`s, so that it can be consumed by `rlp.encode`. We need to encode `to`, `echo`, and  `timestamp`. For `to`, we can use `to.pack()`, since the definition of `item` is recursive. Next, `echo` is already a string of bytes so it can be used as its own encoding. Finally, I use `struct.pack` with `>I` to encode the timestamp as a big endian unsigned 32 bit integer.

The `unpack` method is the inverse of `pack`. Here we decode `to`, `echo`, and timestamp. 
For `to`, we decode using an `EndPoint` classmethod I define below:

    class EndPoint(object):
        ...
        @classmethod
        def unpack(cls, packed):
            udpPort = struct.unpack(">H", packed[1])[0]
            tcpPort = struct.unpack(">H", packed[2])[0]
            return cls(packed[0], udpPort, tcpPort)

The `tcpPort` and `udpPort` are retrieved using `struct.unpack` for big endian 16 bit integers. The IP-address is passed in byte string format, which is handled by the  `ip_address` constructor.

Since `echo` is defined as a `h256`, a hash of 256 bytes, it can be unpacked as itself. The `timestamp` is unpacked using `struct.unpack` for a big-endian 32-bit integer. 

We also need to define  `__str__` and `unpack` method for `PingNode`. I also move the `timestamp`  parameter from the `pack` method to the constructor. The result is:

    class PingNode(object):
        packet_type = '\x01';
        version = '\x03';
        def __init__(self, endpoint_from, endpoint_to, timestamp):
            self.endpoint_from = endpoint_from
            self.endpoint_to = endpoint_to
            self.timestamp = timestamp
    
        def __str__(self):
            return "(Ping " + str(ord(self.version)) + " " + str(self.endpoint_from) + " " + str(self.endpoint_to) + " " +  str(self.timestamp) + ")"
    
    
        def pack(self):
            return [self.version,
                    self.endpoint_from.pack(),
                    self.endpoint_to.pack(),
                    struct.pack(">I", self.timestamp)]
    
        @classmethod
        def unpack(cls, packed):
            assert(packed[0] == cls.version)
            endpoint_from = EndPoint.unpack(packed[1])
            endpoint_to = EndPoint.unpack(packed[2])
            return cls(endpoint_from, endpoint_to)


The change to the `PingNode` constructor needs to be propogated through to the `ping` method of `PingServer`: 

    def ping(self, endpoint):
        ping = PingNode(self.endpoint, endpoint, time.time() + 60)
        message = self.wrap_packet(ping)
        print "sending " + str(ping)
        self.sock.sendto(message, (endpoint.address.exploded, endpoint.udpPort))


### Decoding the response 

Recall the message layout from the [RLPx specification](https://github.com/ethereum/devp2p/blob/master/rlpx.md) discussed in  [part 1](https://ocalog.com/post/10) (`||` is cancatenation):

    hash || signature || packet-type || packet-data

In this section we check the message hash,  the signature, and if both are valid we decode the message according to the `packet-type` byte. 

We need somewhere to put this code. In `discovery.py`, our packet listening function is defined inside the `PingServer` method `udp_listen`:

    def udp_listen(self):
        def receive_ping():
            print "listening..."
            data, addr = self.sock.recvfrom(1024)
            print "received message[", addr, "]"
    
        return threading.Thread(target = receive_ping)

I'm going to split this `receive_ping` function into a more general method called `receive`, which will do that packet decoding:

    def udp_listen(self):
        return threading.Thread(target = self.receive)

    def receive(self):
        print "listening..."
        data, addr = self.sock.recvfrom(1024)
        print "received message[", addr, "]"

        ## decode packet below

Now we'll fill out what goes below `## decode packet below`, starting with decoding the hash.

**Hash:** The hash should be a 256-bit (32 byte) keccak256 hash of the rest of the packet. To verify this, the following code is added to receive:

    ## verify hash
    msg_hash = data[:32]
    if msg_hash != keccak256(data[32:]):
        print " First 32 bytes are not keccak256 hash of the rest."
        return
    else:
        print " Verified message hash."

**Signature:** The next step is to verify the secp256k1 signature. First we deserialize the signature into an object from the [secp256k1 library](https://github.com/ludbb/secp256k1-py), then we recover the public key from the signature, then we use that public key to verify the signature. 

To deserialize the signature we use `ecdsa_recoverable_deserialize` method of our server's private key `priv_key`.  We encoded the signature using
 `sig_serialized[0] + chr(sig_serialized[1])`, the first term being 64 byes, the second term 1 byte.
Therefore we need to grab the next 65 bytes, divide the signature into a 64 byte parameter and a 1 byte parameter, and use `ord`, the inverse of `chr`, on the last byte.  

    ## verify signature
    signature = data[32:97]
    signed_data = data[97:]
    deserialized_sig = self.priv_key.ecdsa_recoverable_deserialize(signature[:64],
                                                                   ord(signature[64]))


To recover the public key, we use `ecdsa_recover`. Remember that we use `raw = True` to tell the algorithm that we are using our own, `keccak256` hashing algorithm instead of the function's default hashing algorithm. 

    remote_pubkey = self.priv_key.ecdsa_recover(keccak256(signed_data),
                                                deserialized_sig,
                                                raw = True)

Now we create a `PublicKey` object to store it in. Import `PublicKey` from `secp256k1` at the top:

    from secp256k1 import PrivateKey, PublicKey

and, back in `receive`, write:

    pub = PublicKey()
    pub.public_key = remote_pubkey

Now we can verify that the `signed_data` was signed by `deserialized_sig` using `ecdsa_verify`, after first converting to a standard signature using `ecdsa_recoverable_convert`  on `deserialized_sig`, a required step in this library. 

    verified = pub.ecdsa_verify(keccak256(signed_data),
                                pub.ecdsa_recoverable_convert(deserialized_sig),
                                raw = True)

    if not verified:
        print " Signature invalid"
        return
    else:
        print " Verified signature."

**Unpack:** The last step is to unpack the message. Response functions are deteremined by the `packet_type` byte:

    response_types = {
        PingNode.packet_type : self.receive_ping,
        Pong.packet_type : self.receive_pong
    }

    try:
        packet_type = data[97]
        dispatch = response_types[packet_type]
    except KeyError:
        print " Unknown message type: " + data[97]
        return

    payload = data[98:]
    dispatch(payload)

We'll keep `receive_ping` and `receive_pong` simple for now, as methods of `PingServer`: 

    def receive_pong(self, payload):
        print " received Pong"
        print "", Pong.unpack(rlp.decode(payload))

    def receive_ping(self, payload):
        print " received Ping"
        print "", PingNode.unpack(rlp.decode(payload))


Let's check how this code runs using `python send_ping.py`. You should see: 

    sending (Ping 3 (EP 52.4.20.183 30303 30303) (EP 13.93.211.84 30303 30303) 1501093574.21)
    listening...
    received message[ ('13.93.211.84', 30303) ]:
     Verified message hash.
     Verified signature.
     received Pong
     (Pong (EP 52.4.20.183 30303 30303) <echo hash> 1501093534)

We have successfully verified and decoded the pong message. 

Next time, we will implement the `FindNeighbors` message, and the `Neighbors` response message.

**Do you like writing in-depth articles? Ocalog is a platform to help you get paid. Consider joining!**

