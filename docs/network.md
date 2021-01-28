# Network

![network diagram](./diagram.png)

## Physical

### Router @ `10.42.0.1`

- `eth0`/`switch0`: chapultepec (bond)
- `eth1`/`switch0`: chapultepec (bond)
- `eth2`/`switch0`: ajusco
- `eth3`/`switch0`: xitle
- `eth4`/`switch0`: _unused_
- `eth5`/`switch0`: _unused_
- `eth6`/`switch0`: _unused_
- `eth7`/`switch0`: _unused_
- `eth8`: _unused_
- `eth9`: wan
- `eth10` (sfp): _unused_
- `eth11` (sfp): switch @ `10.42.0.2`

### Switch @ `10.42.0.2`

- `eth0`: ap0 @ `10.42.0.100`
- `eth1`: ap1 @ `10.42.0.101`
- `eth2`: ap2 @ `10.42.0.102`
- `eth3`: cloudkey @ `10.42.0.10`
- `eth4`: apoltivi
- `eth5`: hueberto
- `eth6`: suich
- `eth7`: _unused_
- `eth8` (sfp): _unused_
- `eth9` (sfp): router @ `10.42.0.1`

## VLANs

### Trusted - 20

- **Range**: `10.42.20.0/20`
- **DHCP**: `10.42.20.128/25`
- **Reservations**:
  - chapultepec: `10.42.20.2`
  - ajusco: `10.42.20.3`
  - xitle: `10.42.20.4`
  - Tláloc: `10.42.20.10`
  - Chiquhuite: `10.42.20.11`
  - Citlaltepetl: `10.42.20.12`
- **Containers**: `10.42.2{2-8}.0/23`, `10.42.3{2-8}.0/23`
- **VPN**: `10.42.101.0/24`

### Shared - 40

- **Range**: `10.42.40.0/23`
- **DHCP**: `10.42.40.0/24`
- **VPN**: `10.42.41.0/24`

### Robotitos - 100

- **Range**: `10.42.100.0/24`
- **DHCP**: `10.42.100.0/24`
- **Reservations**:
  - apoltivi: `10.42.100.2`
  - hueberto: `10.42.100.3`
  - suich: `10.42.100.4`

### Guests - 200

- **Range**: `10.42.200.0/24`
- **DHCP**: `10.42.200.0/24`


# TODO

Do macvlan for containers. See [here](https://kcore.org/2020/08/18/macvlan-host-access/).
