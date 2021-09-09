consul {

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
