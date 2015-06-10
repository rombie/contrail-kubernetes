#!/usr/bin/env ruby

@branch = "3.0" # master
@tag = "4100"
@pkg_tag = "#{@branch}-#{@tag}"

@common_packages = [
#   "docker",
    "curl",
    "gdebi-core",
    "git",
    "software-properties-common",
    "sshpass",
    "strace",
    "tcpdump",
    "unzip",
    "vim",
    "wget",
]

@controller_thirdparty_packages = [
    "#{@ws}/thirdparty/python-pycassa_1.11.0-1contrail2_all.deb",
    "#{@ws}/thirdparty/python-consistent-hash_1.0-0contrail1_amd64.deb",
    "#{@ws}/thirdparty/python-backports.ssl-match-hostname_3.4.0.2-1contrail1_all.deb",
    "#{@ws}/thirdparty/python-certifi_1.0.1-1contrail1_all.deb",
    "#{@ws}/thirdparty/python-geventhttpclient_1.1.0-1contrail1_amd64.deb",
    "#{@ws}/thirdparty/python-kazoo_1.3.1-1contrail2_all.deb",
    "#{@ws}/thirdparty/python-ncclient_0.4.1-1contrail1_all.deb",
    "#{@ws}/thirdparty/python-xmltodict_0.9.0-1contrail1_all.deb",
    "#{@ws}/thirdparty/librdkafka1_0.8.5-2-0contrail0.14.04_amd64.deb",
    "#{@ws}/thirdparty/python-kafka-python_0.9.2-0contrail0_all.deb",
    "#{@ws}/thirdparty/python-redis_2.8.0-1contrail1_all.deb",
    "#{@ws}/thirdparty/cassandra_1.2.11_all.deb",
    "#{@ws}/thirdparty/kafka_2.9.2-0.8.2.0-0contrail0_amd64.deb",
]

@controller_contrail_packages = [
    "#{@ws}/build/packages/python-contrail_#{@pkg_tag}_all.deb",
    "#{@ws}/build/packages/contrail-config_#{@pkg_tag}_all.deb",
    "#{@ws}/build/packages/contrail-lib_#{@pkg_tag}_amd64.deb",
    "#{@ws}/build/packages/contrail-control_#{@pkg_tag}_amd64.deb",
    "#{@ws}/build/packages/contrail-analytics_#{@pkg_tag}_amd64.deb",
    "#{@ws}/build/debian/contrail-web-core_#{@pkg_tag}_amd64.deb",
    "#{@ws}/build/debian/contrail-web-controller_#{@pkg_tag}_amd64.deb",
    "#{@ws}/build/debian/contrail-setup_#{@pkg_tag}_all.deb",
    "#{@ws}/build/debian/contrail-nodemgr_#{@pkg_tag}_all.deb",
    "#{@ws}/build/packages/contrail-utils_#{@pkg_tag}_amd64.deb",
    "#{@ws}/build/packages/contrail-dns_#{@pkg_tag}_amd64.deb",
    "#{@ws}/build/packages/ifmap-server_0.3.2-1contrail1_all.deb",
    "#{@ws}/build/packages/ifmap-python-client_0.1-2_all.deb",

    "#{@ws}/build/debian/contrail-openstack-control_#{@pkg_tag}_all.deb",
    "#{@ws}/build/debian/contrail-openstack-webui_#{@pkg_tag}_all.deb",
    "#{@ws}/build/debian/contrail-openstack-analytics_#{@pkg_tag}_all.deb",

     # "#{@ws}/build/debian/contrail-openstack-database_#{@pkg_tag}_all.deb",

#   "#{@ws}/build/debian/contrail-f5_3.0-4100_all.deb",
#   "#{@ws}/build/debian/contrail-openstack-config_#{@pkg_tag}_all.deb",
]

@compute_thirdparty_packages = [
    "#{@ws}/thirdparty/python-pycassa_1.11.0-1contrail2_all.deb",
    "#{@ws}/thirdparty/python-consistent-hash_1.0-0contrail1_amd64.deb",
    "#{@ws}/thirdparty/python-backports.ssl-match-hostname_3.4.0.2-1contrail1_all.deb",
    "#{@ws}/thirdparty/python-certifi_1.0.1-1contrail1_all.deb",
    "#{@ws}/thirdparty/python-geventhttpclient_1.1.0-1contrail1_amd64.deb",
    "#{@ws}/thirdparty/python-docker-py_0.6.1-dev_all.deb",
]

