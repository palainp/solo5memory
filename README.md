# solo5memory

## setup network

We want to illustrate a non-SYN reply from a local server to the unikernel.

```bash
sudo ip tuntap add service mode tap
sudo ip addr add 10.0.0.1/24 dev service
sudo ip link set dev service up
# the following will forbid reply from the local server
sudo sysctl -w net.ipv4.ip_forward=1
sudo iptables -P FORWARD DROP
sudo iptables -I FORWARD -m state --state NEW -j ACCEPT
```

## compile

```bash
mirage configure -t spt && make depend && dune build && strip dist/network.spt
```

## run test

Start the "server":
```bash
nc -l -s 127.0.0.1 -p 8080
```

Test the non connextivity (wireshark should tells you that a SYN is out to 127.0.0.1 but SYN-ACK is refused):
```bash
nc -s 10.0.0.1 127.0.0.1 -p 8080
```

And run the unikernel:
```bash
solo5-spt --net:service=service --mem=16 dist/network.spt --ipv4-gateway=10.0.0.1
```

Another test (the unikernel is the server and you want to start multiple connexion from netcat, you'll have to remove the iptables FORWARD rules):
```bash
for i in `seq 1 1000` ; do
	printf "" | nc --send-only 10.0.0.2 8080
done 
```
