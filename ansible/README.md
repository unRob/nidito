# Ansible setup for nidito

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
