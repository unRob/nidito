ROOT := $(shell pwd)

.cache:
	mkdir -p .cache

.cache/coredns: .cache
	git clone --depth=1 https://github.com/coredns/coredns.git .cache/coredns
	make .cache/plugin.cfg
	cp .cache/plugin.cfg .cache/coredns/

.cache/plugin.cfg:
	awk '/^kubernetes:kubernetes/{ print; print "consul_catalog:github.com/unRob/coredns-consul"; next }1' .cache/coredns/plugin.cfg > $@

roles/coredns/files/linux/edgeos/coredns: .cache/coredns
	mkdir -p $(dir $@)
	make -C .cache/coredns gen
	make -C .cache/coredns coredns SYSTEM='GOOS=linux GOARCH=mips64'
	mv .cache/coredns/coredns $(ROOT)/$@

sync-config:
	consul kv import <(pipenv run python config-to-consul.py)
