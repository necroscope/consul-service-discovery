

DATACENTER?=stu
LOG_LEVEL?=INFO
DATA_DIR?=/var/consul
ENABLE_SYSLOG?=false


stack: cluster.key build up demo

up:
	docker-compose rm -f || true
	docker-compose build --no-cache
	docker-compose up -d bootstrap
	docker-compose up -d server
	docker-compose up -d agent


demo:
	echo "consul: initial-bootstrap-node + consul-server*1 + consul-agent*1:"
	docker-compose ps
	sleep 1

	echo "and the cluster members:"
	docker exec -it $(docker-compose ps -q agent) consul members
	sleep 1

	echo "lets scale out number of servers:"
	docker-compose scale server=10
	docker exec -it $(docker-compose ps -q agent) consul members
        sleep 1

	echo "and scale down:"
	docker-compose scale server=3
	docker exec -it $(docker-compose ps -q agent) consul members
        sleep 1

	echo "get agent info:"
	docker exec -it $(docker-compose ps -q agent) consul info
	echo "fan, u will have :-)  "



logs:
	docker-compose logs

members:
	docker-compose run agent consul members






# build the docker container image from the dockerfile
build: base bootstrap server agent



# create base container image having consul ready to rnr
base:
	docker build -t consul-base consul-base/



# make bootstrap node config
bootstrap: bootstrap_config bootstrap_image

# create conf for bootstrapping cluster
bootstrap_config:
	# construct some config
	echo '{"bootstrap":true, "server": true, "datacenter": "$(DATACENTER)", "data_dir": "$(DATA_DIR)", "encrypt": "$(shell cat cluster.key)", "log_level": "$(LOG_LEVEL)", "enable_syslog":$(ENABLE_SYSLOG)}' \
        | tee consul-bootstrap/consul-bootstrap.json

# create img to run BS node
bootstrap_image:
	docker build -t consul-bootstrap consul-bootstrap/



server: server_config server_image
server_config:
	# make server config
	# construct some config
	echo '{"start_join":["consul"], "server": true, "datacenter": "$(DATACENTER)", "data_dir": "$(DATA_DIR)", "encrypt": "$(shell cat cluster.key)", "log_level": "$(LOG_LEVEL)", "enable_syslog":$(ENABLE_SYSLOG)}' \
        | tee consul-server/consul-server.json

server_image:
	docker build -t consul-server consul-server/


# demo agent
agent: agent_config agent_image
agent_config:
	# construct some config
	echo '{"start_join":["consul"], "datacenter": "$(DATACENTER)", "data_dir": "$(DATA_DIR)", "encrypt": "$(shell cat cluster.key)", "log_level": "$(LOG_LEVEL)", "enable_syslog":$(ENABLE_SYSLOG)}' \
	| tee consul-agent/consul-agent.json
agent_image:
	docker build -t consul-agent consul-server






# test test test 
test_base: base
	docker run -it --rm rednut/consul --help




# make new cluster key and save in file
cluster.key:
	if [ ! -f cluster.key ]; then \
	  docker run -it --rm consul-base consul keygen \
	    | \
	  tee cluster.key; \
	else \
	  echo "INFO: found existing cluster key in 'consul.d/bootstrap/cluster.key'"; \
	fi




	# check config
#	docker run -it --rm \
#	  -v $(PWD)/consul.d/bootstrap/config.json:/etc/consul.d/bootstrap/config.json \
#	  rednut/consul configtest -config-file=/etc/consul.d/bootstrap/config.json

clean:
	docker-compose kill -f || true
	docker-compose rm -f || true
	docker rm -f consul-agent consul-server consul-bootstrap consul-base
	mv -v cluster.key cluster.key.$(date +%Y-%m-%d:%H:%M:%S)