@compute_contrail_packages = [
    "#{@ws}/build/packages/python-contrail_#{@pkg_tag}_all.deb",
    "#{@ws}/build/packages/contrail-lib_#{@pkg_tag}_amd64.deb",
    "#{@ws}/build/debian/contrail-setup_#{@pkg_tag}_all.deb",
    "#{@ws}/build/packages/contrail-utils_#{@pkg_tag}_amd64.deb",
    "#{@ws}/build/debian/contrail-nodemgr_#{@pkg_tag}_all.deb",
    "#{@ws}/build/packages/contrail-vrouter-utils_#{@pkg_tag}_amd64.deb",
    "#{@ws}/build/packages/contrail-vrouter-dkms_3.0-4100_all.deb",
    "#{@ws}/build/packages/contrail-vrouter-agent_#{@pkg_tag}_amd64.deb",
    "#{@ws}/build/packages/python-contrail-vrouter-api_#{@pkg_tag}_all.deb",
    "#{@ws}/build/packages/python-opencontrail-vrouter-netns_#{@pkg_tag}_amd64.deb",
    "#{@ws}/build/debian/contrail-vrouter-init_#{@pkg_tag}_all.deb",
    "#{@ws}/build/debian/contrail-nova-vif_#{@pkg_tag}_all.deb",
#   "#{@ws}/build/debian/contrail-vrouter-common_#{@pkg_tag}_all.deb",

#   "#{@ws}/build/packages/contrail-vrouter-3.13.0-49-generic_#{@pkg_tag}_all.deb",
#   "#{@ws}/build/packages/python-vrouter-utils_#{@pkg_tag}_amd64.deb",
]

# Download and extract contrail and thirdparty rpms
def download_contrail_software
    sh("wget -qO - https://github.com/rombie/opencontrail-packages/blob/master/ubuntu1404/contrail.tar.xz?raw=true | tar Jx")
    sh("wget -qO - https://github.com/rombie/opencontrail-packages/blob/master/ubuntu1404/thirdparty.tar.xz?raw=true | tar Jx")
    sh("wget -qO - https://github.com/rombie/opencontrail-packages/blob/master/ubuntu1404/kubernetes.tar.xz?raw=true | tar Jx")
end

# Install from /cs-shared/builder/cache/centoslinux70/icehouse
def install_thirdparty_software_controller
    sh("apt-get -y install openjdk-7-jre rabbitmq-server zookeeperd")
    sh("apt-get -y install #{@common_packages.join(" ")}")
    @controller_thirdparty_packages.each { |pkg| sh("gdebi -n #{pkg}") }
end

# Install contrail controller software
def install_contrail_software_controller
    @controller_contrail_packages.each { |pkg| sh("gdebi -n #{pkg}") }

    sh("rm -rf /etc/init/zookeeper.conf")
    sh("dpkg -i --force-overwrite #{@ws}/build/debian/contrail-openstack-database_#{@pkg_tag}_all.deb")

    # Fix ubuntu specific issues
    sh("apt-get -y remove openjdk-6-jre", true)
    sh("apt-get -y autoremove")
    sh("ln -sf /etc/cassandra /etc/cassandra/conf")

    sh("dpkg -x #{@ws}/build/debian/contrail-openstack-config_#{@pkg_tag}_all.deb #{@ws}/build/debian/extract")
    sh("cp -a #{@ws}/build/debian/extract/etc/* /etc/")
    sh("openstack-config --set /etc/contrail/contrail-control.conf DEFAULT http_server_port #{@control_node_introspect_port}")
end

def build_kube_network_manager (kubernetes_branch = "release-0.17",
                                contrail_branch = "master")
    commands=<<EOF
TARGET=$HOME/contrail
CONTRAIL_BRANCH=master
KUBERNETES_BRANCH=release-0.17

rm -rf $TARGET
mkdir -p $TARGET
cd $TARGET

