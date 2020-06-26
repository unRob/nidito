. as $data |

def nodes: $data | .nodes;
def nodes(query): nodes | query;
def global(query): $data | query;

def filter(query):
  nodes(with_entries(select(.value | query)));
def filter(query; rdc):
  filter(query) | rdc;

def names(query):
  filter(query; keys);

def address_pairs(query):
  filter(query; to_entries | map({ name: .key, address: .value.address }));
def address_pairs(query; srt):
  filter(query; to_entries | sort_by(.value | srt) | map({ name: .key, address: .value.address }));

def addresses(query):
  address_pairs(query) | map(.address);
def addresses(query; srt):
  address_pairs(query; srt) | map(.address);

def node_tags($prop):
  nodes |
  to_entries |
  reduce .[] as $n ({}; . * {
      ($n.value[$prop]): ((.[$n.value[$prop]] // []) + [$n.key])
    }
  ) |
  to_entries |
  map({
    ($prop+"_"+(.key | gsub("\\W"; "_"))): { hosts: .value }
  }) |
  add;

{
  _meta: {
    hostvars: nodes(with_entries({
      key: .key,
      value: ({node: .value} + .value._ansible)
    }))
  },
  dns_nameserver: {
    hosts: names(.dns.enabled),
    vars: {
      dns: {
        servers: address_pairs(.dns.enabled; .dns.mode != "leader"),
        hosts: address_pairs(.reachability != "gateway"),
        consul_servers: addresses(.consul)
      }
    }
  },
  all: {
    hosts: nodes(keys),
    vars: {
      nidito: {
        consul: global(.consul),
        dns_servers: addresses(.dns.enabled; .dns.mode != "leader"),
        dns: global(.dns),
        filebeat: global(.filebeat),
        networks: global(.networks),
        nomad: global(.nomad),
        vault: global(.vault),
      }
    }
  },
  consul_server: {
    hosts: names(.consul)
  },
  nomad_server: {
    hosts: names(.nomad)
  },
  vault_server: {
    hosts: names(.vault)
  },
  ungrouped: {
    children: []
  }
}
* node_tags("reachability")
* node_tags("platform")
