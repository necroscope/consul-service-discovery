# build a server for bootstrapping a cluster
FROM consul-base
RUN \
  consul version

ADD consul-bootstrap.json /etc/consul.d/consul.json



