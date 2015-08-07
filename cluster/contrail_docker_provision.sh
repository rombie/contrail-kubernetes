#!/usr/bin/env bash

set -ex

function verify_contrail_listen_services() {
    netstat -anp | \grep LISTEN | \grep -w 5672 # RabbitMQ
    netstat -anp | \grep LISTEN | \grep -w 2181 # ZooKeeper
    netstat -anp | \grep LISTEN | \grep -w 9160 # Cassandra
    netstat -anp | \grep LISTEN | \grep -w 5269 # XMPP Server
    netstat -anp | \grep LISTEN | \grep -w 8083 # Control-Node Introspect
    netstat -anp | \grep LISTEN | \grep -w 8443 # IFMAP
    netstat -anp | \grep LISTEN | \grep -w 8082 # API-Server
    netstat -anp | \grep LISTEN | \grep -w 8087 # Schema
    netstat -anp | \grep LISTEN | \grep -w 5998 # discovery
    netstat -anp | \grep LISTEN | \grep -w 8086 # Collector
    netstat -anp | \grep LISTEN | \grep -w 8081 # OpServer
    netstat -anp | \grep LISTEN | \grep -w 8091 # query-engine
    netstat -anp | \grep LISTEN | \grep -w 6379 # redis
    netstat -anp | \grep LISTEN | \grep -w 8143 # WebUI
    netstat -anp | \grep LISTEN | \grep -w 8070 # WebUI
    netstat -anp | \grep LISTEN | \grep -w 3000 # WebUI
}

function no_verify() {
    netstat -anp | \grep LISTEN | \grep -w 8094 # DNS
    netstat -anp | \grep LISTEN | \grep -w 53   # named
}

function provision_vrouter() {
    docker ps |\grep contrail-api |\grep -v pause | awk '{print "docker exec " $1 " mkdir -p /usr/share/contrail-utils/"}' | sh
    docker ps |\grep contrail-api |\grep -v pause | awk '{print "docker exec " $1 " curl -s https://raw.githubusercontent.com/Juniper/contrail-controller/R2.20/src/config/utils/provision_vrouter.py -o /usr/share/contrail-utils/provision_vrouter.py"}' | sh
    docker ps |\grep contrail-api |\grep -v pause | awk '{print "docker exec " $1 " python /usr/share/contrail-utils/provision_vrouter.py --host_name ip-172-20-0-106 --host_ip 172.20.0.106 --api_server_ip 172.20.0.9 --oper add"}' | sh
}

function provision_bgp() {
    docker ps |\grep contrail-api |\grep -v pause | awk '{print "docker exec " $1 " curl -s https://raw.githubusercontent.com/Juniper/contrail-controller/R2.20/src/config/utils/provision_control.py -o /tmp/provision_control.py"}' | sh
    docker ps |\grep contrail-api |\grep -v pause | awk '{print "docker exec " $1 " curl -s https://raw.githubusercontent.com/Juniper/contrail-controller/R2.20/src/config/utils/provision_bgp.py -o /tmp/provision_bgp.py"}' | sh
    docker ps |\grep contrail-api |\grep -v pause | awk '{print "docker exec " $1 " python /tmp/provision_control.py  --router_asn 64512 --host_name `hostname` --host_ip `hostname --ip-address` --oper add --api_server_ip `hostname --ip-address` --api_server_port 8082"}' | sh
}

function provision_linkloal() {
    docker ps |\grep contrail-api |\grep -v pause | awk '{print "docker exec " $1 " curl -s https://raw.githubusercontent.com/Juniper/contrail-controller/R2.20/src/config/utils/provision_linklocal.py -o /tmp/provision_linklocal.py"}' | sh
    docker ps |\grep contrail-api |\grep -v pause | awk '{print "docker exec " $1 " python /tmp/provision_linklocal.py --api_server_ip `hostname --ip-address` --api_server_port 8082 --linklocal_service_name kubernetes --linklocal_service_ip 10.0.0.1 --linklocal_service_port 8080 --ipfabric_service_ip `hostname --ip-` --ipfabric_service_port 8080 --oper add"}' | sh
}

function setup_kube_dns_endpoints() {
    kubectl --namespace=kube-system create -f /etc/kubernetes/addons/kube-ui/kube-ui-endpoint.yaml
    kubectl --namespace=kube-system create -f /etc/kubernetes/addons/kube-ui/kube-ui-svc-address.yaml
}

verify_contrail_listen_services
setup_kube_dns_endpoints
provision_bgp
provision_linklocal
