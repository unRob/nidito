# Ansible setup for nidito

Ansible will make sure essential services are up and running.

```sh
 export CONFIG_PASSWORD="hunter2"

# ansible all the things
pipenv run tame

# just a host
pipenv run tame -l xitle --diff -v

# just a group in a dc
pipenv run tame -l role_leader -l dc_casa --ask-diff-pass

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
