#!/usr/bin/env bash

function download_if_not_present {
    local url=$1
    local download_file_name=$2
    if [ -f "files/${download_file_name}" ]
        then 
            echo -e "Skipping download of ${download_file_name}"
        else
            echo -e "Downloading ${download_file_name}"
            wget $url -O files/${download_file_name}
    fi 
}

mkdir -p files

download_if_not_present https://github.com/adoptium/temurin17-binaries/releases/download/jdk-17.0.7%2B7/OpenJDK17U-jdk_x64_linux_hotspot_17.0.7_7.tar.gz ${JDK_DOWNLOAD_FILE_NAME}

download_if_not_present https://dlcdn.apache.org/zookeeper/zookeeper-${ZOOKEEPER_VERSION}/apache-zookeeper-${ZOOKEEPER_VERSION}-bin.tar.gz ${ZOOKEEPER_DOWNLOAD_FILE_NAME}

download_if_not_present https://downloads.apache.org/kafka/${KAFKA_VERSION}/kafka_${KAFKA_SCALA_VERSION}-${KAFKA_VERSION}.tgz ${KAFKA_DOWNLOAD_FILE_NAME}


