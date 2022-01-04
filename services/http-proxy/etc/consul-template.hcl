consul {
  address = "https://consul.service.consul:5560"
}


# This is the quiescence timers; it defines the minimum and maximum amount of
# time to wait for the cluster to reach a consistent state before rendering a
# template. This is useful to enable in systems that have a lot of flapping,
# because it will reduce the the number of times a template is rendered.
wait {
  min = "5s"
  max = "10s"
}

exec {
  command       = "nginx -g daemon off;"
  reload_signal = "SIGHUP"
  kill_signal   = "SIGTERM"
  kill_timeout  = "15s"
}

template {
  source      = "/etc/nginx/conf.d/default.conf.ctmpl"
  destination = "/etc/prometheus/prometheus.yml"
  perms       = 0640
}
