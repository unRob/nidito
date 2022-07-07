![network diagram](./diagram.png)

## DNS name overview

- nidi.to
  - {dc}.nidi.to
    - {hostname}.dc.nidi.to
    - {service}.dc.nidi.to
  - {service}.nidi.to

## IP Range overview


- `10.42.0.0/16`: primary dc
  - `10.42.0.0/24`: physical network devices
    - `10.42.0.1` router
    - `10.42.0.2` switch
    - `10.42.0.10` cloudkey
    - `10.42.0.10{0..n}` access points
  - `10.42.16.0.0/20`: altepetl
    - `10.42.20.0/24`: servers
    - `10.42.2{2..9}.0/21`: containers from `10.42.20.{2..9}
    - `10.42.30.0/24`: management tunnel
    - `10.42.31.0/
  - `10.42.32.0.0/19`: calli
    - `10.42.3{2..9}.0/21`: containers from `10.42.20.{2..9}
    - `10.42.40.0/21`: atl
      - `10.42.40.0/24`: atl vpn
      - `10.42.42.0/24`: atl wlan
    - `10.42.55.0/24`: wlan familia
  - `10.42.96.0/19`: robotitos
    - `10.42.100.0/24`: appliance wlan
    - `10.42.13{2..9}.0/21`: containers from `10.42.20.{2..9}
  - `10.42.192.0/19`: guests
    - `10.42.19{2..9}.0/21`: containers from `10.42.20.{2..9}
    - `10.42.200.0/24`: wlan
- `10.24.0.0/16`: secondary dcs
  - `10.24.0.0/20`: nyc1 servers
  - `10.100.


## Physical

### Router @ `10.42.0.1` _df_

- `eth0`/`switch0`: chapultepec (bond)
- `eth1`/`switch0`: chapultepec (bond)
- `eth2`/`switch0`: ajusco
- `eth3`/`switch0`: xitle
- `eth4`/`switch0`: tepeyac
- `eth5`/`switch0`: guerrero
- `eth6`/`switch0`: tláloc
- `eth7`/`switch0`: _unused_
- `eth8`: escape-hatch
- `eth9`: wan
- `eth10` (sfp): _unused_
- `eth11` (sfp): switch @ `10.42.0.2`

### Switch @ `10.42.0.2` _sw0.df_

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

### Altépetl - 20

- **Range**: `10.42.20.0/20`
- **Reservations**:
  - chapultepec: `10.42.20.2`
  - ajusco: `10.42.20.3`
  - xitle: `10.42.20.4`
  - tepeyac: `10.42.20.5`
  - guerrero: `10.42.20.6`
  - tláloc: `10.42.20.7`
- **Containers**: `10.42.2{2-8}.0/23`
- **DHCP**: `10.42.20.128/25`
- **VPN**: `10.42.30.0/24`

### Calli - 42,43,55

- **Range**: `10.42.32.0/20`
- **Containers**: `10.42.3{2-8}.0/23`
- **VPN**: `10.42.31.0/24`

#### Atl - 42

- **Range**: `10.42.42.0/23`
- **Reservations**:
  - citlaltépetl: `10.42.42.42`
  - chiquihuite: `10.42.42.43`
  - chautengo: `10.42.42.44`
  - zempoala: `10.42.42.45`

#### Trusted - 43

- **Range**: `10.42.43.0/23`
- Firewall:
  - puede hablarle a sonos
  - puede hablarle a apoltivi
  - puede hablarle a hueberto
  - puede hablar http/s a tepetl
  - puede hablar con containers de calli

#### Familia - 44
- **Range**: `10.42.44.0/24`
- Firewall:
  - puede hablarle a sonos
  - puede hablarle a apoltivi
  - puede hablarle a hueberto
  - puede hablar con containers de calli


### Robotitos - 100

- **Range**: `10.42.96.0/20`
- **DHCP**: `10.42.100.0/24`
- **Reservations**:
  - apoltivi: `10.42.100.2`
  - hueberto: `10.42.100.3`
  - suich: `10.42.100.4`
- **Containers**: `10.42.10{2-8}.0/23`

### Bandera - 200

- **Range**: `10.42.200.0/24`
- **DHCP**: `10.42.200.0/24`
- **Firewall**:
  - puede


## SSIDs

- `robotitos`: robotitos vlan
- `.mi wifi es su wifi.`: radius vlan

## Radius users

- roberto: atl wlan
- familia: calli
- bandera: guests

## TODO

Do macvlan for containers. See [here](https://kcore.org/2020/08/18/macvlan-host-access/).
