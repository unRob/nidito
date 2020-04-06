# nidito

Automated homelab stuff and stuff

## Setup

```sh
# get required dependencies
brew bundle check || brew bundle install --file=Brewfile
```

`python` and `pipenv` are required for Ansible

## Usage

1. `cd ansible && pipenv run tame && popd`
2. `cd terraform # && TBD TBD`

## Description

My home lab runs on diverse machines, and there's a bunch of workloads I'be been playing with in it. I don't quite know what I'm doing, so I wanna make sure its less of a pain when it comes time to upgrade/undo/redo. Hardware fails, I tend to trip over ethernet, and thus this lab's automation and design is focused on allowing me to be as lazy and chill about failure as possible.

Most things these days can and will run great with docker, and some things will be better off running outside a container. A few essential services run like this and those are setup with ansible. Every other workload is scheduled with nomad.

### Equipment

Power efficiency is the name of the game. 40watts average load or bust.

- **EdgeRouter 12p**: Runs network-y stuff like every other router. 
- **Synology DSM918+**: NAS with nvidia gpu
- **PixiePro**: quad-core ARM microcomputer
- **MacBook Pro**: Broken screen, found on the streets of Brooklyn

### Services

These hosts run a few services I think of in three layers, in descending order of essentialness:

0. **network** provide a working local+remote network, and dns resolution
1. **workload** provide the runtime, scheduler, configuration, storage, logging, and load balancing for other services
2. **home** turn on the lights, media streaming, long-term storage, backup
3. **et al** everything else

#### Network services

Without a working **network**, either wired, wireless or through a vpn, nothing else works.

- **DNS**: `coredns` forwards and caches queries (pihole tbd) to the internet at large. Queries to *.nidi.to from within the network are served from a static list or relayed to consul for discovered services (look ma, no wildcard CNAME!)
- **VPN**: `wireguard` was noticeable faster than `openvpn` when running on the ARM computer, also way easier to configure, so I stuck with that.

Both of these services are running on the router. It already comes with `dnsmasq` and `openvpn`, so it seems to be designed to run these kinds of applications.

Every other service is provided by the default edgerouter stuff itself.

#### Workload services

`consul` and `nomad` provide the basis for running **workload**s and doing the service discovery/config dance. These tools are Since these are hashicorp tools, I decided to 

I currently have some services in the layers 2,3 up and running but not ported over here yet.
