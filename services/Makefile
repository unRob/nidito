export CONSUL_HTTP_ADDR := http://consul.service.consul:5555
export CONSUL_HTTP_TOKEN := $(shell gcy get ../config.yml nodes.xitle.consul.token)

levant:
	curl -L https://github.com/jrasell/levant/releases/download/0.2.9/darwin-amd64-levant -o levant
	chmod +x levant

plan:
	$(wildcard *.nomad)

*.nomad:
	@ ../levant plan $@

.PHONY: *.nomad
