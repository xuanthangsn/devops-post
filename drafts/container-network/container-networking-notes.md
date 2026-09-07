# Container Networking Notes

## 1. Virtual vs Physical Network Interfaces (veth)

A physical network interface just sends packets out into the world — you don't
control (and don't need to know) where they actually go. They might travel
thousands of miles under the ocean, or die instantly because a cat bit through
the cable. The kernel doesn't need a "destination interface" baked in, because
routing/switching hardware out there handles it.

A **veth** (virtual ethernet) interface is different: since there's no physical
wire, *you* are responsible for telling the kernel where a packet handed to
this interface should go. That's why veth interfaces always come in **pairs**:
whatever goes into one end comes out the other.

```bash
ip link add veth0 type veth peer name veth1
```

Running `ip link list` afterward shows *two* interfaces, `veth0` and `veth1` —
they're created together, and traffic sent into one arrives on the other.

## 2. Host Models: Weak vs Strong

Linux uses the **weak host model** for network configuration by default. This
means:

- A packet arriving on one network interface can be accepted even if it's
  addressed to the IP of a *different* local interface.
- When sending, the kernel isn't strictly bound to sending from the interface
  whose subnet matches the destination — routing table order decides.

The alternative is the **strong host model**, where each interface only
accepts/sends traffic for its own IP address — packets destined for another
local interface's IP are dropped rather than silently accepted.

This distinction directly explains some of the "unexpected" behavior observed
in the lab below.

## 3. Lab: Observed veth Behavior Across Namespaces

### Setup

- 2 network namespaces: `netns0`, `netns1`
- 2 veth pairs:
  - `veth0` (132.18.0.10) — `ceth0` (132.18.0.11)
  - `veth1` (132.18.0.20) — `ceth1` (132.18.0.21)
- `veth0` and `veth1` live on the **host**
- `ceth0` lives in `netns0`, `ceth1` lives in `netns1`
- **Creation order matters**: `netns0` + `veth0` + `ceth0` were created *before*
  `netns1` + `veth1` + `ceth1`

### Observed behavior

| From      | Can ping 132.18.0.10 | Can ping 132.18.0.11 | Can ping 132.18.0.20 | Can ping 132.18.0.21 |
|-----------|:---:|:---:|:---:|:---:|
| `netns0`  | ✅ | ✅ | ✅ | ✅ |
| host      | — | ✅ | — | ❌ |
| `netns1`  | ❌ | ❌ | ❌ | ❌ |

### Why this happens

**`netns0` can ping both `132.18.0.10` and `132.18.0.20`** (expected only the
former):

- This is the **weak host model** at work — the kernel accepts/routes packets
  destined for a locally-known IP regardless of which interface "owns" it.

**Host can ping `132.18.0.11` but not `132.18.0.21`** (expected both to work):

- Both `veth0` and `veth1` were assigned the *same subnet* (`132.18.0.0/16`),
  so the host's routing table looks like:

  ```
  132.18.0.0/16 dev veth0 proto kernel scope link src 132.18.0.11
  132.18.0.0/16 dev veth1 proto kernel scope link src 132.18.0.21
  ```

- The kernel searches the routing table top to bottom and uses the **first
  matching entry**. Since both entries match the same subnet, *every* request
  in that subnet goes out `veth0` — the entry created first (i.e. the entry
  for the pair that existed earlier). `veth1`'s entry never gets used.

**`netns1` cannot ping any IP** (expected it to reach `132.18.0.21` but not
`132.18.0.11`):

- Same root cause as above — `netns1`'s traffic is also affected by which
  route wins on the host side, since it depends on host routing to reach
  anything outside its own namespace.

**Takeaway**: overlapping subnets across multiple veth pairs on the same host
cause routing table ordering to silently swallow traffic for the
later-created pair. Each veth pair should get its own distinct subnet.

## 4. Switches and Routers

Switches and routers are the two cornerstones of the internet — not just as
physical devices, but conceptually: the Linux kernel implements virtual
versions of both, which is what makes container networking possible. As
someone working with containers, having a solid grasp of both is essential.

### Switch

- Operates at **L2** — has no concept of IP addresses, only MAC addresses.
- Holds a single subnet together; helps machines within a subnet find each
  other.
- Its job is simple:
  1. **Broadcast ARP requests** — when a machine wants the MAC address behind
     an IP in the subnet, it sends an ARP request. The switch broadcasts it to
     every other machine in the subnet ("who owns this IP? send me your
     MAC"), and the requester gets its answer.
  2. **Forward frames** to the rightful machine based on MAC address.

### Router

- Operates at **L3** — understands both MAC *and* IP addresses. A bit smarter
  than a switch, for good reason.
- While a switch holds machines together into one subnet, a router connects
  *subnets* together into a larger network. It's the bridge to the outside
  world for a subnet, and knows where to send traffic whose destination IP
  isn't part of the local subnet.
- Each machine in a subnet is normally configured with a **default gateway**
  — the router's IP — so it knows where to hand off any traffic not meant for
  a local peer. The router then handles routing that traffic onward.

### Switch vs Router (perspective)

From a switch's point of view, a router is just another machine on the
subnet — no different from any other member. The switch itself is "dumb" in
the sense that it doesn't discriminate; it just does its job honestly.

## 5. `ip neigh`

Shows/manages the kernel's neighbor table — the ARP cache (IPv4) / NDP cache
(IPv6) mapping IP addresses to MAC addresses on the local network. Useful for
checking whether a machine has actually resolved a peer's MAC address, or for
manually adding/removing/flushing neighbor entries.

## 6. Command Reference

| Command | Description |
|---|---|
| `ip netns add <name>` | Create a new network namespace |
| `ip link list` | List all network interfaces |
| `ip link add <name1> type veth peer name <name2>` | Create a pair of virtual network interfaces |
| `ip link set <veth_name> netns <netns_name>` | Move the specified network interface into the specified network namespace |
| `ip link set <veth_name> up` | Turn the specified network interface on |
| `ip addr add <ip_addr> dev <veth_name>` | Assign an IP address to the specified network interface |
| `ip route list` | View the routing table |
| `ip route add default via <ip_addr>` | Add the default gateway for a network namespace |
| `ip neigh` | View/manage the ARP/neighbor table |
