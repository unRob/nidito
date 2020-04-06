# Ansible setup for nidito

Ansible will make sure essential services are up and running.

```sh
# path to top level config
# These will eventually be processed by bin/inventory to generate
# ansible variables `node` and `nidito`
export CONFIG_FILE="../config.yml"
 export CONFIG_PASSWORD="hunter2"


# ansible all the things
pipenv run tame

# just a host
pipenv run tame -l xitle

# see the ansible inventory
pipenv run inventory
```

## Essential services

Essential services need to available or the network is unusable. 

- Router config (TBD)
  - firewall
  - dmz
  - dhcp
  - vlan
- DNS
- VPN
- consul
- nomad
