Vagrant.configure('2') do |config|
    config.vm.define "zk" do |zk|
        zk.vm.box = "generic/rhel8"
        zk.vm.hostname = "zk"
        zk.vm.network "private_network",ip: "#{ENV['ZOOKEEPER_IP']}"
        zk.vm.provision "file", source: './files/', destination: "/tmp/"
        zk.vm.provision "shell", inline: <<-SHELL
            sudo useradd zookeeper -d /opt/zookeeper
            sudo mkdir -p  /opt/zookeeper/{jre,logs,data}
            sudo tar -xzvf /tmp/files/#{ENV['JDK_DOWNLOAD_FILE_NAME']} --strip-components 1 -C /opt/zookeeper/jre
            sudo echo 'export JAVA_HOME=/opt/zookeeper/jre' >> /opt/zookeeper/.bashrc
            sudo echo 'export PATH=$PATH:$JAVA_HOME/bin' >> /opt/zookeeper/.bashrc
            sudo chown -R zookeeper:zookeeper  /opt/zookeeper
            sudo tar -xzvf /tmp/files/#{ENV['ZOOKEEPER_DOWNLOAD_FILE_NAME']} --strip-components 1 -C /opt/zookeeper
            sudo cp /tmp/files/config/zoo.cfg /opt/zookeeper/conf/zoo.cfg
            sudo echo "clientPortAddress=#{ENV['ZOOKEEPER_IP']}" >> /opt/zookeeper/conf/zoo.cfg
            sudo chown -R zookeeper:zookeeper  /opt/zookeeper
            sudo su - zookeeper -c "/opt/zookeeper/bin/zkServer.sh --config /opt/zookeeper/conf start"
            sudo firewall-cmd --add-port 2181/tcp --permanent 
            sudo firewall-cmd --reload
      SHELL
        zk.vm.provider "virtualbox" do |v|
            v.memory = 1024
            v.cpus = 1
      end
    end 

    config.vm.define "broker#{ENV['BROKER_ID']}" do |broker|
        broker.vm.box = "generic/rhel8"
        broker.vm.hostname = "broker#{ENV['BROKER_ID']}"
        broker.vm.network "private_network",ip: "#{ENV['BROKER_NETWORK']}#{ENV['BROKER_ID']}"
        broker.vm.provision "file", source: './files/', destination: "/tmp/"
        broker.vm.provision "shell", inline: <<-SHELL
            sudo useradd kafka -d /opt/kafka
            sudo mkdir -p  /opt/kafka/{jre,data}
            sudo tar -xzvf /tmp/files/#{ENV['JDK_DOWNLOAD_FILE_NAME']} --strip-components 1 -C /opt/kafka/jre
            sudo echo 'export JAVA_HOME=/opt/kafka/jre' >> /opt/kafka/.bashrc
            sudo echo 'export PATH=$PATH:$JAVA_HOME/bin' >> /opt/kafka/.bashrc
            sudo chown -R kafka:kafka  /opt/kafka
            sudo tar -xzvf /tmp/files/#{ENV['KAFKA_DOWNLOAD_FILE_NAME']} --strip-components 1 -C /opt/kafka
            sudo cp /tmp/files/config/server.properties /opt/kafka/config/server.properties
            sudo echo 'broker.id=#{ENV['BROKER_ID']}' >> /opt/kafka/config/server.properties
            sudo echo 'zookeeper.connect=#{ENV['ZOOKEEPER_IP']}:2181' >> /opt/kafka/config/server.properties
            sudo echo 'listeners=PLAINTEXT://#{ENV['BROKER_NETWORK']}#{ENV['BROKER_ID']}:9092' >> /opt/kafka/config/server.properties
            sudo chown -R kafka:kafka  /opt/kafka
            sudo su - kafka -c "/opt/kafka/bin/kafka-server-start.sh  -daemon /opt/kafka/config/server.properties"
            sudo firewall-cmd --add-port 9092/tcp --add-port 9093/tcp  --permanent 
            sudo firewall-cmd --reload
        SHELL
        broker.vm.provider "virtualbox" do |v|
            v.memory = 2048
            v.cpus = 2
        end
    end 
end 

