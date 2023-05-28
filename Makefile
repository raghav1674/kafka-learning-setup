NUM_BROKERS ?= 1

ZOOKEEPER_IP=192.168.56.121
BROKER_NETWORK=192.168.56.13

# check for the prerequisites
check_prerequisites:
	vagrant --version && vboxmanage --version && make --version

# start related targets
install_prerequisite: check_prerequisites
	@source common.env && ./install.sh
start_zookeeper: install_prerequisite
	@source common.env && vagrant up --provision zk
start_broker/%: install_prerequisite
	@source common.env && BROKER_ID=$(@F) vagrant up --provision broker$(@F)
start_brokers: 
	@for i in `seq 0 ${NUM_BROKERS}`; do make start_broker/$$i; done;
start_all: start_zookeeper start_brokers

# stop related targets
stop_zookeeper: 
	@vagrant halt zk --force -g
stop_brokers: 
	@for i in `seq 1 ${NUM_BROKERS}`; do BROKER_ID=$$i vagrant halt broker$$i --force -g; done;
stop_all: stop_brokers stop_zookeeper

# pause/suspend related targets
suspend_zookeeper: 
	@vagrant suspend zk --force -g
suspend_brokers: 
	@for i in `seq 1 ${NUM_BROKERS}`; do BROKER_ID=$$i vagrant suspend broker$$i --force -g; done;
suspend_all: suspend_brokers suspend_zookeeper

# resume related targets
resume_zookeeper: 
	@vagrant resume zk --force -g
resume_brokers: 
	@for i in `seq 1 ${NUM_BROKERS}`; do BROKER_ID=$$i vagrant resume broker$$i --force -g; done;
resume_all: resume_brokers resume_zookeeper

# destroy related targets
destroy_zookeeper: 
	@vagrant destroy zk --force -g
destroy_brokers: 
	@for i in `seq 1 ${NUM_BROKERS}`; do BROKER_ID=$$i vagrant destroy broker$$i --force -g; done;
destroy_all: destroy_brokers destroy_zookeeper

# ssh targets
ssh_zookeeper: 
	@vagrant ssh zk --force -g
ssh_broker/%: 
	@BROKER_ID=$(@F) vagrant ssh broker$(@F)

# extra fns
describe_cluster:
	@echo "Zookeeper Node: ${ZOOKEEPER_IP}:2181" && for i in `seq 1 ${NUM_BROKERS}`; do echo "Broker-$$i Node: ${BROKER_NETWORK}$$i:9092" ; done;

start_ui:
	@broker_ips="" && \
	for i in `seq 1 ${NUM_BROKERS}`; do \
        broker_ips+="${BROKER_NETWORK}$$i:9092," ; \
    done && \
	docker run -d --net host --rm -p 9000:9000 -e KAFKA_BROKERCONNECT=$$broker_ips --name kafdrop-ui obsidiandynamics/kafdrop 

stop_ui:
	docker rm -f kafdrop-ui