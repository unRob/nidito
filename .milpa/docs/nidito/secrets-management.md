---
title: managing secrets for the homelab
---



## Kinds of secrets

### configuration

A tree of typed values addressable by name, editable by humans only via `joão` or in 1Password directly. Contains nearly all secrets necessary to spin up a nidito.

- Risk of data-loss mostly managed by 1Password.
- Risk of breach of source materials is also managed by them, however, I could also do something stupid like not encrypting secret values and pushing to git remotes, having faulty firewall policies for `op-connect`, and/or screwing up vault/1password policies.
- Outages mean services that depend on this can't start.

### service kv

these are secrets stored by internal services.

- risk of data-loss when vault storage is lost (that means every DC's underlying storage backend)
  - currently: consul stores vault data, meaning individual node storage media needs to fail for this to become at-risk. At home, where some service config kinda, sorta, matters, it requires 3 node volumes becoming unreadable (including 2/4 disks inside the NAS). Risk is mostly from damage/loss. Other DCs means rented VMs underlying storage dies and it's gone.
  - ideally: [consul snapshots](https://developer.hashicorp.com/consul/tutorials/production-deploy/backup-and-restore) ¿daily? to b2 to alleviate damage/loss.
- risk of breach by me being dumb about vault policies, or via the vectors available through services themselves.

### TLS certificates

Last, but possibly most important to get started, we need to TLS certs so consul, vault, and nomad can talk amongst each other using https. Certs protect potentially secret data in-transit. `op-connect` also needs to serve using https, so we generate it a cert as well. There's also public-facing https certs we get from Let's Encrypt, these are needed by TLS terminator proxies and rotate around 4 times a year.

- risk of data-loss is same as for configuration, as these are eventually stored in 1password. Losing these means nothing though, I just issue them again, and indeed rotate them
- risk of breach by exposing them unencrypted. These need to be readable by the HC stack


## Infra

### 1Password Connect server (`op-connect`)

`op-connect` is deployed in every DC, it'll talk to 1Password's servers and retrieve **config** from here.

- Deployed via ansible to every node running vault.
- Listens on https://(private_ip|op.(query|service)(.$DC)?.consul):4430
- requires nidito-CA certs for listeners
- available, if needed, but not by default, on public dns/routable ip via node TLS proxy.
  - Should I need to access remotely, theres VPN
  - Maybe to grant outside readers access, like github actions?
- Vault + `joão` talk to https://op.query.consul:4430, routing to local OP if available, else remote DC OP
- requires json credentials (these are stored in 1password, so ansible needs to be able to drop them into the node)
