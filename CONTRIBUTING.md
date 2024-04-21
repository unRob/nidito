## Setup

```sh
git clone https://github.com/unRob/nidito.git
cd nidito
# get required dependencies
brew bundle check || brew bundle install --file=Brewfile
curl -L https://milpa.dev/install.sh | bash -
milpa itself shell install-autocomplete
# add some env vars to a posix shell
eval "$(milpa nidito operator env)"
# fetch config secrets and prevent them from landing into git
milpa nidito operator setup
```

## Usage

```sh
# see sub-commands
milpa nidito help

# create a new node
milpa nidito node provision "$hostname" "$datacenter"

# run provisioning on nodes with ansible
milpa nidito node tame ...

# fetch secrets from 1password into config/**/*.yaml
milpa nidito config fetch

# deploy services with nomad
milpa nidito service deploy docker-registry
```
