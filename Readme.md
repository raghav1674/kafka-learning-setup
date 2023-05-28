Prerequisites:
--------------
- Install vagrant (https://developer.hashicorp.com/vagrant/docs/installation)
- Install virtualbox (https://www.virtualbox.org/wiki/Downloads)
- Install make
- Install docker - needed for ui of kafka kafdrop (https://github.com/obsidiandynamics/kafdrop)

After installing all the above prerequisite start with the following steps:
===========================================================================

1) Run `make start_all` and if you want to change the broker count Run `NUM_BROKERS=2 start_all`
2) To Describe the cluster details, Run `make describe_cluster`
3) To Destroy the cluster, Run `make destroy_all`
4) Start ui by running `make start_ui`


Note:
-----
- If you want to change the ips due to some reason,please change it in 
    `common.env` as well as in `Makefile`
        `ZOOKEEPER_IP`
        `BROKER_NETWORK`
- User who is using this should have permission to run vagrant,virtualbox,make,wget & docker.