($dcs | split("\n")) as $dcs |
to_entries |
map(
  select(.value.tags.role == "leader") |
  {name: .key, address: .value.address, dc: .value.dc}
) |
reduce .[] as $n (
  [];
  . + (
    ["consul", "vault", "nomad"] |
    map(. as $svc | {
      key: "\($n.name)-\($svc)",
      host: $n.name,
      cn: "server.\($n.dc).\($svc)",
      names: (
        [
          "localhost",
          "\($svc).service.consul",
          "\($svc).service.\($n.dc).consul",
          "\($n.name).node.consul",
          "\($n.name).node.\($n.dc).consul",
          "\($n.name).\($n.dc).$mainZone"
        ] + (
          if $svc == "consul" then
            (($dcs | map(select(. != $n.dc) | "*.\(.).consul")) // [])
          else [] end
        )
      ),
      ips: ["127.0.0.1", $n.address]
    })
  ) + [{
    key: "\($n.name)-op",
    host: $n.name,
    cn: "op.service.\($n.dc).consul",
    names: [
      "localhost",
      "op.service.consul",
      "op.query.consul",
      "op.\($n.dc).$mainZone"
    ],
    ips: ["127.0.0.1", $n.address]
  }]
)
