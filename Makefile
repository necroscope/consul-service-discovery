

DATACENTER?=stu
LOG_LEVEL?=INFO
DATA_DIR?=/var/consul
ENABLE_SYSLOG?=false


stack: cluster.key build up members

up:
	# cleanup
	docker-compose stop || true
	docker-compose rm -f || true
	docker-compose ps

	# build up
	docker-compose build --no-cache
	docker-compose up -d bootstrap
	docker-compose up -d server
	docker-compose up -d agent


demo:
	echo "DEMO:  normalizing scale prior to demo:"
	docker-compose scale server=1 agent=1 bootstrap=1

	sleep 2
	echo "DEMO:  *DEMO*"
	echo "DEMO:  consul: initial-bootstrap-node + consul-server*1 + consul-agent*1:"
	docker-compose ps
	sleep 2

	echo "DEMO:   and the cluster members:"
	docker exec -it $(shell docker-compose ps -q agent) consul members
	sleep 2

	echo "DEMO:  lets scale out number of servers:"
	docker-compose scale server=10
	docker exec -it $(shell docker-compose ps -q agent) consul members
	sleep 1

	echo "DEMO:    and scale down:"
	docker-compose scale server=3
	docker-compose ps
	docker exec -it $(shell docker-compose ps -q agent) consul members
	sleep 1

	echo "DEMO:    get agent info:"
	docker exec -it $(shell docker-compose ps -q agent) consul info
	echo "DEMO:    fun, u shall have :-)  "



logs:
	docker-compose logs

members:
	docker exec -it $(shell docker-compose ps -q agent) consul members






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
	docker build -t consul-agent consul-server/







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
	# cleanup
	docker-compose stop || true
	docker-compose rm -f || true
	docker-compose ps

	docker-compose kill -f || true
	docker-compose rm -f || true
	docker rmi -f consul-agent || true
	docker rmi -f consul-server || true
	docker rmi -f consul-bootstrap || true
	docker rmi -f consul-base || true
	test -f cluster.key && mv -v cluster.key cluster.key.$(shell date +"%Y-%m-%d:%H:%M:%S") || true


