# Network

## Physical

Hosts:
  - Brooklyn: `10.0.0.1`
  - AP0: `10.0.0.5`


## Trusted - `10.10.0.0/16`

Hosts: `10.10.0.0/24`

Reservations:
  - *Chapultepec: `10.10.0.2`
  - *Ajusco: `10.10.0.3`
  - *Xitle: `10.10.0.4`
  - *Tláloc: `10.10.0.10`
  - Chiquhuite: `10.10.0.11`
  - Citlaltepetl: `10.10.0.12`

Containers:`10.10.1y.0/24`, `y := sprintf("%0d", lastOctet(host.address))`, i.e. `10.10.102.0/24` for host address `10.10.0.2`

VPN: `10.11.0.0/24`


## Shared - `10.20.0.0/16`

Hosts: `10.20.0.0/24`

Reservations:
  - Apoltivi: `10.20.0.2/24`
  - Hueberto: `10.20.0.3/24`
  - Suich: `10.20.0.4/24`
  - Tepeyac: `10.20.0.5/24`

DHCP:
  - BR30
  - Strip
  - Lock
  - Wemo
  - Outdoors
  - Nest
  - Soplador

VPN: `10.21.0.0/24`

Containers: `10.20.1y.0/24`, `y := sprintf("%0d", lastOctet(host.address))`, i.e. `10.20.110.0/24` for host address `10.10.0.10`
