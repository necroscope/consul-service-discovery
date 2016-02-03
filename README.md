# consul-in-docker

Quick POC demo stack containing:
- consul-base: image containing the consul binary + supervisor + utils
- consul-bootstrap: bootstrap a initial server node (optional)
- consul-server: run a consul server in the cluster
- consul-agent: extent to create agent based images

# i want to be discovery

```
make
```

This will:
- build unique cluster key
- build basic consul configs for `-bootstrap`, `-server` and `-agent` roles
- build containers for `-bootstrap`, `-server` and `-agent` roles
- launch u a consul nano-cluster
- run a quick demo + members + scaling
- brew fine english tea (HTTP/418)

## try also

- `make clean`
- `make clean stack`
- `make members`
- `make demo`
- `make tea`
- `make coffee`


# but i really do live in the real world

Yes, dont use in production :-)

Think: multi docker host hosting

You can run any of the role based images independently (see config + envieronment vars + consul dns stack local name)


extent the `-agent` image, for example:
```
FROM consul-agent
RUN yum install nginx
ADD htdocs /htdocs
ADD <CONSUL_CONFIG_FOR_NGINX>
RUN echo -e "\n[progam:nginx]\nblar=nnnnnnn\n\n" >> /etc/supervisord.conf
```

or 
```
FROM consul-agent
RUN yum install redis
ADD <CONSUL_CONFIG_FOR_REDIS>
RUN echo -e "\n[progam:redis]\nblar=nnnnnnn\n\n" >> /etc/supervisord.conf
```

then lauch with the `--link=container:alias` option so the `container` being linked to is aliased to `consul` so the
agent can auto discover via dns search domain a local `consul.` host server cluster member..






-
-