apt-get -y --allow-unauthenticated install curl wget software-properties-common git python-lxml gcc
wget -q -O - https://storage.googleapis.com/golang/go1.4.2.linux-amd64.tar.gz | tar -C /usr/local -zx
rm -rf /usr/bin/go
ln -sf /usr/local/go/bin/go /usr/bin/go

git clone -b $KUBERNETES_BRANCH https://github.com/googlecloudplatform/kubernetes
export GOPATH=$TARGET/kubernetes/Godeps/_workspace
go get github.com/Juniper/contrail-go-api

wget -q https://raw.githubusercontent.com/Juniper/contrail-controller/$CONTRAIL_BRANCH/src/schema/vnc_cfg.xsd
wget -q https://raw.githubusercontent.com/Juniper/contrail-controller/$CONTRAIL_BRANCH/src/schema/loadbalancer.xsd || true
git clone -b $CONTRAIL_BRANCH https://github.com/Juniper/contrail-generateDS.git
./contrail-generateDS/generateDS.py -f -o ./kubernetes/Godeps/_workspace/src/github.com/Juniper/contrail-go-api/types -g golang-api vnc_cfg.xsd 2>/dev/null

git clone -b $CONTRAIL_BRANCH https://github.com/Juniper/contrail-kubernetes ./kubernetes/Godeps/_workspace/src/github.com/Juniper/contrail-kubernetes
mkdir -p $GOPATH/src/github.com/GoogleCloudPlatform
ln -sf $TARGET/kubernetes $GOPATH/src/github.com/GoogleCloudPlatform/kubernetes

sed -i 's/ClusterIP/PortalIP/' ./kubernetes/Godeps/_workspace/src/github.com/Juniper/contrail-kubernetes/pkg/network/opencontrail/controller.go
sed -i 's/DeprecatedPublicIPs/PublicIPs/' ./kubernetes/Godeps/_workspace/src/github.com/Juniper/contrail-kubernetes/pkg/network/opencontrail/controller.go

go build github.com/Juniper/contrail-go-api/cli
go build github.com/Juniper/contrail-kubernetes/pkg/network
go build github.com/Juniper/contrail-kubernetes/cmd/kube-network-manager
EOF
    commands.split(/\n/).each { |cmd| sh(cmd) }
end

def install_contrail_from_ppa(role)
    commands=<<EOF
wget https://answers.launchpad.net/~syseleven-platform/+archive/ubuntu/contrail-2.0/+build/6635035/+files/nodejs_0.8.15-1contrail1_amd64.deb
dpkg -i nodejs_0.8.15-1contrail1_amd64.deb
add-apt-repository -y ppa:opencontrail/ppa
add-apt-repository -y ppa:opencontrail/release-2.01-juno
curl -L http://debian.datastax.com/debian/repo_key | sudo apt-key add -
sh -c 'echo "deb http://debian.datastax.com/community/ stable main" >> /etc/apt/sources.list.d/datastax.list'
apt-get -y --allow-unauthenticated update

apt-get -y --allow-unauthenticated install contrail-analytics contrail-config contrail-control contrail-web-controller contrail-dns contrail-utils cassandra zookeeperd rabbitmq-server ifmap-server
apt-get -y --allow-unauthenticated install contrail-vrouter-agent
EOF
    commands.split(/\n/).each { |cmd| sh(cmd) }
end

def create_vhost_interface(ip, mask, gw)
    intf = "/etc/network/interfaces"
    `\grep vhost0 #{intf} 2>&1 > /dev/null`
    return if $?.to_i == 0

    ifcfg = <<EOF

auto vhost0
iface vhost0 inet static
      address #{ip}
      netmask #{mask}

EOF
    File.open(intf, "a") { |fp| fp.puts(ifcfg) }
end

# Install third-party software from /cs-shared/builder/cache/ubuntu1404/icehouse
def install_thirdparty_software_compute
    sh("apt-get -y install #{@common_packages.join(" ")}")
    @compute_thirdparty_packages.each { |pkg| sh("gdebi -n #{pkg}") }
end

# Install contrail compute software
def install_contrail_software_compute
    @compute_contrail_packages.each { |pkg| sh("gdebi -n #{pkg}") }
    sh("apt-get -y autoremove")
    sh("sync; echo 3 > /proc/sys/vm/drop_caches")
end
