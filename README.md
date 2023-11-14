# solo5memory

## setup network
```bash
sudo ip tuntap add service mode tap
sudo ip addr add 10.0.0.1/24 dev service
sudo ip link set dev service up
```

## compile & run

```bash
mirage configure -t spt && make depend && dune build && strip dist/network.spt
solo5-spt --net:service=service --mem=16 dist/network.spt 
```

## run test

```bash
for i in `seq 1 300` ; do
	printf "" | nc --send-only 10.0.0.2 8080
done 
```
