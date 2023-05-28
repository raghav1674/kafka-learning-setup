Prerequisites:
--------------
- Install vagrant (https://developer.hashicorp.com/vagrant/docs/installation)
- Install virtualbox (https://www.virtualbox.org/wiki/Downloads)
- Install make
- Install docker - needed for ui of kafka kafdrop (https://github.com/obsidiandynamics/kafdrop)

After installing all the above prerequisite start with the following steps:
===========================================================================

1) Run `make start_all` and if you want to change the broker count Run `NUM_BROKERS=2 make start_all`
2) To Describe the cluster details, Run `make describe_cluster`
3) To Destroy the cluster, Run `make destroy_all`
4) Start ui by running `make start_ui`



Note:
-----

- Inorder to ssh into the zookeeper, run `make ssh_zookeeper`, and then `sudo su - zookeeper`, 
  there you will find all the  binaries in `/opt/zookeeper/bin` folder.

- Inorder to ssh into specific broker, run `make ssh_broker/<broker_number_starting_from_1>`, and then `sudo su - kafka`, 
  there you will find all the  binaries in `/opt/kafka/bin` folder.

- If you want to change the ips due to some reason,please change it in 
    `common.env` as well as in `Makefile`
        `ZOOKEEPER_IP`
        `BROKER_NETWORK`
- User who is using this should have permission to run vagrant,virtualbox,make,wget & docker.