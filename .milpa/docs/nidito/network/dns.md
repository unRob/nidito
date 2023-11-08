
## DNS name overview

My network of mountains has its own domain: tepetl.net. DNS is served by `coredns` and backed by `consul`. Services are registered with consul, and a split-horizon view is served privately for each DC's DNS zone (i.e. `nidi.to`).

## Hierarchy scheme

- `$DC`.tepetl.net: public record pointing to the DC's firewall
  - `$SVC`.`$DC`.tepetl.net: where `$SVC` is one of `consul`, `nomad`, `vault`, points to the private IP addresses of `$SVC` leaders as discovered by consul.
  - `$HOSTNAME`.`$DC`.tepetl.net: points to `$HOSTNAME`'s private IP

## User-facing domains

I've got tons, most of these follow no logical pattern except for my TLS-backed home services at `$shortSubdomainIllRemeber.nidi.to`.
