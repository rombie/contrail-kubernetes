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

# Download and extract contrail and thirdparty rpms
def download_contrail_software
end

# Install from /cs-shared/builder/cache/centoslinux70/icehouse
def install_thirdparty_software_controller
    sh("apt-get -y install #{@common_packages.join(" ")}")
end

# Install contrail controller software
def install_contrail_software_controller
    if !File.file? "nodejs_0.8.15-1contrail1_amd64.deb" then
        sh("wget https://answers.launchpad.net/~syseleven-platform/+archive/ubuntu/contrail-2.0/+build/6635035/+files/nodejs_0.8.15-1contrail1_amd64.deb")
    end
    sh("dpkg -i nodejs_0.8.15-1contrail1_amd64.deb")
    sh("dpkg -i /home/ubuntu/python-kafka-python_0.9.2-0contrail0_all.deb")

    sh("add-apt-repository -y ppa:anantha-l/opencontrail")
    sh("apt-get -y --allow-unauthenticated update")
    sh("apt-get -y --allow-unauthenticated install contrail-analytics contrail-config contrail-control contrail-web-controller contrail-dns contrail-utils cassandra zookeeperd rabbitmq-server ifmap-server")
end

def install_kube_network_manager (kubernetes_branch = "release-0.17",
                                  contrail_branch = "master")
    ENV["TARGET"]="#{ENV["HOME"]}/contrail"
    ENV["CONTRAIL_BRANCH"]="master"
    ENV["KUBERNETES_BRANCH"]="release-0.17"
    ENV["GOPATH"]="#{ENV["TARGET"]}/kubernetes/Godeps/_workspace

    sh("rm -rf #{ENV["TARGET"]}")
    sh("mkdir -p #{ENV["TARGET"]}")
    Dir.chdir(ENV["TARGET"])

    commands=<<EOF
apt-get -y --allow-unauthenticated install curl wget software-properties-common git python-lxml gcc
wget -q -O - https://storage.googleapis.com/golang/go1.4.2.linux-amd64.tar.gz | tar -C /usr/local -zx
rm -rf /usr/bin/go
ln -sf /usr/local/go/bin/go /usr/bin/go
git clone -b #{ENV["KUBERNETES_BRANCH"]} https://github.com/googlecloudplatform/kubernetes
go get github.com/Juniper/contrail-go-api
wget -q https://raw.githubusercontent.com/Juniper/contrail-controller/#{ENV["CONTRAIL_BRANCH"]}/src/schema/vnc_cfg.xsd
wget -q https://raw.githubusercontent.com/Juniper/contrail-controller/#{ENV["CONTRAIL_BRANCH"]}/src/schema/loadbalancer.xsd || true
git clone -b #{ENV["CONTRAIL_BRANCH"]} https://github.com/Juniper/contrail-generateDS.git
./contrail-generateDS/generateDS.py -f -o ./kubernetes/Godeps/_workspace/src/github.com/Juniper/contrail-go-api/types -g golang-api vnc_cfg.xsd 2>/dev/null
git clone -b #{ENV["CONTRAIL_BRANCH"]} https://github.com/Juniper/contrail-kubernetes ./kubernetes/Godeps/_workspace/src/github.com/Juniper/contrail-kubernetes
mkdir -p #{ENV["GOPATH"]}/src/github.com/GoogleCloudPlatform
ln -sf #{ENV["TARGET"]}/kubernetes #{ENV["GOPATH"]}/src/github.com/GoogleCloudPlatform/kubernetes
sed -i 's/ClusterIP/PortalIP/' ./kubernetes/Godeps/_workspace/src/github.com/Juniper/contrail-kubernetes/pkg/network/opencontrail/controller.go
sed -i 's/DeprecatedPublicIPs/PublicIPs/' ./kubernetes/Godeps/_workspace/src/github.com/Juniper/contrail-kubernetes/pkg/network/opencontrail/controller.go
go build github.com/Juniper/contrail-go-api/cli
go build github.com/Juniper/contrail-kubernetes/pkg/network
go build github.com/Juniper/contrail-kubernetes/cmd/kube-network-manager
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
end

# Install contrail compute software
def install_contrail_software_compute
    sh("sync; echo 3 > /proc/sys/vm/drop_caches")
    sh("add-apt-repository -y ppa:anantha-l/opencontrail")
    sh("apt-get -y --allow-unauthenticated update")
    sh("apt-get -y --allow-unauthenticated install contrail-vrouter-agent")
end
