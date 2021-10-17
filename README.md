# nidito

Automated homelab stuff and stuff

## Setup

```sh
git clone https://github.com/unRob/nidito.git
cd nidito
# get required dependencies
brew bundle check || brew bundle install --file=Brewfile
curl -L https://milpa.dev/install.sh | bash -
```

## Usage

```sh
# see sub-commands
milpa help

# run provisioning on nodes with ansible
milpa node provision

# configure services and resources with terraform
milpa config sync

# deploy services with nomad
milpa service deploy docker-registry
```

## Description

My home lab runs on a diverse set of machines, and there's a bunch of workloads I'be been playing with in it. I don't quite know what I'm doing, so I wanna make sure its less of a pain when it comes time to upgrade/undo/redo. Hardware fails, I tend to trip over ethernet, and thus this lab's automation and design is focused on allowing me to be as lazy and chill about failure as possible.

Most things these days can and will run great with docker, and some things will be better off running outside a container. A few essential services run like this and those are provisioned on nodes with ansible. Every other workload is scheduled with nomad.

### Hardware

Power efficiency is the name of the game; I started with a 40 watt/hour budget which has slowly grown along the amount of hardware in my rack. Now we're on a 100 watt/hour budget, which I wanna try to stick to for a long time.

- **edgerouter 12p**: Runs network-y stuff like every other router.
- **edgeswitch 8-150**
- **synology dsm918+**: NAS with nvidia gpu
- **pixiepro**: quad-core 32-bit ARM microcomputer
- **macbook pro 13"** _mid 2011_: Broken screen, found on the streets of Brooklyn
- **macmini server** _late 2011_: donated by the Rodas Hardware Adoption Agency 
- **digitalocean 2gb droplet**: runs my personal website and projects in _the cloud_.

### Services

These hosts run a few services I think of in three layers, in descending order of essentialness:

0. **network** provide a working local+remote network, and dns resolution
1. **workload** provide the runtime, scheduler, configuration, storage, logging, and load balancing for other services
2. **home** turn on the lights, media streaming, long-term storage, backup
3. **et al** everything else

#### Network services

Without a working **network**, either wired, wireless or through a vpn, nothing else works. Apart from regular network-y services, the router runs:

- **DNS**: `coredns` forwards and caches queries (pihole tbd) to the internet at large. Queries to *.nidi.to from within internal networks dynamically resolve from consul.
- **VPN**: `wireguard` runs a site-to-site to a "cloud" DC as well as allowing me to connect outside these walls.

#### Workload services

`consul`, `nomad` and `vault` provide the basis for running **workload**s and doing the service discovery/config dance. `vector` is also provisioned to every node. Along DNS and VPN, I consider these services "tier-1", as everything else is dead without it.

tier-2 services provide nicer abstractions for roberto, the power-user, to run stuff on. These services are:

- **http-proxy**: nginx runs on every leader node, terminating SSL and proxying requests to every other service.
- **docker-registry**: a container image registry
- **telemetry**: `prometheus`, `grafana` and `loki` to get an idea of what's happening inside these boxes

Finally, there's tier-3 services that actually do stuff for humans in my home:

- **radio**: an icecast instance so I can record and stream _ruiditos_
- **cajon**: a drawer to put all my bytes in, i.e. `minio`
- **media-pipeline**: downloads media files from putio, renames them and ships them to plex
- **plex**: self-hosted media streaming service, including my personal recordings