# Ansible setup for nidito

Ansible will make sure essential services are up and running.

```sh
# ansible all the things
pipenv run tame

# just a host
pipenv run tame -l xitle --diff -v

# just a group in a dc
pipenv run tame -l role_leader -l dc_casa

# see the ansible inventory
pipenv run inventory
```
